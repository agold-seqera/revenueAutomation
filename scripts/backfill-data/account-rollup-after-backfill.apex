// Run AccountRollupBatch after USD field backfill to roll up corrected contract values to accounts

System.debug('Starting AccountRollupBatch to roll up corrected USD fields from contracts to accounts');

// Execute AccountRollupBatch to aggregate the newly aligned contract USD fields
Id batchId = Database.executeBatch(new AccountRollupBatch(), 200);

System.debug('AccountRollupBatch submitted successfully with ID: ' + batchId);
System.debug('This will roll up the corrected contract USD fields to account level');
