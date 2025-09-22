// Debug script to trace needsUpdate logic for EUR contract
System.debug('=== DEBUGGING needsUpdate LOGIC ===');

// Simulate the exact logic from ContractRevenueBatch for the EUR contract
Contract testContract = [SELECT Id, Status, StartDate, EndDate, ARR__c, ARR_USD__c 
                        FROM Contract WHERE Id = '800Pn00000k2FjoIAE' LIMIT 1];

System.debug('Contract: ' + testContract.Id + ' | Status: ' + testContract.Status);
System.debug('Current ARR: ' + testContract.ARR__c + ' | Current ARR_USD: ' + testContract.ARR_USD__c);

Boolean needsUpdate = false;
Date today = Date.today();

// Step 1: Status updates
System.debug('=== STEP 1: Status Updates ===');
System.debug('Start Date: ' + testContract.StartDate + ' | End Date: ' + testContract.EndDate);
System.debug('Today: ' + today);

// Simulate determineContractStatus logic
String newStatus = null;
if (testContract.StartDate <= today && testContract.EndDate >= today) {
    if (testContract.Status != 'Activated') {
        newStatus = 'Activated';
    }
}

System.debug('New Status: ' + newStatus);
if (newStatus != null) {
    System.debug('Status change detected - setting needsUpdate = true');
    needsUpdate = true;
} else {
    System.debug('No status change needed');
}

// Step 2: Revenue population check
System.debug('=== STEP 2: Revenue Population ===');
Boolean shouldPopulateRevenue = false;
if (testContract.Status == 'Draft' || testContract.Status == null) {
    if (testContract.ARR__c == null || testContract.ARR__c == 0) {
        shouldPopulateRevenue = true;
    }
} else if (testContract.Status == 'Activated') {
    shouldPopulateRevenue = true;
}

System.debug('shouldPopulateRevenue: ' + shouldPopulateRevenue);
if (shouldPopulateRevenue) {
    System.debug('Revenue recalculation needed - setting needsUpdate = true');
    needsUpdate = true;
} else {
    System.debug('No revenue recalculation needed');
}

// Step 3: USD population check
System.debug('=== STEP 3: USD Population ===');
Boolean shouldPopulateUSD = String.isBlank(testContract.ARR_USD__c);
System.debug('shouldPopulateUSD: ' + shouldPopulateUSD);

if (shouldPopulateUSD) {
    System.debug('USD fields need population');
    // This is where needsUpdate = true should be set for USD-only updates
    System.debug('Current needsUpdate before USD section: ' + needsUpdate);
    
    // NOTE: In the actual batch code, needsUpdate = true is set at line 264 inside the USD section
    needsUpdate = true;
    System.debug('USD formatting would set needsUpdate = true');
} else {
    System.debug('USD fields already populated');
}

System.debug('=== FINAL RESULT ===');
System.debug('needsUpdate: ' + needsUpdate);
System.debug('Would return: ' + (needsUpdate ? 'contract object (UPDATE)' : 'null (NO UPDATE)'));

System.debug('=== END DEBUG ===');
