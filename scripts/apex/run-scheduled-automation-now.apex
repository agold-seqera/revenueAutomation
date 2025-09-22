// Run the full scheduled automation (RevenueAutomationBatchManager) as it would run overnight
System.debug('=== Running Full Scheduled Automation (RevenueAutomationBatchManager) ===');

// This is the exact same class that runs overnight via scheduled job
RevenueAutomationBatchManager batchManager = new RevenueAutomationBatchManager();
batchManager.execute(null);

System.debug('=== Scheduled Automation Started ===');
System.debug('This will run:');
System.debug('1. AssetStatusBatch (all assets)');
System.debug('2. ContractRevenueBatch (all contracts)'); 
System.debug('3. AccountRollupBatch (all accounts)');
System.debug('Same as the overnight scheduled job');
