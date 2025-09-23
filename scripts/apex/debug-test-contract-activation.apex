// Debug script to understand why the test contract isn't being activated

// First, let's see what contracts exist in the org
List<Contract> allContracts = [
    SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c, AccountId, ContractTerm
    FROM Contract 
    WHERE Status = 'Draft' AND Exclude_from_Status_Updates__c = false
    ORDER BY CreatedDate DESC
    LIMIT 5
];

System.debug('=== ALL DRAFT CONTRACTS ===');
for (Contract c : allContracts) {
    System.debug('Contract: ' + c.Id + ', Status: ' + c.Status + ', StartDate: ' + c.StartDate + ', EndDate: ' + c.EndDate);
    System.debug('  Exclude_from_Status_Updates__c: ' + c.Exclude_from_Status_Updates__c);
    System.debug('  AccountId: ' + c.AccountId + ', ContractTerm: ' + c.ContractTerm);
}

if (!allContracts.isEmpty()) {
    Contract testContract = allContracts[0];
    
    // Check assets on this contract
    List<Asset> contractAssets = [
        SELECT Id, Name, Status, Start_Date__c, End_Date__c, ARR__c, Price, Quantity, 
               Product2.Family, Contract__c, AccountId
        FROM Asset 
        WHERE Contract__c = :testContract.Id
    ];
    
    System.debug('=== ASSETS ON CONTRACT ' + testContract.Id + ' ===');
    System.debug('Asset count: ' + contractAssets.size());
    for (Asset a : contractAssets) {
        System.debug('Asset: ' + a.Id + ', Status: ' + a.Status + ', Start: ' + a.Start_Date__c + ', End: ' + a.End_Date__c);
        System.debug('  ARR: ' + a.ARR__c + ', Price: ' + a.Price + ', Quantity: ' + a.Quantity);
        System.debug('  Product Family: ' + a.Product2?.Family + ', AccountId: ' + a.AccountId);
    }
    
    // Now let's see what the ContractRevenueBatch would do
    System.debug('=== BATCH LOGIC SIMULATION ===');
    System.debug('Today: ' + Date.today());
    System.debug('Contract StartDate <= Today? ' + (testContract.StartDate <= Date.today()));
    System.debug('Contract EndDate >= Today? ' + (testContract.EndDate >= Date.today()));
    System.debug('Contract Status = Draft? ' + (testContract.Status == 'Draft'));
    System.debug('Exclude_from_Status_Updates__c = false? ' + (testContract.Exclude_from_Status_Updates__c == false));
    
    Boolean shouldActivate = (testContract.StartDate <= Date.today() && 
                             testContract.EndDate >= Date.today() && 
                             testContract.Status == 'Draft' && 
                             testContract.Exclude_from_Status_Updates__c == false);
    System.debug('Should activate? ' + shouldActivate);
}