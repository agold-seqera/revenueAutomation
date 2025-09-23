// Find and delete ALL scheduled jobs that might be blocking deployment
System.debug('=== FINDING ALL SCHEDULED JOBS ===');

// Find ALL scheduled jobs (not just RevenueAutomationBatchManager)
List<CronTrigger> allScheduledJobs = [
    SELECT Id, CronJobDetail.Name, CronExpression, State, NextFireTime, CronJobDetail.JobType
    FROM CronTrigger 
    ORDER BY CreatedDate DESC
];

System.debug('Found ' + allScheduledJobs.size() + ' total scheduled jobs');

for (CronTrigger job : allScheduledJobs) {
    System.debug('Job: ' + job.CronJobDetail.Name + ' (ID: ' + job.Id + ')');
    System.debug('  Type: ' + job.CronJobDetail.JobType + ', State: ' + job.State);
    System.debug('  Next Fire: ' + job.NextFireTime);
    
    // Delete any job that might be related to our batches
    if (job.CronJobDetail.Name.contains('Revenue') || 
        job.CronJobDetail.Name.contains('Contract') || 
        job.CronJobDetail.Name.contains('Batch') ||
        job.CronJobDetail.JobType == '7') { // JobType 7 is Apex
        
        System.debug('  🗑️  Deleting this job...');
        try {
            System.abortJob(job.Id);
            System.debug('  ✅ Successfully deleted job ' + job.Id);
        } catch (Exception e) {
            System.debug('  ❌ Error deleting job ' + job.Id + ': ' + e.getMessage());
        }
    } else {
        System.debug('  ⏭️  Skipping this job (not related to our batches)');
    }
}

System.debug('\n=== CLEANUP COMPLETE ===');
