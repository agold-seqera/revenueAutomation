// Test the actual ContractRevenueBatch execution for the EUR contract
System.debug('=== TESTING CONTRACT BATCH EXECUTION ===');

// Check the current state
Contract beforeContract = [SELECT Id, Status, ARR__c, ARR_USD__c, TCV_USD__c, ACV_USD__c 
                          FROM Contract WHERE Id = '800Pn00000k2FjoIAE' LIMIT 1];

System.debug('BEFORE batch execution:');
System.debug('  Contract: ' + beforeContract.Id + ' | Status: ' + beforeContract.Status);
System.debug('  ARR: ' + beforeContract.ARR__c);
System.debug('  ARR_USD: ' + beforeContract.ARR_USD__c);
System.debug('  TCV_USD: ' + beforeContract.TCV_USD__c);
System.debug('  ACV_USD: ' + beforeContract.ACV_USD__c);

// Execute just the ContractRevenueBatch (not the full chain)
try {
    System.debug('Starting ContractRevenueBatch...');
    ContractRevenueBatch batch = new ContractRevenueBatch();
    Id jobId = Database.executeBatch(batch, 50);
    System.debug('Batch started with Job ID: ' + jobId);
    
    // Wait a moment and check the job status
    AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                       FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];
    
    System.debug('Batch Job Status: ' + job.Status);
    System.debug('Progress: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
    System.debug('Errors: ' + job.NumberOfErrors);
    
} catch (Exception e) {
    System.debug('Error starting batch: ' + e.getMessage());
}

System.debug('=== END TEST ===');
