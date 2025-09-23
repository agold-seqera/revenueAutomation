// Schedule BatchExecutionLogCleanup for daily execution at 2 AM UTC
// This prevents database clutter by removing Batch_Execution_Log__c records older than 10 days

System.debug('=== SCHEDULING BATCH EXECUTION LOG CLEANUP ===');

// Check for existing cleanup jobs first
List<CronTrigger> existingJobs = [
    SELECT Id, CronJobDetail.Name, State, NextFireTime, CronExpression
    FROM CronTrigger 
    WHERE CronJobDetail.Name LIKE '%Batch Execution Log Cleanup%'
    AND State != 'DELETED'
];

System.debug('Found ' + existingJobs.size() + ' existing batch execution log cleanup jobs');

for (CronTrigger job : existingJobs) {
    System.debug('Existing Job: ' + job.CronJobDetail.Name + ' (' + job.Id + ') - State: ' + job.State);
    System.debug('  Next Fire Time: ' + job.NextFireTime);
    System.debug('  Cron Expression: ' + job.CronExpression);
}

// Schedule the daily cleanup job
try {
    BatchExecutionLogCleanup.scheduleDaily();
    System.debug('✅ Successfully scheduled BatchExecutionLogCleanup');
    
    // Verify the job was scheduled
    List<CronTrigger> newJobs = [
        SELECT Id, CronJobDetail.Name, NextFireTime, CronExpression, State
        FROM CronTrigger 
        WHERE CronJobDetail.Name = 'Batch Execution Log Cleanup - Daily'
        AND State != 'DELETED'
    ];
    
    if (!newJobs.isEmpty()) {
        CronTrigger newJob = newJobs[0];
        System.debug('Job Details:');
        System.debug('  Job ID: ' + newJob.Id);
        System.debug('  Job Name: ' + newJob.CronJobDetail.Name);
        System.debug('  Cron Expression: ' + newJob.CronExpression + ' (Daily at 2:00 AM UTC)');
        System.debug('  Next Fire Time: ' + newJob.NextFireTime);
        System.debug('  State: ' + newJob.State);
    }
    
    // Show cleanup information
    System.debug('');
    System.debug('Cleanup Configuration:');
    System.debug('  Retention Period: 10 days');
    System.debug('  Schedule: Daily at 2:00 AM UTC');
    System.debug('  Safety Limit: 10,000 records per execution');
    
    // Check current record count for cleanup
    Integer recordsForCleanup = BatchExecutionLogCleanup.getRecordCountForCleanup();
    System.debug('  Records currently eligible for cleanup: ' + recordsForCleanup);
    
    DateTime oldestRecord = BatchExecutionLogCleanup.getOldestRecordDate();
    if (oldestRecord != null) {
        System.debug('  Oldest record date: ' + oldestRecord);
        Integer daysSinceOldest = oldestRecord.date().daysBetween(Date.today());
        System.debug('  Days since oldest record: ' + daysSinceOldest);
    } else {
        System.debug('  No records found in Batch_Execution_Log__c');
    }
    
    System.debug('');
    System.debug('Manual Execution Options:');
    System.debug('  Test cleanup: BatchExecutionLogCleanup.executeNow();');
    System.debug('  Check records: BatchExecutionLogCleanup.getRecordCountForCleanup();');
    System.debug('  Oldest record: BatchExecutionLogCleanup.getOldestRecordDate();');
    
} catch (Exception e) {
    System.debug('❌ ERROR scheduling BatchExecutionLogCleanup: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

System.debug('=== END SCHEDULING ===');
