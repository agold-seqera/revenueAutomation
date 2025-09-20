// Analyze the batch processing results to verify rollups are working
System.debug('=== ANALYZING BATCH PROCESSING RESULTS ===');

// Get the batch job details
AsyncApexJob batchJob = [SELECT Id, JobItemsProcessed, TotalJobItems, CreatedDate, CompletedDate 
                        FROM AsyncApexJob 
                        WHERE Id = '707O300002h8fw4IAA'];

System.debug('Batch Job Details:');
System.debug('- Job Items Processed: ' + batchJob.JobItemsProcessed);
System.debug('- Total Job Items: ' + batchJob.TotalJobItems);
System.debug('- Duration: ' + (batchJob.CompletedDate.getTime() - batchJob.CreatedDate.getTime()) + 'ms');

// Analyze what the batch query actually returns
ContractRevenueBatch batch = new ContractRevenueBatch();
Database.QueryLocator ql = batch.start(null);
List<Contract> allContracts = Database.query(ql.getQuery());

System.debug('Query Analysis:');
System.debug('- Total contracts in query: ' + allContracts.size());
System.debug('- Query: ' + ql.getQuery());

// Check contract statuses
Map<String, Integer> statusCounts = new Map<String, Integer>();
for(Contract c : allContracts) {
    String status = c.Status != null ? c.Status : 'null';
    statusCounts.put(status, statusCounts.containsKey(status) ? statusCounts.get(status) + 1 : 1);
}

System.debug('Contract Status Distribution:');
for(String status : statusCounts.keySet()) {
    System.debug('- ' + status + ': ' + statusCounts.get(status));
}

// Sample some contracts to see their revenue data
System.debug('Sample Contract Data:');
for(Integer i = 0; i < Math.min(5, allContracts.size()); i++) {
    Contract c = allContracts[i];
    System.debug('Contract ' + (i+1) + ': ' + c.Id);
    System.debug('  Status: ' + c.Status);
    System.debug('  ARR: ' + c.ARR__c + ' | ARR_USD: ' + c.ARR_USD__c);
    System.debug('  TCV: ' + c.TCV__c + ' | TCV_USD: ' + c.TCV_USD__c);
    System.debug('  Assets: ' + (c.Assets__r != null ? c.Assets__r.size() : 0));
}

System.debug('=== END ANALYSIS ===');
