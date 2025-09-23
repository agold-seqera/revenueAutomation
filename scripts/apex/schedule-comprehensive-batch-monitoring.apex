// Schedule RevenueAutomationBatchManager for comprehensive monitoring and analysis
// This will run in 5 minutes for real-time monitoring during business hours

String jobName = 'RevenueAutomationBatchManager_MonitoringRun_0923';

// Calculate execution time (current time + 5 minutes)
DateTime now = DateTime.now();
DateTime executeTime = now.addMinutes(5);

// Format for cron expression: ss mm HH dd MM ? yyyy
String cronExp = executeTime.format('ss mm HH dd MM') + ' ? ' + executeTime.format('yyyy');

System.debug('Scheduling ' + jobName + ' to execute at: ' + executeTime + ' (5 minutes from now)');
System.debug('Cron expression: ' + cronExp);

// Schedule the job
String jobId = System.schedule(jobName, cronExp, new RevenueAutomationBatchManager());

System.debug('Successfully scheduled job with ID: ' + jobId);
System.debug('Job will process all 3 batch classes in sequence:');
System.debug('1. AssetStatusBatch');
System.debug('2. ContractRevenueBatch'); 
System.debug('3. AccountRollupBatch');
System.debug('');
System.debug('Monitor execution with:');
System.debug('- AsyncApexJob queries for batch progress');
System.debug('- Account/Contract LastModifiedDate analysis');
System.debug('- USD field alignment verification');
System.debug('- Product family inclusion validation');
System.debug('- Account Type field updates verification');
