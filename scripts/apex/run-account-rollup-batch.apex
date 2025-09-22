// Run AccountRollupBatch to aggregate newly populated Contract USD values
System.debug('=== RUNNING ACCOUNT ROLLUP BATCH ===');

try {
    AccountRollupBatch batch = new AccountRollupBatch();
    Id jobId = Database.executeBatch(batch, 100);
    System.debug('AccountRollupBatch started with Job ID: ' + jobId);
    
    // Check initial job status
    AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems 
                       FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];
    
    System.debug('Job Status: ' + job.Status);
    System.debug('Progress: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
    
} catch (Exception e) {
    System.debug('Error starting AccountRollupBatch: ' + e.getMessage());
}

System.debug('=== END BATCH EXECUTION ===');