// Test the enhanced ContractRevenueBatch with comprehensive diagnostic logging
System.debug('=== Testing Enhanced Diagnostic ContractRevenueBatch ===');

// First, reset a contract to wrong values to test properly
Contract resetContract = new Contract(
    Id = '800fJ000007eNJeQAM',
    ARR__c = 550000,
    ACV__c = 650000
);

try {
    update resetContract;
    System.debug('✅ Reset contract to wrong values for testing');
} catch (Exception e) {
    System.debug('❌ Failed to reset contract: ' + e.getMessage());
    return;
}

// Now test the enhanced batch with full diagnostics
System.debug('\n--- Testing Enhanced ContractRevenueBatch ---');

ContractRevenueBatch enhancedBatch = new ContractRevenueBatch();

// Test the start() method to see execution context detection
Database.QueryLocator queryLocator = enhancedBatch.start(null);
System.debug('Enhanced batch start() completed');

// Get our specific contract from the query
List<Contract> allContracts = Database.query(queryLocator.getQuery());
Contract targetContract = null;

for (Contract c : allContracts) {
    if (c.Id == '800fJ000007eNJeQAM') {
        targetContract = c;
        break;
    }
}

if (targetContract == null) {
    System.debug('❌ Target contract not found in query results');
    return;
}

System.debug('BEFORE Enhanced Processing:');
System.debug('  ARR__c: ' + targetContract.ARR__c);
System.debug('  ACV__c: ' + targetContract.ACV__c);

// Execute the enhanced batch with single contract for detailed logging
List<Contract> singleContractBatch = new List<Contract>{targetContract};
enhancedBatch.execute(null, singleContractBatch);

System.debug('\n--- Enhanced Batch Execute Completed ---');

// Check the final result
Contract finalResult = [
    SELECT Id, ARR__c, ACV__c, Active_ARR__c, LastModifiedDate
    FROM Contract 
    WHERE Id = '800fJ000007eNJeQAM'
];

System.debug('AFTER Enhanced Processing:');
System.debug('  ARR__c: ' + finalResult.ARR__c);
System.debug('  ACV__c: ' + finalResult.ACV__c);
System.debug('  Active_ARR__c: ' + finalResult.Active_ARR__c);
System.debug('  LastModified: ' + finalResult.LastModifiedDate);

// Validate the fix
Boolean arrFixed = (finalResult.ARR__c == 300000);
Boolean acvFixed = (finalResult.ACV__c == 300000);

System.debug('\n--- ENHANCED DIAGNOSTIC RESULTS ---');
System.debug('✅ ARR Fixed to 300,000: ' + arrFixed);
System.debug('✅ ACV Fixed to 300,000: ' + acvFixed);

if (arrFixed && acvFixed) {
    System.debug('🎉 SUCCESS: Enhanced diagnostic batch works correctly!');
    System.debug('The enhanced logging will help identify issues in scheduled execution');
} else {
    System.debug('❌ ISSUE: Enhanced batch still has problems');
}

System.debug('\n=== Enhanced Diagnostic Test Complete ===');
