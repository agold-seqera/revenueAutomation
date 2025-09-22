// Test the updated ContractRevenueBatch on the problematic contract
System.debug('=== Testing Updated Batch on Contract 800fJ000007eI3QQAU ===');

// Get the contract with current wrong values
List<Contract> testContract = [
    SELECT Id, Name, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
           ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, 
           MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c,
           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                   Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Id = '800fJ000007eI3QQAU'
];

if (testContract.size() == 0) {
    System.debug('❌ Contract not found');
    return;
}

Contract contract = testContract[0];
System.debug('BEFORE Updated Batch:');
System.debug('  Contract: ' + contract.Id);
System.debug('  Status: ' + contract.Status);
System.debug('  ARR__c: ' + contract.ARR__c + ' (should be 573,000)');
System.debug('  ACV__c: ' + contract.ACV__c + ' (should be 573,000)');
System.debug('  Active_ARR__c: ' + contract.Active_ARR__c + ' (should be 573,000)');
System.debug('  TCV__c: ' + contract.TCV__c + ' (should be 1,146,000)');

// Calculate expected values
Date today = Date.today();
Decimal expectedActiveARR = 0;
Integer activeAssets = 0;

for (Asset asset : contract.Assets__r) {
    System.debug('Asset ' + asset.Id + ': ' + asset.Start_Date__c + ' to ' + asset.End_Date__c + ' | ARR: ' + asset.ARR__c);
    if (asset.Start_Date__c <= today && 
        asset.End_Date__c >= today && 
        asset.ProductFamily != 'Professional Service') {
        expectedActiveARR += (asset.ARR__c != null ? asset.ARR__c : 0);
        activeAssets++;
        System.debug('  ✅ ACTIVE: Contributing ' + asset.ARR__c + ' to ARR');
    } else {
        System.debug('  ❌ NOT ACTIVE: Not contributing to ARR');
    }
}

System.debug('Expected Active ARR: ' + expectedActiveARR + ' (from ' + activeAssets + ' active assets)');

// Run the updated ContractRevenueBatch
System.debug('\n--- Running Updated ContractRevenueBatch ---');
ContractRevenueBatch batch = new ContractRevenueBatch();
List<Contract> contractList = new List<Contract>{contract};
batch.execute(null, contractList);

// Check results
Contract updatedContract = [
    SELECT Id, ARR__c, ACV__c, TCV__c, Active_ARR__c, MRR__c, LastModifiedDate, LastModifiedBy.Name 
    FROM Contract 
    WHERE Id = :contract.Id
];

System.debug('\nAFTER Updated Batch:');
System.debug('  ARR__c: ' + updatedContract.ARR__c + ' (expected: ' + expectedActiveARR + ')');
System.debug('  ACV__c: ' + updatedContract.ACV__c + ' (expected: ' + expectedActiveARR + ')');
System.debug('  Active_ARR__c: ' + updatedContract.Active_ARR__c + ' (expected: ' + expectedActiveARR + ')');
System.debug('  TCV__c: ' + updatedContract.TCV__c + ' (expected: 1,146,000)');
System.debug('  LastModified: ' + updatedContract.LastModifiedDate + ' by ' + updatedContract.LastModifiedBy.Name);

// Validate results
Boolean arrFixed = Math.abs(updatedContract.ARR__c - expectedActiveARR) < 0.01;
Boolean acvFixed = Math.abs(updatedContract.ACV__c - expectedActiveARR) < 0.01;
Boolean activeArrFixed = Math.abs(updatedContract.Active_ARR__c - expectedActiveARR) < 0.01;
Boolean tcvCorrect = Math.abs(updatedContract.TCV__c - 1146000) < 0.01;

System.debug('\n--- VALIDATION RESULTS ---');
System.debug('✅ ARR Fixed: ' + arrFixed);
System.debug('✅ ACV Fixed: ' + acvFixed);
System.debug('✅ Active_ARR Fixed: ' + activeArrFixed);
System.debug('✅ TCV Correct: ' + tcvCorrect);

if (arrFixed && acvFixed && activeArrFixed && tcvCorrect) {
    System.debug('🎉 SUCCESS: Updated batch FIXED all revenue calculation issues!');
    System.debug('The batch logic is now working correctly for Activated contracts.');
} else {
    System.debug('❌ PARTIAL FIX: Some issues remain - batch logic needs further investigation');
}

System.debug('\n=== Test Complete ===');
