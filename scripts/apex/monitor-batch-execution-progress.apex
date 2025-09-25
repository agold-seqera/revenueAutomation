// Monitor Batch Execution Progress
// Date: September 25, 2025 - Full Validation Run

// Check batch execution progress for today's runs
List<AsyncApexJob> todaysBatches = [SELECT Id, JobType, Status, JobItemsProcessed, TotalJobItems,
                                   NumberOfErrors, CreatedDate, CompletedDate, CreatedBy.Name,
                                   ApexClass.Name, ExtendedStatus
                                   FROM AsyncApexJob 
                                   WHERE CreatedDate = TODAY 
                                   AND ApexClass.Name IN ('AssetStatusBatch', 'ContractRevenueBatch', 'AccountRollupBatch', 'RevenueAutomationBatchManager')
                                   ORDER BY CreatedDate DESC];

System.debug('=== BATCH EXECUTION MONITORING ===');
System.debug('Current Time: ' + System.now());
System.debug('Total Batches Today: ' + todaysBatches.size());
System.debug('');

for (AsyncApexJob batch : todaysBatches) {
    System.debug('🔍 Class: ' + batch.ApexClass.Name);
    System.debug('   Job ID: ' + batch.Id);
    System.debug('   Status: ' + batch.Status);
    System.debug('   Created: ' + batch.CreatedDate);
    
    if (batch.Status == 'Completed') {
        System.debug('   ✅ Completed: ' + batch.CompletedDate);
        Decimal duration = batch.CompletedDate.getTime() - batch.CreatedDate.getTime();
        System.debug('   ⏱️  Duration: ' + (duration/1000) + ' seconds');
    } else if (batch.Status == 'Processing') {
        System.debug('   🔄 Processing: ' + batch.JobItemsProcessed + '/' + batch.TotalJobItems + ' batches');
    } else {
        System.debug('   ⏳ Status: ' + batch.Status);
    }
    
    if (batch.NumberOfErrors > 0) {
        System.debug('   ❌ Errors: ' + batch.NumberOfErrors);
    }
    
    System.debug('   👤 Created By: ' + batch.CreatedBy.Name);
    System.debug('---');
}

// Check if our scheduled job has fired
List<CronTrigger> ourJob = [SELECT Id, CronJobDetail.Name, State, TimesTriggered, 
                           NextFireTime, PreviousFireTime
                           FROM CronTrigger 
                           WHERE CronJobDetail.Name = 'RevenueAutomationBatchManager_FullValidation_0925'];

if (!ourJob.isEmpty()) {
    CronTrigger job = ourJob[0];
    System.debug('🎯 SCHEDULED JOB STATUS:');
    System.debug('   Name: ' + job.CronJobDetail.Name);
    System.debug('   State: ' + job.State);
    System.debug('   Times Triggered: ' + job.TimesTriggered);
    System.debug('   Previous Fire: ' + job.PreviousFireTime);
    System.debug('   Next Fire: ' + job.NextFireTime);
}
