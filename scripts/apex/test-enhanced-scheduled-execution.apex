// Test enhanced ContractRevenueBatch in scheduled context to identify execution differences
System.debug('=== Testing Enhanced Batch in Scheduled Context ===');

// First, reset the contract to wrong values again
Contract resetContract = new Contract(
    Id = '800fJ000007eNJeQAM',
    ARR__c = 550000,
    ACV__c = 650000
);

try {
    update resetContract;
    System.debug('✅ Reset contract to wrong values for scheduled testing');
} catch (Exception e) {
    System.debug('❌ Failed to reset contract: ' + e.getMessage());
    return;
}

// Now run the FULL scheduled automation with enhanced logging
System.debug('\n--- Running Enhanced Scheduled Automation ---');

RevenueAutomationBatchManager batchManager = new RevenueAutomationBatchManager();
batchManager.execute(null);

System.debug('✅ Enhanced scheduled automation started');
System.debug('This will run with enhanced diagnostic logging:');
System.debug('  - Execution context detection (should show SCHEDULED)');
System.debug('  - Resource consumption monitoring');
System.debug('  - Comprehensive error tracking');
System.debug('  - SaveResult analysis');
System.debug('');
System.debug('Monitor the batch execution and check if contract 800fJ000007eNJeQAM gets updated');
System.debug('If it doesn\'t update, the enhanced logging will reveal why');

System.debug('\n=== Enhanced Scheduled Test Started ===');
