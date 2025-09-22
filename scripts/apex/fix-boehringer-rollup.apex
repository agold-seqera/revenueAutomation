// Fix Boehringer revenue rollup after EUR currency update
System.debug('=== FIXING BOEHRINGER REVENUE ROLLUP ===');

// Run AccountRollupBatch for just Boehringer account
System.debug('Running AccountRollupBatch to recalculate revenue after EUR currency update...');

try {
    AccountRollupBatch batch = new AccountRollupBatch();
    Id jobId = Database.executeBatch(batch, 100);
    System.debug('AccountRollupBatch started with Job ID: ' + jobId);
    System.debug('This will recalculate all account rollups including Boehringer.');
    
} catch (Exception e) {
    System.debug('Error starting AccountRollupBatch: ' + e.getMessage());
}

System.debug('=== END BOEHRINGER FIX ===');
