// Monitor the validation batch suite execution
// Check AsyncApexJob status for all batch components

System.debug(LoggingLevel.INFO, '=== MONITORING VALIDATION BATCH EXECUTION ===');

DateTime checkTime = DateTime.now();
System.debug(LoggingLevel.INFO, 'Monitor check time: ' + checkTime);

// Check for recent batch executions (last 10 minutes)
DateTime cutoffTime = checkTime.addMinutes(-10);

try {
    // Query for recent AsyncApexJob records related to our batch suite
    List<AsyncApexJob> batchJobs = [
        SELECT Id, JobType, Status, JobItemsProcessed, TotalJobItems, 
               NumberOfErrors, CreatedDate, CompletedDate, ExtendedStatus,
               ApexClass.Name, CreatedBy.Name
        FROM AsyncApexJob 
        WHERE ApexClass.Name IN ('RevenueAutomationBatchManager', 'AssetStatusBatch', 'ContractRevenueBatch', 'AccountRollupBatch')
        AND CreatedDate >= :cutoffTime
        ORDER BY CreatedDate DESC
        LIMIT 20
    ];
    
    System.debug(LoggingLevel.INFO, 'Found ' + batchJobs.size() + ' recent batch job(s)');
    System.debug(LoggingLevel.INFO, '');
    
    if (batchJobs.isEmpty()) {
        System.debug(LoggingLevel.INFO, '⏳ No batch executions found yet - may still be scheduled');
        System.debug(LoggingLevel.INFO, 'Expected start time: 17:43:25 UTC (13:43:25 EDT)');
    } else {
        System.debug(LoggingLevel.INFO, '📊 BATCH EXECUTION STATUS:');
        System.debug(LoggingLevel.INFO, '');
        
        for (AsyncApexJob job : batchJobs) {
            String statusIcon = getStatusIcon(job.Status);
            String progress = job.TotalJobItems > 0 ? 
                String.valueOf(job.JobItemsProcessed) + '/' + String.valueOf(job.TotalJobItems) : 'N/A';
            
            System.debug(LoggingLevel.INFO, statusIcon + ' ' + job.ApexClass.Name);
            System.debug(LoggingLevel.INFO, '   Status: ' + job.Status);
            System.debug(LoggingLevel.INFO, '   Progress: ' + progress);
            System.debug(LoggingLevel.INFO, '   Errors: ' + job.NumberOfErrors);
            System.debug(LoggingLevel.INFO, '   Created: ' + job.CreatedDate);
            if (job.CompletedDate != null) {
                System.debug(LoggingLevel.INFO, '   Completed: ' + job.CompletedDate);
            }
            if (String.isNotBlank(job.ExtendedStatus)) {
                System.debug(LoggingLevel.INFO, '   Details: ' + job.ExtendedStatus);
            }
            System.debug(LoggingLevel.INFO, '');
        }
    }
    
    // Check scheduled job status
    List<CronTrigger> scheduledJobs = [
        SELECT Id, CronJobDetail.Name, State, NextFireTime, PreviousFireTime
        FROM CronTrigger 
        WHERE CronJobDetail.Name LIKE 'Validation_Batch_Suite_%'
        ORDER BY NextFireTime DESC
        LIMIT 5
    ];
    
    if (!scheduledJobs.isEmpty()) {
        System.debug(LoggingLevel.INFO, '📅 SCHEDULED JOB STATUS:');
        for (CronTrigger cronJob : scheduledJobs) {
            System.debug(LoggingLevel.INFO, '• ' + cronJob.CronJobDetail.Name);
            System.debug(LoggingLevel.INFO, '  State: ' + cronJob.State);
            System.debug(LoggingLevel.INFO, '  Next Fire: ' + cronJob.NextFireTime);
            if (cronJob.PreviousFireTime != null) {
                System.debug(LoggingLevel.INFO, '  Previous Fire: ' + cronJob.PreviousFireTime);
            }
            System.debug(LoggingLevel.INFO, '');
        }
    }
    
} catch (Exception e) {
    System.debug(LoggingLevel.ERROR, '❌ Error monitoring batch execution');
    System.debug(LoggingLevel.ERROR, 'Error: ' + e.getMessage());
}

System.debug(LoggingLevel.INFO, '=== MONITORING COMPLETE ===');

// Helper method to get status icons
private static String getStatusIcon(String status) {
    switch on status {
        when 'Completed' { return '✅'; }
        when 'Processing' { return '⚙️'; }
        when 'Queued' { return '⏳'; }
        when 'Preparing' { return '🔄'; }
        when 'Failed', 'Aborted' { return '❌'; }
        when else { return '📊'; }
    }
}
