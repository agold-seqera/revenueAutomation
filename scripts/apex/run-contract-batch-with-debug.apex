// Run ContractRevenueBatch with specific focus on the problematic contracts
System.debug('=== Running ContractRevenueBatch with Debug Focus ===');

// First, check which contracts should be in the batch query
List<Contract> allContracts = [
    SELECT Id, Name, Status, ARR__c, LastModifiedDate
    FROM Contract 
    ORDER BY LastModifiedDate DESC
    LIMIT 20
];

System.debug('Sample contracts in org (most recently modified):');
for (Contract c : allContracts) {
    if (c.Id == '800Pn00000m35yvIAA') {
        System.debug('  🎯 TARGET: ' + c.Id + ' | ' + c.Name + ' | ARR: ' + c.ARR__c + ' | Modified: ' + c.LastModifiedDate);
    } else {
        System.debug('  - ' + c.Id + ' | ' + c.Name + ' | ARR: ' + c.ARR__c + ' | Modified: ' + c.LastModifiedDate);
    }
}

// Run a smaller batch manually to track exactly what it processes
ContractRevenueBatch batch = new ContractRevenueBatch();

// Get the same query the batch uses
List<Contract> batchContracts = [
    SELECT Id, Name, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
           ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, 
           MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c,
           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                   Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Id = '800Pn00000m35yvIAA'
];

System.debug('\nTarget contract found in batch query: ' + batchContracts.size());

if (batchContracts.size() > 0) {
    Contract target = batchContracts[0];
    System.debug('Target contract details:');
    System.debug('  Status: ' + target.Status);
    System.debug('  Exclude_from_Status_Updates__c: ' + target.Exclude_from_Status_Updates__c);
    System.debug('  Current ARR: ' + target.ARR__c);
    System.debug('  Assets: ' + target.Assets__r.size());
    
    // Manually execute the batch logic on this one contract
    System.debug('\n--- Manual Batch Execution ---');
    List<Contract> testList = new List<Contract>{target};
    batch.execute(null, testList);
    
    // Check the result
    Contract afterBatch = [SELECT Id, ARR__c, LastModifiedDate, LastModifiedBy.Name FROM Contract WHERE Id = :target.Id];
    System.debug('After manual batch execution:');
    System.debug('  ARR: ' + afterBatch.ARR__c + ' (expected: 143200)');
    System.debug('  LastModified: ' + afterBatch.LastModifiedDate + ' by ' + afterBatch.LastModifiedBy.Name);
    
    if (afterBatch.ARR__c == 143200) {
        System.debug('✅ Manual batch execution WORKED!');
    } else {
        System.debug('❌ Manual batch execution FAILED!');
    }
}

System.debug('\n=== Debug Test Complete ===');
