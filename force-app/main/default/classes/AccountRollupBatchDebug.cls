/**
 * DEBUG VERSION of AccountRollupBatch with comprehensive logging
 * Temporary enhanced version to debug the Caris Life Sciences account status issue
 * 
 * This version adds:
 * - Detailed logging for specific account (Caris Life Sciences: 001fJ000021YBjKQAW)
 * - Custom object logging via Batch_Execution_Log__c
 * - Enhanced debug output for status determination logic
 * - Execution context tracking
 */
public class AccountRollupBatchDebug implements Database.Batchable<sObject>, Database.Stateful {
    
    // Debug target account
    private static final String TARGET_ACCOUNT_ID = '001fJ000021YBjKQAW'; // Caris Life Sciences
    
    // Execution tracking (Database.Stateful preserves across batch executions)
    private String executionContext;
    private String currentBatchJobId;
    private List<Batch_Execution_Log__c> debugLogs = new List<Batch_Execution_Log__c>();
    private Integer totalAccountsProcessed = 0;
    private Integer targetAccountBatchNumber = -1;
    
    /**
     * Query accounts matching exact flow criteria with debug context
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Detect execution context
        try {
            User currentUser = [SELECT Id, Name, Alias, UserType FROM User WHERE Id = :UserInfo.getUserId()];
            executionContext = (currentUser.Alias == 'autoproc' || currentUser.UserType == 'AutomatedProcess') ? 'SCHEDULED' : 'MANUAL';
            
            System.debug('AccountRollupBatchDebug: Starting in ' + executionContext + ' context');
            System.debug('AccountRollupBatchDebug: Running as user: ' + currentUser.Name + ' (' + currentUser.Alias + ')');
        } catch (Exception e) {
            executionContext = 'UNKNOWN';
            System.debug('AccountRollupBatchDebug: Could not determine execution context: ' + e.getMessage());
        }
        
        if (bc != null) {
            currentBatchJobId = bc.getJobId();
            System.debug('AccountRollupBatchDebug: Job ID: ' + currentBatchJobId);
        } else {
            currentBatchJobId = 'DEBUG_TEST';
        }
        
        // Log batch start
        Batch_Execution_Log__c startLog = new Batch_Execution_Log__c(
            Batch_Job_ID__c = currentBatchJobId,
            Execution_Context__c = executionContext,
            Processing_Stage__c = 'QUERIED',
            Contract_ID__c = 'BATCH_START',
            Error_Message__c = 'AccountRollupBatchDebug started - Target: ' + TARGET_ACCOUNT_ID
        );
        debugLogs.add(startLog);
        
        return Database.getQueryLocator([
            SELECT Id, Name, Status__c, Type, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
                   ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                   (SELECT Id, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
                           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                           StartDate, EndDate, Status, Exclude_from_Status_Updates__c,
                           Renewal_Opportunity__c,
                           Renewal_Opportunity__r.Id, Renewal_Opportunity__r.StageName, 
                           Renewal_Opportunity__r.IsClosed, Renewal_Opportunity__r.Deal_Type__c
                    FROM Contracts)
            FROM Account 
            WHERE Has_Contracts__c = true
        ]);
    }
    
    /**
     * Process each batch of accounts with enhanced debugging
     */
    public void execute(Database.BatchableContext bc, List<Account> accounts) {
        List<Account> accountsToUpdate = new List<Account>();
        Date today = Date.today();
        
        Integer batchNumber = (totalAccountsProcessed / 100) + 1; // Assuming batch size 100
        totalAccountsProcessed += accounts.size();
        
        System.debug('AccountRollupBatchDebug: Processing batch #' + batchNumber + ' with ' + accounts.size() + ' accounts');
        System.debug('AccountRollupBatchDebug: Execution date: ' + today);
        
        // Check if target account is in this batch
        Boolean targetAccountInBatch = false;
        for (Account acc : accounts) {
            if (acc.Id == TARGET_ACCOUNT_ID) {
                targetAccountInBatch = true;
                targetAccountBatchNumber = batchNumber;
                break;
            }
        }
        
        if (targetAccountInBatch) {
            System.debug('🎯 TARGET ACCOUNT FOUND in batch #' + batchNumber);
            
            // Log target account discovery
            Batch_Execution_Log__c targetFoundLog = new Batch_Execution_Log__c(
                Batch_Job_ID__c = currentBatchJobId,
                Execution_Context__c = executionContext,
                Processing_Stage__c = 'PROCESSED',
                Contract_ID__c = TARGET_ACCOUNT_ID,
                Error_Message__c = 'Target account found in batch #' + batchNumber + ' on ' + today
            );
            debugLogs.add(targetFoundLog);
        }
        
        for (Account account : accounts) {
            Account updatedAccount = processAccountWithDebug(account, today, targetAccountInBatch && account.Id == TARGET_ACCOUNT_ID);
            
            if (updatedAccount != null) {
                accountsToUpdate.add(updatedAccount);
            }
        }
        
        // Bulk update with enhanced error tracking
        if (!accountsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(accountsToUpdate, false);
                
                System.debug('AccountRollupBatchDebug: Attempted to update ' + accountsToUpdate.size() + ' accounts');
                
                // Enhanced error analysis
                for (Integer i = 0; i < results.size(); i++) {
                    Account updatedAccount = accountsToUpdate[i];
                    Database.SaveResult result = results[i];
                    
                    if (result.isSuccess()) {
                        if (updatedAccount.Id == TARGET_ACCOUNT_ID) {
                            System.debug('🎯 TARGET ACCOUNT UPDATE SUCCESS: ' + updatedAccount.Id);
                            
                            // Log successful target account update
                            Batch_Execution_Log__c successLog = new Batch_Execution_Log__c(
                                Batch_Job_ID__c = currentBatchJobId,
                                Execution_Context__c = executionContext,
                                Processing_Stage__c = 'UPDATED',
                                Contract_ID__c = TARGET_ACCOUNT_ID,
                                Error_Message__c = 'Target account updated successfully to Status: ' + updatedAccount.Status__c
                            );
                            debugLogs.add(successLog);
                        }
                    } else {
                        String errorMsg = 'Update failed for Account ' + updatedAccount.Id + ': ';
                        for (Database.Error err : result.getErrors()) {
                            errorMsg += err.getMessage() + '; ';
                        }
                        
                        System.debug(LoggingLevel.ERROR, 'AccountRollupBatchDebug: ' + errorMsg);
                        
                        if (updatedAccount.Id == TARGET_ACCOUNT_ID) {
                            System.debug('🎯 TARGET ACCOUNT UPDATE FAILED: ' + errorMsg);
                            
                            // Log target account update failure
                            Batch_Execution_Log__c failLog = new Batch_Execution_Log__c(
                                Batch_Job_ID__c = currentBatchJobId,
                                Execution_Context__c = executionContext,
                                Processing_Stage__c = 'FAILED',
                                Contract_ID__c = TARGET_ACCOUNT_ID,
                                Error_Message__c = errorMsg.length() > 1000 ? errorMsg.substring(0, 1000) : errorMsg
                            );
                            debugLogs.add(failLog);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'AccountRollupBatchDebug: Exception during update: ' + e.getMessage());
                
                // Log exception
                Batch_Execution_Log__c exceptionLog = new Batch_Execution_Log__c(
                    Batch_Job_ID__c = currentBatchJobId,
                    Execution_Context__c = executionContext,
                    Processing_Stage__c = 'FAILED',
                    Contract_ID__c = 'BATCH_EXCEPTION',
                    Error_Message__c = 'Batch exception: ' + e.getMessage()
                );
                debugLogs.add(exceptionLog);
            }
        }
        
        // Insert debug logs for this batch
        if (!debugLogs.isEmpty()) {
            try {
                insert debugLogs;
                System.debug('AccountRollupBatchDebug: Inserted ' + debugLogs.size() + ' debug logs');
            } catch (Exception logError) {
                System.debug(LoggingLevel.ERROR, 'AccountRollupBatchDebug: Failed to insert debug logs: ' + logError.getMessage());
            }
            debugLogs.clear();
        }
    }
    
    /**
     * Enhanced processAccount with comprehensive debugging for target account
     */
    private Account processAccountWithDebug(Account account, Date today, Boolean isTargetAccount) {
        if (isTargetAccount) {
            System.debug('🎯🎯🎯 PROCESSING TARGET ACCOUNT: ' + account.Name + ' (ID: ' + account.Id + ') 🎯🎯🎯');
            System.debug('🎯 Current Status: ' + account.Status__c);
            System.debug('🎯 Processing Date: ' + today);
            System.debug('🎯 Execution Context: ' + executionContext);
            System.debug('🎯 Contracts Count: ' + account.Contracts.size());
        }
        
        // Initialize tracking variables (same as original)
        Decimal varARR_USD_Total = 0;
        Decimal varACV_USD_Total = 0;
        Decimal varTCV_USD_Total = 0;
        Decimal varMRR_USD_Total = 0;
        
        Decimal varARR_Reporting_Total = 0;
        Decimal varACV_Reporting_Total = 0;
        Decimal varTCV_Reporting_Total = 0;
        Decimal varMRR_Reporting_Total = 0;
        
        // v42 Enhancement variables for status determination
        Boolean varB_HasOpenRenewal = false;
        Boolean varB_HasLostRenewal = false;
        Boolean varB_AllContractsCancelled = false;
        
        // Contract counting variables
        Decimal varN_ActiveContracts = 0;
        Decimal varN_FutureContracts = 0;
        Decimal varN_NumExpiredContracts = 0;
        
        if (isTargetAccount) {
            System.debug('🎯 === STEP 1: PROCESS CONTRACTS WITH RENEWALS ===');
        }
        
        // Step 1: Process contracts with renewals (v42 enhancement)
        for (Contract contract : account.Contracts) {
            if (isTargetAccount) {
                System.debug('🎯 Contract: ' + contract.Id);
                System.debug('🎯   Status: ' + contract.Status);
                System.debug('🎯   StartDate: ' + contract.StartDate + ', EndDate: ' + contract.EndDate);
                System.debug('🎯   Renewal_Opportunity__c: ' + contract.Renewal_Opportunity__c);
            }
            
            if (contract.Renewal_Opportunity__c != null) {
                if (isTargetAccount) {
                    System.debug('🎯   Renewal opportunity found:');
                    if (contract.Renewal_Opportunity__r != null) {
                        System.debug('🎯     Id: ' + contract.Renewal_Opportunity__r.Id);
                        System.debug('🎯     StageName: ' + contract.Renewal_Opportunity__r.StageName);
                        System.debug('🎯     IsClosed: ' + contract.Renewal_Opportunity__r.IsClosed);
                        System.debug('🎯     Deal_Type__c: ' + contract.Renewal_Opportunity__r.Deal_Type__c);
                    } else {
                        System.debug('🎯     ❌ ERROR: Renewal_Opportunity__r is NULL!');
                    }
                }
                
                // Check_Renewal_Status logic
                if (contract.Renewal_Opportunity__r.IsClosed == false) {
                    varB_HasOpenRenewal = true;
                    if (isTargetAccount) {
                        System.debug('🎯     → Setting varB_HasOpenRenewal = true');
                    }
                } else if (contract.Renewal_Opportunity__r.StageName == 'Closed Lost' && 
                          contract.Renewal_Opportunity__r.Deal_Type__c == 'Churn') {
                    varB_HasLostRenewal = true;
                    if (isTargetAccount) {
                        System.debug('🎯     → Setting varB_HasLostRenewal = true');
                    }
                }
            }
        }
        
        if (isTargetAccount) {
            System.debug('🎯 === STEP 2: CHECK CANCELLED CONTRACTS ===');
        }
        
        // Step 2: Check if all contracts are cancelled
        Integer totalContracts = account.Contracts.size();
        Integer cancelledContracts = 0;
        for (Contract contract : account.Contracts) {
            if (contract.Status == 'Cancelled') {
                cancelledContracts++;
            }
        }
        varB_AllContractsCancelled = (cancelledContracts == totalContracts && totalContracts > 0);
        
        if (isTargetAccount) {
            System.debug('🎯 Total Contracts: ' + totalContracts + ', Cancelled: ' + cancelledContracts);
            System.debug('🎯 varB_AllContractsCancelled: ' + varB_AllContractsCancelled);
        }
        
        if (isTargetAccount) {
            System.debug('🎯 === STEP 3: CONTRACT COUNTING ===');
        }
        
        // Step 3: Contract counting (exact same logic as original)
        for (Contract contract : account.Contracts) {
            if (isTargetAccount) {
                System.debug('🎯 Contract ' + contract.Id + ':');
                System.debug('🎯   StartDate: ' + contract.StartDate + ', EndDate: ' + contract.EndDate + ', Today: ' + today);
                System.debug('🎯   Exclude_from_Status_Updates__c: ' + contract.Exclude_from_Status_Updates__c);
            }
            
            // Contract counting logic (exact flow replication)
            if (contract.StartDate > today && contract.Exclude_from_Status_Updates__c == false) {
                varN_FutureContracts += 1;
                if (isTargetAccount) {
                    System.debug('🎯   → FUTURE contract');
                }
            } else if (contract.StartDate <= today && 
                      contract.EndDate >= today && 
                      contract.Exclude_from_Status_Updates__c == false) {
                varN_ActiveContracts += 1;
                if (isTargetAccount) {
                    System.debug('🎯   → ACTIVE contract');
                }
            } else if (contract.EndDate < today) {
                varN_NumExpiredContracts += 1;
                if (isTargetAccount) {
                    System.debug('🎯   → EXPIRED contract');
                }
            }
        }
        
        if (isTargetAccount) {
            System.debug('🎯 === CONTRACT COUNT RESULTS ===');
            System.debug('🎯 varN_ActiveContracts: ' + varN_ActiveContracts);
            System.debug('🎯 varN_FutureContracts: ' + varN_FutureContracts);
            System.debug('🎯 varN_NumExpiredContracts: ' + varN_NumExpiredContracts);
            System.debug('🎯 varB_HasOpenRenewal: ' + varB_HasOpenRenewal);
            System.debug('🎯 varB_HasLostRenewal: ' + varB_HasLostRenewal);
            System.debug('🎯 varB_AllContractsCancelled: ' + varB_AllContractsCancelled);
        }
        
        // Step 4: Determine preservation logic (same as original)
        Boolean preserveAllExpired = (varN_ActiveContracts == 0 && 
                                     varN_FutureContracts == 0 && 
                                     varN_NumExpiredContracts > 0 &&
                                     !varB_AllContractsCancelled);
        
        Boolean preserveExpiredWithOpenRenewal = (varN_ActiveContracts == 0 && 
                                                 varN_FutureContracts == 0 && 
                                                 varN_NumExpiredContracts > 0 &&
                                                 varB_HasOpenRenewal);
        
        Boolean shouldPreserveExpiredRevenue = preserveAllExpired || preserveExpiredWithOpenRenewal;
        
        if (isTargetAccount) {
            System.debug('🎯 === PRESERVATION LOGIC ===');
            System.debug('🎯 preserveAllExpired: ' + preserveAllExpired);
            System.debug('🎯 preserveExpiredWithOpenRenewal: ' + preserveExpiredWithOpenRenewal);
            System.debug('🎯 shouldPreserveExpiredRevenue: ' + shouldPreserveExpiredRevenue);
        }
        
        // Step 5: Revenue calculation (abbreviated for debugging focus)
        if (shouldPreserveExpiredRevenue) {
            if (isTargetAccount) {
                System.debug('🎯 PRESERVING revenue fields (not recalculating)');
            }
        } else {
            if (isTargetAccount) {
                System.debug('🎯 RECALCULATING revenue fields from active contracts');
            }
            // Simplified revenue calculation for debug version
            account.ARR__c = 0;
            account.ACV__c = 0;
            account.TCV__c = 0;
            account.Incremental_ARR__c = 0;
            
            for (Contract contract : account.Contracts) {
                if (contract.Exclude_from_Status_Updates__c == false && 
                    ((contract.StartDate <= today && contract.EndDate >= today) ||
                     (contract.StartDate > today))) {
                    account.ARR__c += contract.ARR__c != null ? contract.ARR__c : 0;
                    account.ACV__c += contract.ACV__c != null ? contract.ACV__c : 0;
                    account.TCV__c += contract.TCV__c != null ? contract.TCV__c : 0;
                }
            }
        }
        
        if (isTargetAccount) {
            System.debug('🎯 === STEP 6: ACCOUNT STATUS DETERMINATION ===');
            System.debug('🎯 Current Status: ' + account.Status__c);
        }
        
        // Step 6: Account status determination with detailed logging
        String newStatus = determineAccountStatusWithDebug(account, varN_ActiveContracts, varN_FutureContracts, 
                                                           varN_NumExpiredContracts, varB_HasOpenRenewal, 
                                                           varB_HasLostRenewal, varB_AllContractsCancelled, isTargetAccount);
        
        String originalStatus = account.Status__c;
        Boolean statusChanged = false;
        
        if (newStatus != null) {
            account.Status__c = newStatus;
            statusChanged = (newStatus != originalStatus);
            
            if (isTargetAccount) {
                System.debug('🎯 STATUS UPDATE: ' + originalStatus + ' → ' + newStatus);
                System.debug('🎯 Status Changed: ' + statusChanged);
            }
            
            // Update Type field based on Status__c
            String newType = determineAccountType(newStatus);
            if (newType != null) {
                account.Type = newType;
                if (isTargetAccount) {
                    System.debug('🎯 TYPE UPDATE: → ' + newType);
                }
            }
        } else {
            if (isTargetAccount) {
                System.debug('🎯 NO STATUS CHANGE (newStatus is null)');
            }
        }
        
        // Calculate MRR and format fields (simplified)
        if (!shouldPreserveExpiredRevenue) {
            account.MRR__c = account.ARR__c != null ? account.ARR__c / 12 : 0;
        }
        
        if (isTargetAccount) {
            System.debug('🎯 === FINAL ACCOUNT STATE ===');
            System.debug('🎯 Final Status: ' + account.Status__c);
            System.debug('🎯 Final Type: ' + account.Type);
            System.debug('🎯 Will be flagged for update: ' + (account != null));
            
            // Log detailed status determination result
            String logMessage = String.format('Status: {0}→{1}, ActiveContracts: {2}, HasLostRenewal: {3}, HasOpenRenewal: {4}', 
                new List<String>{originalStatus, String.valueOf(newStatus), String.valueOf(varN_ActiveContracts), 
                                String.valueOf(varB_HasLostRenewal), String.valueOf(varB_HasOpenRenewal)});
            
            Batch_Execution_Log__c detailLog = new Batch_Execution_Log__c(
                Batch_Job_ID__c = currentBatchJobId,
                Execution_Context__c = executionContext,
                Processing_Stage__c = statusChanged ? 'PROCESSED' : 'SKIPPED',
                Contract_ID__c = TARGET_ACCOUNT_ID,
                Error_Message__c = logMessage
            );
            debugLogs.add(detailLog);
        }
        
        return account;
    }
    
    /**
     * Enhanced status determination with detailed debugging
     */
    private String determineAccountStatusWithDebug(Account account, Decimal activeContracts, Decimal futureContracts, 
                                                   Decimal expiredContracts, Boolean hasOpenRenewal, 
                                                   Boolean hasLostRenewal, Boolean allContractsCancelled, Boolean isTargetAccount) {
        
        if (isTargetAccount) {
            System.debug('🎯 Evaluating status rules in priority order...');
        }
        
        // Rule 1: All_Contracts_Cancelled (highest priority)
        if (isTargetAccount) {
            System.debug('🎯 Rule 1: All_Contracts_Cancelled');
            System.debug('🎯   Condition: allContractsCancelled && activeContracts == 0');
            System.debug('🎯   Values: ' + allContractsCancelled + ' && ' + activeContracts + ' == 0');
        }
        if (allContractsCancelled && activeContracts == 0) {
            if (isTargetAccount) System.debug('🎯   → MATCH: Returning Churned');
            return 'Churned';
        }
        
        // Rule 2: Null_To_Prospect
        if (isTargetAccount) {
            System.debug('🎯 Rule 2: Null_To_Prospect');
            System.debug('🎯   Condition: Status = null && futureContracts == 0 && activeContracts == 0');
            System.debug('🎯   Values: ' + account.Status__c + ' == null && ' + futureContracts + ' == 0 && ' + activeContracts + ' == 0');
        }
        if (account.Status__c == null && futureContracts == 0 && activeContracts == 0) {
            if (isTargetAccount) System.debug('🎯   → MATCH: Returning Prospect');
            return 'Prospect';
        }
        
        // Rule 3: Only_Future_Contracts
        if (isTargetAccount) {
            System.debug('🎯 Rule 3: Only_Future_Contracts');
            System.debug('🎯   Condition: futureContracts > 0 && activeContracts == 0');
            System.debug('🎯   Values: ' + futureContracts + ' > 0 && ' + activeContracts + ' == 0');
        }
        if (futureContracts > 0 && activeContracts == 0) {
            if (isTargetAccount) System.debug('🎯   → MATCH: Returning Contracted');
            return 'Contracted';
        }
        
        // Rule 4: Churning_To_Churned
        if (isTargetAccount) {
            System.debug('🎯 Rule 4: Churning_To_Churned');
            System.debug('🎯   Condition: Status = \'Active (Churning)\' && activeContracts == 0 && expiredContracts > 0 && !hasOpenRenewal');
            System.debug('🎯   Values: ' + account.Status__c + ' == \'Active (Churning)\' && ' + activeContracts + ' == 0 && ' + expiredContracts + ' > 0 && !' + hasOpenRenewal);
        }
        if (account.Status__c == 'Active (Churning)' && activeContracts == 0 && expiredContracts > 0 && !hasOpenRenewal) {
            if (isTargetAccount) System.debug('🎯   → MATCH: Returning Churned');
            return 'Churned';
        }
        
        // Rule 5: Active_With_Lost_Renewal_No_Active
        if (isTargetAccount) {
            System.debug('🎯 Rule 5: Active_With_Lost_Renewal_No_Active');
            System.debug('🎯   Condition: Status = \'Active\' && activeContracts == 0 && hasLostRenewal');
            System.debug('🎯   Values: ' + account.Status__c + ' == \'Active\' && ' + activeContracts + ' == 0 && ' + hasLostRenewal);
        }
        if (account.Status__c == 'Active' && activeContracts == 0 && hasLostRenewal) {
            if (isTargetAccount) System.debug('🎯   → MATCH: Returning Churned');
            return 'Churned';
        }
        
        // Rule 6: Active_With_Lost_Renewal_Enhanced (THE CRITICAL RULE)
        if (isTargetAccount) {
            System.debug('🎯 Rule 6: Active_With_Lost_Renewal_Enhanced (CRITICAL RULE FOR THIS CASE)');
            System.debug('🎯   Condition: Status = \'Active\' && activeContracts > 0 && hasLostRenewal && !hasOpenRenewal');
            System.debug('🎯   Values: ' + account.Status__c + ' == \'Active\' && ' + activeContracts + ' > 0 && ' + hasLostRenewal + ' && !' + hasOpenRenewal);
            System.debug('🎯   Individual checks:');
            System.debug('🎯     Status = \'Active\': ' + (account.Status__c == 'Active'));
            System.debug('🎯     activeContracts > 0: ' + (activeContracts > 0));
            System.debug('🎯     hasLostRenewal: ' + hasLostRenewal);
            System.debug('🎯     !hasOpenRenewal: ' + (!hasOpenRenewal));
        }
        if (account.Status__c == 'Active' && activeContracts > 0 && hasLostRenewal && !hasOpenRenewal) {
            if (isTargetAccount) System.debug('🎯   → ✅ MATCH: Returning Active (Churning)');
            return 'Active (Churning)';
        } else {
            if (isTargetAccount) System.debug('🎯   → ❌ NO MATCH');
        }
        
        // Rule 7: Expired_Contracts_With_Open_Renewal
        if (isTargetAccount) {
            System.debug('🎯 Rule 7: Expired_Contracts_With_Open_Renewal');
            System.debug('🎯   Condition: activeContracts == 0 && expiredContracts > 0 && hasOpenRenewal');
            System.debug('🎯   Values: ' + activeContracts + ' == 0 && ' + expiredContracts + ' > 0 && ' + hasOpenRenewal);
        }
        if (activeContracts == 0 && expiredContracts > 0 && hasOpenRenewal) {
            if (isTargetAccount) System.debug('🎯   → MATCH: Returning Active (Churning)');
            return 'Active (Churning)';
        }
        
        // Rule 8: Has_Active_Contracts
        if (isTargetAccount) {
            System.debug('🎯 Rule 8: Has_Active_Contracts');
            System.debug('🎯   Condition: activeContracts > 0');
            System.debug('🎯   Values: ' + activeContracts + ' > 0');
        }
        if (activeContracts > 0) {
            if (isTargetAccount) System.debug('🎯   → MATCH: Returning Active');
            return 'Active';
        }
        
        // Rule 9: Default - no change
        if (isTargetAccount) {
            System.debug('🎯 Rule 9: Default - no change');
            System.debug('🎯   → NO MATCH: Returning null (no status change)');
        }
        return null;
    }
    
    /**
     * Determine Account Type (same as original)
     */
    private String determineAccountType(String status) {
        if (status == 'Contracted' || status == 'Active' || status == 'Active (Churning)') {
            return 'Customer';
        }
        if (status == 'Prospect') {
            return 'Prospect';
        }
        if (status == 'Churned') {
            return 'Churned';
        }
        return null;
    }
    
    /**
     * Enhanced finish method with comprehensive logging
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('AccountRollupBatchDebug: Sequential revenue automation processing complete');
        
        // Log completion
        Batch_Execution_Log__c finishLog = new Batch_Execution_Log__c(
            Batch_Job_ID__c = currentBatchJobId,
            Execution_Context__c = executionContext,
            Processing_Stage__c = 'UPDATED',
            Contract_ID__c = 'BATCH_COMPLETE',
            Error_Message__c = 'Total accounts processed: ' + totalAccountsProcessed + ', Target account in batch: ' + targetAccountBatchNumber
        );
        
        try {
            insert finishLog;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to insert finish log: ' + e.getMessage());
        }
        
        if (targetAccountBatchNumber > 0) {
            System.debug('🎯 TARGET ACCOUNT WAS PROCESSED in batch #' + targetAccountBatchNumber);
        } else {
            System.debug('🎯 TARGET ACCOUNT WAS NOT FOUND in any batch!');
        }
    }
}
