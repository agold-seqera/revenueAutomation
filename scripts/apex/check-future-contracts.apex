// Check for accounts with future contracts to verify AccountRollupBatch logic
System.debug('=== CHECKING FUTURE CONTRACTS AND ACCOUNT STATUS ===');

Date today = Date.today();

// Find accounts with future contracts
List<Account> accountsWithFuture = [
    SELECT Id, Name, Status__c, ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           (SELECT Id, Status, StartDate, EndDate, ARR__c, ARR_USD__c, ARR_USD_Reporting__c
            FROM Contracts
            WHERE StartDate > :today
            AND Status = 'Draft'
            LIMIT 5)
    FROM Account
    WHERE Has_Contracts__c = true
    LIMIT 10
];

System.debug('Found ' + accountsWithFuture.size() + ' accounts to check for future contracts');

Integer futureContractCount = 0;
for (Account acc : accountsWithFuture) {
    if (!acc.Contracts.isEmpty()) {
        System.debug('--- Account: ' + acc.Name + ' ---');
        System.debug('  Status: ' + acc.Status__c);
        System.debug('  ARR: ' + acc.ARR__c + ' | USD: ' + acc.ARR_USD__c + ' | Reporting: ' + acc.ARR_USD_Reporting__c);
        
        for (Contract contract : acc.Contracts) {
            futureContractCount++;
            System.debug('  ✓ FUTURE Contract: ' + contract.Id);
            System.debug('    Status: ' + contract.Status + ' | Start: ' + contract.StartDate + ' | End: ' + contract.EndDate);
            System.debug('    ARR: ' + contract.ARR__c + ' | USD: ' + contract.ARR_USD__c + ' | Reporting: ' + contract.ARR_USD_Reporting__c);
        }
    }
}

if (futureContractCount == 0) {
    System.debug('ℹ️ No future contracts found. Let\'s check for any Draft contracts:');
    
    List<Contract> draftContracts = [
        SELECT Id, Status, StartDate, EndDate, AccountId, Account.Name, Account.Status__c
        FROM Contract
        WHERE Status = 'Draft'
        AND StartDate >= :today
        LIMIT 5
    ];
    
    System.debug('Found ' + draftContracts.size() + ' Draft contracts with future start dates:');
    for (Contract contract : draftContracts) {
        System.debug('  Contract: ' + contract.Id + ' (' + contract.Account.Name + ')');
        System.debug('    Account Status: ' + contract.Account.Status__c);
        System.debug('    Contract Start: ' + contract.StartDate + ' | End: ' + contract.EndDate);
    }
}

System.debug('=== FUTURE CONTRACTS CHECK COMPLETE ===');
