// Abort scheduled job for deployment
System.debug('=== ABORTING SCHEDULED JOB FOR DEPLOYMENT ===');

List<CronTrigger> existingJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger
                                 WHERE CronJobDetail.Name LIKE '%RevenueAutomationBatchManager%'];

System.debug('Found RevenueAutomationBatchManager jobs: ' + existingJobs.size());

for(CronTrigger job : existingJobs) {
    try {
        System.abortJob(job.Id);
        System.debug('Successfully aborted job: ' + job.CronJobDetail.Name + ' (ID: ' + job.Id + ')');
    } catch(Exception e) {
        System.debug('Error aborting job ' + job.Id + ': ' + e.getMessage());
    }
}

System.debug('=== END ABORT SCHEDULED JOBS ===');
