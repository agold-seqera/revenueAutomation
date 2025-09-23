// Monitor the scheduled RevenueAutomationBatchManager execution
System.debug('=== MONITORING FULL BATCH EXECUTION ===');
System.debug('Current time: ' + DateTime.now());

// Check scheduled job status
try {
    CronTrigger scheduledJob = [
        SELECT Id, CronJobDetail.Name, State, StartTime, EndTime, NextFireTime
        FROM CronTrigger 
        WHERE Id = '08ePn00000u6j0gIAA'
        LIMIT 1
    ];
    
    System.debug('--- SCHEDULED JOB STATUS ---');
    System.debug('Job ID: ' + scheduledJob.Id);
    System.debug('Job Name: ' + scheduledJob.CronJobDetail.Name);
    System.debug('State: ' + scheduledJob.State);
    System.debug('Next Fire Time: ' + scheduledJob.NextFireTime);
    System.debug('Start Time: ' + scheduledJob.StartTime);
    System.debug('End Time: ' + scheduledJob.EndTime);
    
} catch (Exception e) {
    System.debug('❌ Error querying scheduled job: ' + e.getMessage());
}

// Check for any recent AsyncApexJob executions (last 5 minutes)
DateTime fiveMinutesAgo = DateTime.now().addMinutes(-5);

List<AsyncApexJob> recentJobs = [
    SELECT Id, JobType, ApexClass.Name, Status, JobItemsProcessed, TotalJobItems,
           NumberOfErrors, CompletedDate, CreatedDate, ExtendedStatus
    FROM AsyncApexJob 
    WHERE CreatedDate >= :fiveMinutesAgo
    AND ApexClass.Name IN ('AssetStatusBatch', 'ContractRevenueBatch', 'AccountRollupBatch', 'RevenueAutomationBatchManager')
    ORDER BY CreatedDate DESC
];

System.debug('--- RECENT BATCH EXECUTIONS (Last 5 minutes) ---');
System.debug('Found ' + recentJobs.size() + ' recent batch jobs');

for (AsyncApexJob job : recentJobs) {
    System.debug('Job: ' + job.ApexClass.Name + ' (' + job.Id + ')');
    System.debug('  Status: ' + job.Status);
    System.debug('  Created: ' + job.CreatedDate);
    System.debug('  Completed: ' + job.CompletedDate);
    System.debug('  Items: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
    System.debug('  Errors: ' + job.NumberOfErrors);
    if (job.ExtendedStatus != null) {
        System.debug('  Extended Status: ' + job.ExtendedStatus);
    }
    System.debug('');
}

System.debug('=== MONITORING COMPLETE ===');
