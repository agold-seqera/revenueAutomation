// Execute Account Rollup Batch to aggregate Contract revenue to Account level
AccountRollupBatch batch = new AccountRollupBatch();
Database.executeBatch(batch, 200);
System.debug('AccountRollupBatch started - this will roll up Contract revenue to Account level');
