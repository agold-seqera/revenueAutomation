/**
 * - Processes accounts with Has_Contracts__c = true
 * - Active accounts: Recalculate All fields (base + reporting) from Active contracts only
 * - Churning/Churned accounts: Preserve All existing field values (no changes)
 */
public class AccountRollupBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c, Type, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c, Incremental_ARR_USD_Reporting__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                   (SELECT Id, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c, Incremental_ARR_USD_Reporting__c,
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
    
    // Process each batch of accounts
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
    
    // Final batch in the chain - no further chaining needed
    public void finish(Database.BatchableContext bc) {
        System.debug('AccountRollupBatch: Sequential revenue automation processing complete');
    }
    
    private Account processAccount(Account account, Date today) {
        // Variables for status determination
        Boolean varB_HasOpenRenewal = false;
        Boolean varB_HasLostRenewal = false;
        Boolean varB_AllContractsCancelled = false;
        
        // Nullify contract counting variables
        Decimal varN_ActiveContracts = 0;
        Decimal varN_FutureContracts = 0;
        Decimal varN_NumExpiredContracts = 0;
        
        // Process contracts with renewals
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
        
        // Check if all contracts are cancelled
        Integer totalContracts = account.Contracts.size();
        Integer cancelledContracts = 0;
        for (Contract contract : account.Contracts) {
            if (contract.Status == 'Cancelled') {
                cancelledContracts++;
            }
        }
        varB_AllContractsCancelled = (cancelledContracts == totalContracts && totalContracts > 0);
        
        // Contract counting
        for (Contract contract : account.Contracts) {
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
        
        // Determine if we should preserve expired revenue
        Boolean shouldPreserveRevenue = (varN_ActiveContracts == 0 && 
                                         varN_FutureContracts == 0 && 
                                         varN_NumExpiredContracts > 0 &&
                                         !varB_AllContractsCancelled);
        
        // Revenue Calculations
        if (shouldPreserveRevenue) {
            System.debug('AccountRollupBatch: Preserving ALL revenue fields for account ' + account.Id);
        } else {
            // Active Account - recalculate all fields from Active contracts only
            System.debug('AccountRollupBatch: Recalculating all revenue fields from active contracts for account ' + account.Id);
            
            // Reset base currency fields
            account.ARR__c = 0;
            account.ACV__c = 0;
            account.TCV__c = 0;
            account.Incremental_ARR__c = 0;
            account.MRR__c = 0;

            // Reset reporting fields
            account.ARR_USD_Reporting__c = 0;
            account.ACV_USD_Reporting__c = 0;
            account.TCV_USD_Reporting__c = 0;
            account.Incremental_ARR_USD_Reporting__c = 0;
            account.MRR_USD_Reporting__c = 0;
            
            // Apply contract counting business logic for revenue calculations:
            // 1. If account has Activated contracts → calculate revenue from only Activated contracts
            // 2. If account has no Activated contracts → calculate revenue from Draft contracts  
            // 3. Otherwise → revenue = 0
            
            // First, determine which contracts should contribute to revenue
            List<Contract> eligibleContracts = new List<Contract>();
            
            // Count contract types for business logic
            Integer activatedCount = 0;
            Integer draftCount = 0;
            List<Contract> activatedContracts = new List<Contract>();
            List<Contract> draftContracts = new List<Contract>();
            
            for (Contract contract : account.Contracts) {
                if (contract.Exclude_from_Status_Updates__c == false && 
                    ((contract.StartDate <= today && contract.EndDate >= today) ||   
                     (contract.StartDate > today))) {                                 
                    
                    if (contract.Status == 'Activated') {
                        activatedCount++;
                        activatedContracts.add(contract);
                    } else if (contract.Status == 'Draft') {
                        draftCount++;
                        draftContracts.add(contract);
                    }
                }
            }            
            // Activated takes priority over Draft
            if (activatedCount > 0) {
                eligibleContracts = activatedContracts; 
            } else if (draftCount > 0) {
                eligibleContracts = draftContracts;      
            }           
            // Calculate revenue from eligible contracts only
            for (Contract contract : eligibleContracts) {
                // Base currency fields from eligible contracts
                account.ARR__c += contract.ARR__c != null ? contract.ARR__c : 0;
                account.ACV__c += contract.ACV__c != null ? contract.ACV__c : 0;
                account.TCV__c += contract.TCV__c != null ? contract.TCV__c : 0;
                account.MRR__c += contract.MRR__c != null ? contract.MRR__c : 0;
                account.Incremental_ARR__c += contract.Incremental_ARR__c != null ? contract.Incremental_ARR__c : 0;                
                // Reporting fields from eligible contracts
                varARR_Reporting_Total += contract.ARR_USD_Reporting__c != null ? contract.ARR_USD_Reporting__c : 0;
                varACV_Reporting_Total += contract.ACV_USD_Reporting__c != null ? contract.ACV_USD_Reporting__c : 0;
                varTCV_Reporting_Total += contract.TCV_USD_Reporting__c != null ? contract.TCV_USD_Reporting__c : 0;
                varMRR_Reporting_Total += contract.MRR_USD_Reporting__c != null ? contract.MRR_USD_Reporting__c : 0;
                account.Incremental_ARR_USD_Reporting__c += contract.Incremental_ARR_USD_Reporting__c != null ? contract.Incremental_ARR_USD_Reporting__c : 0;
            }
        }        
        // Account status determination
        String newStatus = determineAccountStatus(account, varN_ActiveContracts, varN_FutureContracts, 
                                                 varN_NumExpiredContracts, varB_HasOpenRenewal, 
                                                 varB_HasLostRenewal, varB_AllContractsCancelled);
        if (newStatus != null) {
            account.Status__c = newStatus;
            
            // Update Type field based on Status__c (replaces flow logic)
            String newType = determineAccountType(newStatus);
            if (newType != null) {
                account.Type = newType;
            }
        }
        return account;
    }
    
    private String determineAccountStatus(Account account, Decimal activeContracts, Decimal futureContracts, 
                                        Decimal expiredContracts, Boolean hasOpenRenewal, 
                                        Boolean hasLostRenewal, Boolean allContractsCancelled) {
        
        // 1. All contracts cancelled
        if (allContractsCancelled && activeContracts == 0) {
            return 'Churned';
        }
        // 2. Only future contracts
        else if (futureContracts > 0 && activeContracts == 0) {
            return 'Contracted';
        }      
        // 3. Has active contracts
        else if (activeContracts > 0) {
            // 3.1. Active with lost renewal and no open renewals
            if (account.Status__c == 'Active' && hasLostRenewal && !hasOpenRenewal) {
                return 'Active (Churning)';
            }
            // 3.2. All other active contract scenarios
            return 'Active';
        }        
        // 4. No active contracts
        else if (activeContracts == 0) {
            // 4.1. Expired contracts with open renewals
            if (expiredContracts > 0 && hasOpenRenewal) {
                return 'Active (Churning)';
            }
            // 4.2. Churning status with expired contracts and no open renewals
            else if (account.Status__c == 'Active (Churning)' && expiredContracts > 0 && !hasOpenRenewal) {
                return 'Churned';
            }
            // 4.3. Active status with lost renewal
            else if (account.Status__c == 'Active' && hasLostRenewal) {
                return 'Churned';
            }
        }        
        // 5. Default
        return null;
    }

    private String determineAccountType(String status) {
        // Customer statuses
        if (status == 'Contracted' || status == 'Active' || status == 'Active (Churning)') {
            return 'Customer';
        }        
        // Churned status  
        if (status == 'Churned') {
            return 'Churned';
        }        
        // Default
        return null;
    }
}