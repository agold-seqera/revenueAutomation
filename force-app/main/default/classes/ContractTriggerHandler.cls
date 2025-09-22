public with sharing class ContractTriggerHandler {
    
    // Prevent recursion
    private static Boolean isProcessingUSDFormatting = false;
    private static Boolean isProcessingAccountFields = false;
    
    public static void handleAfterInsertUpdate(List<Contract> contracts, Map<Id, Contract> oldMap) {
        // Prevent recursion when we update contracts
        if (isProcessingUSDFormatting) {
            return;
        }
        
        // Only process UPDATE operations to ensure Assets exist before USD formatting
        // INSERT operations should leave USD fields as NULL for later formatting
        if (Trigger.isInsert) {
            return;
        }
        
        Set<Id> contractIdsToFormat = new Set<Id>();
        
        for (Contract contract : contracts) {
            // Only process Draft contracts that need USD formatting or Incremental ARR calculation
            if (contract.Status == 'Draft' && (needsUSDFormatting(contract) || needsIncrementalARR(contract))) {
                contractIdsToFormat.add(contract.Id);
            }
        }
        
        // Use @future method to process USD formatting in separate transaction
        // This ensures Assets are fully committed and visible
        // CRITICAL: Skip @future calls when running in batch context to avoid AsyncException
        if (!contractIdsToFormat.isEmpty()) {
            if (System.isBatch() || System.isFuture()) {
                // In batch or future context: use synchronous processing
                processContractFieldsSync(contractIdsToFormat);
            } else {
                // In regular trigger context: use @future for separation
                processContractFieldsAsync(contractIdsToFormat);
            }
        }
        
        // Update Account contract fields for all INSERT and UPDATE operations
        if (!isProcessingAccountFields) {
            updateAccountContractFields(contracts, oldMap, Trigger.operationType);
        }
    }
    
    private static Boolean needsUSDFormatting(Contract contract) {
        // Check if any USD fields are null or placeholder values (including '--.00')
        return (contract.ARR_USD__c == null || contract.ARR_USD__c == '$0.00' || contract.ARR_USD__c == '--.00') ||
               (contract.ACV_USD__c == null || contract.ACV_USD__c == '$0.00' || contract.ACV_USD__c == '--.00') ||
               (contract.TCV_USD__c == null || contract.TCV_USD__c == '$0.00' || contract.TCV_USD__c == '--.00') ||
               (contract.MRR_USD__c == null || contract.MRR_USD__c == '$0.00' || contract.MRR_USD__c == '--.00');
    }
    
    private static Boolean needsIncrementalARR(Contract contract) {
        // Only calculate Incremental ARR (and USD) if they're currently null/blank
        // Also check all Previous USD fields if Previous_ARR exists
        return contract.Incremental_ARR__c == null || 
               contract.Incremental_ARR_USD__c == null || 
               contract.Incremental_ARR_USD__c == '$0.00' || 
               contract.Incremental_ARR_USD__c == '--.00' ||
               (contract.Previous_ARR__c != null && 
                (contract.Previous_ARR_USD__c == null || 
                 contract.Previous_ARR_USD__c == '$0.00' || 
                 contract.Previous_ARR_USD__c == '--.00' ||
                 contract.Previous_ACV_USD__c == null || 
                 contract.Previous_ACV_USD__c == '$0.00' || 
                 contract.Previous_ACV_USD__c == '--.00' ||
                 contract.Previous_TCV_USD__c == null || 
                 contract.Previous_TCV_USD__c == '$0.00' || 
                 contract.Previous_TCV_USD__c == '--.00' ||
                 contract.Previous_MRR_USD__c == null || 
                 contract.Previous_MRR_USD__c == '$0.00' || 
                 contract.Previous_MRR_USD__c == '--.00'));
    }
    
    private static void processContractFields(List<Contract> contracts) {
        try {
            isProcessingUSDFormatting = true;
            
            // Get exchange rates from assets for each contract - preserves original rates
            Map<Id, Decimal> contractExchangeRates = getContractExchangeRates(contracts);
            
            // Prepare amounts for formatting
            List<CurrencyFormatterHelper.FormatInput> formatInputs = new List<CurrencyFormatterHelper.FormatInput>();
            List<ContractAmountInfo> contractAmounts = new List<ContractAmountInfo>();
            
            for (Contract contract : contracts) {
                Decimal exchangeRate = contractExchangeRates.get(contract.Id);
                if (exchangeRate == null) exchangeRate = 1.0; // Default to 1 if no rate found
                
                ContractAmountInfo info = new ContractAmountInfo();
                info.contract = contract;
                info.exchangeRate = exchangeRate;
                contractAmounts.add(info);
                
                // Only add amounts for formatting if this contract needs USD formatting
                if (needsUSDFormatting(contract)) {
                    addAmountToFormat(formatInputs, contract.Initial_ARR__c, exchangeRate);
                    addAmountToFormat(formatInputs, contract.Initial_ACV__c, exchangeRate);
                    addAmountToFormat(formatInputs, contract.Initial_TCV__c, exchangeRate);
                    addAmountToFormat(formatInputs, contract.Initial_MRR__c, exchangeRate);
                }
            }
            
            // Format all amounts in one call (only if we have amounts to format)
            List<CurrencyFormatterHelper.FormatOutput> formatOutputs = new List<CurrencyFormatterHelper.FormatOutput>();
            if (!formatInputs.isEmpty()) {
                formatOutputs = CurrencyFormatterHelper.formatCurrency(formatInputs);
            }
            
            // Apply formatted values back to contracts
            List<Contract> contractsToUpdate = new List<Contract>();
            Integer outputIndex = 0;
            
            for (ContractAmountInfo info : contractAmounts) {
                Contract contractToUpdate = new Contract(Id = info.contract.Id);
                
                // Initialize formatted amounts as null (only populate if we have formatting to do)
                String formattedARR = null;
                String formattedACV = null;
                String formattedTCV = null;
                String formattedMRR = null;
                
                // Get the four formatted amounts for this contract (if it needs USD formatting)
                if (needsUSDFormatting(info.contract)) {
                    formattedARR = formatOutputs[outputIndex++].formattedAmount;
                    formattedACV = formatOutputs[outputIndex++].formattedAmount;
                    formattedTCV = formatOutputs[outputIndex++].formattedAmount;
                    formattedMRR = formatOutputs[outputIndex++].formattedAmount;
                }
                
                // Set both Initial and Current USD fields (only if they need formatting)
                if (needsUSDFormatting(info.contract)) {
                    contractToUpdate.Initial_ARR_USD__c = formattedARR;
                    contractToUpdate.ARR_USD__c = formattedARR;
                    contractToUpdate.Initial_ACV_USD__c = formattedACV;
                    contractToUpdate.ACV_USD__c = formattedACV;
                    contractToUpdate.Initial_TCV_USD__c = formattedTCV;
                    contractToUpdate.TCV_USD__c = formattedTCV;
                    contractToUpdate.Initial_MRR_USD__c = formattedMRR;
                    contractToUpdate.MRR_USD__c = formattedMRR;
                }
                
                // Calculate Incremental ARR if needed
                if (needsIncrementalARR(info.contract)) {
                    // Calculate Incremental ARR: If Previous_ARR is null (new business), use Current ARR
                    // Otherwise, use Current ARR - Previous ARR (renewals)
                    Decimal incrementalARR = (info.contract.Previous_ARR__c == null) ? 
                                           info.contract.ARR__c : 
                                           (info.contract.ARR__c - info.contract.Previous_ARR__c);
                    
                    contractToUpdate.Incremental_ARR__c = incrementalARR;
                    
                    // Calculate all Previous USD fields if Previous_ARR exists
                    if (info.contract.Previous_ARR__c != null) {
                        // Calculate Previous USD amounts
                        Decimal previousARR_USD = info.contract.Previous_ARR__c * info.exchangeRate;
                        Decimal previousACV_USD = info.contract.Previous_ARR__c * info.exchangeRate; // ACV = ARR for renewals
                        Decimal previousTCV_USD = info.contract.Previous_ARR__c * info.exchangeRate; // TCV = ARR for renewals  
                        Decimal previousMRR_USD = (info.contract.Previous_ARR__c / 12) * info.exchangeRate;
                        
                        // Format all Previous USD amounts in one call
                        List<CurrencyFormatterHelper.FormatInput> previousInputs = new List<CurrencyFormatterHelper.FormatInput>();
                        
                        CurrencyFormatterHelper.FormatInput arrInput = new CurrencyFormatterHelper.FormatInput();
                        arrInput.amount = previousARR_USD;
                        previousInputs.add(arrInput);
                        
                        CurrencyFormatterHelper.FormatInput acvInput = new CurrencyFormatterHelper.FormatInput();
                        acvInput.amount = previousACV_USD;
                        previousInputs.add(acvInput);
                        
                        CurrencyFormatterHelper.FormatInput tcvInput = new CurrencyFormatterHelper.FormatInput();
                        tcvInput.amount = previousTCV_USD;
                        previousInputs.add(tcvInput);
                        
                        CurrencyFormatterHelper.FormatInput mrrInput = new CurrencyFormatterHelper.FormatInput();
                        mrrInput.amount = previousMRR_USD;
                        previousInputs.add(mrrInput);
                        
                        List<CurrencyFormatterHelper.FormatOutput> previousOutputs = CurrencyFormatterHelper.formatCurrency(previousInputs);
                        contractToUpdate.Previous_ARR_USD__c = previousOutputs[0].formattedAmount;
                        contractToUpdate.Previous_ACV_USD__c = previousOutputs[1].formattedAmount;
                        contractToUpdate.Previous_TCV_USD__c = previousOutputs[2].formattedAmount;
                        contractToUpdate.Previous_MRR_USD__c = previousOutputs[3].formattedAmount;
                    }
                    
                    // Calculate Incremental ARR USD using the same exchange rate
                    Decimal incrementalARR_USD = (incrementalARR != null) ? incrementalARR * info.exchangeRate : 0;
                    
                    // Format the USD amount
                    List<CurrencyFormatterHelper.FormatInput> incrementalInput = new List<CurrencyFormatterHelper.FormatInput>();
                    CurrencyFormatterHelper.FormatInput input = new CurrencyFormatterHelper.FormatInput();
                    input.amount = incrementalARR_USD;
                    incrementalInput.add(input);
                    
                    List<CurrencyFormatterHelper.FormatOutput> incrementalOutput = CurrencyFormatterHelper.formatCurrency(incrementalInput);
                    contractToUpdate.Incremental_ARR_USD__c = incrementalOutput[0].formattedAmount;
                }
                
                contractsToUpdate.add(contractToUpdate);
            }
            
            // Update all contracts
            if (!contractsToUpdate.isEmpty()) {
                update contractsToUpdate;
            }
            
        } catch (Exception e) {
            System.debug('Error in ContractTriggerHandler: ' + e.getMessage());
            // Don't throw exception to avoid blocking the original transaction
        } finally {
            isProcessingUSDFormatting = false;
        }
    }
    
    private static void addAmountToFormat(List<CurrencyFormatterHelper.FormatInput> formatInputs, Decimal amount, Decimal exchangeRate) {
        CurrencyFormatterHelper.FormatInput input = new CurrencyFormatterHelper.FormatInput();
        input.amount = (amount != null) ? amount * exchangeRate : 0;
        formatInputs.add(input);
    }
    
    private static Map<Id, Decimal> getContractExchangeRates(List<Contract> contracts) {
        Map<Id, Decimal> contractRates = new Map<Id, Decimal>();
        
        if (contracts.isEmpty()) {
            return contractRates;
        }
        
        // Get contract IDs
        Set<Id> contractIds = new Set<Id>();
        for (Contract contract : contracts) {
            contractIds.add(contract.Id);
        }
        
        // Query Asset exchange rates for each contract - use the same rates as the flows
        // This preserves the exchange rate from when the assets were originally created
        for (Asset asset : [
            SELECT Contract__c, Exchange_Rate__c, CurrencyIsoCode
            FROM Asset 
            WHERE Contract__c IN :contractIds
            AND Exchange_Rate__c != null
            LIMIT 200
        ]) {
            // Use the first asset's exchange rate for each contract
            // All assets on the same contract should have the same exchange rate
            if (!contractRates.containsKey(asset.Contract__c)) {
                Decimal rate = asset.Exchange_Rate__c;
                if (rate == null || rate == 0) {
                    rate = 1.0; // Default for USD or missing rates
                }
                contractRates.put(asset.Contract__c, rate);
            }
        }
        
        return contractRates;
    }
    
    /**
     * Synchronous version of contract fields processing for batch context
     * Avoids AsyncException when called from batch operations
     */
    public static void processContractFieldsSync(Set<Id> contractIds) {
        processContractFieldsInternal(contractIds);
    }
    
    // @future method to process USD formatting in separate transaction
    // This ensures Assets are fully committed and visible when USD calculation runs
    @future
    public static void processContractFieldsAsync(Set<Id> contractIds) {
        processContractFieldsInternal(contractIds);
    }
    
    /**
     * Internal method that contains the actual contract processing logic
     * Used by both sync and async versions
     */
    private static void processContractFieldsInternal(Set<Id> contractIds) {
        try {
            // Query contracts with all necessary fields
            List<Contract> contracts = [
                SELECT Id, Status, CurrencyIsoCode,
                       ARR__c, ACV__c, TCV__c, MRR__c,
                       Initial_ARR__c, Initial_ACV__c, Initial_TCV__c, Initial_MRR__c,
                       ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                       Initial_ARR_USD__c, Initial_ACV_USD__c, Initial_TCV_USD__c, Initial_MRR_USD__c,
                       Incremental_ARR__c, Incremental_ARR_USD__c, Previous_ARR__c, 
                       Previous_ARR_USD__c, Previous_ACV_USD__c, Previous_TCV_USD__c, Previous_MRR_USD__c
                FROM Contract
                WHERE Id IN :contractIds
                AND Status = 'Draft'
            ];
            
            if (!contracts.isEmpty()) {
                processContractFields(contracts);
            }
            
        } catch (Exception e) {
            System.debug('Error in processContractFieldsAsync: ' + e.getMessage());
        }
    }

    // Helper class to track contract and exchange rate info
    private class ContractAmountInfo {
        public Contract contract;
        public Decimal exchangeRate;
    }
    
    // Account field update methods for Has_Contracts__c and Contract_Count__c
    private static void updateAccountContractFields(List<Contract> contracts, Map<Id, Contract> oldMap, System.TriggerOperation operationType) {
        Set<Id> accountIds = new Set<Id>();
        
        // Collect Account IDs from contracts
        if (contracts != null) {
            for (Contract contract : contracts) {
                if (contract.AccountId != null) {
                    accountIds.add(contract.AccountId);
                }
            }
        }
        
        // For updates, also check old account values (in case contract moved accounts)
        if (operationType == System.TriggerOperation.AFTER_UPDATE && oldMap != null) {
            for (Contract contract : contracts) {
                Contract oldContract = oldMap.get(contract.Id);
                if (oldContract != null && oldContract.AccountId != null && 
                    oldContract.AccountId != contract.AccountId) {
                    accountIds.add(oldContract.AccountId);
                }
            }
        }
        
        if (!accountIds.isEmpty()) {
            if (System.isBatch() || System.isFuture()) {
                // In batch or future context: use synchronous processing
                updateAccountFieldsSync(accountIds);
            } else {
                // In regular trigger context: use @future for separation
                updateAccountFieldsAsync(accountIds);
            }
        }
    }
    
    // Handle delete/undelete operations for account field updates only
    public static void handleAccountFieldUpdates(List<Contract> contracts, System.TriggerOperation operationType) {
        if (isProcessingAccountFields) return;
        
        Set<Id> accountIds = new Set<Id>();
        
        for (Contract contract : contracts) {
            if (contract.AccountId != null) {
                accountIds.add(contract.AccountId);
            }
        }
        
        if (!accountIds.isEmpty()) {
            if (System.isBatch() || System.isFuture()) {
                // In batch or future context: use synchronous processing
                updateAccountFieldsSync(accountIds);
            } else {
                // In regular trigger context: use @future for separation
                updateAccountFieldsAsync(accountIds);
            }
        }
    }
    
    /**
     * Synchronous version of account fields update for batch context
     * Avoids AsyncException when called from batch operations
     */
    public static void updateAccountFieldsSync(Set<Id> accountIds) {
        updateAccountFieldsInternal(accountIds);
    }
    
    @future
    private static void updateAccountFieldsAsync(Set<Id> accountIds) {
        updateAccountFieldsInternal(accountIds);
    }
    
    /**
     * Internal method that contains the actual account fields update logic
     * Used by both sync and async versions
     */
    private static void updateAccountFieldsInternal(Set<Id> accountIds) {
        if (isProcessingAccountFields) return;
        
        try {
            isProcessingAccountFields = true;
            
            Map<Id, Integer> accountContractCounts = new Map<Id, Integer>();
            
            // Initialize all accounts with 0 count
            for (Id accountId : accountIds) {
                accountContractCounts.put(accountId, 0);
            }
            
            // Get actual contract counts
            for (AggregateResult ar : [
                SELECT AccountId, COUNT(Id) contractCount 
                FROM Contract 
                WHERE AccountId IN :accountIds 
                GROUP BY AccountId
            ]) {
                Id accountId = (Id)ar.get('AccountId');
                Integer count = (Integer)ar.get('contractCount');
                accountContractCounts.put(accountId, count);
            }
            
            // Build account updates
            List<Account> accountsToUpdate = new List<Account>();
            for (Id accountId : accountIds) {
                Integer contractCount = accountContractCounts.get(accountId);
                Boolean hasContracts = contractCount != null && contractCount > 0;
                
                accountsToUpdate.add(new Account(
                    Id = accountId,
                    Has_Contracts__c = hasContracts,
                    Contract_Count__c = contractCount != null ? contractCount : 0
                ));
            }
            
            // Bulk update with error handling
            if (!accountsToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(accountsToUpdate, false);
                
                // Log any errors
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        System.debug(LoggingLevel.ERROR, 
                            'Failed to update Account contract fields for ' + accountsToUpdate[i].Id + 
                            ': ' + results[i].getErrors());
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in updateAccountFieldsAsync: ' + e.getMessage());
        } finally {
            isProcessingAccountFields = false;
        }
    }
}