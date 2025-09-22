// Debug why contract 800fJ000007eI3QQAU is being skipped by the batch
System.debug('=== Debugging Why Contract 800fJ000007eI3QQAU Is Skipped ===');

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
Date today = Date.today();

System.debug('Contract: ' + contract.Id);
System.debug('Status: ' + contract.Status);
System.debug('Exclude_from_Status_Updates__c: ' + contract.Exclude_from_Status_Updates__c);
System.debug('Current ARR: ' + contract.ARR__c);
System.debug('Assets: ' + contract.Assets__r.size());

// Step-by-step simulation of processContract logic
Boolean needsUpdate = false;

System.debug('\n--- Step 1: Status Change Check ---');
String newStatus = null;
if (contract.Exclude_from_Status_Updates__c == true) {
    System.debug('❌ Contract excluded from status updates');
} else {
    // Status determination logic
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
        System.debug('❌ No status change needed (Status: ' + contract.Status + ')');
    }
}

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

System.debug('\n--- Step 3: USD Population Check ---');
Boolean shouldPopulateUSD = (String.isBlank(contract.ARR_USD__c) || 
                            String.isBlank(contract.TCV_USD__c) || 
                            String.isBlank(contract.ACV_USD__c) ||
                            String.isBlank(contract.MRR_USD__c) ||
                            String.isBlank(contract.Active_ARR_USD__c));

System.debug('USD Fields populated?');
System.debug('  ARR_USD__c: "' + contract.ARR_USD__c + '" (blank? ' + String.isBlank(contract.ARR_USD__c) + ')');
System.debug('  TCV_USD__c: "' + contract.TCV_USD__c + '" (blank? ' + String.isBlank(contract.TCV_USD__c) + ')');
System.debug('  ACV_USD__c: "' + contract.ACV_USD__c + '" (blank? ' + String.isBlank(contract.ACV_USD__c) + ')');

if (shouldPopulateUSD) {
    needsUpdate = true;
    System.debug('✅ shouldPopulateUSD=true → needsUpdate=true');
} else {
    System.debug('❌ shouldPopulateUSD=false → needsUpdate unchanged');
}

System.debug('\n--- Final Decision ---');
System.debug('FINAL needsUpdate: ' + needsUpdate);

if (needsUpdate) {
    System.debug('✅ Contract SHOULD BE PROCESSED by batch');
    System.debug('🚨 BUT LastModified shows 20:09:44 - it was NOT updated by recent batches!');
    System.debug('🚨 This means either:');
    System.debug('   1. The batch is not querying this contract');
    System.debug('   2. The batch is querying it but processContract is returning null');
    System.debug('   3. There is an exception during processing');
} else {
    System.debug('❌ Contract WOULD BE SKIPPED - this explains why it has wrong values');
    System.debug('🚨 THE NEEDSUPDATE LOGIC IS TOO RESTRICTIVE!');
}

System.debug('\n--- Recommended Fix ---');
System.debug('Per user requirements: ALL Activated contracts should have revenue recalculated');
System.debug('Current logic should work, but may have edge cases or exceptions');
System.debug('Consider: Always process Activated contracts regardless of existing values');

System.debug('\n=== Debug Complete ===');
