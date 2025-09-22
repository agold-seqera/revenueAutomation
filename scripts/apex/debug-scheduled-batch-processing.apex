// Debug why scheduled batches aren't processing contracts with incorrect ARR values
System.debug('=== Debugging Scheduled Batch Processing Issue ===');

// Get contracts that should be processed but have wrong ARR values
List<Contract> contractsWithIssues = [
    SELECT Id, Name, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
           ARR__c, ACV__c, TCV__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                   Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Id IN ('800fJ000007eMFWQA2', '800fJ000007eMZFQA2')
];

System.debug('Found ' + contractsWithIssues.size() + ' contracts to analyze');

Date today = Date.today();

for (Contract contract : contractsWithIssues) {
    System.debug('\n--- Contract: ' + contract.Id + ' ---');
    System.debug('Status: ' + contract.Status);
    System.debug('StartDate: ' + contract.StartDate + ' | EndDate: ' + contract.EndDate);
    System.debug('Exclude_from_Status_Updates__c: ' + contract.Exclude_from_Status_Updates__c);
    System.debug('Current ARR: ' + contract.ARR__c + ' | Current ACV: ' + contract.ACV__c);
    
    // Step 1: Check status change logic
    Boolean needsUpdate = false;
    String newStatus = null;
    
    if (contract.Status == 'Draft' && 
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
    
    // Step 2: Check revenue population logic
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
        System.debug('✅ Revenue population will trigger needsUpdate = true');
    }
    
    // Step 3: Check USD population logic
    Boolean shouldPopulateUSD = (String.isBlank(contract.ARR_USD__c) || 
                                String.isBlank(contract.TCV_USD__c) || 
                                String.isBlank(contract.ACV_USD__c) ||
                                String.isBlank(contract.MRR_USD__c) ||
                                String.isBlank(contract.Active_ARR_USD__c));
    
    System.debug('USD Fields populated? ARR: ' + !String.isBlank(contract.ARR_USD__c) + 
                 ', TCV: ' + !String.isBlank(contract.TCV_USD__c) + 
                 ', ACV: ' + !String.isBlank(contract.ACV_USD__c));
    
    if (shouldPopulateUSD) {
        needsUpdate = true;
        System.debug('✅ USD fields need population - will trigger needsUpdate = true');
    } else {
        System.debug('❌ USD fields already populated - SKIP USD population');
    }
    
    // Final decision
    System.debug('FINAL needsUpdate: ' + needsUpdate);
    
    if (needsUpdate) {
        System.debug('✅ Contract SHOULD BE PROCESSED by scheduled batch');
        
        // Calculate expected ARR from active assets
        Decimal expectedARR = 0;
        Integer activeAssets = 0;
        
        for (Asset asset : contract.Assets__r) {
            if (asset.Start_Date__c <= today && 
                asset.End_Date__c >= today && 
                asset.ProductFamily != 'Professional Service') {
                expectedARR += (asset.ARR__c != null ? asset.ARR__c : 0);
                activeAssets++;
            }
        }
        
        System.debug('Expected ARR from ' + activeAssets + ' active assets: ' + expectedARR);
        System.debug('Current ARR: ' + contract.ARR__c);
        
        if (Math.abs(contract.ARR__c - expectedARR) > 0.01) {
            System.debug('🚨 ARR MISMATCH: Contract shows ' + contract.ARR__c + ' but should be ' + expectedARR);
            System.debug('🚨 This contract has wrong values but would be processed by batch');
        } else {
            System.debug('✅ ARR is correct');
        }
        
    } else {
        System.debug('❌ Contract WOULD BE SKIPPED by scheduled batch');
        System.debug('🚨 THIS IS THE BUG: Contract with wrong ARR would be skipped!');
    }
}

System.debug('\n--- HYPOTHESIS ---');
System.debug('The scheduled batches ARE running and ARE querying these contracts');
System.debug('But the processContract logic is returning null (needsUpdate = false)');
System.debug('This means wrong ARR values persist because the batch skips processing');
System.debug('Manual execution works because it forces the same logic, but...');
System.debug('...there may be a bug where needsUpdate logic is incorrect');

System.debug('\n=== Investigation Complete ===');
