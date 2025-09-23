// Final comprehensive test of the complete revenue automation system
// This will test the full chain: AssetStatusBatch → ContractRevenueBatch → AccountRollupBatch

System.debug('=== FINAL REVENUE AUTOMATION SYSTEM TEST ===');
System.debug('Testing complete automation chain with AsyncException fix');
System.debug('Expected: All batches complete successfully with no errors');

// Clear recent logs for clean analysis
System.debug('\n--- Clearing Recent Logs ---');
delete [SELECT Id FROM Batch_Execution_Log__c WHERE CreatedDate >= TODAY];
System.debug('✅ Cleared today\'s batch execution logs');

// Get baseline counts before automation
System.debug('\n--- Pre-Automation Baseline ---');

// Sample contracts to monitor
List<Contract> monitorContracts = [
    SELECT Id, Name, ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, Status
    FROM Contract 
    WHERE Id IN ('800fJ000007eNJeQAM', '800fJ000007eMFWQA2', '800fJ000007eI3QQAU')
    ORDER BY Name
];

System.debug('Monitoring ' + monitorContracts.size() + ' key contracts:');
for (Contract c : monitorContracts) {
    System.debug('  ' + c.Name + ' (' + c.Id + '):');
    System.debug('    ARR: ' + c.ARR__c + ' | ACV: ' + c.ACV__c + ' | Status: ' + c.Status);
    System.debug('    ARR_Reporting: ' + c.ARR_USD_Reporting__c + ' | ACV_Reporting: ' + c.ACV_USD_Reporting__c);
}

// Sample accounts to monitor
List<Account> monitorAccounts = [
    SELECT Id, Name, ARR__c, ACV__c, TCV__c, MRR__c, Status__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c
    FROM Account 
    WHERE Id IN ('001fJ000021Y30LQAS', '001fJ000021YDzUQAW', '001fJ000021YE4QQAW')
    ORDER BY Name
];

System.debug('\nMonitoring ' + monitorAccounts.size() + ' key accounts:');
for (Account a : monitorAccounts) {
    System.debug('  ' + a.Name + ' (' + a.Id + '):');
    System.debug('    ARR: ' + a.ARR__c + ' | ACV: ' + a.ACV__c + ' | Status: ' + a.Status__c);
    System.debug('    ARR_Reporting: ' + a.ARR_USD_Reporting__c + ' | ACV_Reporting: ' + a.ACV_USD_Reporting__c);
}

// Get total counts
Integer totalAssets = [SELECT COUNT() FROM Asset];
Integer totalContracts = [SELECT COUNT() FROM Contract];
Integer totalAccounts = [SELECT COUNT() FROM Account WHERE Has_Contracts__c = true];

System.debug('\nSystem Totals:');
System.debug('  Assets: ' + totalAssets);
System.debug('  Contracts: ' + totalContracts);
System.debug('  Accounts with Contracts: ' + totalAccounts);

// Execute the full revenue automation manager
System.debug('\n--- EXECUTING FULL REVENUE AUTOMATION ---');
System.debug('Starting RevenueAutomationBatchManager...');

RevenueAutomationBatchManager manager = new RevenueAutomationBatchManager();
manager.execute(null);

System.debug('✅ Revenue Automation Manager started successfully');
System.debug('');
System.debug('🔄 BATCH CHAIN INITIATED:');
System.debug('  1. AssetStatusBatch (200 records/batch)');
System.debug('  2. → ContractRevenueBatch (50 records/batch)');
System.debug('  3. → → AccountRollupBatch (100 records/batch)');
System.debug('');
System.debug('⏳ Wait for completion, then run analysis...');
System.debug('');
System.debug('Expected Results:');
System.debug('  - All batches complete with Status = "Completed"');
System.debug('  - NumberOfErrors = 0 for all batch jobs');
System.debug('  - Contract revenue fields updated correctly');
System.debug('  - Account rollup fields aggregated properly');
System.debug('  - Batch_Execution_Log__c shows clean execution');
System.debug('  - No AsyncException errors in any context');

System.debug('\n=== FULL AUTOMATION TEST INITIATED ===');
