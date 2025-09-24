// Schedule full RevenueAutomationBatchManager suite for ARR formula validation
// Focus: Sample-based SKU ARR inclusion, CPUh family alignment, and record monitoring

System.debug(LoggingLevel.INFO, '=== ARR FORMULA VALIDATION BATCH SCHEDULING ===');

// Get current time and calculate execution time (3 minutes from now)
DateTime now = DateTime.now();
DateTime executionTime = now.addMinutes(3);

// Format execution time for cron expression (seconds minutes hours day month dayOfWeek year)
String cronExpression = String.format(
    '{0} {1} {2} {3} {4} ? {5}',
    new List<String>{
        String.valueOf(executionTime.second()),
        String.valueOf(executionTime.minute()),
        String.valueOf(executionTime.hour()),
        String.valueOf(executionTime.day()),
        String.valueOf(executionTime.month()),
        String.valueOf(executionTime.year())
    }
);

System.debug(LoggingLevel.INFO, 'Current Time: ' + now);
System.debug(LoggingLevel.INFO, 'Scheduled Execution: ' + executionTime);
System.debug(LoggingLevel.INFO, 'Cron Expression: ' + cronExpression);

// Check for existing scheduled job and abort if found
List<CronTrigger> existingJobs = [
    SELECT Id, CronJobDetail.Name, State, NextFireTime 
    FROM CronTrigger 
    WHERE CronJobDetail.Name = 'ARR_Validation_Batch_Test'
    AND State IN ('WAITING', 'ACQUIRED', 'EXECUTING')
];

if (!existingJobs.isEmpty()) {
    System.debug(LoggingLevel.WARN, 'Found existing ARR validation job: ' + existingJobs[0].Id);
    System.abortJob(existingJobs[0].Id);
    System.debug(LoggingLevel.INFO, 'Aborted existing job: ' + existingJobs[0].Id);
}

// Schedule the batch with unique job name
String jobId = System.schedule(
    'ARR_Validation_Batch_Test', 
    cronExpression, 
    new RevenueAutomationBatchManager()
);

System.debug(LoggingLevel.INFO, '✅ BATCH SCHEDULED SUCCESSFULLY');
System.debug(LoggingLevel.INFO, 'Job ID: ' + jobId);
System.debug(LoggingLevel.INFO, 'Job Name: ARR_Validation_Batch_Test');
System.debug(LoggingLevel.INFO, 'Execution Time: ' + executionTime + ' (' + executionTime.format('HH:mm:ss') + ')');

// Log monitoring details
System.debug(LoggingLevel.INFO, '📋 MONITORING FOCUS AREAS:');
System.debug(LoggingLevel.INFO, '1. Sample-based SKU ARR inclusion');
System.debug(LoggingLevel.INFO, '2. CPUh family alignment verification');
System.debug(LoggingLevel.INFO, '3. Caris/Almirall NO CHANGE verification');
System.debug(LoggingLevel.INFO, '4. KTest exclusion validation');

System.debug(LoggingLevel.INFO, '=== READY FOR MONITORING ===');
System.debug(LoggingLevel.INFO, 'Expected batch chain execution in ~3 minutes');
System.debug(LoggingLevel.INFO, 'Monitor AsyncApexJob records starting at: ' + executionTime.format());
