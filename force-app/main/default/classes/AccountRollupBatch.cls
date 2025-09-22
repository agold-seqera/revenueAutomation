/**
 * Batch class to replace Scheduled_Flow_Daily_Update_Accounts (v42)
 * Replicates EXACT flow business logic for account revenue rollups and enhanced status updates
 * 
 * Flow Logic Replicated (v42 Enhanced):
 * - Processes accounts with Has_Contracts__c = true
 * - Revenue Rollup: Sum ARR, ACV, TCV, MRR, Incremental_ARR from contracts
 * - USD Rollup: Parse and sum formatted USD fields from contracts
 * - Enhanced Status Logic (v42):
 *   - Check for contracts with renewal opportunities
 *   - Detect open vs lost renewals
 *   - Check if all contracts are cancelled
 *   - Apply complex status transition rules
 */
public class AccountRollupBatch implements Database.Batchable<sObject> {
    
    /**
     * Query accounts matching exact flow criteria:
     * Has_Contracts__c = true
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
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
     * Process each batch of accounts using exact flow logic
     */
    public void execute(Database.BatchableContext bc, List<Account> accounts) {
        List<Account> accountsToUpdate = new List<Account>();
        Date today = Date.today();
        
        for (Account account : accounts) {
            Account updatedAccount = processAccount(account, today);
            
            if (updatedAccount != null) {
                accountsToUpdate.add(updatedAccount);
            }
        }
        
        // Bulk update - matches flow's Update_Account element
        if (!accountsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(accountsToUpdate, false);
                
                // Log any failures
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        System.debug(LoggingLevel.ERROR, 
                            'AccountRollupBatch: Failed to update Account ' + accountsToUpdate[i].Id + 
                            ': ' + results[i].getErrors());
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'AccountRollupBatch: Exception during update: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Final batch in the chain - no further chaining needed
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('AccountRollupBatch: Sequential revenue automation processing complete');
    }
    
    /**
     * Replicate exact Account flow v42 logic for single account
     * 
     * Flow Sequence (v42):
     * 1. Nullify_Revenue_Fields
     * 2. Get_Contracts_With_Renewals → Loop_Contracts_With_Renewals
     * 3. Check_Renewal_Status → Set renewal flags
     * 4. Get_Cancelled_Contracts → Check_All_Contracts_Cancelled
     * 5. Get_Lost_Renewals → Check_Lost_Renewals
     * 6. Loop_Contracts → Add revenue totals + contract counts
     * 7. Account_Status decision (enhanced v42 logic)
     * 8. Format USD fields
     * 9. Update_Account
     */
    private Account processAccount(Account account, Date today) {
        // Initialize USD totals and tracking variables
        Decimal varARR_USD_Total = 0;
        Decimal varACV_USD_Total = 0;
        Decimal varTCV_USD_Total = 0;
        Decimal varMRR_USD_Total = 0;
        Decimal varIncrementalARR_USD_Total = 0;
        
        // Initialize Number reporting field totals
        Decimal varARR_Reporting_Total = 0;
        Decimal varACV_Reporting_Total = 0;
        Decimal varTCV_Reporting_Total = 0;
        Decimal varMRR_Reporting_Total = 0;
        
        // v42 Enhancement variables
        Boolean varB_HasOpenRenewal = false;
        Boolean varB_HasLostRenewal = false;
        Boolean varB_AllContractsCancelled = false;
        
        // Contract counting variables
        Decimal varN_ActiveContracts = 0;
        Decimal varN_FutureContracts = 0;
        Decimal varN_NumExpiredContracts = 0;
        
        // Revenue preservation flag
        Boolean shouldPreserveExpiredRevenue = false;
        
        // Step 2-3: Process contracts with renewals (v42 enhancement)
        for (Contract contract : account.Contracts) {
            if (contract.Renewal_Opportunity__c != null) {
                // Check_Renewal_Status logic
                if (contract.Renewal_Opportunity__r.IsClosed == false) {
                    varB_HasOpenRenewal = true;
                } else if (contract.Renewal_Opportunity__r.StageName == 'Closed Lost' && 
                          contract.Renewal_Opportunity__r.Deal_Type__c == 'Churn') {
                    varB_HasLostRenewal = true;
                }
            }
        }
        
        // Step 4: Check if all contracts are cancelled
        Integer totalContracts = account.Contracts.size();
        Integer cancelledContracts = 0;
        for (Contract contract : account.Contracts) {
            if (contract.Status == 'Cancelled') {
                cancelledContracts++;
            }
        }
        varB_AllContractsCancelled = (cancelledContracts == totalContracts && totalContracts > 0);
        
        // Step 6: Loop_Contracts - Contract counting first (to determine preservation logic)
        for (Contract contract : account.Contracts) {
            // Contract counting logic (exact flow replication)
            if (contract.StartDate > today && contract.Exclude_from_Status_Updates__c == false) {
                varN_FutureContracts += 1;
            } else if (contract.StartDate <= today && 
                      contract.EndDate >= today && 
                      contract.Exclude_from_Status_Updates__c == false) {
                varN_ActiveContracts += 1;
            } else if (contract.EndDate < today) {
                varN_NumExpiredContracts += 1;
            }
        }
        
        // CRITICAL BUSINESS LOGIC: Expired Contract Revenue Preservation
        // Scenario 1: "if all contracts are expired that's when we preserve the expired amount"
        Boolean preserveAllExpired = (varN_ActiveContracts == 0 && 
                                     varN_FutureContracts == 0 && 
                                     varN_NumExpiredContracts > 0 &&
                                     !varB_AllContractsCancelled);
        
        // Scenario 2: All contracts expired but open renewals - preserve until renewal resolves
        Boolean preserveExpiredWithOpenRenewal = (varN_ActiveContracts == 0 && 
                                                 varN_FutureContracts == 0 && 
                                                 varN_NumExpiredContracts > 0 &&
                                                 varB_HasOpenRenewal);
        
        shouldPreserveExpiredRevenue = preserveAllExpired || preserveExpiredWithOpenRenewal;
        
        if (shouldPreserveExpiredRevenue) {
            // PRESERVE existing revenue - don't nullify, don't recalculate
            System.debug('AccountRollupBatch: Preserving expired revenue for account ' + account.Id + 
                        ' (Active: ' + varN_ActiveContracts + ', Future: ' + varN_FutureContracts + 
                        ', Expired: ' + varN_NumExpiredContracts + ', HasOpenRenewal: ' + varB_HasOpenRenewal + 
                        ', Scenario: ' + (preserveAllExpired ? 'AllExpired' : 'ExpiredWithOpenRenewal') + ')');
            
            // Keep existing ARR/ACV/TCV values, but still update USD fields if needed
            // Parse existing USD values for status calculations
            varARR_USD_Total = parseUSDValue(account.ARR_USD__c);
            varACV_USD_Total = parseUSDValue(account.ACV_USD__c);
            varTCV_USD_Total = parseUSDValue(account.TCV_USD__c);
            varMRR_USD_Total = parseUSDValue(account.MRR_USD__c);
            
            // Parse existing Number reporting values
            varARR_Reporting_Total = account.ARR_USD_Reporting__c != null ? account.ARR_USD_Reporting__c : 0;
            varACV_Reporting_Total = account.ACV_USD_Reporting__c != null ? account.ACV_USD_Reporting__c : 0;
            varTCV_Reporting_Total = account.TCV_USD_Reporting__c != null ? account.TCV_USD_Reporting__c : 0;
            varMRR_Reporting_Total = account.MRR_USD_Reporting__c != null ? account.MRR_USD_Reporting__c : 0;
            
        } else {
            // STANDARD LOGIC: Nullify then recalculate revenue from active contracts
            account.ARR__c = 0;
            account.Incremental_ARR__c = 0;
            account.ACV__c = 0;
            account.TCV__c = 0;
            
            for (Contract contract : account.Contracts) {
                if (contract.StartDate <= today && 
                    contract.EndDate >= today && 
                    contract.Exclude_from_Status_Updates__c == false) {
                    
                    // Add revenue for ACTIVE contracts only (exact flow logic)
                    account.ARR__c += contract.ARR__c != null ? contract.ARR__c : 0;
                    account.ACV__c += contract.ACV__c != null ? contract.ACV__c : 0;
                    account.TCV__c += contract.TCV__c != null ? contract.TCV__c : 0;
                    account.Incremental_ARR__c += contract.Incremental_ARR__c != null ? contract.Incremental_ARR__c : 0;
                    
                    // USD aggregation for ACTIVE contracts only (exact flow formulas)
                    varARR_USD_Total += parseUSDValue(contract.ARR_USD__c);
                    varACV_USD_Total += parseUSDValue(contract.ACV_USD__c);
                    varTCV_USD_Total += parseUSDValue(contract.TCV_USD__c);
                    varMRR_USD_Total += parseUSDValue(contract.MRR_USD__c);
                    
                    // Number reporting field aggregation for ACTIVE contracts only
                    varARR_Reporting_Total += contract.ARR_USD_Reporting__c != null ? contract.ARR_USD_Reporting__c : 0;
                    varACV_Reporting_Total += contract.ACV_USD_Reporting__c != null ? contract.ACV_USD_Reporting__c : 0;
                    varTCV_Reporting_Total += contract.TCV_USD_Reporting__c != null ? contract.TCV_USD_Reporting__c : 0;
                    varMRR_Reporting_Total += contract.MRR_USD_Reporting__c != null ? contract.MRR_USD_Reporting__c : 0;
                }
            }
        }
        
        // Step 7: Account_Status decision (v42 enhanced logic)
        String newStatus = determineAccountStatus(account, varN_ActiveContracts, varN_FutureContracts, 
                                                 varN_NumExpiredContracts, varB_HasOpenRenewal, 
                                                 varB_HasLostRenewal, varB_AllContractsCancelled);
        if (newStatus != null) {
            account.Status__c = newStatus;
        }
        
        // Step 8: Calculate MRR (exact flow formula)
        // Only recalculate MRR if we're not preserving expired revenue
        if (!shouldPreserveExpiredRevenue) {
            account.MRR__c = account.ARR__c != null ? account.ARR__c / 12 : 0;
        }
        // If preserving, keep existing MRR value
        
        // Step 9: Format USD fields (exact flow logic)
        try {
            // Format using exact flow formulas
            account.ARR_USD__c = '$' + String.valueOf(varARR_USD_Total.setScale(2).format());
            account.ACV_USD__c = '$' + String.valueOf(varACV_USD_Total.setScale(2).format());
            account.TCV_USD__c = '$' + String.valueOf(varTCV_USD_Total.setScale(2).format());
            account.MRR_USD__c = '$' + String.valueOf(varMRR_USD_Total.setScale(2).format());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AccountRollupBatch: USD formatting error for Account ' + account.Id + ': ' + e.getMessage());
        }
        
        // Step 10: Populate Number reporting fields (for aggregation and reporting)
        try {
            account.ARR_USD_Reporting__c = varARR_Reporting_Total.setScale(2);
            account.ACV_USD_Reporting__c = varACV_Reporting_Total.setScale(2);
            account.TCV_USD_Reporting__c = varTCV_Reporting_Total.setScale(2);
            account.MRR_USD_Reporting__c = varMRR_Reporting_Total.setScale(2);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AccountRollupBatch: Number reporting field error for Account ' + account.Id + ': ' + e.getMessage());
        }
        
        return account;
    }
    
    /**
     * Parse USD formatted string back to decimal (exact flow formula replication)
     * Flow formulas like: VALUE(SUBSTITUTE(SUBSTITUTE(ARR_USD__c, "$", ""), ",", ""))
     */
    private Decimal parseUSDValue(String usdString) {
        if (String.isBlank(usdString)) {
            return 0;
        }
        
        try {
            // Remove $ and , characters (exact flow logic)
            String cleanValue = usdString.replace('$', '').replace(',', '');
            return Decimal.valueOf(cleanValue);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'AccountRollupBatch: Failed to parse USD value: ' + usdString);
            return 0;
        }
    }
    
