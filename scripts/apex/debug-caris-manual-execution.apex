// Manual debugging execution for Caris Life Sciences account issue
// Account ID: 001fJ000021YBjKQAW
// This script will manually execute AccountRollupBatch logic with enhanced debugging

System.debug('=== STARTING MANUAL DEBUG EXECUTION FOR CARIS ACCOUNT ===');

// Account to debug
String targetAccountId = '001fJ000021YBjKQAW';

// Query the account exactly as AccountRollupBatch does
List<Account> accounts = [
    SELECT Id, Name, Status__c, Type, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
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
    WHERE Id = :targetAccountId
];

if (accounts.isEmpty()) {
    System.debug('❌ Account not found: ' + targetAccountId);
    return;
}

Account account = accounts[0];
System.debug('🎯 Found account: ' + account.Name + ' (Status: ' + account.Status__c + ')');
System.debug('🎯 Contracts count: ' + account.Contracts.size());

// Log the contract details
for (Contract contract : account.Contracts) {
    System.debug('📋 Contract ' + contract.Id + ':');
    System.debug('   Status: ' + contract.Status);
    System.debug('   StartDate: ' + contract.StartDate + ', EndDate: ' + contract.EndDate);
    System.debug('   Exclude_from_Status_Updates__c: ' + contract.Exclude_from_Status_Updates__c);
    System.debug('   Renewal_Opportunity__c: ' + contract.Renewal_Opportunity__c);
    
    if (contract.Renewal_Opportunity__r != null) {
        System.debug('   Renewal Opportunity:');
        System.debug('     Id: ' + contract.Renewal_Opportunity__r.Id);
        System.debug('     StageName: ' + contract.Renewal_Opportunity__r.StageName);
        System.debug('     IsClosed: ' + contract.Renewal_Opportunity__r.IsClosed);
        System.debug('     Deal_Type__c: ' + contract.Renewal_Opportunity__r.Deal_Type__c);
    }
}

// Manually create a batch execution log entry
Batch_Execution_Log__c debugLog = new Batch_Execution_Log__c(
    Batch_Job_ID__c = 'MANUAL_DEBUG_' + DateTime.now().getTime(),
    Execution_Context__c = 'MANUAL',
    Processing_Stage__c = 'STARTED',
    Contract_ID__c = targetAccountId,
    Error_Message__c = 'Manual debug execution started for Caris investigation'
);

try {
    insert debugLog;
    System.debug('✅ Debug log created: ' + debugLog.Id);
} catch (Exception e) {
    System.debug('❌ Failed to create debug log: ' + e.getMessage());
}

// Now execute the actual batch on this account
System.debug('=== EXECUTING ACCOUNTROLLUPBATCH ON TARGET ACCOUNT ===');

try {
    // Create and execute the batch with scope limited to this account
    AccountRollupBatch batch = new AccountRollupBatch();
    
    // Execute it manually (this will process all accounts, but we'll track our target)
    Database.executeBatch(batch, 100);
    
    System.debug('✅ AccountRollupBatch started successfully');
    
    // Update debug log
    if (debugLog.Id != null) {
        debugLog.Processing_Stage__c = 'BATCH_STARTED';
        debugLog.Error_Message__c = 'AccountRollupBatch execution initiated';
        update debugLog;
    }
    
} catch (Exception e) {
    System.debug('❌ Failed to execute batch: ' + e.getMessage());
    
    // Update debug log with error
    if (debugLog.Id != null) {
        debugLog.Processing_Stage__c = 'FAILED';
        debugLog.Error_Message__c = 'Batch execution failed: ' + e.getMessage();
        update debugLog;
    }
}

System.debug('=== MANUAL DEBUG EXECUTION COMPLETE ===');
System.debug('📝 Monitor the batch execution and check Batch_Execution_Log__c for results');
System.debug('📝 Next: Query account status in a few minutes to see if it changed');

// Instructions for follow-up
System.debug('🔍 FOLLOW-UP QUERIES TO RUN:');
System.debug('1. Check batch status: SELECT Id, Status, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE ApexClass.Name = \'AccountRollupBatch\' AND CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 1');
System.debug('2. Check account status: SELECT Id, Name, Status__c, LastModifiedDate, LastModifiedBy.Name FROM Account WHERE Id = \'' + targetAccountId + '\'');
System.debug('3. Check debug logs: SELECT Id, Processing_Stage__c, Error_Message__c, CreatedDate FROM Batch_Execution_Log__c WHERE Contract_ID__c = \'' + targetAccountId + '\' ORDER BY CreatedDate DESC LIMIT 5');
