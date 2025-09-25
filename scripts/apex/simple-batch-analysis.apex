// Simple Analysis of Today's Batch Modifications
// Date: September 25, 2025

System.debug('=== SIMPLE BATCH MODIFICATION ANALYSIS ===');

// Check contracts modified today
List<Contract> contracts = [
    SELECT Id, ContractNumber, Status, ARR__c, ARR_USD__c, 
           Account.Name, LastModifiedDate, LastModifiedBy.Name
    FROM Contract 
    WHERE LastModifiedDate = TODAY 
    AND LastModifiedBy.Name = 'Sys Admin'
    LIMIT 50
];

System.debug('Contracts modified today: ' + contracts.size());

// Check accounts modified today  
List<Account> accounts = [
    SELECT Id, Name, Status__c, ARR__c, ARR_USD__c,
           LastModifiedDate, LastModifiedBy.Name
    FROM Account 
    WHERE LastModifiedDate = TODAY 
    AND LastModifiedBy.Name = 'Sys Admin'
    LIMIT 50
];

System.debug('Accounts modified today: ' + accounts.size());

// Check assets modified today
List<Asset> assets = [
    SELECT Id, Name, Status, LastModifiedDate, LastModifiedBy.Name
    FROM Asset 
    WHERE LastModifiedDate = TODAY 
    AND LastModifiedBy.Name = 'Sys Admin'
    LIMIT 50
];

System.debug('Assets modified today: ' + assets.size());

// Sample contract details
if (contracts.size() > 0) {
    System.debug('');
    System.debug('Sample Contract Details:');
    for (Integer i = 0; i < Math.min(5, contracts.size()); i++) {
        Contract c = contracts[i];
        System.debug('Contract ' + c.ContractNumber + ' - Status: ' + c.Status);
        System.debug('  ARR: ' + c.ARR__c + ' | ARR_USD: ' + c.ARR_USD__c);
        System.debug('  Account: ' + c.Account.Name);
    }
}

System.debug('');
System.debug('Analysis complete at: ' + System.now());
