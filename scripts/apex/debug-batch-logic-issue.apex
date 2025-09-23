// Debug why the batch logic isn't fixing the USD field issues
System.debug('=== DEBUGGING BATCH LOGIC ISSUE ===');

// The issue: We manually updated records instead of fixing the batch code
// Let's analyze what the batch SHOULD be doing vs what it IS doing

// Check the problematic contracts
List<Contract> problemContracts = [
    SELECT Id, ContractNumber, Status, CurrencyIsoCode,
           ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c, Incremental_ARR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, 
           MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c, Incremental_ARR_USD_Reporting__c,
           StartDate, EndDate, Exclude_from_Status_Updates__c,
           (SELECT Id, Status, ARR__c, MRR__c, Total_Value__c, Total_Price__c,
                   ProductFamily, Include_in_ARR_Override__c,
                   Start_Date__c, End_Date__c
            FROM Assets__r)
    FROM Contract 
    WHERE ContractNumber IN ('00000365', '00000654', '00000710')
    ORDER BY ContractNumber
];

Date today = Date.today();

System.debug('\n🔍 ANALYZING BATCH LOGIC FOR EACH CONTRACT:');

for (Contract contract : problemContracts) {
    System.debug('\n--- Contract ' + contract.ContractNumber + ' (' + contract.Status + ') ---');
    System.debug('Current Values:');
    System.debug('  ARR: ' + contract.ARR__c + ' | USD: ' + contract.ARR_USD__c + ' | Reporting: ' + contract.ARR_USD_Reporting__c);
    
    // Simulate the batch logic
    System.debug('\nBatch Logic Analysis:');
    
    // Step 1: Status determination
    Boolean needsStatusUpdate = false;
    String newStatus = null;
    
    if (contract.Exclude_from_Status_Updates__c != true) {
        if ((contract.Status == 'Draft' || contract.Status == null) &&
            contract.StartDate <= today && 
            contract.EndDate >= today) {
            newStatus = 'Activated';
            needsStatusUpdate = true;
            System.debug('  📋 Status: Draft/null → Activated (within date range)');
        } else if (contract.StartDate <= today && 
                   contract.EndDate >= today && 
                   contract.Status != 'Activated') {
            newStatus = 'Activated';
            needsStatusUpdate = true;
            System.debug('  📋 Status: ' + contract.Status + ' → Activated (within date range)');
        } else if (contract.EndDate < today && 
                   contract.Status != 'Expired') {
            newStatus = 'Expired';
            needsStatusUpdate = true;
            System.debug('  📋 Status: ' + contract.Status + ' → Expired (past end date)');
        } else {
            System.debug('  📋 Status: No change (' + contract.Status + ')');
        }
    } else {
        System.debug('  📋 Status: Excluded from updates');
    }
    
    // Step 2: Revenue calculation decision
    Boolean shouldPopulateRevenue = false;
    String currentStatus = newStatus != null ? newStatus : contract.Status;
    
    if (currentStatus == 'Draft' || currentStatus == null) {
        if (contract.ARR__c == null || contract.ARR__c == 0) {
            shouldPopulateRevenue = true;
            System.debug('  💰 Revenue: Will populate (Draft with empty revenue)');
        } else {
            System.debug('  💰 Revenue: Will NOT populate (Draft with existing revenue: ' + contract.ARR__c + ')');
            System.debug('    ❌ THIS IS THE PROBLEM! Draft contracts with wrong values won\'t be fixed!');
        }
    } else if (currentStatus == 'Activated') {
        shouldPopulateRevenue = true;
        System.debug('  💰 Revenue: Will populate (Activated - always recalculate)');
    } else {
        System.debug('  💰 Revenue: Will NOT populate (Expired - preserve historical)');
    }
    
    // Step 3: Calculate what the revenue SHOULD be
    if (shouldPopulateRevenue) {
        Decimal expectedARR = 0;
        Decimal expectedACV = 0;
        Decimal expectedTCV = 0;
        Decimal expectedActiveARR = 0;
        
        System.debug('  🔧 Asset Analysis:');
        for (Asset asset : contract.Assets__r) {
            System.debug('    Asset ' + asset.Id + ': Status=' + asset.Status + ', ARR=' + asset.ARR__c + ', ProductFamily=' + asset.ProductFamily);
            
            // TCV includes all assets
            expectedTCV += (asset.Total_Value__c != null ? asset.Total_Value__c : 0);
            
            // ARR/ACV only includes active assets
            Boolean isActive = (asset.Start_Date__c <= today && 
                               asset.End_Date__c >= today && 
                               asset.ProductFamily == 'Software Subscriptions' &&
                               asset.Include_in_ARR_Override__c != true);
            
            if (isActive) {
                expectedARR += (asset.ARR__c != null ? asset.ARR__c : 0);
                expectedActiveARR += (asset.ARR__c != null ? asset.ARR__c : 0);
            }
        }
        
        expectedACV = expectedARR; // ACV = ARR for annual contracts
        
        System.debug('  📊 Expected Values:');
        System.debug('    ARR: ' + expectedARR + ' (current: ' + contract.ARR__c + ')');
        System.debug('    ACV: ' + expectedACV + ' (current: ' + contract.ACV__c + ')');
        System.debug('    TCV: ' + expectedTCV + ' (current: ' + contract.TCV__c + ')');
        System.debug('    Active ARR: ' + expectedActiveARR + ' (current: ' + contract.Active_ARR__c + ')');
        
        if (contract.ARR__c != expectedARR) {
            System.debug('    ❌ ARR MISMATCH: Batch should fix this');
        } else {
            System.debug('    ✅ ARR CORRECT: No change needed');
        }
    }
    
    // Final decision
    Boolean wouldUpdate = needsStatusUpdate || shouldPopulateRevenue;
    System.debug('  🎯 Final Decision: ' + (wouldUpdate ? 'WOULD UPDATE' : 'WOULD SKIP'));
    
    if (!wouldUpdate) {
        System.debug('    ❌ THIS IS WHY THE BATCH ISN\'T FIXING THE ISSUE!');
    }
}

System.debug('\n🎯 ROOT CAUSE ANALYSIS:');
System.debug('The batch logic has a flaw in the revenue population decision.');
System.debug('Draft contracts with WRONG values (not empty) are being skipped.');
System.debug('We need to fix the batch logic to detect and correct wrong values.');

System.debug('\n=== DEBUG COMPLETE ===');
