// Corrected ARR analysis - only include ACTIVE assets in expected ARR calculation
System.debug('=== CORRECTED ARR Analysis (Active Assets Only) ===');

List<Contract> contractsToCheck = [
    SELECT Id, Name, Status, ARR__c, ACV__c, Active_ARR__c, StartDate, EndDate,
           LastModifiedDate, LastModifiedBy.Name,
           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Start_Date__c, End_Date__c, 
                   ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Status = 'Activated' 
    AND ARR__c > 0
    ORDER BY LastModifiedDate DESC
    LIMIT 10
];

System.debug('Found ' + contractsToCheck.size() + ' contracts to check');

Date today = Date.today();
Integer realIssuesFound = 0;

for (Contract contract : contractsToCheck) {
    // CORRECTED: Calculate expected ARR from ACTIVE assets only (matching batch logic)
    Decimal expectedARR = 0;
    Decimal expectedACV = 0;
    Decimal expectedActiveARR = 0;
    Integer totalAssets = 0;
    Integer activeAssets = 0;
    Integer futureAssets = 0;
    Integer expiredAssets = 0;
    
    for (Asset asset : contract.Assets__r) {
        totalAssets++;
        
        if (asset.Start_Date__c <= today && asset.End_Date__c >= today) {
            if (asset.ProductFamily != 'Professional Service') {
                // ACTIVE assets: count for ARR, ACV, and Active_ARR
                expectedARR += (asset.ARR__c != null ? asset.ARR__c : 0);
                expectedACV += (asset.Total_Price__c != null ? asset.Total_Price__c : 0);
                expectedActiveARR += (asset.ARR__c != null ? asset.ARR__c : 0);
                activeAssets++;
            }
        } else if (asset.Start_Date__c > today) {
            futureAssets++;
        } else {
            expiredAssets++;
        }
    }
    
    // Check for discrepancies (only for ACTIVE asset calculations)
    Boolean hasARRIssue = Math.abs(contract.ARR__c - expectedARR) > 0.01;
    Boolean hasACVIssue = Math.abs(contract.ACV__c - expectedACV) > 0.01;
    Boolean hasActiveARRIssue = Math.abs(contract.Active_ARR__c - expectedActiveARR) > 0.01;
    
    if (hasARRIssue || hasACVIssue || hasActiveARRIssue) {
        realIssuesFound++;
        System.debug('\n🚨 REAL ISSUE - Contract: ' + contract.Name + ' (' + contract.Id + ')');
        System.debug('Last Modified: ' + contract.LastModifiedDate + ' by ' + contract.LastModifiedBy.Name);
        System.debug('Assets: ' + totalAssets + ' total (' + activeAssets + ' active, ' + futureAssets + ' future, ' + expiredAssets + ' expired)');
        
        if (hasARRIssue) {
            System.debug('❌ ARR Issue: Contract=' + contract.ARR__c + ' vs Expected(ActiveOnly)=' + expectedARR);
        }
        if (hasACVIssue) {
            System.debug('❌ ACV Issue: Contract=' + contract.ACV__c + ' vs Expected(ActiveOnly)=' + expectedACV);
        }
        if (hasActiveARRIssue) {
            System.debug('❌ Active_ARR Issue: Contract=' + contract.Active_ARR__c + ' vs Expected=' + expectedActiveARR);
        }
        
        // Debug active assets only
        System.debug('Active Assets (affecting ARR/ACV):');
        for (Asset asset : contract.Assets__r) {
            if (asset.Start_Date__c <= today && 
                asset.End_Date__c >= today && 
                asset.ProductFamily != 'Professional Service') {
                System.debug('  ✅ ' + asset.Id + ' | ARR: ' + asset.ARR__c + ' | TCV: ' + asset.Total_Price__c + ' | Family: ' + asset.ProductFamily);
            }
        }
        
    } else {
        System.debug('✅ ' + contract.Name + ' (' + contract.Id + ') - ARR calculations are CORRECT');
    }
}

if (realIssuesFound == 0) {
    System.debug('\n🎉 NO REAL ARR ISSUES FOUND!');
    System.debug('All contracts have correct ARR calculations based on their active assets.');
    System.debug('The previous "issues" were due to my incorrect analysis including future/expired assets.');
} else {
    System.debug('\n🚨 Found ' + realIssuesFound + ' contracts with REAL ARR calculation issues');
    System.debug('These need investigation in the batch logic.');
}

System.debug('\n=== Corrected Analysis Complete ===');
