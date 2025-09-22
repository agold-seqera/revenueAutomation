// Run full ContractRevenueBatch to test if our logic fixes the calculation issues
System.debug('=== Running Full ContractRevenueBatch ===');

// Execute the full batch
ContractRevenueBatch batch = new ContractRevenueBatch();
Id batchJobId = Database.executeBatch(batch, 200);

System.debug('ContractRevenueBatch started with Job ID: ' + batchJobId);
System.debug('This will process ALL contracts in the org');
System.debug('Monitor the job with: SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE Id = \'' + batchJobId + '\'');

System.debug('=== Batch Execution Started ===');
