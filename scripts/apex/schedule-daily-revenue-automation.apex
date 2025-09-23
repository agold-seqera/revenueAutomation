// Schedule daily RevenueAutomationBatchManager for midnight EST (4 AM UTC)
System.debug('=== SCHEDULING DAILY REVENUE AUTOMATION ===');

// Clear any existing scheduled jobs with similar names first
List<CronTrigger> existingJobs = [
    SELECT Id, CronJobDetail.Name, State, NextFireTime
    FROM CronTrigger 
    WHERE CronJobDetail.Name LIKE '%RevenueAutomationBatchManager%'
    AND State != 'DELETED'
];

System.debug('Found ' + existingJobs.size() + ' existing revenue automation jobs');

for (CronTrigger job : existingJobs) {
    System.debug('Existing Job: ' + job.CronJobDetail.Name + ' (' + job.Id + ') - State: ' + job.State);
    System.debug('  Next Fire Time: ' + job.NextFireTime);
    
    // Abort existing jobs to prevent conflicts
    try {
        System.abortJob(job.Id);
        System.debug('  ✅ Aborted existing job: ' + job.Id);
    } catch (Exception e) {
        System.debug('  ⚠️ Could not abort job ' + job.Id + ': ' + e.getMessage());
    }
}

// Schedule new daily job for midnight EST (4 AM UTC)
// Cron expression: "0 0 4 * * ?" = Every day at 4:00 AM UTC
String cronExpression = '0 0 4 * * ?';
String jobName = 'RevenueAutomationBatchManager_Daily_Production';

try {
    Id scheduledJobId = System.schedule(jobName, cronExpression, new RevenueAutomationBatchManager());
    System.debug('✅ SUCCESS: Scheduled daily batch job');
    System.debug('   Job ID: ' + scheduledJobId);
    System.debug('   Job Name: ' + jobName);
    System.debug('   Schedule: Every day at midnight EST (4:00 AM UTC)');
    System.debug('   Cron Expression: ' + cronExpression);
    
    // Verify the scheduled job
    CronTrigger newJob = [
        SELECT Id, CronJobDetail.Name, State, StartTime, EndTime, NextFireTime, 
               CronExpression, TimesTriggered, PreviousFireTime
        FROM CronTrigger 
        WHERE Id = :scheduledJobId
    ];
    
    System.debug('--- SCHEDULED JOB DETAILS ---');
    System.debug('Job Name: ' + newJob.CronJobDetail.Name);
    System.debug('State: ' + newJob.State);
    System.debug('Cron Expression: ' + newJob.CronExpression);
    System.debug('Next Fire Time: ' + newJob.NextFireTime);
    System.debug('Times Triggered: ' + newJob.TimesTriggered);
    
    DateTime nextRun = newJob.NextFireTime;
    if (nextRun != null) {
        System.debug('Next run (EST): ' + nextRun.format('yyyy-MM-dd HH:mm:ss', 'America/New_York'));
        System.debug('Next run (UTC): ' + nextRun.format('yyyy-MM-dd HH:mm:ss', 'UTC'));
    }

} catch (Exception e) {
    System.debug('❌ ERROR scheduling daily batch: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

System.debug('=== DAILY REVENUE AUTOMATION SCHEDULING COMPLETE ===');
