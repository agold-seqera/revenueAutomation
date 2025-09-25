// Check Current Scheduled Jobs Status
// Date: September 25, 2025

// Check all active cron jobs
List<CronTrigger> cronJobs = [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, 
                             CronExpression, TimesTriggered, NextFireTime, PreviousFireTime, State
                             FROM CronTrigger 
                             WHERE CronJobDetail.Name LIKE '%Revenue%' 
                             ORDER BY NextFireTime ASC];

System.debug('=== CURRENT REVENUE AUTOMATION CRON JOBS ===');
System.debug('Total Jobs Found: ' + cronJobs.size());

for (CronTrigger job : cronJobs) {
    System.debug('---');
    System.debug('Job Name: ' + job.CronJobDetail.Name);
    System.debug('Job ID: ' + job.Id);
    System.debug('State: ' + job.State);
    System.debug('Cron Expression: ' + job.CronExpression);
    System.debug('Next Fire Time: ' + job.NextFireTime);
    System.debug('Previous Fire Time: ' + job.PreviousFireTime);
    System.debug('Times Triggered: ' + job.TimesTriggered);
}

// Check recent async apex jobs (batch executions)
List<AsyncApexJob> recentBatches = [SELECT Id, JobType, Status, JobItemsProcessed, TotalJobItems,
                                   NumberOfErrors, CreatedDate, CompletedDate, CreatedBy.Name,
                                   ApexClass.Name, ExtendedStatus
                                   FROM AsyncApexJob 
                                   WHERE CreatedDate = TODAY 
                                   AND ApexClass.Name IN ('AssetStatusBatch', 'ContractRevenueBatch', 'AccountRollupBatch', 'RevenueAutomationBatchManager')
                                   ORDER BY CreatedDate DESC];

System.debug('=== TODAY\'S BATCH EXECUTIONS ===');
System.debug('Total Batches Found: ' + recentBatches.size());

for (AsyncApexJob batch : recentBatches) {
    System.debug('---');
    System.debug('Class: ' + batch.ApexClass.Name);
    System.debug('Status: ' + batch.Status);
    System.debug('Created: ' + batch.CreatedDate);
    System.debug('Completed: ' + batch.CompletedDate);
    System.debug('Progress: ' + batch.JobItemsProcessed + '/' + batch.TotalJobItems);
    System.debug('Errors: ' + batch.NumberOfErrors);
    System.debug('Created By: ' + batch.CreatedBy.Name);
}
