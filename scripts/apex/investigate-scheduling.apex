// Investigate scheduling and batch job status
System.debug('=== SCHEDULING INVESTIGATION ===');

// Check for scheduled batch jobs
List<CronTrigger> cronJobs = [SELECT Id, CronJobDetail.Name, CronJobDetail.JobType, State, NextFireTime, PreviousFireTime 
                             FROM CronTrigger 
                             ORDER BY CronJobDetail.Name];

System.debug('Total Scheduled Jobs: ' + cronJobs.size());
for(CronTrigger ct : cronJobs) {
    System.debug('Job: ' + ct.CronJobDetail.Name + ' | Type: ' + ct.CronJobDetail.JobType + ' | State: ' + ct.State + ' | Next: ' + ct.NextFireTime);
}

// Check recent batch job executions
List<AsyncApexJob> recentJobs = [SELECT Id, ApexClass.Name, Status, CreatedDate, CompletedDate, NumberOfErrors
                                FROM AsyncApexJob 
                                WHERE CreatedDate >= YESTERDAY
                                ORDER BY CreatedDate DESC];

System.debug('Recent Batch Jobs (last 24h): ' + recentJobs.size());
for(AsyncApexJob job : recentJobs) {
    System.debug('Batch: ' + job.ApexClass.Name + ' | Status: ' + job.Status + ' | Created: ' + job.CreatedDate + ' | Errors: ' + job.NumberOfErrors);
}

// Check if RevenueAutomationBatchManager exists
try {
    Type batchType = Type.forName('RevenueAutomationBatchManager');
    System.debug('RevenueAutomationBatchManager class exists: ' + (batchType != null));
} catch(Exception e) {
    System.debug('RevenueAutomationBatchManager class NOT FOUND: ' + e.getMessage());
}

System.debug('=== END INVESTIGATION ===');
