// Test the updated ContractRevenueBatch logic in partial sandbox
System.debug('=== TESTING UPDATED CONTRACT BATCH LOGIC ===');

// Check how many contracts will be processed now
List<Contract> contracts = [
    SELECT Id, Status, StartDate, EndDate, ARR__c, ARR_USD__c
    FROM Contract 
    // New query: ALL contracts (no status exclusions)
    LIMIT 10
];

System.debug('Total contracts that will be processed: ' + contracts.size());

for(Contract c : contracts) {
    System.debug('Contract: ' + c.Id + ' | Status: ' + c.Status + ' | ARR: ' + c.ARR__c + ' | ARR_USD: ' + c.ARR_USD__c);
}

// Run the updated batch manually
try {
    ContractRevenueBatch batch = new ContractRevenueBatch();
    Id jobId = Database.executeBatch(batch, 50);
    System.debug('Successfully started updated ContractRevenueBatch with Job ID: ' + jobId);
} catch(Exception e) {
    System.debug('ERROR running updated batch: ' + e.getMessage());
}

System.debug('=== END BATCH TEST ===');
