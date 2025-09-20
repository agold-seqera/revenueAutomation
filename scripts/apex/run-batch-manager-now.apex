// Run RevenueAutomationBatchManager immediately to process backlog
System.debug('=== RUNNING BATCH MANAGER IMMEDIATELY ===');

try {
    RevenueAutomationBatchManager batchManager = new RevenueAutomationBatchManager();
    Id jobId = Database.executeBatch(batchManager, 200);
    System.debug('Successfully started RevenueAutomationBatchManager with Job ID: ' + jobId);
    System.debug('This will process the backlog of USD conversions and revenue calculations');
} catch(Exception e) {
    System.debug('ERROR running batch manager: ' + e.getMessage());
}

System.debug('=== END BATCH EXECUTION ===');
