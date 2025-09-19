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
     * Query contracts matching exact flow criteria:
     * Status != null AND Status != 'Expired'
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
            WHERE Status != null AND Status != 'Expired'
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
     * Replicate exact Contract flow logic for single contract
     * 
     * Flow Sequence:
     * 1. Check_Contract_Start_End_Dates decision
     * 2. If within dates → Assign_Contract_Status_Activated → Nullify_Revenue_Fields
     * 3. If after end date → Assign_Contract_Status_Expired → Update_Contract
     * 4. If before start date → Exit (no processing)
     * 5. Get_Related_Assets → Loop_Related_Assets
     * 6. For each asset: Add_Revenue_Totals → Is_Asset_Active decision
     * 7. If asset active: Add_Active_ARR
     * 8. Format currency using CurrencyFormatterHelper
     * 9. Assign final calculations (MRR, Incremental ARR)
     * 10. Update_Contract
     */
    private Contract processContract(Contract contract, Date today) {
        Boolean needsUpdate = false;
        
        // Step 1: Check_Contract_Start_End_Dates decision logic
        String newStatus = determineContractStatus(contract, today);
        if (newStatus != null) {
            contract.Status = newStatus;
            needsUpdate = true;
        }
        
        // Step 2: Exit early if before start date (flow logic)
        if (contract.StartDate > today) {
            return needsUpdate ? contract : null;
        }
        
        // Step 3: Nullify_Revenue_Fields (exact flow logic)
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
        
        // Step 5: Format currency using CurrencyFormatterHelper (exact flow logic)
        try {
            // Format_Currency_Action_1: Format ARR (USD)
            CurrencyFormatterHelper.FormatInput request1 = new CurrencyFormatterHelper.FormatInput();
            request1.amount = varARR_Total;
            List<CurrencyFormatterHelper.FormatInput> requests1 = new List<CurrencyFormatterHelper.FormatInput>{request1};
            List<CurrencyFormatterHelper.FormatOutput> responses1 = CurrencyFormatterHelper.formatCurrency(requests1);
            contract.ARR_USD__c = responses1[0].formattedAmount;
            
            // Format_Currency_Action_2: Format ACV (USD)
            CurrencyFormatterHelper.FormatInput request2 = new CurrencyFormatterHelper.FormatInput();
            request2.amount = varACV_Total;
            List<CurrencyFormatterHelper.FormatInput> requests2 = new List<CurrencyFormatterHelper.FormatInput>{request2};
            List<CurrencyFormatterHelper.FormatOutput> responses2 = CurrencyFormatterHelper.formatCurrency(requests2);
            contract.ACV_USD__c = responses2[0].formattedAmount;
            
            // Format_Currency_Action_3: Format TCV (USD)
            CurrencyFormatterHelper.FormatInput request3 = new CurrencyFormatterHelper.FormatInput();
            request3.amount = varTCV_Total;
            List<CurrencyFormatterHelper.FormatInput> requests3 = new List<CurrencyFormatterHelper.FormatInput>{request3};
            List<CurrencyFormatterHelper.FormatOutput> responses3 = CurrencyFormatterHelper.formatCurrency(requests3);
            contract.TCV_USD__c = responses3[0].formattedAmount;
            
            // Format_Currency_Action_4: Format Active ARR (USD)
            CurrencyFormatterHelper.FormatInput request4 = new CurrencyFormatterHelper.FormatInput();
            request4.amount = varActiveARR_Total;
            List<CurrencyFormatterHelper.FormatInput> requests4 = new List<CurrencyFormatterHelper.FormatInput>{request4};
            List<CurrencyFormatterHelper.FormatOutput> responses4 = CurrencyFormatterHelper.formatCurrency(requests4);
            contract.Active_ARR_USD__c = responses4[0].formattedAmount;
            
            // Format_Currency_Action_5: Format MRR (USD)
            CurrencyFormatterHelper.FormatInput request5 = new CurrencyFormatterHelper.FormatInput();
            request5.amount = varMRR_Total;
            List<CurrencyFormatterHelper.FormatInput> requests5 = new List<CurrencyFormatterHelper.FormatInput>{request5};
            List<CurrencyFormatterHelper.FormatOutput> responses5 = CurrencyFormatterHelper.formatCurrency(requests5);
            contract.MRR_USD__c = responses5[0].formattedAmount;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: Currency formatting error for Contract ' + contract.Id + ': ' + e.getMessage());
        }
        
        // Step 6: Assign_Revenue_Calculations (exact flow formulas)
        // forC_MRR formula: ARR / 12
        contract.MRR__c = contract.ARR__c != null ? contract.ARR__c / 12 : 0;
        
        // forC_iARR formula: IF(ISNULL(Previous_ARR), ARR, ARR - Previous_ARR)
        if (contract.Previous_ARR__c == null) {
            contract.Incremental_ARR__c = contract.ARR__c != null ? contract.ARR__c : 0;
        } else {
            contract.Incremental_ARR__c = (contract.ARR__c != null ? contract.ARR__c : 0) - contract.Previous_ARR__c;
        }
        
        return contract;
    }
    
    /**
     * Replicate exact Contract flow status determination logic
     * 
     * Flow Decision: Check_Contract_Start_End_Dates
     * Rule 1: Before_Start_Date (StartDate > TODAY) → Exit flow
     * Rule 2: Within_Start_End_Dates (StartDate <= TODAY AND EndDate >= TODAY AND Exclude_from_Status_Updates__c = false) → Activated
     * Rule 3: After_End_Date (EndDate < TODAY AND Status != 'Expired' AND Exclude_from_Status_Updates__c = false) → Expired
     */
    private String determineContractStatus(Contract contract, Date today) {
        // Rule 1: Before Start Date - no status change (flow exits)
        if (contract.StartDate > today) {
            return null;
        }
        
        // Rule 2: Within Start & End Dates
        if (contract.StartDate <= today && 
            contract.EndDate >= today && 
            contract.Exclude_from_Status_Updates__c == false) {
            return 'Activated';
        }
        
        // Rule 3: After End Date
        if (contract.EndDate < today && 
            contract.Status != 'Expired' && 
            contract.Exclude_from_Status_Updates__c == false) {
            return 'Expired';
        }
        
        // Default: No status change
        return null;
    }
}