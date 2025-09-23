// Debug the test setup to understand why the contract is already Activated
List<Contract> testContracts = [SELECT Id, Status, StartDate, EndDate, ContractNumber, CreatedDate
                               FROM Contract 
                               WHERE ContractNumber LIKE '00%' 
                               ORDER BY CreatedDate DESC 
                               LIMIT 5];

System.debug('Recent test contracts:');
for (Contract c : testContracts) {
    System.debug('Contract ' + c.ContractNumber + ' (' + c.Id + '): Status=' + c.Status + 
                ', StartDate=' + c.StartDate + ', EndDate=' + c.EndDate + ', Created=' + c.CreatedDate);
}

// Check if there are assets on the most recent contract
Contract latestContract = testContracts[0];
List<Asset> assets = [SELECT Id, Name, Status, Start_Date__c, End_Date__c, ARR__c, Price, Quantity
                     FROM Asset 
                     WHERE Contract__c = :latestContract.Id];

System.debug('Assets on latest contract (' + latestContract.Id + '):');
for (Asset a : assets) {
    System.debug('Asset ' + a.Name + ': Status=' + a.Status + ', ARR=' + a.ARR__c + 
                ', Price=' + a.Price + ', Qty=' + a.Quantity);
}
