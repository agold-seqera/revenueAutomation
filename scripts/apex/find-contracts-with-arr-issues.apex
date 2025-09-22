// Find contracts that might have ARR calculation issues
System.debug('=== Finding Contracts with ARR Calculation Issues ===');

// Get contracts with their assets and calculate expected vs actual ARR
List<Contract> contractsToCheck = [
    SELECT Id, Name, Status, ARR__c, ACV__c, Active_ARR__c, StartDate, EndDate,
           LastModifiedDate, LastModifiedBy.Name,
           (SELECT Id, ARR__c, Total_Value__c, Start_Date__c, End_Date__c, 
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
Integer issuesFound = 0;

for (Contract contract : contractsToCheck) {
    // Calculate expected ARR from active assets
    Decimal expectedARR = 0;
    Decimal expectedACV = 0;
    Decimal expectedActiveARR = 0;
    Integer totalAssets = 0;
    Integer activeAssets = 0;
    Integer futureAssets = 0;
    
    for (Asset asset : contract.Assets__r) {
        totalAssets++;
        
        // For ACV and ARR: include ALL assets except Professional Services
        if (asset.ProductFamily != 'Professional Service') {
            expectedARR += (asset.ARR__c != null ? asset.ARR__c : 0);
            expectedACV += (asset.Total_Value__c != null ? asset.Total_Value__c : 0);
        }
        
        // For Active_ARR: only currently active assets
        if (asset.Start_Date__c <= today && 
            asset.End_Date__c >= today && 
            asset.ProductFamily != 'Professional Service') {
            expectedActiveARR += (asset.ARR__c != null ? asset.ARR__c : 0);
            activeAssets++;
        } else if (asset.Start_Date__c > today) {
            futureAssets++;
        }
    }
    
    // Check for discrepancies
    Boolean hasARRIssue = Math.abs(contract.ARR__c - expectedARR) > 0.01;
    Boolean hasACVIssue = Math.abs(contract.ACV__c - expectedACV) > 0.01;
    Boolean hasActiveARRIssue = Math.abs(contract.Active_ARR__c - expectedActiveARR) > 0.01;
    
    if (hasARRIssue || hasACVIssue || hasActiveARRIssue) {
        issuesFound++;
        System.debug('\n🚨 ISSUE FOUND - Contract: ' + contract.Name + ' (' + contract.Id + ')');
        System.debug('Last Modified: ' + contract.LastModifiedDate + ' by ' + contract.LastModifiedBy.Name);
        System.debug('Assets: ' + totalAssets + ' total, ' + activeAssets + ' active, ' + futureAssets + ' future');
        
        if (hasARRIssue) {
            System.debug('❌ ARR Mismatch: Contract=' + contract.ARR__c + ' vs Expected=' + expectedARR);
        }
        if (hasACVIssue) {
            System.debug('❌ ACV Mismatch: Contract=' + contract.ACV__c + ' vs Expected=' + expectedACV);
        }
        if (hasActiveARRIssue) {
            System.debug('❌ Active_ARR Mismatch: Contract=' + contract.Active_ARR__c + ' vs Expected=' + expectedActiveARR);
        }
        
        // Debug individual assets
        System.debug('Asset Details:');
        for (Asset asset : contract.Assets__r) {
            String assetStatus = '';
            if (asset.Start_Date__c <= today && asset.End_Date__c >= today) {
                assetStatus = 'ACTIVE';
            } else if (asset.Start_Date__c > today) {
                assetStatus = 'FUTURE';
            } else {
                assetStatus = 'EXPIRED';
            }
            
            System.debug('  - ' + asset.Id + ' | ' + assetStatus + ' | Family: ' + asset.ProductFamily + 
                        ' | ARR: ' + asset.ARR__c + ' | TCV: ' + asset.Total_Value__c);
        }
        
    } else {
        System.debug('✅ ' + contract.Name + ' - Values are correct');
    }
}

if (issuesFound == 0) {
    System.debug('\n✅ No ARR calculation issues found in the checked contracts');
    System.debug('This suggests either:');
    System.debug('1. The scheduled batches ARE working correctly now');
    System.debug('2. All contracts were recently processed and fixed');
    System.debug('3. The issue was already resolved');
} else {
    System.debug('\n🚨 Found ' + issuesFound + ' contracts with calculation issues');
    System.debug('These contracts need to be investigated for batch processing bugs');
}

// Check when batches last ran
System.debug('\n--- Recent Batch Execution History ---');
List<AsyncApexJob> recentJobs = [
    SELECT Id, JobType, ApexClass.Name, Status, CreatedDate, CompletedDate
    FROM AsyncApexJob 
    WHERE ApexClass.Name IN ('ContractRevenueBatch', 'AccountRollupBatch', 'RevenueAutomationBatchManager')
    AND CreatedDate = TODAY
    ORDER BY CreatedDate DESC
    LIMIT 10
];

for (AsyncApexJob job : recentJobs) {
    System.debug(job.CreatedDate + ' | ' + job.ApexClass.Name + ' | ' + job.Status);
}

System.debug('\n=== Investigation Complete ===');
