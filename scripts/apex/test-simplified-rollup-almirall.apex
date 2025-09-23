// TEST: Run AccountRollupBatch specifically for Almirall account to verify the simplified logic fix

System.debug('=== TESTING SIMPLIFIED ACCOUNTROLLUPBATCH FOR ALMIRALL ===');

String almirallAccountId = '001fJ000021YCbNQAW';

// Step 1: Check current state
Account beforeAccount = [
    SELECT Id, Name, Status__c, ARR__c, ARR_USD__c, ARR_USD_Reporting__c
    FROM Account 
    WHERE Id = :almirallAccountId
];

System.debug('BEFORE - Account: ' + beforeAccount.Name + ' (' + beforeAccount.Status__c + ')');
System.debug('BEFORE - ARR__c: ' + beforeAccount.ARR__c + ' | ARR_USD__c: ' + beforeAccount.ARR_USD__c + ' | ARR_USD_Reporting__c: ' + beforeAccount.ARR_USD_Reporting__c);

// Step 2: Run AccountRollupBatch for this specific account
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
    WHERE Id = :almirallAccountId AND Has_Contracts__c = true
];

batch.execute(null, accounts);

// Step 3: Check updated state  
Account afterAccount = [
    SELECT Id, Name, Status__c, ARR__c, ARR_USD__c, ARR_USD_Reporting__c
    FROM Account 
    WHERE Id = :almirallAccountId
];

System.debug('AFTER - Account: ' + afterAccount.Name + ' (' + afterAccount.Status__c + ')');
System.debug('AFTER - ARR__c: ' + afterAccount.ARR__c + ' | ARR_USD__c: ' + afterAccount.ARR_USD__c + ' | ARR_USD_Reporting__c: ' + afterAccount.ARR_USD_Reporting__c);

// Step 4: Verify the fix
System.debug('=== EXPECTED vs ACTUAL ===');
System.debug('Expected ARR_USD__c: ~$57,095.36 (from active contract)');
System.debug('Actual ARR_USD__c: ' + afterAccount.ARR_USD__c);

if (afterAccount.ARR_USD__c.contains('57,095') || afterAccount.ARR_USD__c.contains('57095')) {
    System.debug('✅ SUCCESS: Simplified logic working correctly!');
} else {
    System.debug('❌ STILL BROKEN: USD calculation still incorrect');
}

System.debug('=== TEST COMPLETE ===');
