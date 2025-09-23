// Verify the ContractTriggerHandler results after it fired
System.debug('=== VERIFYING CONTRACTTRIGGERHANDLER RESULTS ===');

// Check the contract again after trigger fired
Contract futureContract = [
    SELECT Id, Status, ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
           TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
           MRR__c, MRR_USD__c, MRR_USD_Reporting__c
    FROM Contract 
    WHERE Id = '800Pn00000r6GA9IAM'
];

System.debug('--- FUTURE CONTRACT AFTER TRIGGER ---');
System.debug('  ARR: ' + futureContract.ARR__c + ' | USD: ' + futureContract.ARR_USD__c + ' | Reporting: ' + futureContract.ARR_USD_Reporting__c);
System.debug('  ACV: ' + futureContract.ACV__c + ' | USD: ' + futureContract.ACV_USD__c + ' | Reporting: ' + futureContract.ACV_USD_Reporting__c);
System.debug('  TCV: ' + futureContract.TCV__c + ' | USD: ' + futureContract.TCV_USD__c + ' | Reporting: ' + futureContract.TCV_USD_Reporting__c);
System.debug('  MRR: ' + futureContract.MRR__c + ' | USD: ' + futureContract.MRR_USD__c + ' | Reporting: ' + futureContract.MRR_USD_Reporting__c);

// Check the account rollup as well
Account atlasAccount = [
    SELECT Id, Name, Status__c, ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
           TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
           MRR__c, MRR_USD__c, MRR_USD_Reporting__c
    FROM Account
    WHERE Name = 'Atlas Data Storage'
    LIMIT 1
];

System.debug('--- ATLAS DATA STORAGE ACCOUNT ROLLUP ---');
System.debug('  Status: ' + atlasAccount.Status__c);
System.debug('  ARR: ' + atlasAccount.ARR__c + ' | USD: ' + atlasAccount.ARR_USD__c + ' | Reporting: ' + atlasAccount.ARR_USD_Reporting__c);
System.debug('  ACV: ' + atlasAccount.ACV__c + ' | USD: ' + atlasAccount.ACV_USD__c + ' | Reporting: ' + atlasAccount.ACV_USD_Reporting__c);
System.debug('  TCV: ' + atlasAccount.TCV__c + ' | USD: ' + atlasAccount.TCV_USD__c + ' | Reporting: ' + atlasAccount.TCV_USD_Reporting__c);
System.debug('  MRR: ' + atlasAccount.MRR__c + ' | USD: ' + atlasAccount.MRR_USD__c + ' | Reporting: ' + atlasAccount.MRR_USD_Reporting__c);

System.debug('=== VERIFICATION COMPLETE ===');
