// Schedule RevenueAutomationBatchManager to run at midnight for real-world validation
// This will test if the batch logic works correctly in production vs test context

// First, delete any existing scheduled jobs to avoid conflicts
List<CronTrigger> existingJobs = [
    SELECT Id, CronJobDetail.Name, State, NextFireTime
    FROM CronTrigger 
    WHERE CronJobDetail.Name LIKE '%RevenueAutomationBatchManager%'
    AND State IN ('WAITING', 'ACQUIRED', 'EXECUTING')
];

System.debug('Found ' + existingJobs.size() + ' existing RevenueAutomationBatchManager jobs');
for (CronTrigger job : existingJobs) {
    System.debug('Deleting job: ' + job.CronJobDetail.Name + ' (State: ' + job.State + ')');
    System.abortJob(job.Id);
}

// Schedule new job to run at midnight (00:00) tonight
// Cron expression: "0 0 0 * * ?" = At 00:00:00am every day
String cronExpression = '0 0 0 * * ?';
String jobName = 'RevenueAutomationBatchManager_MidnightTest_' + DateTime.now().format('MMdd');

RevenueAutomationBatchManager batchManager = new RevenueAutomationBatchManager();
String jobId = System.schedule(jobName, cronExpression, batchManager);

System.debug('✅ SUCCESS: Scheduled ' + jobName + ' to run at midnight');
System.debug('Job ID: ' + jobId);

// Query to confirm the job was scheduled
CronTrigger scheduledJob = [
    SELECT Id, CronJobDetail.Name, State, NextFireTime, CronExpression
    FROM CronTrigger 
    WHERE Id = :jobId
];

System.debug('📅 Next Fire Time: ' + scheduledJob.NextFireTime);
System.debug('🔄 Cron Expression: ' + scheduledJob.CronExpression);
System.debug('📊 Job State: ' + scheduledJob.State);

System.debug('');
System.debug('🌙 MIDNIGHT TEST SCHEDULED SUCCESSFULLY!');
System.debug('The batch will run at midnight to test if the logic works correctly');
System.debug('in production context vs the test context issues we encountered.');
System.debug('');
System.debug('Check results tomorrow morning by querying:');
System.debug('- Batch_Execution_Log__c records for execution details');
System.debug('- Contract records for status and revenue updates');
System.debug('- AsyncApexJob records for batch completion status');
