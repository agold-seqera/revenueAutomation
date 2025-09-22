// Test ContractRevenueBatch on the specific problematic contract
System.debug('=== Testing ContractRevenueBatch on Contract 800fJ000007eMFWQA2 ===');

// Get the contract before processing
List<Contract> beforeContracts = [
    SELECT Id, Name, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
           ARR__c, ACV__c, TCV__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           (SELECT Id, Start_Date__c, End_Date__c, ARR__c, Total_Value__c, Total_Price__c,
                   Exchange_Rate__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Id = '800fJ000007eMFWQA2'
];

if (beforeContracts.size() == 0) {
    System.debug('Contract not found!');
    return;
}

Contract beforeContract = beforeContracts[0];
System.debug('BEFORE Batch - Contract: ' + beforeContract.Id);
System.debug('  ARR__c: ' + beforeContract.ARR__c);
System.debug('  ACV__c: ' + beforeContract.ACV__c);
System.debug('  TCV__c: ' + beforeContract.TCV__c);
System.debug('  Active_ARR__c: ' + beforeContract.Active_ARR__c);
System.debug('  Assets: ' + beforeContract.Assets__r.size());

for (Asset asset : beforeContract.Assets__r) {
    System.debug('    Asset: ' + asset.Id + ' | Start: ' + asset.Start_Date__c + ' | End: ' + asset.End_Date__c + ' | ARR: ' + asset.ARR__c);
}

// Run the ContractRevenueBatch
System.debug('\n--- Running ContractRevenueBatch ---');
ContractRevenueBatch batch = new ContractRevenueBatch();
batch.execute(null, beforeContracts);

// Get the contract after processing
List<Contract> afterContracts = [
    SELECT Id, Name, Status, ARR__c, ACV__c, TCV__c, Active_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c
    FROM Contract 
    WHERE Id = '800fJ000007eMFWQA2'
];

Contract afterContract = afterContracts[0];
System.debug('\nAFTER Batch - Contract: ' + afterContract.Id);
System.debug('  ARR__c: ' + afterContract.ARR__c + ' (was: ' + beforeContract.ARR__c + ')');
System.debug('  ACV__c: ' + afterContract.ACV__c + ' (was: ' + beforeContract.ACV__c + ')');
System.debug('  TCV__c: ' + afterContract.TCV__c + ' (was: ' + beforeContract.TCV__c + ')');
System.debug('  Active_ARR__c: ' + afterContract.Active_ARR__c + ' (was: ' + beforeContract.Active_ARR__c + ')');

// Check for changes
Boolean arrChanged = beforeContract.ARR__c != afterContract.ARR__c;
Boolean acvChanged = beforeContract.ACV__c != afterContract.ACV__c;
Boolean tcvChanged = beforeContract.TCV__c != afterContract.TCV__c;

System.debug('\n--- Change Analysis ---');
System.debug('ARR Changed: ' + arrChanged);
System.debug('ACV Changed: ' + acvChanged);
System.debug('TCV Changed: ' + tcvChanged);

if (arrChanged) {
    System.debug('🔄 ARR changed from ' + beforeContract.ARR__c + ' to ' + afterContract.ARR__c);
    Decimal expectedARR = 21452.20; // Only the active asset
    if (Math.abs(afterContract.ARR__c - expectedARR) < 0.01) {
        System.debug('✅ ARR is now CORRECT: ' + afterContract.ARR__c);
    } else {
        System.debug('❌ ARR is still WRONG: ' + afterContract.ARR__c + ' (expected: ' + expectedARR + ')');
    }
} else {
    System.debug('❌ ARR did NOT change - batch may not have processed this contract');
}

System.debug('=== Test Complete ===');
