/**
 * Batch class to replace Contract scheduled flow
 * Replicates EXACT flow business logic for contract revenue calculations and status updates
 * 
 * Flow Logic Replicated:
 * - Processes contracts with Status != null AND Status != 'Expired'
 * - Contract Status Logic:
 *   - Before Start Date: No action (exit flow)
 *   - Within Start & End Dates + Exclude_from_Status_Updates__c = false: Status = 'Activated'
 *   - After End Date + Status != 'Expired' + Exclude_from_Status_Updates__c = false: Status = 'Expired'
 * - Revenue Calculations:
 *   - Nullify all revenue fields first
 *   - Loop through related assets (Exclude_from_Status_Updates__c = false)
 *   - Add revenue totals (TCV from Total_Value__c, others from respective fields)
 *   - Check if asset is active (Start_Date <= TODAY, End_Date >= TODAY, ProductFamily != 'Professional Service')
 *   - If active: Add to ARR, ACV (Total_Price__c), Active_ARR, USD totals, counts
 *   - Calculate MRR = ARR / 12
 *   - Calculate Incremental ARR = IF(ISNULL(Previous_ARR), ARR, ARR - Previous_ARR)
 *   - Format USD fields using CurrencyFormatterHelper
 */
public class ContractRevenueBatch implements Database.Batchable<sObject> {
    
