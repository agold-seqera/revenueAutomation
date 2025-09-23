// Schedule comprehensive full batch run for validation
System.debug('=== SCHEDULING COMPREHENSIVE BATCH VALIDATION ===');

// Get current time and add 3 minutes for scheduling
DateTime currentTime = DateTime.now();
DateTime scheduledTime = currentTime.addMinutes(3);

System.debug('Current time: ' + currentTime);
System.debug('Scheduled time: ' + scheduledTime);

// Create cron expression for 3 minutes from now
String cronExpression = scheduledTime.second() + ' ' + 
                       scheduledTime.minute() + ' ' + 
                       scheduledTime.hour() + ' ' + 
                       scheduledTime.day() + ' ' + 
                       scheduledTime.month() + ' ' + 
                       '? ' + 
                       scheduledTime.year();

System.debug('Cron expression: ' + cronExpression);

// Schedule the RevenueAutomationBatchManager
String jobName = 'RevenueAutomationBatchManager_FullValidation_' + 
                 currentTime.format('MMdd_HHmm');

try {
    Id scheduledJobId = System.schedule(jobName, cronExpression, new RevenueAutomationBatchManager());
    System.debug('✅ SUCCESS: Scheduled batch job with ID: ' + scheduledJobId);
    System.debug('   Job Name: ' + jobName);
    System.debug('   Will execute at: ' + scheduledTime);
    System.debug('');
    System.debug('🎯 VALIDATION FOCUS AREAS:');
    System.debug('   1. All 149 accounts with Has_Contracts__c = true');
    System.debug('   2. Contracted accounts (6 total) - USD Reporting field aggregation');
    System.debug('   3. Churning/Churned accounts - revenue preservation validation');
    System.debug('   4. Future contract logic - Atlas Data Storage and others');
    System.debug('   5. Asset exchange rate usage - newly populated rates');
    System.debug('   6. Base/USD/Reporting field alignment across all objects');
    
} catch (Exception e) {
    System.debug('❌ ERROR scheduling batch: ' + e.getMessage());
}

System.debug('=== BATCH SCHEDULING COMPLETE ===');
