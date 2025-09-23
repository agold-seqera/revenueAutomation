// Monitor the scheduled test job execution
System.debug('=== MONITORING SCHEDULED TEST JOB ===');

// Check scheduled job status
List<CronTrigger> testJobs = [
    SELECT Id, CronJobDetail.Name, State, NextFireTime, PreviousFireTime
    FROM CronTrigger 
    WHERE CronJobDetail.Name = 'TEST Revenue Automation - AsyncException Validation'
];

if (testJobs.isEmpty()) {
    System.debug('❌ No test job found!');
    return;
}

CronTrigger testJob = testJobs[0];
System.debug('📋 Test Job Status:');
System.debug('  Job ID: ' + testJob.Id);
System.debug('  State: ' + testJob.State);
System.debug('  Next Fire: ' + testJob.NextFireTime);
System.debug('  Previous Fire: ' + testJob.PreviousFireTime);

// Check for recent batch executions (last 5 minutes)
DateTime recentTime = DateTime.now().addMinutes(-5);
List<AsyncApexJob> recentBatches = [
    SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, 
           CreatedDate, CompletedDate, ApexClass.Name
    FROM AsyncApexJob 
    WHERE CreatedDate >= :recentTime
    AND ApexClass.Name IN ('AssetStatusBatch', 'ContractRevenueBatch', 'AccountRollupBatch')
    ORDER BY CreatedDate DESC
];

System.debug('\n📊 Recent Batch Executions (last 5 minutes):');
System.debug('Found ' + recentBatches.size() + ' recent batch jobs:');

for (AsyncApexJob job : recentBatches) {
    System.debug('  ' + job.ApexClass.Name + ' (' + job.Id + '):');
    System.debug('    Status: ' + job.Status + ' | Processed: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
    System.debug('    Errors: ' + job.NumberOfErrors + ' | Created: ' + job.CreatedDate);
    if (job.CompletedDate != null) {
        System.debug('    Completed: ' + job.CompletedDate);
    }
}

// Check batch execution logs for scheduled context
List<Batch_Execution_Log__c> scheduledLogs = [
    SELECT Id, Execution_Context__c, Processing_Stage__c, Contract_ID__c, 
           Error_Message__c, CreatedDate
    FROM Batch_Execution_Log__c 
    WHERE CreatedDate >= :recentTime
    AND Execution_Context__c = 'SCHEDULED'
    ORDER BY CreatedDate DESC
    LIMIT 10
];

System.debug('\n📝 Scheduled Context Logs (last 5 minutes):');
System.debug('Found ' + scheduledLogs.size() + ' scheduled execution logs:');

for (Batch_Execution_Log__c log : scheduledLogs) {
    System.debug('  ' + log.Processing_Stage__c + ' - Contract: ' + log.Contract_ID__c);
    System.debug('    Context: ' + log.Execution_Context__c + ' | Created: ' + log.CreatedDate);
    if (log.Error_Message__c != null) {
        System.debug('    ❌ ERROR: ' + log.Error_Message__c);
    } else {
        System.debug('    ✅ No errors');
    }
}

// Summary
System.debug('\n🎯 MONITORING SUMMARY:');
if (testJob.PreviousFireTime != null) {
    System.debug('✅ Test job has executed at: ' + testJob.PreviousFireTime);
    
    if (recentBatches.size() > 0) {
        Integer completedBatches = 0;
        Integer errorBatches = 0;
        
        for (AsyncApexJob job : recentBatches) {
            if (job.Status == 'Completed') completedBatches++;
            if (job.NumberOfErrors > 0) errorBatches++;
        }
        
        System.debug('📊 Batch Results: ' + completedBatches + ' completed, ' + errorBatches + ' with errors');
        
        if (errorBatches == 0 && scheduledLogs.size() > 0) {
            System.debug('🎉 SUCCESS: Scheduled execution completed without AsyncException!');
        } else if (errorBatches > 0) {
            System.debug('⚠️  Some batches had errors - check logs');
        }
    } else {
        System.debug('⏳ Batches may still be running or not yet started');
    }
} else {
    System.debug('⏳ Test job has not executed yet');
    System.debug('   Current time: ' + DateTime.now());
    System.debug('   Next fire: ' + testJob.NextFireTime);
}

System.debug('\n=== MONITORING COMPLETE ===');
