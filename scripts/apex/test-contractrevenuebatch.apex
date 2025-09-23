// Test our ContractRevenueBatch on the test contract we just created

// Find the contract we just created (it should be the newest USD contract with ARR = 100000)
List<Contract> testContracts = [SELECT Id, ContractNumber, CurrencyIsoCode, ARR__c, ARR_USD__c, ACV__c, ACV_USD__c 
                               FROM Contract 
                               WHERE ARR__c = 100000 AND CurrencyIsoCode = 'USD' 
                               ORDER BY CreatedDate DESC LIMIT 1];

if (!testContracts.isEmpty()) {
    Contract testContract = testContracts[0];
    
    System.debug('=== BEFORE CONTRACTREVENUEBATCH ===');
    System.debug('Contract: ' + testContract.ContractNumber);
    System.debug('ARR__c: ' + testContract.ARR__c);
    System.debug('ARR_USD__c: ' + testContract.ARR_USD__c);
    System.debug('ACV__c: ' + testContract.ACV__c);
    System.debug('ACV_USD__c: ' + testContract.ACV_USD__c);
    
    // Run ContractRevenueBatch.execute directly
    ContractRevenueBatch batch = new ContractRevenueBatch();
    List<Contract> contracts = new List<Contract>{testContract};
    
    System.debug('=== RUNNING CONTRACTREVENUEBATCH ===');
    batch.execute(null, contracts);
    
    // Query the contract again to see if it was updated
    Contract updatedContract = [SELECT Id, ARR__c, ARR_USD__c, ACV__c, ACV_USD__c, TCV_USD__c 
                               FROM Contract WHERE Id = :testContract.Id];
    
    System.debug('=== AFTER CONTRACTREVENUEBATCH ===');
    System.debug('ARR__c: ' + updatedContract.ARR__c);
    System.debug('ARR_USD__c: ' + updatedContract.ARR_USD__c);
    System.debug('ACV__c: ' + updatedContract.ACV__c);
    System.debug('ACV_USD__c: ' + updatedContract.ACV_USD__c);
    System.debug('TCV_USD__c: ' + updatedContract.TCV_USD__c);
    
    // Check if USD fields were aligned
    if (updatedContract.ARR_USD__c == '$100,000.00') {
        System.debug('✅ SUCCESS: ARR_USD__c was correctly aligned!');
    } else {
        System.debug('❌ ISSUE: ARR_USD__c was NOT aligned. Expected $100,000.00, got: ' + updatedContract.ARR_USD__c);
    }
} else {
    System.debug('No test contract found');
}
