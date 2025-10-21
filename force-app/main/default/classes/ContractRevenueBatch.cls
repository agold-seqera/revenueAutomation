/**
 * Processes contracts with Status != null AND Status != 'Expired'
 * Contract Status Logic:
 * - Before Start Date: No action (exit flow)
 * - Within Start & End Dates + Exclude_from_Status_Updates__c = false: Status = 'Activated'
 * - After End Date + Status != 'Expired' + Exclude_from_Status_Updates__c = false: Status = 'Expired'
 * Revenue Calculations:
 * - Nullify all revenue fields first
 * - Loop through related assets (Exclude_from_Status_Updates__c = false)
 * - Add revenue totals (TCV from Total_Value__c, others from respective fields)
 * - Check if asset is active (Start_Date <= TODAY, End_Date >= TODAY, ProductFamily in recurring revenue families)
 * - If active: Add to ARR, ACV (Total_Price__c), Active_ARR, USD totals, counts
 * - Calculate MRR = ARR / 12
 * - Calculate Incremental ARR = IF(ISNULL(Previous_ARR), ARR, ARR - Previous_ARR)
 * - Format USD fields for reporting
 */
public class ContractRevenueBatch implements Database.Batchable<sObject>, 
                                            Database.Stateful, 
                                            Database.RaisesPlatformEvents {
    
    private static final Set<String> RECURRING_REVENUE_FAMILIES = new Set<String>{
        'Software Subscriptions',
        'Sample-based', 
        'Recurring Services',
        'CPUh - Prepaid'
    };
    
    // Diagnostic tracking (Database.Stateful preserves across batch executions)
    private List<String> processingErrors = new List<String>();
    private Integer totalProcessed = 0;
    private Integer totalUpdated = 0;
    private Integer totalSkipped = 0;
    private Integer totalFailed = 0;
    
    // Query ALL contracts for processing
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('ContractRevenueBatch: Starting batch processing');
        
        processingErrors.clear();
        
        return Database.getQueryLocator([
            SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c, CurrencyIsoCode,
                   ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
                   Previous_ARR_USD_Reporting__c, MRR_USD_Reporting__c, Incremental_ARR_USD_Reporting__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, Active_ARR_USD_Reporting__c,
                   (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                           Start_Date__c, End_Date__c, Product2.Family, ProductFamily, Exclude_from_Status_Updates__c
                    FROM Assets__r 
                    WHERE Exclude_from_Status_Updates__c = false)
            FROM Contract 
        ]);
    }
    
    // Process each batch of contracts
    public void execute(Database.BatchableContext bc, List<Contract> contracts) {
        System.debug('ContractRevenueBatch: Processing ' + contracts.size() + ' contracts in batch');
        
        List<Contract> contractsToUpdate = new List<Contract>();
        Date today = Date.today();
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Process each contract
            for (Contract contract : contracts) {
                totalProcessed++;
                
                try {                
                    Contract updatedContract = processContract(contract, today);
                    
                    if (updatedContract != null) {
                        contractsToUpdate.add(updatedContract);

                    } else {
                        totalSkipped++;
                        
                        System.debug('ContractRevenueBatch: Contract ' + contract.Id + ' was skipped (processContract returned null)');
                    }
                } catch (Exception e) {
                    totalFailed++;
                    String errorMsg = 'Contract ' + contract.Id + ' processing failed: ' + e.getMessage() + 
                                    ' | Stack: ' + e.getStackTraceString();
                    processingErrors.add(errorMsg);
                    System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: ' + errorMsg);
                }
            }
            
            // Bulk update with SaveResult analysis
            if (!contractsToUpdate.isEmpty()) {
                System.debug('ContractRevenueBatch: Attempting to update ' + contractsToUpdate.size() + ' contracts');
                
                // Use allOrNone=false to get detailed failure information
                Database.SaveResult[] results = Database.update(contractsToUpdate, false);
                
                // Log update results for each contract
                for (Integer i = 0; i < results.size(); i++) {
                    Contract processedContract = contractsToUpdate[i];
                    Database.SaveResult result = results[i];
                    
                    if (result.isSuccess()) {
                        // Field history tracking will capture the changes
                        totalUpdated++;
                    } else {
                        totalFailed++;
                        // Capture detailed DML error information
                        String errorMsg = 'DML Update Failed for Contract ' + processedContract.Id + ': ';
                        for (Database.Error err : result.getErrors()) {
                            errorMsg += '\nStatusCode: ' + err.getStatusCode() + 
                                       '\nMessage: ' + err.getMessage();
                            
                            // Capture affected fields
                            if (!err.getFields().isEmpty()) {
                                errorMsg += '\nAffected Fields: ' + String.join(err.getFields(), ', ');
                            }            
                        }
                        
                        System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: ' + errorMsg);
                    }
                }
                
            } else {
                System.debug('ContractRevenueBatch: No contracts to update in this batch');
            }
            
            System.debug('ContractRevenueBatch: Completed processing ' + contracts.size() + ' contracts');
            
        } catch (Exception e) {
            // Critical error - rollback and re-throw for platform events
            Database.rollback(sp);
            System.debug('ContractRevenueBatch: Failed to process batch of ' + contracts.size() + ' contracts');
            String criticalError = 'Critical batch failure: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString();
            processingErrors.add(criticalError);
            System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: ' + criticalError);
            
            // Re-throw to trigger BatchApexErrorEvent via Database.RaisesPlatformEvents
            throw e;
        }
    }

    //Chain to Account processing after Contract processing completes
    public void finish(Database.BatchableContext bc) {
        // Generate comprehensive execution summary
        String summary = 'ContractRevenueBatch execution summary:' +
                        '\n  Total Processed: ' + totalProcessed +
                        '\n  Total Updated: ' + totalUpdated +
                        '\n  Total Skipped: ' + totalSkipped +
                        '\n  Total Failed: ' + totalFailed +
                        '\n  Job ID: ' + bc.getJobId();
        
        System.debug('ContractRevenueBatch: ' + summary);
        
        
        // Sequential execution: Asset → Contract → Account
        Database.executeBatch(new AccountRollupBatch(), 100);
        System.debug('ContractRevenueBatch: Processing complete, chaining to AccountRollupBatch');
    }
    
    private Contract processContract(Contract contract, Date today) {
        Boolean needsUpdate = false;
        
        // Handle status updates
        String newStatus = determineContractStatus(contract, today);
        if (newStatus != null) {
            contract.Status = newStatus;
            needsUpdate = true;
        }
        
        // Active Contracts: Calculate revenue fields
        Boolean shouldPopulateRevenue = false;
        if (contract.Status == 'Activated') {
            shouldPopulateRevenue = true;
        }
        // Expired contracts: Do not recalculate revenue
        
        // Revenue calculations
        if (shouldPopulateRevenue) {
            System.debug('ContractRevenueBatch: Processing Contract: ' + contract.Id);
            
            // Nullify and recalculate revenue fields
            contract.ARR__c = 0;
            contract.Active_ARR__c = 0;
            contract.Incremental_ARR__c = 0;
            contract.ACV__c = 0;
            contract.MRR__c = 0;
            contract.TCV__c = 0;

            contract.ARR_USD_Reporting__c = 0;
            contract.Active_ARR_USD_Reporting__c = 0;
            contract.Incremental_ARR_USD_Reporting__c = 0;
            contract.ACV_USD_Reporting__c = 0;
            contract.MRR_USD_Reporting__c = 0;
            contract.TCV_USD_Reporting__c = 0;

            needsUpdate = true;
            
            // Process related assets
            Decimal varActiveAssetCount = 0;
            Decimal varTotalAssetCount = 0;
            
            for (Asset asset : contract.Assets__r) {
                // Add Total Contract Revenue 
                contract.TCV__c += asset.Total_Value__c != null ? asset.Total_Value__c : 0;
                
                Decimal forTCV_USD = (asset.Total_Value__c != null ? asset.Total_Value__c : 0) / 
                                     (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                contract.TCV_USD_Reporting__c += forTCV_USD;
                
                varTotalAssetCount += 1;
                
                // Add Recurring Revenue 
                if (asset.Start_Date__c <= today && asset.End_Date__c >= today && 
                    RECURRING_REVENUE_FAMILIES.contains(asset.Product2.Family)) {
                    
                    contract.ARR__c += asset.ARR__c != null ? asset.ARR__c : 0;
                    contract.ACV__c += asset.Total_Price__c != null ? asset.Total_Price__c : 0;
                    contract.Active_ARR__c += asset.ARR__c != null ? asset.ARR__c : 0;
                    
                    // USD calculations
                    Decimal forARR_USD = (asset.ARR__c != null ? asset.ARR__c : 0) / 
                                         (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    Decimal forACV_USD = (asset.Total_Price__c != null ? asset.Total_Price__c : 0) / 
                                         (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);

                    Decimal assetMRR = (asset.ARR__c != null ? asset.ARR__c / 12 : 0);
                    Decimal forMRR_USD = assetMRR / (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    
                    // Add USD Values
                    contract.ARR_USD_Reporting__c += forARR_USD;
                    contract.ACV_USD_Reporting__c += forACV_USD;
                    contract.Active_ARR_USD_Reporting__c += forARR_USD;
                    contract.MRR_USD_Reporting__c += forMRR_USD;

                    varActiveAssetCount += 1;
                }
            }
            
            // Calculate MRR from ARR (MRR = ARR / 12)
            contract.MRR__c = contract.ARR__c != null ? contract.ARR__c / 12 : 0;
            
            // Calculate Incremental ARR
            contract.Incremental_ARR__c = (contract.Previous_ARR__c != null) ? 
                                         (contract.ARR__c - contract.Previous_ARR__c) : 
                                         contract.ARR__c;
            contract.Incremental_ARR_USD_Reporting__c = (contract.Previous_ARR_USD_Reporting__c != null) ? 
                                         (contract.ARR_USD_Reporting__c - contract.Previous_ARR_USD_Reporting__c) : 
                                         contract.ARR_USD_Reporting__c;
        }        

        return needsUpdate ? contract : null;
    }
    
    private String determineContractStatus(Contract contract, Date today) {
        // Skip if excluded from status updates
        if (contract.Exclude_from_Status_Updates__c == true) {
            return null;
        }
        
        // Draft/null contracts within date range should be Activated
        if ((contract.Status == 'Draft' || contract.Status == null) &&
            contract.StartDate <= today && 
            contract.EndDate >= today) {
            System.debug('ContractRevenueBatch: Draft/null Contract ' + contract.Id + ' should be Activated');
            return 'Activated';
        }
        
        // Within Start & End Dates 
        if (contract.StartDate <= today && 
            contract.EndDate >= today && 
            contract.Status != 'Activated') {
            System.debug('ContractRevenueBatch: Contract ' + contract.Id + ' should be Activated');
            return 'Activated';
        }
        
        // After End Date
        if (contract.EndDate < today && 
            contract.Status != 'Expired') {
            System.debug('ContractRevenueBatch: Contract ' + contract.Id + ' should be Expired');
            return 'Expired';
        }
        
        return null; // No status change needed
    }
    
}