// Run a limited batch to test reporting field population
System.debug('=== Running Limited Batch Test for Reporting Fields ===');

// Get a few contracts to test
List<Contract> targetContracts = [
    SELECT Id, Name, AccountId, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
           ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, 
           MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c,
           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                   Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Status = 'Activated' 
    AND ARR__c > 0
    AND Id IN (SELECT Contract__c FROM Asset WHERE Exchange_Rate__c != null)
    LIMIT 5
];

System.debug('Found ' + targetContracts.size() + ' contracts to test');

// Show BEFORE state
for (Contract c : targetContracts) {
    System.debug('BEFORE - Contract: ' + c.Name + ' (ARR: ' + c.ARR__c + ', ARR_USD: ' + c.ARR_USD__c + ', ARR_Reporting: ' + c.ARR_USD_Reporting__c + ')');
}

// Run ContractRevenueBatch
System.debug('\n--- Running ContractRevenueBatch ---');
ContractRevenueBatch contractBatch = new ContractRevenueBatch();
contractBatch.execute(null, targetContracts);

// Check AFTER state for contracts
System.debug('\n--- Contract Results AFTER Batch ---');
List<Contract> updatedContracts = [
    SELECT Id, Name, ARR__c, ARR_USD__c, ARR_USD_Reporting__c, ACV_USD_Reporting__c, 
           TCV_USD_Reporting__c, MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c
    FROM Contract 
    WHERE Id IN :targetContracts
];

for (Contract c : updatedContracts) {
    System.debug('AFTER - Contract: ' + c.Name);
    System.debug('  ARR_USD__c (Text): ' + c.ARR_USD__c + ' → ARR_USD_Reporting__c (Number): ' + c.ARR_USD_Reporting__c);
    System.debug('  ACV_USD_Reporting__c: ' + c.ACV_USD_Reporting__c);
    System.debug('  TCV_USD_Reporting__c: ' + c.TCV_USD_Reporting__c);
    System.debug('  MRR_USD_Reporting__c: ' + c.MRR_USD_Reporting__c);
    
    Boolean hasReportingFields = c.ARR_USD_Reporting__c != null || c.ACV_USD_Reporting__c != null;
    System.debug('  ✅ Reporting Fields Populated: ' + hasReportingFields);
    System.debug('');
}

// Now test AccountRollupBatch with these accounts
System.debug('\n--- Running AccountRollupBatch ---');

// Get the accounts for these contracts
Set<Id> accountIds = new Set<Id>();
for (Contract c : targetContracts) {
    accountIds.add(c.AccountId);
}

List<Account> targetAccounts = [
    SELECT Id, Name, Has_Contracts__c, Status__c, ARR__c, ACV__c, TCV__c, MRR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
           (SELECT Id, ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
                   Status, StartDate, EndDate, Exclude_from_Status_Updates__c, Renewal_Opportunity__c,
                   Renewal_Opportunity__r.StageName, Renewal_Opportunity__r.Deal_Type__c, Renewal_Opportunity__r.IsClosed,
                   ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c
            FROM Contracts WHERE Exclude_from_Status_Updates__c = false)
    FROM Account 
    WHERE Id IN :accountIds
];

System.debug('Found ' + targetAccounts.size() + ' accounts to test');

// Show BEFORE state for accounts
for (Account a : targetAccounts) {
    System.debug('BEFORE - Account: ' + a.Name + ' (ARR: ' + a.ARR__c + ', ARR_USD: ' + a.ARR_USD__c + ', ARR_Reporting: ' + a.ARR_USD_Reporting__c + ')');
}

// Run AccountRollupBatch
AccountRollupBatch accountBatch = new AccountRollupBatch();
accountBatch.execute(null, targetAccounts);

// Check AFTER state for accounts
System.debug('\n--- Account Results AFTER Batch ---');
List<Account> updatedAccounts = [
    SELECT Id, Name, ARR__c, ARR_USD__c, ARR_USD_Reporting__c, ACV_USD_Reporting__c, 
           TCV_USD_Reporting__c, MRR_USD_Reporting__c
    FROM Account 
    WHERE Id IN :accountIds
];

for (Account a : updatedAccounts) {
    System.debug('AFTER - Account: ' + a.Name);
    System.debug('  ARR_USD__c (Text): ' + a.ARR_USD__c + ' → ARR_USD_Reporting__c (Number): ' + a.ARR_USD_Reporting__c);
    System.debug('  ACV_USD_Reporting__c: ' + a.ACV_USD_Reporting__c);
    System.debug('  TCV_USD_Reporting__c: ' + a.TCV_USD_Reporting__c);
    System.debug('  MRR_USD_Reporting__c: ' + a.MRR_USD_Reporting__c);
    
    Boolean hasReportingFields = a.ARR_USD_Reporting__c != null || a.ACV_USD_Reporting__c != null;
    System.debug('  ✅ Reporting Fields Populated: ' + hasReportingFields);
    System.debug('');
}

System.debug('=== Limited Batch Test Complete ===');
