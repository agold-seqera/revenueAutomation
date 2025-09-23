// FINAL BATCH: Propagate all newly corrected contract USD values to accounts

System.debug('=== FINAL BATCH TO PROPAGATE CORRECTED USD VALUES ===');

// Check current state before final batch
List<Account> accountsBefore = [
    SELECT Id, Name, Status__c, ARR__c, ARR_USD__c, ARR_USD_Reporting__c
    FROM Account 
    WHERE Status__c IN ('Active (Churning)', 'Churned') AND ARR__c > 0 
    AND (ARR_USD__c = '$0' OR ARR_USD__c = null OR ARR_USD_Reporting__c = 0)
    LIMIT 10
];

System.debug('ACCOUNTS STILL NEEDING USD FIELD UPDATES:');
for (Account acc : accountsBefore) {
    System.debug('Account ' + acc.Name + ' (' + acc.Status__c + '): ARR=' + acc.ARR__c + ', USD=' + acc.ARR_USD__c + ', Reporting=' + acc.ARR_USD_Reporting__c);
}

System.debug('Found ' + accountsBefore.size() + ' accounts still needing USD field updates');

// Execute final batch manager to propagate corrected contract values
RevenueAutomationBatchManager batchManager = new RevenueAutomationBatchManager();
batchManager.execute(null);

System.debug('✓ Final RevenueAutomationBatchManager executed');
System.debug('✓ This should propagate all corrected contract USD values to accounts');
System.debug('✓ AccountRollupBatch will aggregate from newly corrected contracts');

System.debug('=== FINAL BATCH PROPAGATION INITIATED ===');
