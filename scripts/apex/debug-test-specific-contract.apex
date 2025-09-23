// Debug script to understand the specific test contract issue

// Let's see all contracts in the org with their creation details
List<Contract> allContracts = [
    SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c, 
           AccountId, Account.Name, ContractTerm, CreatedDate, CreatedBy.Name
    FROM Contract 
    ORDER BY CreatedDate DESC
    LIMIT 10
];

System.debug('=== ALL CONTRACTS (RECENT FIRST) ===');
for (Contract c : allContracts) {
    System.debug('Contract: ' + c.Id + ', Status: ' + c.Status);
    System.debug('  StartDate: ' + c.StartDate + ', EndDate: ' + c.EndDate);
    System.debug('  Account: ' + c.Account.Name + ' (' + c.AccountId + ')');
    System.debug('  Created: ' + c.CreatedDate + ' by ' + c.CreatedBy.Name);
    System.debug('  Exclude_from_Status_Updates__c: ' + c.Exclude_from_Status_Updates__c);
    System.debug('  ---');
}

// Now let's specifically look for Draft contracts that would match the test query
List<Contract> draftContracts = [
    SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c, 
           AccountId, Account.Name, CreatedDate
    FROM Contract 
    WHERE Status = 'Draft' AND Exclude_from_Status_Updates__c = false
    ORDER BY CreatedDate DESC
    LIMIT 5
];

System.debug('=== DRAFT CONTRACTS MATCHING TEST QUERY ===');
for (Contract c : draftContracts) {
    System.debug('Contract: ' + c.Id + ', Account: ' + c.Account.Name);
    System.debug('  StartDate: ' + c.StartDate + ', EndDate: ' + c.EndDate);
    System.debug('  Created: ' + c.CreatedDate);
    
    // Check activation criteria
    Boolean shouldActivate = (c.StartDate <= Date.today() && 
                             c.EndDate >= Date.today() && 
                             c.Status == 'Draft' && 
                             c.Exclude_from_Status_Updates__c == false);
    System.debug('  Should activate? ' + shouldActivate);
    System.debug('  ---');
}
