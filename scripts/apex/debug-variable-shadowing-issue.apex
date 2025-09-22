// Debug the variable shadowing issue that might affect scheduled vs manual execution
System.debug('=== Debugging Variable Shadowing Issue ===');

// Get the contract data
Contract testContract = [
    SELECT Id, Status, ARR__c, ACV__c, ARR_USD__c, ACV_USD__c,
           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                   Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Id = '800fJ000007eNJeQAM'
];

System.debug('Testing variable shadowing in processContract logic...');
System.debug('Contract ARR__c before: ' + testContract.ARR__c);
System.debug('Contract ACV__c before: ' + testContract.ACV__c);

Date today = Date.today();

// Simulate the exact logic from ContractRevenueBatch.processContract()
// Step 1: Reset revenue fields (lines 127-131)
testContract.ARR__c = 0;
testContract.ACV__c = 0;
testContract.TCV__c = 0;

System.debug('After reset - ARR__c: ' + testContract.ARR__c + ', ACV__c: ' + testContract.ACV__c);

// Step 2: First variable declaration (lines 135-139)
Decimal varARR_Total = 0;
Decimal varACV_Total = 0;
Decimal varTCV_Total = 0;
Decimal varActiveARR_Total = 0;
Decimal varMRR_Total = 0;

System.debug('First variables declared - varARR_Total: ' + varARR_Total);

// Step 3: First asset loop (lines 144-186) - DIRECT field modification
for (Asset asset : testContract.Assets__r) {
    // TCV calculation
    testContract.TCV__c += asset.Total_Value__c != null ? asset.Total_Value__c : 0;
    
    // Active asset check
    if (asset.Start_Date__c <= today && 
        asset.End_Date__c >= today && 
        asset.ProductFamily != 'Professional Service') {
        
        // DIRECT field modification (this should work)
        testContract.ARR__c += asset.ARR__c != null ? asset.ARR__c : 0;
        testContract.ACV__c += asset.Total_Price__c != null ? asset.Total_Price__c : 0;
        
        System.debug('Active asset ' + asset.Id + ' - Adding ARR: ' + asset.ARR__c + ', Total_Price: ' + asset.Total_Price__c);
        System.debug('  Contract ARR__c now: ' + testContract.ARR__c);
        System.debug('  Contract ACV__c now: ' + testContract.ACV__c);
    }
}

System.debug('After first loop - ARR__c: ' + testContract.ARR__c + ', ACV__c: ' + testContract.ACV__c);

// Step 4: Check if USD fields are blank (this determines if second loop runs)
Boolean shouldPopulateUSD = (String.isBlank(testContract.ARR_USD__c) || 
                            String.isBlank(testContract.ACV_USD__c));

System.debug('shouldPopulateUSD: ' + shouldPopulateUSD);
System.debug('ARR_USD__c is blank: ' + String.isBlank(testContract.ARR_USD__c));
System.debug('ACV_USD__c is blank: ' + String.isBlank(testContract.ACV_USD__c));

if (shouldPopulateUSD) {
    System.debug('USD fields are blank - second loop WILL run');
    
    // Step 5: VARIABLE SHADOWING (lines 197-201)
    Decimal varARR_Total = 0;  // SHADOWS the original variable!
    Decimal varACV_Total = 0;  // SHADOWS the original variable!
    
    System.debug('SHADOWED variables declared - varARR_Total: ' + varARR_Total);
    System.debug('Original variables are now inaccessible!');
    
} else {
    System.debug('USD fields are populated - second loop will NOT run');
    System.debug('No variable shadowing occurs');
}

System.debug('\nFinal contract values:');
System.debug('  ARR__c: ' + testContract.ARR__c + ' (should be 300000)');
System.debug('  ACV__c: ' + testContract.ACV__c + ' (should be 300000)');

// The key insight: Variable shadowing doesn't affect the main revenue fields
// because they're calculated via DIRECT field assignment, not via the variables
System.debug('\n--- ANALYSIS ---');
System.debug('✅ Variable shadowing does NOT affect ARR__c/ACV__c calculation');
System.debug('✅ Main revenue fields use direct assignment (contract.ARR__c +=)');
System.debug('❌ Variable shadowing DOES affect USD reporting fields');
System.debug('🔍 The issue must be elsewhere...');

System.debug('\n=== Variable Shadowing Debug Complete ===');
