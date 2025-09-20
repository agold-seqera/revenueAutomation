// Schedule the RevenueAutomationBatchManager
System.debug('=== SCHEDULING BATCH MANAGER ===');

// Check if already scheduled
List<CronTrigger> existingJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger 
                                 WHERE CronJobDetail.Name LIKE '%RevenueAutomationBatchManager%'];

System.debug('Existing RevenueAutomationBatchManager jobs: ' + existingJobs.size());

if(existingJobs.size() == 0) {
    System.debug('No existing batch manager scheduled. Need to schedule it.');
    
    // Schedule for daily execution at 4:00 AM EST (as per session log)
    String cronExpression = '0 0 4 * * ?'; // Daily at 4:00 AM
    
    try {
        RevenueAutomationBatchManager batchManager = new RevenueAutomationBatchManager();
        String jobId = System.schedule('RevenueAutomationBatchManager_Daily', cronExpression, batchManager);
        System.debug('Successfully scheduled RevenueAutomationBatchManager with Job ID: ' + jobId);
    } catch(Exception e) {
        System.debug('ERROR scheduling batch manager: ' + e.getMessage());
    }
} else {
    System.debug('RevenueAutomationBatchManager already scheduled.');
    for(CronTrigger ct : existingJobs) {
        System.debug('Existing job: ' + ct.CronJobDetail.Name + ' (ID: ' + ct.Id + ')');
    }
}

System.debug('=== END SCHEDULING ===');