    /**
     * Replicate exact Account flow v42 status determination logic
     * 
     * Flow Decision: Account_Status (v42 Enhanced)
     * Rules (in priority order):
     * 1. All_Contracts_Cancelled: varB_AllContractsCancelled = true AND varN_ActiveContracts = 0 → Churned
     * 2. Null_To_Prospect: Status = null AND varN_FutureContracts = 0 AND varN_ActiveContracts = 0 → Prospect
     * 3. Only_Future_Contracts: varN_FutureContracts > 0 AND varN_ActiveContracts = 0 → Prospect
     * 4. Churning_To_Churned: Status = 'Active (Churning)' AND varN_ActiveContracts = 0 AND varN_NumExpiredContracts > 0 → Churned
     * 5. Active_With_Lost_Renewal_No_Active: Status = 'Active' AND varN_ActiveContracts = 0 AND varB_HasLostRenewal = true → Churned
     * 6. Active_With_Lost_Renewal_Enhanced: Status = 'Active' AND varN_ActiveContracts > 0 AND varB_HasLostRenewal = true AND varB_HasOpenRenewal = false → Active (Churning)
     * 7. Expired_Contracts_With_Open_Renewal: varN_ActiveContracts = 0 AND varN_NumExpiredContracts > 0 AND varB_HasOpenRenewal = true → Active (Churning)
     * 8. Has_Active_Contracts: varN_ActiveContracts > 0 → Active
     * 9. Default: No change
     */
    private String determineAccountStatus(Account account, Decimal activeContracts, Decimal futureContracts, 
                                        Decimal expiredContracts, Boolean hasOpenRenewal, 
                                        Boolean hasLostRenewal, Boolean allContractsCancelled) {
        
        // Rule 1: All_Contracts_Cancelled (highest priority)
        if (allContractsCancelled && activeContracts == 0) {
            return 'Churned';
        }
        
        // Rule 2: Null_To_Prospect
        if (account.Status__c == null && futureContracts == 0 && activeContracts == 0) {
            return 'Prospect';
        }
        
        // Rule 3: Only_Future_Contracts
        if (futureContracts > 0 && activeContracts == 0) {
            return 'Prospect';
        }
        
        // Rule 4: Churning_To_Churned
        if (account.Status__c == 'Active (Churning)' && activeContracts == 0 && expiredContracts > 0) {
            return 'Churned';
        }
        
        // Rule 5: Active_With_Lost_Renewal_No_Active (NEW - direct to Churned)
        if (account.Status__c == 'Active' && 
            activeContracts == 0 && 
            hasLostRenewal) {
            return 'Churned';
        }
        
        // Rule 6: Active_With_Lost_Renewal_Enhanced (v42)
        if (account.Status__c == 'Active' && 
            activeContracts > 0 && 
            hasLostRenewal && 
            !hasOpenRenewal) {
            return 'Active (Churning)';
        }
        
        // Rule 7: Expired_Contracts_With_Open_Renewal (v42)
        if (activeContracts == 0 && 
            expiredContracts > 0 && 
            hasOpenRenewal) {
            return 'Active (Churning)';
        }
        
        // Rule 8: Has_Active_Contracts
        if (activeContracts > 0) {
            return 'Active';
        }
        
        // Rule 9: Default - no change
        return null;
    }
}