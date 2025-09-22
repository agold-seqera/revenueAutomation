// Run full batch on entire database - ALL assets, contracts, and accounts
System.debug('=== Running Full Database Batch Processing ===');

// Step 1: Run ContractRevenueBatch for ALL contracts
System.debug('Step 1: Starting ContractRevenueBatch for ALL contracts...');
ContractRevenueBatch contractBatch = new ContractRevenueBatch();
Id contractBatchJobId = Database.executeBatch(contractBatch, 200);
System.debug('ContractRevenueBatch Job ID: ' + contractBatchJobId);

System.debug('=== Full Database Batch Started ===');
System.debug('Monitor contract batch: SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE Id = \'' + contractBatchJobId + '\'');
System.debug('The AccountRollupBatch will automatically chain after ContractRevenueBatch completes');
System.debug('This will process ALL contracts and accounts in the entire database');
