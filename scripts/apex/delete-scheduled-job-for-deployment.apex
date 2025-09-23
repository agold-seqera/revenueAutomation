// Delete scheduled job to allow deployment of fixed ContractRevenueBatch
System.debug('=== DELETING SCHEDULED JOB FOR DEPLOYMENT ===');

// Find and delete the scheduled job
List<CronTrigger> scheduledJobs = [
    SELECT Id, CronJobDetail.Name, CronExpression, State, NextFireTime
    FROM CronTrigger 
    WHERE CronJobDetail.Name LIKE '%RevenueAutomationBatchManager%'
    ORDER BY CreatedDate DESC
];

System.debug('Found ' + scheduledJobs.size() + ' scheduled jobs to delete');

for (CronTrigger job : scheduledJobs) {
    System.debug('Deleting job: ' + job.CronJobDetail.Name + ' (ID: ' + job.Id + ')');
    System.debug('  State: ' + job.State + ', Next Fire: ' + job.NextFireTime);
    
    try {
        System.abortJob(job.Id);
        System.debug('✅ Successfully deleted job ' + job.Id);
    } catch (Exception e) {
        System.debug('❌ Error deleting job ' + job.Id + ': ' + e.getMessage());
    }
}

System.debug('\n✅ Scheduled jobs deleted. Ready for deployment.');
System.debug('After deployment, we will reschedule the job with the fixed batch logic.');

System.debug('\n=== CLEANUP COMPLETE ===');
