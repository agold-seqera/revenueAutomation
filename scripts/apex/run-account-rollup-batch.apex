// Execute AccountRollupBatch to update Account Type fields based on Status__c
Database.executeBatch(new AccountRollupBatch(), 100);