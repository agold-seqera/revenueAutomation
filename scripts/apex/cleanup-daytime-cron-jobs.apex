// Cleanup Daytime Cron Jobs
// Date: September 25, 2025
// Purpose: Remove any daytime/test cron jobs and clean up old ones

System.debug('=== CLEANUP DAYTIME CRON JOBS ===');

// Find all revenue automation related cron jobs
List<CronTrigger> allRevenueCrons = [
    SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, 
           CronExpression, TimesTriggered, NextFireTime, PreviousFireTime, State
    FROM CronTrigger 
    WHERE CronJobDetail.Name LIKE '%Revenue%' 
    ORDER BY CronJobDetail.Name
];

System.debug('Found ' + allRevenueCrons.size() + ' revenue automation cron jobs:');

List<String> jobsToDelete = new List<String>();

for (CronTrigger job : allRevenueCrons) {
    System.debug('');
    System.debug('📋 Job: ' + job.CronJobDetail.Name);
    System.debug('   ID: ' + job.Id);
    System.debug('   State: ' + job.State);
    System.debug('   Cron Expression: ' + job.CronExpression);
    System.debug('   Next Fire: ' + job.NextFireTime);
    System.debug('   Times Triggered: ' + job.TimesTriggered);
    
    // Identify jobs to clean up
    String jobName = job.CronJobDetail.Name;
    
    if (jobName.contains('FullValidation_0925') || 
        jobName.contains('MonitoringRun_0923') ||
        jobName.contains('FullValidation_0923') ||
        job.State == 'DELETED') {
        
        System.debug('   🗑️  MARKED FOR CLEANUP: ' + jobName);
        jobsToDelete.add(job.Id);
        
    } else if (jobName.contains('Sequential Processing')) {
        System.debug('   ✅ KEEP: Main production job');
    } else {
        System.debug('   ❓ REVIEW: Unknown job pattern');
    }
}

System.debug('');
System.debug('🧹 CLEANUP PROCESS:');

// Clean up identified jobs
for (String jobId : jobsToDelete) {
    try {
        System.abortJob(jobId);
        System.debug('   ✅ Aborted job: ' + jobId);
    } catch (Exception e) {
        System.debug('   ⚠️  Could not abort job ' + jobId + ': ' + e.getMessage());
    }
}

System.debug('');
System.debug('Total jobs cleaned up: ' + jobsToDelete.size());
System.debug('Cleanup complete: ' + System.now());
