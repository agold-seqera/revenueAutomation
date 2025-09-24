// Schedule RevenueAutomationBatchManager to run in SCHEDULED context for debugging
// This will run the full batch chain in automated context to debug the Caris issue

System.debug('=== SCHEDULING DEBUG BATCH FOR CARIS INVESTIGATION ===');

// Calculate time 3 minutes from now
DateTime now = DateTime.now();
DateTime futureTime = now.addMinutes(3);

// Format for cron expression (second minute hour day month year)
String cronExpression = String.format(
    '{0} {1} {2} {3} {4} ?',
    new List<String>{
        String.valueOf(futureTime.second()),
        String.valueOf(futureTime.minute()),
        String.valueOf(futureTime.hour()),
        String.valueOf(futureTime.day()),
        String.valueOf(futureTime.month())
    }
);

String jobName = 'DebugBatch_Caris_' + String.valueOf(now.getTime()).substring(7);

System.debug('Current time: ' + now.format('yyyy-MM-dd HH:mm:ss'));
System.debug('Scheduled time: ' + futureTime.format('yyyy-MM-dd HH:mm:ss'));
System.debug('Cron expression: ' + cronExpression);
System.debug('Job name: ' + jobName);

try {
    // Check for existing jobs with similar name and abort them
    List<CronTrigger> existingJobs = [
        SELECT Id, CronJobDetail.Name 
        FROM CronTrigger 
        WHERE CronJobDetail.Name LIKE 'DebugBatch_Caris_%'
        AND State IN ('WAITING', 'ACQUIRED', 'EXECUTING')
    ];
    
    for (CronTrigger job : existingJobs) {
        System.abortJob(job.Id);
        System.debug('Aborted existing job: ' + job.CronJobDetail.Name);
    }
    
    // Schedule the new job
    String jobId = System.schedule(jobName, cronExpression, new RevenueAutomationBatchManager());
    
    System.debug('✅ Successfully scheduled debug batch');
    System.debug('Job ID: ' + jobId);
    System.debug('Job Name: ' + jobName);
    System.debug('Execution Time: ' + futureTime.format('yyyy-MM-dd HH:mm:ss'));
    
    // Log to custom object for tracking
    Batch_Execution_Log__c scheduleLog = new Batch_Execution_Log__c(
        Batch_Job_ID__c = jobId.substring(0, 15), // Truncate to fit field length
        Execution_Context__c = 'SCHEDULED',
        Processing_Stage__c = 'SCHEDULED',
        Contract_ID__c = '001fJ000021YBjKQAW', // Target account ID
        Error_Message__c = 'Debug batch scheduled for Caris investigation at ' + futureTime.format('yyyy-MM-dd HH:mm:ss')
    );
    
    insert scheduleLog;
    System.debug('✅ Schedule log created: ' + scheduleLog.Id);
    
} catch (Exception e) {
    System.debug('❌ Failed to schedule batch: ' + e.getMessage());
    System.debug('❌ Stack trace: ' + e.getStackTraceString());
}

System.debug('=== SCHEDULING COMPLETE ===');
System.debug('🔍 MONITORING INSTRUCTIONS:');
System.debug('1. Wait for scheduled execution time: ' + futureTime.format('yyyy-MM-dd HH:mm:ss'));
System.debug('2. Monitor job status: SELECT Id, Status, NextFireTime, PreviousFireTime FROM CronTrigger WHERE CronJobDetail.Name = \'' + jobName + '\'');
System.debug('3. Check batch execution: SELECT Id, Status, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE ApexClass.Name IN (\'RevenueAutomationBatchManager\', \'AccountRollupBatch\') AND CreatedDate >= ' + futureTime.format('yyyy-MM-dd') + 'T' + futureTime.format('HH:mm:ss') + '.000+0000');
System.debug('4. Check account status after execution: SELECT Id, Name, Status__c, LastModifiedDate, LastModifiedBy.Name FROM Account WHERE Id = \'001fJ000021YBjKQAW\'');
System.debug('5. Check debug logs: SELECT Id, Processing_Stage__c, Error_Message__c, CreatedDate FROM Batch_Execution_Log__c WHERE Contract_ID__c = \'001fJ000021YBjKQAW\' ORDER BY CreatedDate DESC LIMIT 5');
