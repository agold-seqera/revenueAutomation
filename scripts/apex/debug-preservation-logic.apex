// DEBUG: Check why preservation logic is failing in simplified AccountRollupBatch

System.debug('=== DEBUGGING PRESERVATION LOGIC FAILURE ===');

// Test with CDC account (Churned status)
String cdcAccountId = '001fJ000021YDQmQAO';

AccountRollupBatch batch = new AccountRollupBatch();
List<Account> accounts = [
    SELECT Id, Status__c, Type, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
           (SELECT Id, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
                   ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                   StartDate, EndDate, Status, Exclude_from_Status_Updates__c,
                   Renewal_Opportunity__c,
                   Renewal_Opportunity__r.Id, Renewal_Opportunity__r.StageName, 
                   Renewal_Opportunity__r.IsClosed, Renewal_Opportunity__r.Deal_Type__c
            FROM Contracts)
    FROM Account 
    WHERE Id = :cdcAccountId AND Has_Contracts__c = true
];

Account testAccount = accounts[0];

System.debug('BEFORE PROCESSING:');
System.debug('Account: ' + testAccount.Id + ' (' + testAccount.Status__c + ')');
System.debug('ARR__c: ' + testAccount.ARR__c + ' | ARR_USD__c: ' + testAccount.ARR_USD__c + ' | ARR_USD_Reporting__c: ' + testAccount.ARR_USD_Reporting__c);

// Check contract details
System.debug('CONTRACTS:');
for (Contract contract : testAccount.Contracts) {
    System.debug('Contract ' + contract.Id + ': StartDate=' + contract.StartDate + ', EndDate=' + contract.EndDate + ', Status=' + contract.Status);
    System.debug('  ARR__c=' + contract.ARR__c + ', ARR_USD__c=' + contract.ARR_USD__c);
}

// Now process through batch
batch.execute(null, accounts);

// Check results
Account afterAccount = [
    SELECT Id, Status__c, ARR__c, ARR_USD__c, ARR_USD_Reporting__c
    FROM Account 
    WHERE Id = :cdcAccountId
];

System.debug('AFTER PROCESSING:');
System.debug('Account: ' + afterAccount.Id + ' (' + afterAccount.Status__c + ')');
System.debug('ARR__c: ' + afterAccount.ARR__c + ' | ARR_USD__c: ' + afterAccount.ARR_USD__c + ' | ARR_USD_Reporting__c: ' + afterAccount.ARR_USD_Reporting__c);

System.debug('=== PRESERVATION LOGIC DEBUG COMPLETE ===');
