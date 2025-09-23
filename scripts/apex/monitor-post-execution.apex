// Monitor batch execution after it should have started
System.debug('=== POST-EXECUTION MONITORING ===');
System.debug('Current time: ' + DateTime.now());

// Check for batch executions in the last 10 minutes
DateTime tenMinutesAgo = DateTime.now().addMinutes(-10);

List<AsyncApexJob> batchJobs = [
    SELECT Id, JobType, ApexClass.Name, Status, JobItemsProcessed, TotalJobItems,
           NumberOfErrors, CompletedDate, CreatedDate, ExtendedStatus
    FROM AsyncApexJob 
    WHERE CreatedDate >= :tenMinutesAgo
    AND ApexClass.Name IN ('AssetStatusBatch', 'ContractRevenueBatch', 'AccountRollupBatch', 'RevenueAutomationBatchManager')
    ORDER BY CreatedDate DESC
];

System.debug('--- BATCH EXECUTION RESULTS ---');
System.debug('Found ' + batchJobs.size() + ' batch jobs in last 10 minutes');

Map<String, List<AsyncApexJob>> jobsByClass = new Map<String, List<AsyncApexJob>>();

for (AsyncApexJob job : batchJobs) {
    String className = job.ApexClass.Name;
    if (!jobsByClass.containsKey(className)) {
        jobsByClass.put(className, new List<AsyncApexJob>());
    }
    jobsByClass.get(className).add(job);
    
    System.debug('--- ' + job.ApexClass.Name + ' (' + job.Id + ') ---');
    System.debug('  Status: ' + job.Status);
    System.debug('  Created: ' + job.CreatedDate);
    System.debug('  Completed: ' + job.CompletedDate);
    System.debug('  Items Processed: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
    System.debug('  Errors: ' + job.NumberOfErrors);
    if (job.ExtendedStatus != null) {
        System.debug('  Extended Status: ' + job.ExtendedStatus);
    }
    System.debug('');
}

// Calculate total processing time if we have all three batches
Integer totalBatches = 0;
DateTime earliestStart = null;
DateTime latestEnd = null;

for (String className : jobsByClass.keySet()) {
    List<AsyncApexJob> jobs = jobsByClass.get(className);
    if (!jobs.isEmpty()) {
        AsyncApexJob latestJob = jobs[0]; // Most recent
        totalBatches++;
        
        if (earliestStart == null || latestJob.CreatedDate < earliestStart) {
            earliestStart = latestJob.CreatedDate;
        }
        
        if (latestJob.CompletedDate != null && (latestEnd == null || latestJob.CompletedDate > latestEnd)) {
            latestEnd = latestJob.CompletedDate;
        }
    }
}

System.debug('--- EXECUTION SUMMARY ---');
System.debug('Total batch classes executed: ' + totalBatches);
System.debug('Earliest start: ' + earliestStart);
System.debug('Latest completion: ' + latestEnd);

if (earliestStart != null && latestEnd != null) {
    Long duration = latestEnd.getTime() - earliestStart.getTime();
    System.debug('Total execution time: ' + (duration / 1000) + ' seconds');
}

// Check scheduled job status again
try {
    CronTrigger scheduledJob = [
        SELECT Id, CronJobDetail.Name, State, StartTime, EndTime, NextFireTime
        FROM CronTrigger 
        WHERE Id = '08ePn00000u6j0gIAA'
        LIMIT 1
    ];
    
    System.debug('--- SCHEDULED JOB FINAL STATUS ---');
    System.debug('State: ' + scheduledJob.State);
    System.debug('Start Time: ' + scheduledJob.StartTime);
    System.debug('End Time: ' + scheduledJob.EndTime);
    
} catch (Exception e) {
    System.debug('❌ Error querying scheduled job: ' + e.getMessage());
}

System.debug('=== POST-EXECUTION MONITORING COMPLETE ===');
