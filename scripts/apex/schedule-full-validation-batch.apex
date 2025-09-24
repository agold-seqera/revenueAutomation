// Schedule full RevenueAutomationBatchManager suite for validation after debug cleanup
// This will verify all systems are working correctly without debug code

System.debug(LoggingLevel.INFO, '=== SCHEDULING FULL VALIDATION BATCH SUITE ===');

// Calculate schedule time (3 minutes from now)
DateTime now = DateTime.now();
DateTime scheduledTime = now.addMinutes(3);

String cronExpression = scheduledTime.format('s m H d M ? yyyy');
System.debug(LoggingLevel.INFO, 'Current time: ' + now);
System.debug(LoggingLevel.INFO, 'Scheduled time: ' + scheduledTime);
System.debug(LoggingLevel.INFO, 'Cron expression: ' + cronExpression);

try {
    // Create the batch manager instance
    RevenueAutomationBatchManager batchManager = new RevenueAutomationBatchManager();
    
    // Schedule the full batch suite
    String jobId = System.schedule(
        'Validation_Batch_Suite_' + String.valueOf(now.getTime()), 
        cronExpression, 
        batchManager
    );
    
    System.debug(LoggingLevel.INFO, '✅ Successfully scheduled full batch suite');
    System.debug(LoggingLevel.INFO, 'Job ID: ' + jobId);
    System.debug(LoggingLevel.INFO, 'Job Name: Validation_Batch_Suite_' + String.valueOf(now.getTime()));
    
    // Log what this batch will run
    System.debug(LoggingLevel.INFO, '');
    System.debug(LoggingLevel.INFO, '📋 BATCH SUITE INCLUDES:');
    System.debug(LoggingLevel.INFO, '1. AssetStatusBatch - Asset status updates');
    System.debug(LoggingLevel.INFO, '2. ContractRevenueBatch - Contract revenue calculations');
    System.debug(LoggingLevel.INFO, '3. AccountRollupBatch - Account revenue rollups and status updates');
    System.debug(LoggingLevel.INFO, '');
    
    // Key validation points
    System.debug(LoggingLevel.INFO, '🎯 VALIDATION OBJECTIVES:');
    System.debug(LoggingLevel.INFO, '- Verify clean AccountRollupBatch operates correctly');
    System.debug(LoggingLevel.INFO, '- Confirm no debug code artifacts remain');
    System.debug(LoggingLevel.INFO, '- Validate full batch chain execution');
    System.debug(LoggingLevel.INFO, '- Ensure all revenue calculations are accurate');
    
    System.debug(LoggingLevel.INFO, '');
    System.debug(LoggingLevel.INFO, '⏰ Monitor execution starting at: ' + scheduledTime);
    
} catch (Exception e) {
    System.debug(LoggingLevel.ERROR, '❌ Failed to schedule validation batch suite');
    System.debug(LoggingLevel.ERROR, 'Error: ' + e.getMessage());
    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
}

System.debug(LoggingLevel.INFO, '=== SCHEDULING COMPLETE ===');
