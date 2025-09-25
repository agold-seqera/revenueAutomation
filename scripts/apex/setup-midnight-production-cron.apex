// Setup Midnight Production Cron Job
// Date: September 25, 2025
// Purpose: Create recurring midnight (4 UTC) cron job for nightly batch processing

System.debug('=== SETUP MIDNIGHT PRODUCTION CRON JOB ===');

try {
    // Use the built-in scheduleDaily() method from RevenueAutomationBatchManager
    // This sets up: '0 15 4 * * ?' = 04:15 UTC daily (12:15 AM EDT)
    RevenueAutomationBatchManager.scheduleDaily();
    
    System.debug('✅ SUCCESS: Midnight production cron job scheduled');
    System.debug('📅 Schedule: Daily at 04:15 UTC (12:15 AM EDT)');
    System.debug('🔧 Job Name: Revenue Automation - Sequential Processing');
    System.debug('⚡ Execution Chain: AssetStatusBatch → ContractRevenueBatch → AccountRollupBatch');
    
    // Verify the job was created
    List<CronTrigger> newJob = [
        SELECT Id, CronJobDetail.Name, CronExpression, NextFireTime, State
        FROM CronTrigger 
        WHERE CronJobDetail.Name = 'Revenue Automation - Sequential Processing'
        AND State != 'DELETED'
        LIMIT 1
    ];
    
    if (!newJob.isEmpty()) {
        CronTrigger job = newJob[0];
        System.debug('');
        System.debug('🎯 VERIFICATION - Job Created Successfully:');
        System.debug('   Job ID: ' + job.Id);
        System.debug('   Job Name: ' + job.CronJobDetail.Name);
        System.debug('   Cron Expression: ' + job.CronExpression);
        System.debug('   Next Fire Time: ' + job.NextFireTime);
        System.debug('   State: ' + job.State);
        
        // Calculate next execution
        if (job.NextFireTime != null) {
            DateTime nextRun = job.NextFireTime;
            System.debug('   Next Execution: ' + nextRun.format('yyyy-MM-dd HH:mm:ss') + ' UTC');
            System.debug('   Next Execution (EDT): ' + nextRun.addHours(-4).format('yyyy-MM-dd HH:mm:ss') + ' EDT');
        }
    } else {
        System.debug('⚠️  WARNING: Could not verify job creation');
    }
    
} catch (Exception e) {
    System.debug('❌ ERROR setting up midnight cron job: ' + e.getMessage());
    throw e;
}

System.debug('');
System.debug('🎉 MIDNIGHT CRON SETUP COMPLETE');
System.debug('The Revenue Automation system is now scheduled for nightly execution.');
System.debug('Setup completed at: ' + System.now());
