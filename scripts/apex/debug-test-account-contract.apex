// Debug script to check the test account and its contract

// Look for the test account
List<Account> testAccounts = [
    SELECT Id, Name, Type__c, Has_Contracts__c
    FROM Account 
    WHERE Name = 'Batch Test Account'
    LIMIT 5
];

System.debug('=== TEST ACCOUNTS ===');
for (Account acc : testAccounts) {
    System.debug('Account: ' + acc.Id + ', Name: ' + acc.Name);
    System.debug('  Type__c: ' + acc.Type__c + ', Has_Contracts__c: ' + acc.Has_Contracts__c);
}

if (!testAccounts.isEmpty()) {
    Account testAccount = testAccounts[0];
    
    // Check contracts on this account
    List<Contract> accountContracts = [
        SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c, 
               AccountId, ContractTerm, CreatedDate
        FROM Contract 
        WHERE AccountId = :testAccount.Id
        ORDER BY CreatedDate DESC
        LIMIT 5
    ];
    
    System.debug('=== CONTRACTS ON TEST ACCOUNT ===');
    System.debug('Contract count: ' + accountContracts.size());
    for (Contract c : accountContracts) {
        System.debug('Contract: ' + c.Id + ', Status: ' + c.Status);
        System.debug('  StartDate: ' + c.StartDate + ', EndDate: ' + c.EndDate);
        System.debug('  Exclude_from_Status_Updates__c: ' + c.Exclude_from_Status_Updates__c);
        System.debug('  Created: ' + c.CreatedDate);
        
        // Check activation criteria
        Boolean shouldActivate = (c.StartDate <= Date.today() && 
                                 c.EndDate >= Date.today() && 
                                 c.Status == 'Draft' && 
                                 c.Exclude_from_Status_Updates__c == false);
        System.debug('  Should activate? ' + shouldActivate);
        System.debug('  ---');
    }
    
    // Check assets on these contracts
    if (!accountContracts.isEmpty()) {
        Set<Id> contractIds = new Set<Id>();
        for (Contract c : accountContracts) {
            contractIds.add(c.Id);
        }
        
        List<Asset> contractAssets = [
            SELECT Id, Name, Status, Start_Date__c, End_Date__c, ARR__c, Price, Quantity, 
                   Product2.Family, Contract__c
            FROM Asset 
            WHERE Contract__c IN :contractIds
        ];
        
        System.debug('=== ASSETS ON TEST CONTRACTS ===');
        System.debug('Asset count: ' + contractAssets.size());
        for (Asset a : contractAssets) {
            System.debug('Asset: ' + a.Id + ', Status: ' + a.Status + ', Contract: ' + a.Contract__c);
            System.debug('  Start: ' + a.Start_Date__c + ', End: ' + a.End_Date__c);
            System.debug('  ARR: ' + a.ARR__c + ', Price: ' + a.Price + ', Quantity: ' + a.Quantity);
            System.debug('  Product Family: ' + a.Product2?.Family);
        }
    }
}
