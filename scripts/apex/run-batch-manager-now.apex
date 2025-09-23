// Execute RevenueAutomationBatchManager immediately for final validation

System.debug('=== EXECUTING REVENUE AUTOMATION BATCH MANAGER FOR FINAL VALIDATION ===');

// Execute the batch manager directly
RevenueAutomationBatchManager batchManager = new RevenueAutomationBatchManager();
batchManager.execute(null); // Execute directly

System.debug('✓ RevenueAutomationBatchManager executed directly');
System.debug('This runs all three batches: ContractRevenueBatch → AccountRollupBatch → AssetStatusBatch');
System.debug('Check debug logs for execution results');

System.debug('=== BATCH MANAGER EXECUTION INITIATED ===');