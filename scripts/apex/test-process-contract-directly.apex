// Test the processContract method directly on the problematic contract
System.debug('=== Testing processContract Method Directly ===');

// Get the exact contract data as the batch would
List<Contract> contracts = [
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

if (contracts.size() == 0) {
    System.debug('❌ Contract not found');
    return;
}

Contract contract = contracts[0];
System.debug('BEFORE processing:');
System.debug('  ARR__c: ' + contract.ARR__c + ' (should be 143200)');
System.debug('  ACV__c: ' + contract.ACV__c);
System.debug('  Active_ARR__c: ' + contract.Active_ARR__c);
System.debug('  ARR_USD__c: ' + contract.ARR_USD__c);

// Manually execute the processContract logic
ContractRevenueBatch batch = new ContractRevenueBatch();

// We need to call the private method, so let's simulate it
Date today = Date.today();
Boolean needsUpdate = false;

// Status check
if (contract.Status == 'Activated') {
    // No status change needed
}

// Revenue population for Activated contracts
Boolean shouldPopulateRevenue = (contract.Status == 'Activated');
System.debug('shouldPopulateRevenue: ' + shouldPopulateRevenue);

if (shouldPopulateRevenue) {
    needsUpdate = true;
    
    // Reset revenue fields
    contract.ARR__c = 0;
    contract.Active_ARR__c = 0;
    contract.ACV__c = 0;
    contract.MRR__c = 0;
    contract.TCV__c = 0;
    
    System.debug('Revenue fields reset to 0');
    
    // Process assets
    for (Asset asset : contract.Assets__r) {
        // TCV calculation for ALL assets
        contract.TCV__c += asset.Total_Value__c != null ? asset.Total_Value__c : 0;
        
        // ARR/ACV calculation for ACTIVE assets only
        if (asset.Start_Date__c <= today && 
            asset.End_Date__c >= today && 
            asset.ProductFamily != 'Professional Service') {
            
            contract.ARR__c += asset.ARR__c != null ? asset.ARR__c : 0;
            contract.ACV__c += asset.Total_Price__c != null ? asset.Total_Price__c : 0;
            contract.Active_ARR__c += asset.ARR__c != null ? asset.ARR__c : 0;
            
            System.debug('  Added asset ' + asset.Id + ': ARR=' + asset.ARR__c + ', TCV=' + asset.Total_Value__c);
        } else {
            System.debug('  Skipped asset ' + asset.Id + ': ARR=' + asset.ARR__c + ' (not active or Professional Service)');
        }
    }
    
    // Final MRR calculation
    contract.MRR__c = contract.ARR__c != null ? contract.ARR__c / 12 : 0;
    
    // Incremental ARR calculation
    if (contract.Previous_ARR__c == null) {
        contract.Incremental_ARR__c = contract.ARR__c != null ? contract.ARR__c : 0;
    } else {
        contract.Incremental_ARR__c = (contract.ARR__c != null ? contract.ARR__c : 0) - contract.Previous_ARR__c;
    }
}

System.debug('AFTER processing (needsUpdate=' + needsUpdate + '):');
System.debug('  ARR__c: ' + contract.ARR__c + ' (expected: 143200)');
System.debug('  ACV__c: ' + contract.ACV__c);
System.debug('  TCV__c: ' + contract.TCV__c);
System.debug('  Active_ARR__c: ' + contract.Active_ARR__c);
System.debug('  MRR__c: ' + contract.MRR__c);

if (needsUpdate) {
    System.debug('\n--- Attempting DML Update ---');
    try {
        update contract;
        System.debug('✅ Contract updated successfully!');
        
        // Verify the update
        Contract updatedContract = [SELECT Id, ARR__c, LastModifiedDate, LastModifiedBy.Name FROM Contract WHERE Id = :contract.Id];
        System.debug('Verification: ARR__c=' + updatedContract.ARR__c + ', LastModified=' + updatedContract.LastModifiedDate + ' by ' + updatedContract.LastModifiedBy.Name);
        
    } catch (Exception e) {
        System.debug('❌ DML Error: ' + e.getMessage());
        System.debug('❌ Stack Trace: ' + e.getStackTraceString());
    }
} else {
    System.debug('❌ needsUpdate=false, contract would be skipped');
}

System.debug('\n=== Direct Processing Test Complete ===');
