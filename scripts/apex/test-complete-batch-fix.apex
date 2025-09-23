// TEST: Run complete RevenueAutomationBatchManager to verify the full fix

System.debug('=== TESTING COMPLETE BATCH MANAGER FIX ===');

// Check specific accounts before running batch
List<Account> accountsBefore = [
    SELECT Id, Name, Status__c, ARR__c, ARR_USD__c, ARR_USD_Reporting__c
    FROM Account 
    WHERE Id IN ('001fJ000021YDQmQAO', '001fJ000021Y30LQAS')
];

System.debug('BEFORE BATCH MANAGER:');
for (Account acc : accountsBefore) {
    System.debug('Account ' + acc.Name + ' (' + acc.Status__c + '): ARR=' + acc.ARR__c + ', USD=' + acc.ARR_USD__c + ', Reporting=' + acc.ARR_USD_Reporting__c);
}

// Run the complete batch manager
RevenueAutomationBatchManager batchManager = new RevenueAutomationBatchManager();
batchManager.execute(null);

System.debug('✓ RevenueAutomationBatchManager executed');
System.debug('✓ This should fix contracts AND roll up to accounts');

System.debug('=== COMPLETE BATCH TEST INITIATED ===');
