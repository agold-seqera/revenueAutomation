// Test processing of the single EUR contract in isolation
System.debug('=== TESTING SINGLE CONTRACT BATCH PROCESSING ===');

// Create a mini-batch to process just this one contract
List<Contract> testContracts = [SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
                                       ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
                                       ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
                                       (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                                               Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
                                        FROM Assets__r 
                                        WHERE Exclude_from_Status_Updates__c = false)
                               FROM Contract 
                               WHERE Id = '800Pn00000k2FjoIAE'];

System.debug('Found contracts: ' + testContracts.size());

if (testContracts.size() > 0) {
    Contract testContract = testContracts[0];
    System.debug('Processing contract: ' + testContract.Id);
    System.debug('  Status: ' + testContract.Status);
    System.debug('  Assets count: ' + testContract.Assets__r.size());
    System.debug('  Current ARR_USD: ' + testContract.ARR_USD__c);
    
    // Manually instantiate and call the batch method
    ContractRevenueBatch batch = new ContractRevenueBatch();
    List<Contract> contractsToUpdate = new List<Contract>();
    
    try {
        // This simulates the execute method logic
        for (Contract contract : testContracts) {
            Contract processedContract = batch.processContract(contract, Date.today());
            if (processedContract != null) {
                contractsToUpdate.add(processedContract);
                System.debug('Contract marked for update: ' + processedContract.Id);
                System.debug('  New ARR_USD: ' + processedContract.ARR_USD__c);
                System.debug('  New TCV_USD: ' + processedContract.TCV_USD__c);
            } else {
                System.debug('Contract NOT marked for update: ' + contract.Id);
            }
        }
        
        System.debug('Contracts to update: ' + contractsToUpdate.size());
        
        if (contractsToUpdate.size() > 0) {
            System.debug('Attempting database update...');
            update contractsToUpdate;
            System.debug('Update successful!');
            
            // Verify the update
            Contract updatedContract = [SELECT Id, ARR_USD__c, TCV_USD__c FROM Contract WHERE Id = '800Pn00000k2FjoIAE' LIMIT 1];
            System.debug('Post-update verification:');
            System.debug('  ARR_USD: ' + updatedContract.ARR_USD__c);
            System.debug('  TCV_USD: ' + updatedContract.TCV_USD__c);
        } else {
            System.debug('No contracts need updating');
        }
        
    } catch (Exception e) {
        System.debug('Error during processing: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
    }
} else {
    System.debug('No contracts found');
}

System.debug('=== END TEST ===');
