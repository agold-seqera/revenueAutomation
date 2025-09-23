// Run AccountRollupBatch to update all accounts (including Atlas Data Storage)
System.debug('=== RUNNING ACCOUNTROLLUPBATCH FOR ALL ACCOUNTS ===');

// Create and execute AccountRollupBatch 
AccountRollupBatch batch = new AccountRollupBatch();

// Execute the batch with batch size of 50
Id jobId = Database.executeBatch(batch, 50);

System.debug('✅ AccountRollupBatch queued with Job ID: ' + jobId);
System.debug('=== ACCOUNT ROLLUP INITIATED ===');
