// Set up a test scheduled job to validate AsyncException fix in true scheduled context
System.debug('=== SETTING UP TEST SCHEDULED JOB ===');

// First, check if there are any existing scheduled jobs for RevenueAutomationBatchManager
List<CronTrigger> existingJobs = [
    SELECT Id, CronJobDetail.Name, CronExpression, State, NextFireTime
    FROM CronTrigger 
    WHERE CronJobDetail.JobType = '7'
    AND CronJobDetail.Name LIKE '%Revenue%'
];

System.debug('Found ' + existingJobs.size() + ' existing revenue automation jobs:');
for (CronTrigger job : existingJobs) {
    System.debug('  ' + job.CronJobDetail.Name + ' (' + job.Id + ') - State: ' + job.State);
    System.debug('    Next Fire: ' + job.NextFireTime);
}

// Delete any existing test jobs to avoid conflicts
for (CronTrigger job : existingJobs) {
    if (job.CronJobDetail.Name.contains('TEST') || job.CronJobDetail.Name.contains('Test')) {
        System.debug('Deleting existing test job: ' + job.CronJobDetail.Name);
        System.abortJob(job.Id);
    }
}

// Schedule a test job to run in 2 minutes from now
DateTime now = DateTime.now();
DateTime testTime = now.addMinutes(2);

// Create cron expression for 2 minutes from now
String cronExp = testTime.second() + ' ' + testTime.minute() + ' ' + testTime.hour() + ' ' + 
                 testTime.day() + ' ' + testTime.month() + ' ? ' + testTime.year();

System.debug('\n--- Scheduling Test Job ---');
System.debug('Current Time: ' + now.format('yyyy-MM-dd HH:mm:ss'));
System.debug('Test Job Time: ' + testTime.format('yyyy-MM-dd HH:mm:ss'));
System.debug('Cron Expression: ' + cronExp);

// Schedule the test job
String jobId = System.schedule('TEST Revenue Automation - AsyncException Validation', 
                              cronExp, 
                              new RevenueAutomationBatchManager());

System.debug('✅ Test scheduled job created: ' + jobId);

// Verify the job was scheduled
CronTrigger scheduledJob = [
    SELECT Id, CronJobDetail.Name, CronExpression, State, NextFireTime, CreatedDate
    FROM CronTrigger 
    WHERE Id = :jobId
];

System.debug('\n--- Scheduled Job Details ---');
System.debug('Job ID: ' + scheduledJob.Id);
System.debug('Job Name: ' + scheduledJob.CronJobDetail.Name);
System.debug('Cron Expression: ' + scheduledJob.CronExpression);
System.debug('State: ' + scheduledJob.State);
System.debug('Next Fire Time: ' + scheduledJob.NextFireTime);
System.debug('Created: ' + scheduledJob.CreatedDate);

System.debug('\n🎯 TEST SCHEDULED JOB SETUP COMPLETE');
System.debug('');
System.debug('⏰ The job will execute in ~2 minutes in TRUE SCHEDULED CONTEXT');
System.debug('');
System.debug('This will test:');
System.debug('  ✅ AsyncException fix in ContractTriggerHandler');
System.debug('  ✅ Context-aware async method selection');
System.debug('  ✅ Scheduled batch execution without silent failures');
System.debug('  ✅ Complete revenue automation chain in scheduled context');
System.debug('');
System.debug('Monitor with: AsyncApexJob and Batch_Execution_Log__c queries');
System.debug('Expected: All batches complete successfully with no AsyncException errors');

System.debug('\n=== TEST SCHEDULED JOB READY ===');
