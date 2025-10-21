public with sharing class ContractTriggerHandler {

    public static void handleAfterInsert(List<Contract> contracts) {
        updateAccountFields(contracts);
    }

    public static void handleAfterUpdate(List<Contract> contracts, Map<Id, Contract> oldMap) {
        updateAccountFields(contracts);
        // Also handle contracts that moved accounts
        if (oldMap != null) {
            List<Contract> movedContracts = new List<Contract>();
            for (Contract contract : contracts) {
                Contract oldContract = oldMap.get(contract.Id);
                if (oldContract != null && oldContract.AccountId != null &&
                    oldContract.AccountId != contract.AccountId) {
                    // This contract moved accounts, include old version for count adjustment
                    movedContracts.add(oldContract);
                }
            }
            if (!movedContracts.isEmpty()) {
                updateAccountFields(movedContracts);
            }
        }
    }

    public static void handleAfterDelete(List<Contract> contracts) {
        updateAccountFields(contracts);
    }

    public static void handleAfterUndelete(List<Contract> contracts) {
        updateAccountFields(contracts);
    }

    private static void updateAccountFields(List<Contract> contracts) {
        if (contracts == null || contracts.isEmpty()) return;

        Set<Id> accountIds = new Set<Id>();
        for (Contract contract : contracts) {
            if (contract.AccountId != null) {
                accountIds.add(contract.AccountId);
            }
        }

        if (accountIds.isEmpty()) return;

        // Count contracts per account (simple approach)
        Map<Id, Integer> contractCounts = new Map<Id, Integer>();
        for (Contract contract : [SELECT AccountId FROM Contract WHERE AccountId IN :accountIds AND Status != 'Expired']) {
            Integer currentCount = contractCounts.get(contract.AccountId) ?? 0;
            contractCounts.put(contract.AccountId, currentCount + 1);
        }

        // Update accounts with counts and flags
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountIds) {
            Integer count = contractCounts.get(accountId) ?? 0;
            accountsToUpdate.add(new Account(
                Id = accountId,
                Contract_Count__c = count,
                Has_Contracts__c = count > 0
            ));
        }

        if (!accountsToUpdate.isEmpty()) {
            Database.update(accountsToUpdate, false);
        }
    }
}