// COMPLETE POST-DEPLOYMENT SCRIPT
// Run this after deploying to populate all revenue fields and Include in First Year ARR flags

System.debug('=== STARTING POST-DEPLOYMENT PROCESSES ===');

// 1. TRIGGER OPPORTUNITY FIRST YEAR LOGIC
// This will set Include_in_ARR__c flags on all OpportunityLineItems
System.debug('Step 1: Triggering Opportunity First Year Logic...');

// Get all Opportunities that need first year logic processing
List<Opportunity> oppsToUpdate = [
    SELECT Id, Name, Contract_Start_Date__c, Description
    FROM Opportunity 
    WHERE Contract_Start_Date__c != null
    AND StageName = 'Closed Won'
    LIMIT 200
];

System.debug('Found ' + oppsToUpdate.size() + ' Opportunities to process for first year logic');

// Trigger the flows by updating the opportunities (this will fire the After Save flows)
if (!oppsToUpdate.isEmpty()) {
    // Add a dummy field update to trigger the flows
    for (Opportunity opp : oppsToUpdate) {
        opp.Description = (opp.Description != null ? opp.Description : '') + ' [First Year Logic Triggered]';
    }
    update oppsToUpdate;
    System.debug('Updated ' + oppsToUpdate.size() + ' Opportunities to trigger first year logic flows');
}

// 2. EXECUTE CONTRACT REVENUE BATCH
System.debug('Step 2: Starting ContractRevenueBatch...');
ContractRevenueBatch contractBatch = new ContractRevenueBatch();
Id contractBatchId = Database.executeBatch(contractBatch, 200);
System.debug('ContractRevenueBatch started with ID: ' + contractBatchId);

// 3. EXECUTE ACCOUNT ROLLUP BATCH  
System.debug('Step 3: Starting AccountRollupBatch...');
AccountRollupBatch accountBatch = new AccountRollupBatch();
Id accountBatchId = Database.executeBatch(accountBatch, 200);
System.debug('AccountRollupBatch started with ID: ' + accountBatchId);

System.debug('=== POST-DEPLOYMENT PROCESSES INITIATED ===');
System.debug('Monitor batch jobs in Setup > Apex Jobs');
System.debug('Contract Batch ID: ' + contractBatchId);
System.debug('Account Batch ID: ' + accountBatchId);
