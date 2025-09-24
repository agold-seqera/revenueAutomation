// Debug AssetStatusBatch execution for specific Asset ID: 02ifJ000000EKA9QAO
// This Asset should remain "Purchased" until Start_Date__c (2025-12-17)

System.debug('=== DEBUGGING ASSETSTATUSBATCH FOR ALMIRALL ASSET ===');

String targetAssetId = '02ifJ000000EKA9QAO';
Date today = Date.today();

System.debug('Target Asset ID: ' + targetAssetId);
System.debug('Today: ' + today);

// Query the Asset exactly as AssetStatusBatch does
List<Asset> assets = [
    SELECT Id, Status, Start_Date__c, End_Date__c, Exclude_from_Status_Updates__c
    FROM Asset 
    WHERE Id = :targetAssetId
    AND (Status = 'Purchased' OR Status = 'Active')
];

if (assets.isEmpty()) {
    System.debug('❌ Asset not found or not in scope for AssetStatusBatch');
    return;
}

Asset asset = assets[0];
System.debug('🎯 Found Asset in scope:');
System.debug('  Status: ' + asset.Status);
System.debug('  Start_Date__c: ' + asset.Start_Date__c);
System.debug('  End_Date__c: ' + asset.End_Date__c);
System.debug('  Exclude_from_Status_Updates__c: ' + asset.Exclude_from_Status_Updates__c);

// Replicate the exact determineAssetStatus logic with detailed debugging
System.debug('=== REPLICATING ASSETSTATUSBATCH LOGIC ===');

// Check exclusion
if (asset.Exclude_from_Status_Updates__c == true) {
    System.debug('❌ Asset excluded from status updates');
    return;
}
System.debug('✅ Asset NOT excluded from status updates');

// Check if cancelled
if (asset.Status == 'Cancelled') {
    System.debug('❌ Asset is Cancelled, no change needed');
    return;
}
System.debug('✅ Asset is NOT Cancelled');

// Flow Decision 1: Should_Asset_be_Active
System.debug('=== CHECKING: Should Asset be Active? ===');
System.debug('Conditions for Active status:');
System.debug('  1. Start_Date__c <= TODAY: ' + asset.Start_Date__c + ' <= ' + today + ' = ' + (asset.Start_Date__c <= today));
System.debug('  2. End_Date__c >= TODAY: ' + asset.End_Date__c + ' >= ' + today + ' = ' + (asset.End_Date__c >= today));
System.debug('  3. Status != Active: ' + asset.Status + ' != Active = ' + (asset.Status != 'Active'));
System.debug('  4. Status != Cancelled: ' + asset.Status + ' != Cancelled = ' + (asset.Status != 'Cancelled'));

Boolean shouldBeActive = (asset.Start_Date__c <= today && 
                         asset.End_Date__c >= today && 
                         asset.Status != 'Active' && 
                         asset.Status != 'Cancelled');

System.debug('Should be Active? ' + shouldBeActive);

if (shouldBeActive) {
    System.debug('✅ MATCH: Asset should change to Active');
} else {
    System.debug('❌ NO MATCH: Asset should NOT change to Active');
}

// Flow Decision 2: Should_Asset_be_Inactive  
System.debug('=== CHECKING: Should Asset be Inactive? ===');
System.debug('Conditions for Inactive status:');
System.debug('  1. Start_Date__c < TODAY: ' + asset.Start_Date__c + ' < ' + today + ' = ' + (asset.Start_Date__c < today));
System.debug('  2. End_Date__c < TODAY: ' + asset.End_Date__c + ' < ' + today + ' = ' + (asset.End_Date__c < today));
System.debug('  3. Status != Inactive: ' + asset.Status + ' != Inactive = ' + (asset.Status != 'Inactive'));
System.debug('  4. Status != Cancelled: ' + asset.Status + ' != Cancelled = ' + (asset.Status != 'Cancelled'));

Boolean shouldBeInactive = (asset.Start_Date__c < today && 
                           asset.End_Date__c < today && 
                           asset.Status != 'Inactive' && 
                           asset.Status != 'Cancelled');

System.debug('Should be Inactive? ' + shouldBeInactive);

if (shouldBeInactive) {
    System.debug('✅ MATCH: Asset should change to Inactive');
} else {
    System.debug('❌ NO MATCH: Asset should NOT change to Inactive');
}

// Final determination
String expectedStatus = null;
if (shouldBeActive) {
    expectedStatus = 'Active';
} else if (shouldBeInactive) {
    expectedStatus = 'Inactive';
}

if (expectedStatus != null) {
    System.debug('🔄 EXPECTED STATUS CHANGE: ' + asset.Status + ' → ' + expectedStatus);
} else {
    System.debug('✅ NO STATUS CHANGE EXPECTED: Asset should remain ' + asset.Status);
}

System.debug('=== NOW RUNNING ACTUAL ASSETSTATUSBATCH ===');

// Execute the actual AssetStatusBatch
try {
    AssetStatusBatch batch = new AssetStatusBatch();
    String jobId = Database.executeBatch(batch, 100);
    
    System.debug('✅ AssetStatusBatch started successfully');
    System.debug('Job ID: ' + jobId);
    
    System.debug('🔍 MONITORING INSTRUCTIONS:');
    System.debug('1. Wait 30-60 seconds for batch completion');
    System.debug('2. Check batch status: SELECT Id, Status, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id = \'' + jobId + '\'');
    System.debug('3. Check Asset status: SELECT Id, Status, LastModifiedDate, LastModifiedBy.Name FROM Asset WHERE Id = \'' + targetAssetId + '\'');
    
} catch (Exception e) {
    System.debug('❌ Failed to execute AssetStatusBatch: ' + e.getMessage());
}

System.debug('=== DEBUG EXECUTION COMPLETE ===');
