// Test if the ContractRevenueBatch start() method is querying our problem contract
System.debug('=== Testing ContractRevenueBatch Query Locator ===');

// Simulate exactly what the batch start() method does
ContractRevenueBatch batch = new ContractRevenueBatch();
Database.QueryLocator queryLocator = batch.start(null);

// Get the query string
String queryString = queryLocator.getQuery();
System.debug('Batch Query: ' + queryString);

// Execute the same query to see what contracts are returned
List<Contract> contractsFromQuery = Database.query(queryString);
System.debug('Total contracts returned by batch query: ' + contractsFromQuery.size());

// Check if our problem contract is in the results
Contract problemContract = null;
for (Contract c : contractsFromQuery) {
    if (c.Id == '800fJ000007eNJeQAM') {
        problemContract = c;
        break;
    }
}

if (problemContract != null) {
    System.debug('✅ Problem contract IS included in batch query');
    System.debug('  Status: ' + problemContract.Status);
    System.debug('  ARR__c: ' + problemContract.ARR__c);
    System.debug('  Assets: ' + problemContract.Assets__r.size());
    
    // Check if it has the exact same data as our manual test
    System.debug('  StartDate: ' + problemContract.StartDate);
    System.debug('  EndDate: ' + problemContract.EndDate);
    System.debug('  Exclude_from_Status_Updates__c: ' + problemContract.Exclude_from_Status_Updates__c);
} else {
    System.debug('❌ Problem contract is NOT included in batch query');
    System.debug('🚨 This would explain why scheduled batches skip it!');
}

// Also check a few other contracts to see the pattern
System.debug('\nSample of contracts in batch query:');
Integer sampleCount = Math.min(5, contractsFromQuery.size());
for (Integer i = 0; i < sampleCount; i++) {
    Contract c = contractsFromQuery[i];
    System.debug('  ' + c.Id + ' | Status: ' + c.Status + ' | ARR: ' + c.ARR__c);
}

System.debug('\n=== Query Locator Test Complete ===');
