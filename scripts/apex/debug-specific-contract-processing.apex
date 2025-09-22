// Debug why specific contract 800Pn00000m35yvIAA isn't being updated
System.debug('=== Debugging Specific Contract Processing ===');

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
    WHERE Id = '800Pn00000m35yvIAA'
];

if (testContract.size() == 0) {
    System.debug('❌ Contract not found');
    return;
}

Contract contract = testContract[0];
System.debug('Contract: ' + contract.Id + ' | Status: ' + contract.Status);
System.debug('Current ARR: ' + contract.ARR__c + ' (should be 143200)');
System.debug('USD Fields: ARR=' + contract.ARR_USD__c + ', ACV=' + contract.ACV_USD__c + ', TCV=' + contract.TCV_USD__c);

Date today = Date.today();

// Simulate the processContract logic step by step
Boolean needsUpdate = false;

// Step 1: Status change check
System.debug('\n--- Step 1: Status Change Check ---');
String newStatus = null;
if ((contract.Status == 'Draft' || contract.Status == null) &&
    contract.StartDate <= today && 
    contract.EndDate >= today) {
    newStatus = 'Activated';
} else if (contract.StartDate <= today && 
           contract.EndDate >= today && 
           contract.Status != 'Activated') {
    newStatus = 'Activated';
} else if (contract.EndDate < today && 
           contract.Status != 'Expired') {
    newStatus = 'Expired';
}

if (newStatus != null) {
    needsUpdate = true;
    System.debug('✅ Status change needed: ' + contract.Status + ' → ' + newStatus);
} else {
    System.debug('❌ No status change needed');
}

// Step 2: Revenue population check
System.debug('\n--- Step 2: Revenue Population Check ---');
Boolean shouldPopulateRevenue = false;
if (contract.Status == 'Draft' || contract.Status == null) {
    if (contract.ARR__c == null || contract.ARR__c == 0) {
        shouldPopulateRevenue = true;
        System.debug('✅ Draft/null with empty revenue - SHOULD populate');
    } else {
        System.debug('❌ Draft/null with existing revenue - SKIP population');
    }
} else if (contract.Status == 'Activated') {
    shouldPopulateRevenue = true;
    System.debug('✅ Activated contract - SHOULD populate (always recalculate)');
} else {
    System.debug('❌ Other status (' + contract.Status + ') - SKIP revenue population');
}

if (shouldPopulateRevenue) {
    needsUpdate = true;
    System.debug('✅ shouldPopulateRevenue=true → needsUpdate=true');
} else {
    System.debug('❌ shouldPopulateRevenue=false → needsUpdate unchanged');
}

// Step 3: USD population check
System.debug('\n--- Step 3: USD Population Check ---');
Boolean shouldPopulateUSD = (String.isBlank(contract.ARR_USD__c) || 
                            String.isBlank(contract.TCV_USD__c) || 
                            String.isBlank(contract.ACV_USD__c) ||
                            String.isBlank(contract.MRR_USD__c) ||
                            String.isBlank(contract.Active_ARR_USD__c));

System.debug('USD Fields Check:');
System.debug('  ARR_USD__c blank? ' + String.isBlank(contract.ARR_USD__c) + ' (value: "' + contract.ARR_USD__c + '")');
System.debug('  TCV_USD__c blank? ' + String.isBlank(contract.TCV_USD__c) + ' (value: "' + contract.TCV_USD__c + '")');
System.debug('  ACV_USD__c blank? ' + String.isBlank(contract.ACV_USD__c) + ' (value: "' + contract.ACV_USD__c + '")');

if (shouldPopulateUSD) {
    needsUpdate = true;
    System.debug('✅ shouldPopulateUSD=true → needsUpdate=true');
} else {
    System.debug('❌ shouldPopulateUSD=false → needsUpdate unchanged');
}

// Final decision
System.debug('\n--- Final Decision ---');
System.debug('FINAL needsUpdate: ' + needsUpdate);

if (needsUpdate) {
    System.debug('✅ Contract SHOULD BE PROCESSED');
    
    // Calculate expected ARR manually
    Decimal expectedARR = 0;
    for (Asset asset : contract.Assets__r) {
        if (asset.Start_Date__c <= today && 
            asset.End_Date__c >= today && 
            asset.ProductFamily != 'Professional Service') {
            expectedARR += (asset.ARR__c != null ? asset.ARR__c : 0);
            System.debug('  Including asset ' + asset.Id + ': ARR=' + asset.ARR__c + ' (Family: ' + asset.ProductFamily + ')');
        } else {
            System.debug('  Excluding asset ' + asset.Id + ': ARR=' + asset.ARR__c + ' (Family: ' + asset.ProductFamily + ', Status: not active)');
        }
    }
    System.debug('Expected ARR: ' + expectedARR);
    
} else {
    System.debug('❌ Contract WOULD BE SKIPPED - THIS IS THE BUG!');
}

System.debug('\n=== Debug Complete ===');
