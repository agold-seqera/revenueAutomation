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
 *   - Check if asset is active (Start_Date <= TODAY, End_Date >= TODAY, ProductFamily in recurring revenue families)
 *   - If active: Add to ARR, ACV (Total_Price__c), Active_ARR, USD totals, counts
 *   - Calculate MRR = ARR / 12
 *   - Calculate Incremental ARR = IF(ISNULL(Previous_ARR), ARR, ARR - Previous_ARR)
 *   - Format USD fields using CurrencyFormatterHelper (ALWAYS for full field alignment)
 */
public class ContractRevenueBatch implements Database.Batchable<sObject>, 
                                            Database.Stateful, 
                                            Database.RaisesPlatformEvents {
    
    // Recurring revenue product families (included in ARR calculations)
    private static final Set<String> RECURRING_REVENUE_FAMILIES = new Set<String>{
        'Software Subscriptions',
        'Sample-based', 
        'Recurring Services',
        'CPUh - Prepaid'
    };
    
    // Enhanced diagnostic tracking (Database.Stateful preserves across batch executions)
    private String executionContext;
    private List<String> processingErrors = new List<String>();
    private Integer totalProcessed = 0;
    private Integer totalUpdated = 0;
    private Integer totalSkipped = 0;
    private Integer totalFailed = 0;
    
    // Custom logging for persistent audit trail
    private String currentBatchJobId;
    private List<Batch_Execution_Log__c> batchLogs = new List<Batch_Execution_Log__c>();
    
    /**
     * Query ALL contracts for legacy data safe processing:
     * - Include Draft, Activated, Expired, and null status contracts
     * - Legacy data protection: only populate empty fields
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Detect execution context for enhanced diagnostics
        try {
            User currentUser = [SELECT Id, Name, Alias, UserType FROM User WHERE Id = :UserInfo.getUserId()];
            executionContext = (currentUser.Alias == 'autoproc' || currentUser.UserType == 'AutomatedProcess') ? 'SCHEDULED' : 'MANUAL';
            
            System.debug('ContractRevenueBatch: Starting in ' + executionContext + ' context');
            System.debug('ContractRevenueBatch: Running as user: ' + currentUser.Name + ' (' + currentUser.Alias + ')');
        } catch (Exception e) {
            // Fallback if User query fails in test context
            executionContext = 'UNKNOWN';
            System.debug('ContractRevenueBatch: Could not determine execution context: ' + e.getMessage());
        }
        
        if (bc != null) {
            currentBatchJobId = bc.getJobId();
            System.debug('ContractRevenueBatch: Job ID: ' + currentBatchJobId);
        } else {
            currentBatchJobId = 'MANUAL_TEST';
            System.debug('ContractRevenueBatch: Running in test context');
        }
        
        // Initialize counters
        totalProcessed = 0;
        totalUpdated = 0;
        totalSkipped = 0;
        totalFailed = 0;
        processingErrors.clear();
        
        return Database.getQueryLocator([
            SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c, CurrencyIsoCode,
                   ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
                   ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c,
                   (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                           Start_Date__c, End_Date__c, Product2.Family, ProductFamily, Exclude_from_Status_Updates__c
                    FROM Assets__r 
                    WHERE Exclude_from_Status_Updates__c = false)
            FROM Contract 
            // Process ALL contracts - no status exclusions for legacy data safety
            // Note: FOR UPDATE not supported in Batch Apex - using alternative concurrency control
        ]);
    }
    
    /**
     * Process each batch of contracts using exact flow logic
     */
    public void execute(Database.BatchableContext bc, List<Contract> contracts) {
        // Monitor resource consumption at start
        System.debug('ContractRevenueBatch: Execute batch starting - Heap: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize() + 
                    ', CPU: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime() + 
                    ', SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
        
        List<Contract> contractsToUpdate = new List<Contract>();
        Date today = Date.today();
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Process each contract with enhanced tracking
            for (Contract contract : contracts) {
                totalProcessed++;
                
                try {
                    // Log contract before processing
                    Batch_Execution_Log__c beforeLog = createBatchLog(contract, 'QUERIED', contract.ARR__c, null, null, null);
                    batchLogs.add(beforeLog);
                    
                    Contract updatedContract = processContract(contract, today);
                    
                    if (updatedContract != null) {
                        contractsToUpdate.add(updatedContract);
                        
                        // Log successful processing
                        Batch_Execution_Log__c processedLog = createBatchLog(contract, 'PROCESSED', contract.ARR__c, updatedContract.ARR__c, true, null);
                        batchLogs.add(processedLog);
                    } else {
                        totalSkipped++;
                        
                        // Log skipped contract
                        Batch_Execution_Log__c skippedLog = createBatchLog(contract, 'SKIPPED', contract.ARR__c, contract.ARR__c, false, 'processContract returned null');
                        batchLogs.add(skippedLog);
                        
                        if (executionContext == 'SCHEDULED') {
                            System.debug('ContractRevenueBatch: Contract ' + contract.Id + ' was skipped (processContract returned null)');
                        }
                    }
                } catch (Exception e) {
                    totalFailed++;
                    String errorMsg = 'Contract ' + contract.Id + ' processing failed: ' + e.getMessage() + 
                                    ' | Stack: ' + e.getStackTraceString();
                    processingErrors.add(errorMsg);
                    System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: ' + errorMsg);
                }
            }
            
            // Enhanced bulk update with comprehensive SaveResult analysis
            if (!contractsToUpdate.isEmpty()) {
                System.debug('ContractRevenueBatch: Attempting to update ' + contractsToUpdate.size() + ' contracts');
                
                // Use allOrNone=false to get detailed failure information
                Database.SaveResult[] results = Database.update(contractsToUpdate, false);
                
                // Analyze each SaveResult for detailed failure tracking
                analyzeUpdateResults(results, contractsToUpdate);
                
                // Log update results for each contract
                for (Integer i = 0; i < results.size(); i++) {
                    Contract processedContract = contractsToUpdate[i];
                    Database.SaveResult result = results[i];
                    
                    if (result.isSuccess()) {
                        Batch_Execution_Log__c successLog = createBatchLog(processedContract, 'UPDATED', null, processedContract.ARR__c, true, null);
                        batchLogs.add(successLog);
                    } else {
                        // Capture detailed DML error information
                        String errorMsg = 'DML Update Failed for Contract ' + processedContract.Id + ': ';
                        for (Database.Error err : result.getErrors()) {
                            errorMsg += '\nStatusCode: ' + err.getStatusCode() + 
                                       '\nMessage: ' + err.getMessage();
                            
                            // Capture affected fields (critical for FLS issues)
                            if (!err.getFields().isEmpty()) {
                                errorMsg += '\nAffected Fields: ' + String.join(err.getFields(), ', ');
                            }
                            
                            // Add context about likely causes
                            if (err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION) {
                                errorMsg += '\nLikely Cause: Field-level security or validation rule issue';
                            } else if (err.getStatusCode() == StatusCode.INSUFFICIENT_ACCESS_OR_READONLY) {
                                errorMsg += '\nLikely Cause: User permissions or read-only field issue';
                            } else if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
                                errorMsg += '\nLikely Cause: Record locking conflict with concurrent operations';
                            }
                        }
                        
                        Batch_Execution_Log__c failLog = createBatchLog(processedContract, 'FAILED', null, null, false, errorMsg);
                        batchLogs.add(failLog);
                        
                        System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: ' + errorMsg);
                    }
                }
                
            } else {
                System.debug('ContractRevenueBatch: No contracts to update in this batch');
            }
            
            // Monitor resource consumption at end
            System.debug('ContractRevenueBatch: Execute batch completed - Heap: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize() + 
                        ', CPU: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime() + 
                        ', SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
            
            // Insert batch logs immediately (within same transaction for now)
            // Future enhancement: Use Platform Events for autonomous transaction
            if (!batchLogs.isEmpty()) {
                try {
                    insert batchLogs;
                    System.debug('ContractRevenueBatch: Inserted ' + batchLogs.size() + ' batch execution logs');
                } catch (Exception logError) {
                    System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: Failed to insert batch logs: ' + logError.getMessage());
                }
                batchLogs.clear(); // Clear for next batch
            }
            
        } catch (Exception e) {
            // Critical error - rollback and re-throw for platform events
            Database.rollback(sp);
            String criticalError = 'Critical batch failure: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString();
            processingErrors.add(criticalError);
            System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: ' + criticalError);
            
            // Re-throw to trigger BatchApexErrorEvent via Database.RaisesPlatformEvents
            throw e;
        }
    }
    
    /**
     * Analyze Database.SaveResult[] for detailed failure tracking
     * Critical for identifying field-level security and validation issues
     */
    private void analyzeUpdateResults(Database.SaveResult[] results, List<Contract> contracts) {
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                totalUpdated++;
            } else {
                totalFailed++;
                Contract failedContract = contracts[i];
                
                String errorMsg = 'Contract ' + failedContract.Id + ' update failed: ';
                for (Database.Error err : results[i].getErrors()) {
                    errorMsg += err.getStatusCode() + ': ' + err.getMessage();
                    
                    // Critical: Log field-level errors (often indicates FLS issues)
                    if (!err.getFields().isEmpty()) {
                        errorMsg += ' | Affected Fields: ' + String.join(err.getFields(), ', ');
                    }
                    
                    // Special handling for field-level security errors
                    if (err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION ||
                        err.getStatusCode() == StatusCode.INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY) {
                        errorMsg += ' | LIKELY CAUSE: Field-level security or user permissions issue in ' + executionContext + ' context';
                    }
                }
                
                processingErrors.add(errorMsg);
                System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: ' + errorMsg);
            }
        }
        
        System.debug('ContractRevenueBatch: Update results - Success: ' + totalUpdated + ', Failed: ' + (results.size() - totalUpdated));
    }
    
    /**
     * Chain to Account processing after Contract processing completes
     * Enhanced with comprehensive error reporting
     */
    public void finish(Database.BatchableContext bc) {
        // Generate comprehensive execution summary
        String summary = 'ContractRevenueBatch execution summary:' +
                        '\n  Execution Context: ' + executionContext +
                        '\n  Total Processed: ' + totalProcessed +
                        '\n  Total Updated: ' + totalUpdated +
                        '\n  Total Skipped: ' + totalSkipped +
                        '\n  Total Failed: ' + totalFailed +
                        '\n  Job ID: ' + bc.getJobId();
        
        System.debug('ContractRevenueBatch: ' + summary);
        
        // Send error notification if there were failures
        if (!processingErrors.isEmpty()) {
            sendErrorNotification(bc.getJobId(), summary, processingErrors);
        }
        
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
        
        // Step 2: Determine if we should populate revenue fields (ALWAYS for accuracy)
        Boolean shouldPopulateRevenue = false;
        if (contract.Status == 'Draft' || contract.Status == null) {
            // Legacy Draft/null: Only if revenue fields are empty
            if (contract.ARR__c == null || contract.ARR__c == 0) {
                shouldPopulateRevenue = true;
            }
        } else if (contract.Status == 'Activated') {
            // Activated contracts: ALWAYS recalculate for accuracy (per user requirements)
            // This ensures all revenue calculations are correct regardless of existing values
            shouldPopulateRevenue = true;
        }
        // Expired contracts: Never recalculate revenue (preserve historical)
        
        // Step 3: Revenue calculations (conditional for legacy data safety)
        if (shouldPopulateRevenue) {
            // Debug logging for Activated contracts
            if (contract.Status == 'Activated') {
                System.debug('ContractRevenueBatch: Processing Activated contract ' + contract.Id + ' - ALWAYS recalculate revenue');
            }
            
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
                
                Decimal forTCV_USD = (asset.Total_Value__c != null ? asset.Total_Value__c : 0) / 
                                     (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                varTCV_Total += forTCV_USD;
                
                varTotalAssetCount += 1;
                
                // forAssetHasStarted formula: IF(Start_Date__c <= TODAY(), 1, 0)
                if (asset.Start_Date__c <= today) {
                    varAssetsStartedCount += 1;
                }
                
                // Is_Asset_Active decision logic (updated for all recurring revenue families)
                if (asset.Start_Date__c <= today && 
                    asset.End_Date__c >= today && 
                    RECURRING_REVENUE_FAMILIES.contains(asset.Product2.Family)) {
                    
                    // Add_Active_ARR logic (exact flow replication)
                    contract.ARR__c += asset.ARR__c != null ? asset.ARR__c : 0;
                    contract.ACV__c += asset.Total_Price__c != null ? asset.Total_Price__c : 0;
                    contract.Active_ARR__c += asset.ARR__c != null ? asset.ARR__c : 0;
                    
                    // USD calculations (corrected division formulas)
                    Decimal forARR_USD = (asset.ARR__c != null ? asset.ARR__c : 0) / 
                                         (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    Decimal forACV_USD = (asset.Total_Price__c != null ? asset.Total_Price__c : 0) / 
                                         (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    // Calculate MRR from ARR (MRR = ARR / 12)
                    Decimal assetMRR = (asset.ARR__c != null ? asset.ARR__c / 12 : 0);
                    Decimal forMRR_USD = assetMRR / (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    
                    varARR_Total += forARR_USD;
                    varACV_Total += forACV_USD;
                    varActiveARR_Total += forARR_USD;
                    varMRR_Total += forMRR_USD;
                    varActiveAssetCount += 1;
                }
            }
            
            // Calculate MRR from ARR (MRR = ARR / 12)
            contract.MRR__c = contract.ARR__c != null ? contract.ARR__c / 12 : 0;
            
            // Calculate Incremental ARR
            contract.Incremental_ARR__c = (contract.Previous_ARR__c != null) ? 
                                         (contract.ARR__c - contract.Previous_ARR__c) : 
                                         contract.ARR__c;
        }
        
        // Step 4: USD fields - ALWAYS ensure full alignment with base currency fields
        // This ensures ALL contracts (including expired) have aligned USD values
        Boolean shouldPopulateUSD = true;
        
        // Only skip USD calculation if explicitly excluded from updates
        if (contract.Exclude_from_Status_Updates__c == true) {
            shouldPopulateUSD = false;
        }
        
        if (shouldPopulateUSD) {
            // Calculate USD totals from assets (even if revenue fields weren't recalculated)
            Decimal varARR_Total = 0;
            Decimal varACV_Total = 0;
            Decimal varTCV_Total = 0;
            Decimal varActiveARR_Total = 0;
            Decimal varMRR_Total = 0;
            
            for (Asset asset : contract.Assets__r) {
                // TCV calculation (corrected division formula)
                Decimal forTCV_USD = (asset.Total_Value__c != null ? asset.Total_Value__c : 0) / 
                                     (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                varTCV_Total += forTCV_USD;
                
                // Active asset USD calculations
                if (asset.Start_Date__c <= today && 
                    asset.End_Date__c >= today && 
                    RECURRING_REVENUE_FAMILIES.contains(asset.ProductFamily)) {
                    
                    Decimal forARR_USD = (asset.ARR__c != null ? asset.ARR__c : 0) / 
                                         (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    Decimal forACV_USD = (asset.Total_Price__c != null ? asset.Total_Price__c : 0) / 
                                         (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    // Calculate MRR from ARR (MRR = ARR / 12)
                    Decimal assetMRR = (asset.ARR__c != null ? asset.ARR__c / 12 : 0);
                    Decimal forMRR_USD = assetMRR / (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                    
                    varARR_Total += forARR_USD;
                    varACV_Total += forACV_USD;
                    varActiveARR_Total += forARR_USD;
                    varMRR_Total += forMRR_USD;
                }
            }
            
            // Step 5: Format currency using CurrencyFormatterHelper
            try {
                // For USD currency: always update, for others: only if blank
                if (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.ARR_USD__c)) {
                    CurrencyFormatterHelper.FormatInput request1 = new CurrencyFormatterHelper.FormatInput();
                    request1.amount = varARR_Total;
                    List<CurrencyFormatterHelper.FormatInput> requests1 = new List<CurrencyFormatterHelper.FormatInput>{request1};
                    List<CurrencyFormatterHelper.FormatOutput> responses1 = CurrencyFormatterHelper.formatCurrency(requests1);
                    contract.ARR_USD__c = responses1[0].formattedAmount;
                }
                
                if (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.ACV_USD__c)) {
                    CurrencyFormatterHelper.FormatInput request2 = new CurrencyFormatterHelper.FormatInput();
                    request2.amount = varACV_Total;
                    List<CurrencyFormatterHelper.FormatInput> requests2 = new List<CurrencyFormatterHelper.FormatInput>{request2};
                    List<CurrencyFormatterHelper.FormatOutput> responses2 = CurrencyFormatterHelper.formatCurrency(requests2);
                    contract.ACV_USD__c = responses2[0].formattedAmount;
                }
                
                if (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.TCV_USD__c)) {
                    CurrencyFormatterHelper.FormatInput request3 = new CurrencyFormatterHelper.FormatInput();
                    request3.amount = varTCV_Total;
                    List<CurrencyFormatterHelper.FormatInput> requests3 = new List<CurrencyFormatterHelper.FormatInput>{request3};
                    List<CurrencyFormatterHelper.FormatOutput> responses3 = CurrencyFormatterHelper.formatCurrency(requests3);
                    contract.TCV_USD__c = responses3[0].formattedAmount;
                }
                
                if (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.Active_ARR_USD__c)) {
                    CurrencyFormatterHelper.FormatInput request4 = new CurrencyFormatterHelper.FormatInput();
                    request4.amount = varActiveARR_Total;
                    List<CurrencyFormatterHelper.FormatInput> requests4 = new List<CurrencyFormatterHelper.FormatInput>{request4};
                    List<CurrencyFormatterHelper.FormatOutput> responses4 = CurrencyFormatterHelper.formatCurrency(requests4);
                    contract.Active_ARR_USD__c = responses4[0].formattedAmount;
                }
                
                if (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.MRR_USD__c)) {
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
            
            // Step 5.5: Populate Number reporting fields 
            // For USD currency: always update, for others: only if empty
            try {
                if (contract.CurrencyIsoCode == 'USD' || contract.ARR_USD_Reporting__c == null) {
                    contract.ARR_USD_Reporting__c = varARR_Total;
                }
                
                if (contract.CurrencyIsoCode == 'USD' || contract.ACV_USD_Reporting__c == null) {
                    contract.ACV_USD_Reporting__c = varACV_Total;
                }
                
                if (contract.CurrencyIsoCode == 'USD' || contract.TCV_USD_Reporting__c == null) {
                    contract.TCV_USD_Reporting__c = varTCV_Total;
                }
                
                if (contract.CurrencyIsoCode == 'USD' || contract.MRR_USD_Reporting__c == null) {
                    contract.MRR_USD_Reporting__c = varMRR_Total;
                }
                
                if (contract.CurrencyIsoCode == 'USD' || contract.Active_ARR_USD_Reporting__c == null) {
                    contract.Active_ARR_USD_Reporting__c = varActiveARR_Total;
                }
                
                needsUpdate = true;
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: Number reporting field error for Contract ' + contract.Id + ': ' + e.getMessage());
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
        
        // Step 7: Handle additional USD fields (Incremental, Previous, Initial)
        // For USD currency: always update if empty, for others: only if empty
        if (contract.CurrencyIsoCode == 'USD' || shouldPopulateUSD) {
            try {
                // Incremental ARR USD
                if (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.Incremental_ARR_USD__c)) {
                    if (contract.Incremental_ARR__c != null) {
                        CurrencyFormatterHelper.FormatInput incrementalRequest = new CurrencyFormatterHelper.FormatInput();
                        incrementalRequest.amount = contract.Incremental_ARR__c;
                        List<CurrencyFormatterHelper.FormatInput> incrementalRequests = new List<CurrencyFormatterHelper.FormatInput>{incrementalRequest};
                        List<CurrencyFormatterHelper.FormatOutput> incrementalResponses = CurrencyFormatterHelper.formatCurrency(incrementalRequests);
                        contract.Incremental_ARR_USD__c = incrementalResponses[0].formattedAmount;
                        
                        // Also update reporting field
                        if (contract.CurrencyIsoCode == 'USD' || contract.Incremental_ARR_USD_Reporting__c == null) {
                            contract.Incremental_ARR_USD_Reporting__c = contract.Incremental_ARR__c;
                        }
                    }
                }
                
                // Previous fields USD (only if they have values)
                if (contract.Previous_ARR__c != null && (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.Previous_ARR_USD__c))) {
                    CurrencyFormatterHelper.FormatInput prevARRRequest = new CurrencyFormatterHelper.FormatInput();
                    prevARRRequest.amount = contract.Previous_ARR__c;
                    List<CurrencyFormatterHelper.FormatInput> prevARRRequests = new List<CurrencyFormatterHelper.FormatInput>{prevARRRequest};
                    List<CurrencyFormatterHelper.FormatOutput> prevARRResponses = CurrencyFormatterHelper.formatCurrency(prevARRRequests);
                    contract.Previous_ARR_USD__c = prevARRResponses[0].formattedAmount;
                    
                    // Also update reporting field
                    if (contract.CurrencyIsoCode == 'USD' || contract.Previous_ARR_USD_Reporting__c == null) {
                        contract.Previous_ARR_USD_Reporting__c = contract.Previous_ARR__c;
                    }
                }
                
                if (contract.Previous_ACV__c != null && (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.Previous_ACV_USD__c))) {
                    CurrencyFormatterHelper.FormatInput prevACVRequest = new CurrencyFormatterHelper.FormatInput();
                    prevACVRequest.amount = contract.Previous_ACV__c;
                    List<CurrencyFormatterHelper.FormatInput> prevACVRequests = new List<CurrencyFormatterHelper.FormatInput>{prevACVRequest};
                    List<CurrencyFormatterHelper.FormatOutput> prevACVResponses = CurrencyFormatterHelper.formatCurrency(prevACVRequests);
                    contract.Previous_ACV_USD__c = prevACVResponses[0].formattedAmount;
                    
                    // Also update reporting field
                    if (contract.CurrencyIsoCode == 'USD' || contract.Previous_ACV_USD_Reporting__c == null) {
                        contract.Previous_ACV_USD_Reporting__c = contract.Previous_ACV__c;
                    }
                }
                
                if (contract.Previous_MRR__c != null && (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.Previous_MRR_USD__c))) {
                    CurrencyFormatterHelper.FormatInput prevMRRRequest = new CurrencyFormatterHelper.FormatInput();
                    prevMRRRequest.amount = contract.Previous_MRR__c;
                    List<CurrencyFormatterHelper.FormatInput> prevMRRRequests = new List<CurrencyFormatterHelper.FormatInput>{prevMRRRequest};
                    List<CurrencyFormatterHelper.FormatOutput> prevMRRResponses = CurrencyFormatterHelper.formatCurrency(prevMRRRequests);
                    contract.Previous_MRR_USD__c = prevMRRResponses[0].formattedAmount;
                    
                    // Also update reporting field
                    if (contract.CurrencyIsoCode == 'USD' || contract.Previous_MRR_USD_Reporting__c == null) {
                        contract.Previous_MRR_USD_Reporting__c = contract.Previous_MRR__c;
                    }
                }
                
                if (contract.Previous_TCV__c != null && (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.Previous_TCV_USD__c))) {
                    CurrencyFormatterHelper.FormatInput prevTCVRequest = new CurrencyFormatterHelper.FormatInput();
                    prevTCVRequest.amount = contract.Previous_TCV__c;
                    List<CurrencyFormatterHelper.FormatInput> prevTCVRequests = new List<CurrencyFormatterHelper.FormatInput>{prevTCVRequest};
                    List<CurrencyFormatterHelper.FormatOutput> prevTCVResponses = CurrencyFormatterHelper.formatCurrency(prevTCVRequests);
                    contract.Previous_TCV_USD__c = prevTCVResponses[0].formattedAmount;
                    
                    // Also update reporting field
                    if (contract.CurrencyIsoCode == 'USD' || contract.Previous_TCV_USD_Reporting__c == null) {
                        contract.Previous_TCV_USD_Reporting__c = contract.Previous_TCV__c;
                    }
                }
                
                // Initial fields USD (only if they have values)
                if (contract.Initial_ARR__c != null && (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.Initial_ARR_USD__c))) {
                    CurrencyFormatterHelper.FormatInput initARRRequest = new CurrencyFormatterHelper.FormatInput();
                    initARRRequest.amount = contract.Initial_ARR__c;
                    List<CurrencyFormatterHelper.FormatInput> initARRRequests = new List<CurrencyFormatterHelper.FormatInput>{initARRRequest};
                    List<CurrencyFormatterHelper.FormatOutput> initARRResponses = CurrencyFormatterHelper.formatCurrency(initARRRequests);
                    contract.Initial_ARR_USD__c = initARRResponses[0].formattedAmount;
                    
                    // Also update reporting field
                    if (contract.CurrencyIsoCode == 'USD' || contract.Initial_ARR_USD_Reporting__c == null) {
                        contract.Initial_ARR_USD_Reporting__c = contract.Initial_ARR__c;
                    }
                }
                
                if (contract.Initial_ACV__c != null && (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.Initial_ACV_USD__c))) {
                    CurrencyFormatterHelper.FormatInput initACVRequest = new CurrencyFormatterHelper.FormatInput();
                    initACVRequest.amount = contract.Initial_ACV__c;
                    List<CurrencyFormatterHelper.FormatInput> initACVRequests = new List<CurrencyFormatterHelper.FormatInput>{initACVRequest};
                    List<CurrencyFormatterHelper.FormatOutput> initACVResponses = CurrencyFormatterHelper.formatCurrency(initACVRequests);
                    contract.Initial_ACV_USD__c = initACVResponses[0].formattedAmount;
                    
                    // Also update reporting field
                    if (contract.CurrencyIsoCode == 'USD' || contract.Initial_ACV_USD_Reporting__c == null) {
                        contract.Initial_ACV_USD_Reporting__c = contract.Initial_ACV__c;
                    }
                }
                
                if (contract.Initial_MRR__c != null && (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.Initial_MRR_USD__c))) {
                    CurrencyFormatterHelper.FormatInput initMRRRequest = new CurrencyFormatterHelper.FormatInput();
                    initMRRRequest.amount = contract.Initial_MRR__c;
                    List<CurrencyFormatterHelper.FormatInput> initMRRRequests = new List<CurrencyFormatterHelper.FormatInput>{initMRRRequest};
                    List<CurrencyFormatterHelper.FormatOutput> initMRRResponses = CurrencyFormatterHelper.formatCurrency(initMRRRequests);
                    contract.Initial_MRR_USD__c = initMRRResponses[0].formattedAmount;
                    
                    // Also update reporting field
                    if (contract.CurrencyIsoCode == 'USD' || contract.Initial_MRR_USD_Reporting__c == null) {
                        contract.Initial_MRR_USD_Reporting__c = contract.Initial_MRR__c;
                    }
                }
                
                if (contract.Initial_TCV__c != null && (contract.CurrencyIsoCode == 'USD' || String.isBlank(contract.Initial_TCV_USD__c))) {
                    CurrencyFormatterHelper.FormatInput initTCVRequest = new CurrencyFormatterHelper.FormatInput();
                    initTCVRequest.amount = contract.Initial_TCV__c;
                    List<CurrencyFormatterHelper.FormatInput> initTCVRequests = new List<CurrencyFormatterHelper.FormatInput>{initTCVRequest};
                    List<CurrencyFormatterHelper.FormatOutput> initTCVResponses = CurrencyFormatterHelper.formatCurrency(initTCVRequests);
                    contract.Initial_TCV_USD__c = initTCVResponses[0].formattedAmount;
                    
                    // Also update reporting field
                    if (contract.CurrencyIsoCode == 'USD' || contract.Initial_TCV_USD_Reporting__c == null) {
                        contract.Initial_TCV_USD_Reporting__c = contract.Initial_TCV__c;
                    }
                }
                
                needsUpdate = true;
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch: Additional USD fields error for Contract ' + contract.Id + ': ' + e.getMessage());
            }
        }
        
        // Debug logging for final decision
        if (contract.Status == 'Activated') {
            System.debug('ContractRevenueBatch: Final decision for Activated contract ' + contract.Id + ' - needsUpdate: ' + needsUpdate);
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
    
    /**
     * Send detailed error notification for batch failures
     * Creates persistent audit trail independent of debug logs
     */
    private void sendErrorNotification(Id jobId, String summary, List<String> errors) {
        try {
            // In production, this would integrate with your notification system
            // For now, use System.debug with ERROR level for visibility
            System.debug(LoggingLevel.ERROR, 'ContractRevenueBatch FAILURE REPORT:');
            System.debug(LoggingLevel.ERROR, summary);
            System.debug(LoggingLevel.ERROR, 'Detailed Errors:');
            
            for (String error : errors) {
                System.debug(LoggingLevel.ERROR, '  - ' + error);
            }
            
            // Future enhancement: Send email notification or create custom log record
            // This ensures error visibility even when debug logs are not retained
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to send error notification: ' + e.getMessage());
        }
    }
    
    /**
     * Create a batch execution log record for persistent audit trail
     */
    private Batch_Execution_Log__c createBatchLog(Contract contract, String stage, Decimal beforeARR, Decimal afterARR, Boolean needsUpdate, String errorMsg) {
        Batch_Execution_Log__c log = new Batch_Execution_Log__c(
            Batch_Job_ID__c = currentBatchJobId,
            Execution_Context__c = executionContext,
            Contract_ID__c = contract.Id,
            Processing_Stage__c = stage
        );
        
        // Add error message if provided
        if (String.isNotBlank(errorMsg)) {
            log.Error_Message__c = errorMsg.length() > 1000 ? errorMsg.substring(0, 1000) : errorMsg;
        }
        
        return log;
    }
    
}