// Run RevenueAutomationBatchManager immediately to process backlog
System.debug('=== RUNNING BATCH MANAGER IMMEDIATELY ===');

try {
    // Use the static method to execute now
    RevenueAutomationBatchManager.executeNow();
    System.debug('Successfully started sequential revenue automation processing');
    System.debug('Chain: AssetStatusBatch → ContractRevenueBatch → AccountRollupBatch');
} catch(Exception e) {
    System.debug('ERROR running batch manager: ' + e.getMessage());
}

// Check current processing status
List<AsyncApexJob> jobs = RevenueAutomationBatchManager.getProcessingStatus();
System.debug('Current batch jobs today: ' + jobs.size());
for(AsyncApexJob job : jobs) {
    System.debug('Job: ' + job.ApexClass.Name + ' | Status: ' + job.Status + ' | Progress: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
}

System.debug('=== END BATCH EXECUTION ===');