    /**
     * Query ALL contracts for legacy data safe processing:
     * - Include Draft, Activated, Expired, and null status contracts
     * - Legacy data protection: only populate empty fields
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
                   ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
                   ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
                   (SELECT Id, ARR__c, MRR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                           Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
                    FROM Assets__r 
                    WHERE Exclude_from_Status_Updates__c = false)
            FROM Contract 
            // Process ALL contracts - no status exclusions for legacy data safety
        ]);
    }
    
    /**
     * Process each batch of contracts using exact flow logic
     */
    public void execute(Database.BatchableContext bc, List<Contract> contracts) {
        List<Contract> contractsToUpdate = new List<Contract>();
        Date today = Date.today();
        
        for (Contract contract : contracts) {
            Contract updatedContract = processContract(contract, today);
            
            if (updatedContract != null) {
                contractsToUpdate.add(updatedContract);
            }
        }
        
        // Bulk update - matches flow's Update_Contract element
        if (!contractsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(contractsToUpdate, false);
                
                // Log any failures
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        System.debug(LoggingLevel.ERROR, 
                            'ContractRevenueBatch: Failed to update Contract ' + contractsToUpdate[i].Id + 
                            ': ' + results[i].getErrors());
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: Exception during update: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Chain to Account processing after Contract processing completes
     */
    public void finish(Database.BatchableContext bc) {
        // Sequential execution: Asset → Contract → Account
        Database.executeBatch(new AccountRollupBatch(), 100);
        System.debug('ContractRevenueBatch: Processing complete, chaining to AccountRollupBatch');
    }
    
    /**
     * Legacy-safe Contract processing logic
     * 
     * Processing Rules:
     * 1. Status Updates: Handle Draft→Activated, Activated maintenance, Expired preservation
     * 2. Revenue Fields: Only populate if empty (Draft) or always recalculate (Active/Activated)
     * 3. USD Fields: Only populate if currently empty/null
     * 4. Expired Contracts: Preserve existing data, only fill gaps
     */
    private Contract processContract(Contract contract, Date today) {
        Boolean needsUpdate = false;
        
        // Step 1: Handle status updates (including Draft → Activated)
        String newStatus = determineContractStatus(contract, today);
        if (newStatus != null) {
            contract.Status = newStatus;
            needsUpdate = true;
        }
        
        // Step 2: Determine if we should populate revenue fields (legacy data safe)
        Boolean shouldPopulateRevenue = false;
        if (contract.Status == 'Draft' || contract.Status == null) {
            // Legacy Draft/null: Only if revenue fields are empty
            if (contract.ARR__c == null || contract.ARR__c == 0) {
                shouldPopulateRevenue = true;
            }
        } else if (contract.Status == 'Activated') {
            // Activated contracts: Always recalculate (automation managed)
            shouldPopulateRevenue = true;
        }
        // Expired contracts: Never recalculate revenue (preserve historical)
        
        // Step 3: Revenue calculations (conditional for legacy data safety)
        if (shouldPopulateRevenue) {
            // Nullify and recalculate revenue fields
            contract.ARR__c = 0;
            contract.Active_ARR__c = 0;
            contract.ACV__c = 0;
            contract.MRR__c = 0;
            contract.TCV__c = 0;
            needsUpdate = true;
        
        // Step 4: Process related assets (Get_Related_Assets + Loop_Related_Assets)
        Decimal varARR_Total = 0;
        Decimal varACV_Total = 0;
        Decimal varTCV_Total = 0;
        Decimal varActiveARR_Total = 0;
        Decimal varMRR_Total = 0;
        Decimal varActiveAssetCount = 0;
        Decimal varTotalAssetCount = 0;
        Decimal varAssetsStartedCount = 0;
        
        for (Asset asset : contract.Assets__r) {
            // Add_Revenue_Totals logic (exact flow replication)
            contract.TCV__c += asset.Total_Value__c != null ? asset.Total_Value__c : 0;
            
            Decimal forTCV_USD = (asset.Total_Value__c != null ? asset.Total_Value__c : 0) * 
                                 (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
            varTCV_Total += forTCV_USD;
            
            varTotalAssetCount += 1;
            
            // forAssetHasStarted formula: IF(Start_Date__c <= TODAY(), 1, 0)
            if (asset.Start_Date__c <= today) {
                varAssetsStartedCount += 1;
            }
            
            // Is_Asset_Active decision logic (exact flow replication)
            if (asset.Start_Date__c <= today && 
                asset.End_Date__c >= today && 
                asset.ProductFamily != 'Professional Service') {
                
                // Add_Active_ARR logic (exact flow replication)
                contract.ARR__c += asset.ARR__c != null ? asset.ARR__c : 0;
                contract.ACV__c += asset.Total_Price__c != null ? asset.Total_Price__c : 0;
                contract.Active_ARR__c += asset.ARR__c != null ? asset.ARR__c : 0;
                
                // USD calculations (exact flow formulas)
                Decimal forARR_USD = (asset.ARR__c != null ? asset.ARR__c : 0) * 
                                     (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                Decimal forACV_USD = (asset.Total_Price__c != null ? asset.Total_Price__c : 0) * 
                                     (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                Decimal forMRR_USD = (asset.MRR__c != null ? asset.MRR__c : 0) * 
                                     (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                
                varARR_Total += forARR_USD;
                varACV_Total += forACV_USD;
                varActiveARR_Total += forARR_USD;
                varMRR_Total += forMRR_USD;
                varActiveAssetCount += 1;
            }
        }
        
        }
        
        // Step 4: USD fields - Only populate if empty (legacy data safe)
        Boolean shouldPopulateUSD = (String.isBlank(contract.ARR_USD__c) || 
                                    String.isBlank(contract.TCV_USD__c) || 
                                    String.isBlank(contract.ACV_USD__c) ||
                                    String.isBlank(contract.MRR_USD__c) ||
                                    String.isBlank(contract.Active_ARR_USD__c));
        
        if (shouldPopulateUSD) {
            // Calculate USD totals from assets (even if revenue fields weren't recalculated)
            Decimal varARR_Total = 0;
            Decimal varACV_Total = 0;
            Decimal varTCV_Total = 0;
            Decimal varActiveARR_Total = 0;
            Decimal varMRR_Total = 0;
            
            for (Asset asset : contract.Assets__r) {
                // TCV calculation
                Decimal forTCV_USD = (asset.Total_Value__c != null ? asset.Total_Value__c : 0) * 
                                     (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                varTCV_Total += forTCV_USD;
                
                // Active asset USD calculations
                if (asset.Start_Date__c <= today && 
                    asset.End_Date__c >= today && 
                    asset.ProductFamily != 'Professional Service') {
                    
                    Decimal forARR_USD = (asset.ARR__c != null ? asset.ARR__c : 0) * 
                                         (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    Decimal forACV_USD = (asset.Total_Price__c != null ? asset.Total_Price__c : 0) * 
                                         (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    Decimal forMRR_USD = (asset.MRR__c != null ? asset.MRR__c : 0) * 
                                         (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    
                    varARR_Total += forARR_USD;
                    varACV_Total += forACV_USD;
                    varActiveARR_Total += forARR_USD;
                    varMRR_Total += forMRR_USD;
                }
            }
            
            // Step 5: Format currency using CurrencyFormatterHelper (only if USD fields empty)
            try {
                if (String.isBlank(contract.ARR_USD__c)) {
                    CurrencyFormatterHelper.FormatInput request1 = new CurrencyFormatterHelper.FormatInput();
                    request1.amount = varARR_Total;
                    List<CurrencyFormatterHelper.FormatInput> requests1 = new List<CurrencyFormatterHelper.FormatInput>{request1};
                    List<CurrencyFormatterHelper.FormatOutput> responses1 = CurrencyFormatterHelper.formatCurrency(requests1);
                    contract.ARR_USD__c = responses1[0].formattedAmount;
                }
                
                if (String.isBlank(contract.ACV_USD__c)) {
                    CurrencyFormatterHelper.FormatInput request2 = new CurrencyFormatterHelper.FormatInput();
                    request2.amount = varACV_Total;
                    List<CurrencyFormatterHelper.FormatInput> requests2 = new List<CurrencyFormatterHelper.FormatInput>{request2};
                    List<CurrencyFormatterHelper.FormatOutput> responses2 = CurrencyFormatterHelper.formatCurrency(requests2);
                    contract.ACV_USD__c = responses2[0].formattedAmount;
                }
                
                if (String.isBlank(contract.TCV_USD__c)) {
                    CurrencyFormatterHelper.FormatInput request3 = new CurrencyFormatterHelper.FormatInput();
                    request3.amount = varTCV_Total;
                    List<CurrencyFormatterHelper.FormatInput> requests3 = new List<CurrencyFormatterHelper.FormatInput>{request3};
                    List<CurrencyFormatterHelper.FormatOutput> responses3 = CurrencyFormatterHelper.formatCurrency(requests3);
                    contract.TCV_USD__c = responses3[0].formattedAmount;
                }
                
                if (String.isBlank(contract.Active_ARR_USD__c)) {
                    CurrencyFormatterHelper.FormatInput request4 = new CurrencyFormatterHelper.FormatInput();
                    request4.amount = varActiveARR_Total;
                    List<CurrencyFormatterHelper.FormatInput> requests4 = new List<CurrencyFormatterHelper.FormatInput>{request4};
                    List<CurrencyFormatterHelper.FormatOutput> responses4 = CurrencyFormatterHelper.formatCurrency(requests4);
                    contract.Active_ARR_USD__c = responses4[0].formattedAmount;
                }
                
                if (String.isBlank(contract.MRR_USD__c)) {
                    CurrencyFormatterHelper.FormatInput request5 = new CurrencyFormatterHelper.FormatInput();
                    request5.amount = varMRR_Total;
                    List<CurrencyFormatterHelper.FormatInput> requests5 = new List<CurrencyFormatterHelper.FormatInput>{request5};
                    List<CurrencyFormatterHelper.FormatOutput> responses5 = CurrencyFormatterHelper.formatCurrency(requests5);
                    contract.MRR_USD__c = responses5[0].formattedAmount;
                }
                
                needsUpdate = true;
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: Currency formatting error for Contract ' + contract.Id + ': ' + e.getMessage());
            }
        }
        
        
        // Step 6: Final calculations (only if revenue fields were recalculated)
        if (shouldPopulateRevenue) {
            // forC_MRR formula: ARR / 12
            contract.MRR__c = contract.ARR__c != null ? contract.ARR__c / 12 : 0;
            
            // forC_iARR formula: IF(ISNULL(Previous_ARR), ARR, ARR - Previous_ARR)
            if (contract.Previous_ARR__c == null) {
                contract.Incremental_ARR__c = contract.ARR__c != null ? contract.ARR__c : 0;
            } else {
                contract.Incremental_ARR__c = (contract.ARR__c != null ? contract.ARR__c : 0) - contract.Previous_ARR__c;
            }
        }
        
        return needsUpdate ? contract : null;
    }
    
    /**
     * Legacy-safe Contract status determination logic
     * 
     * Status Rules:
     * Rule 1: Draft/null → Activated (if within date range)
     * Rule 2: Within Start & End Dates → Activated
     * Rule 3: After End Date → Expired
     * Rule 4: Before Start Date → No change (preserve Draft for future activation)
     */
    private String determineContractStatus(Contract contract, Date today) {
        // Skip if excluded from status updates
        if (contract.Exclude_from_Status_Updates__c == true) {
            return null;
        }
        
        // Rule 1: Draft/null contracts within date range should be Activated
        if ((contract.Status == 'Draft' || contract.Status == null) &&
            contract.StartDate <= today && 
            contract.EndDate >= today) {
            System.debug('ContractRevenueBatch: Draft/null Contract ' + contract.Id + ' should be Activated');
            return 'Activated';
        }
        
        // Rule 2: Within Start & End Dates (for non-Draft contracts)
        if (contract.StartDate <= today && 
            contract.EndDate >= today && 
            contract.Status != 'Activated') {
            System.debug('ContractRevenueBatch: Contract ' + contract.Id + ' should be Activated');
            return 'Activated';
        }
        
        // Rule 3: After End Date
        if (contract.EndDate < today && 
            contract.Status != 'Expired') {
            System.debug('ContractRevenueBatch: Contract ' + contract.Id + ' should be Expired');
            return 'Expired';
        }
        
        // Rule 4: Before Start Date - preserve current status (no change)
        // This allows Draft contracts to remain Draft until their start date
        
        return null; // No status change needed
    }
}