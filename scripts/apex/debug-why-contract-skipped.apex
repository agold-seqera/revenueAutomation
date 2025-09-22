// Debug why contract 800fJ000007eMFWQA2 was being skipped by scheduled batches
System.debug('=== Debugging Why Contract Was Skipped ===');

// Get the contract
List<Contract> contracts = [
    SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
           ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                   Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Id = '800fJ000007eMFWQA2'
];

if (contracts.size() == 0) {
    System.debug('Contract not found!');
    return;
}

Contract contract = contracts[0];
Date today = Date.today();

System.debug('Contract: ' + contract.Id);
System.debug('Status: ' + contract.Status);
System.debug('StartDate: ' + contract.StartDate);
System.debug('EndDate: ' + contract.EndDate);
System.debug('Exclude_from_Status_Updates__c: ' + contract.Exclude_from_Status_Updates__c);
System.debug('Today: ' + today);

// Simulate the processContract logic step by step
Boolean needsUpdate = false;

System.debug('\n--- Step 1: Status Updates ---');
// Step 1: Handle status updates (including Draft → Activated)
String newStatus = null;

// Check if this is Draft and should be activated
if (contract.Status == 'Draft' && 
    contract.StartDate <= today && 
    contract.EndDate >= today) {
    newStatus = 'Activated';
    System.debug('Rule: Draft should be Activated');
}

// Check if this should be Activated (within dates but not already Activated)
if (contract.StartDate <= today && 
    contract.EndDate >= today && 
    contract.Status != 'Activated') {
    newStatus = 'Activated';
    System.debug('Rule: Should be Activated (within dates)');
}

// Check if this should be Expired
if (contract.EndDate < today && 
    contract.Status != 'Expired') {
    newStatus = 'Expired';
    System.debug('Rule: Should be Expired (past end date)');
}

if (newStatus != null) {
    System.debug('✅ Status change needed: ' + contract.Status + ' → ' + newStatus);
    needsUpdate = true;
} else {
    System.debug('❌ No status change needed');
}

System.debug('\n--- Step 2: Revenue Field Population Logic ---');
Boolean shouldPopulateRevenue = false;

if (contract.Status == 'Draft' || contract.Status == null) {
    // Legacy Draft/null: Only if revenue fields are empty
    if (contract.ARR__c == null || contract.ARR__c == 0) {
        shouldPopulateRevenue = true;
        System.debug('✅ Draft/null with empty revenue - SHOULD populate');
    } else {
        System.debug('❌ Draft/null with existing revenue - SKIP population');
    }
} else if (contract.Status == 'Activated') {
    // Activated contracts: Always recalculate (automation managed)
    shouldPopulateRevenue = true;
    System.debug('✅ Activated contract - SHOULD populate (always recalculate)');
} else {
    System.debug('❌ Other status (' + contract.Status + ') - SKIP revenue population');
}

if (shouldPopulateRevenue) {
    needsUpdate = true;
    System.debug('✅ Revenue population will set needsUpdate = true');
}

System.debug('\n--- Step 3: USD Field Population Logic ---');
Boolean shouldPopulateUSD = (String.isBlank(contract.ARR_USD__c) || 
                            String.isBlank(contract.TCV_USD__c) || 
                            String.isBlank(contract.ACV_USD__c) ||
                            String.isBlank(contract.MRR_USD__c) ||
                            String.isBlank(contract.Active_ARR_USD__c));

System.debug('ARR_USD__c: "' + contract.ARR_USD__c + '" (blank: ' + String.isBlank(contract.ARR_USD__c) + ')');
System.debug('TCV_USD__c: "' + contract.TCV_USD__c + '" (blank: ' + String.isBlank(contract.TCV_USD__c) + ')');
System.debug('ACV_USD__c: "' + contract.ACV_USD__c + '" (blank: ' + String.isBlank(contract.ACV_USD__c) + ')');
System.debug('MRR_USD__c: "' + contract.MRR_USD__c + '" (blank: ' + String.isBlank(contract.MRR_USD__c) + ')');
System.debug('Active_ARR_USD__c: "' + contract.Active_ARR_USD__c + '" (blank: ' + String.isBlank(contract.Active_ARR_USD__c) + ')');

if (shouldPopulateUSD) {
    needsUpdate = true;
    System.debug('✅ USD fields need population - SHOULD set needsUpdate = true');
} else {
    System.debug('❌ USD fields already populated - SKIP USD population');
}

System.debug('\n--- Final Decision ---');
System.debug('needsUpdate: ' + needsUpdate);

if (needsUpdate) {
    System.debug('✅ Contract WOULD BE PROCESSED (needsUpdate = true)');
} else {
    System.debug('❌ Contract WOULD BE SKIPPED (needsUpdate = false)');
}

System.debug('\n--- The Problem ---');
System.debug('This contract was showing ARR = £42,904.40 (both assets)');
System.debug('But shouldPopulateRevenue = ' + shouldPopulateRevenue + ' for Status = ' + contract.Status);
System.debug('If shouldPopulateRevenue = false, the asset loop never runs to recalculate ARR');
System.debug('This means wrong ARR values persist until something forces needsUpdate = true');

System.debug('=== Debug Complete ===');
