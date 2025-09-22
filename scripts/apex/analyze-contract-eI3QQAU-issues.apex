// Analyze the actual issues with contract 800fJ000007eI3QQAU
System.debug('=== Contract 800fJ000007eI3QQAU Analysis ===');

// Contract details
System.debug('Contract: 800fJ000007eI3QQAU');
System.debug('Status: Activated');
System.debug('Contract Period: 2024-07-04 to 2027-07-03 (3 years)');
System.debug('LastModified: 2025-09-22 20:09:44 by Sys Admin');
System.debug('');

// Current contract values
System.debug('CURRENT CONTRACT VALUES:');
System.debug('  ARR__c: 1,146,000');
System.debug('  ACV__c: 1,146,000');
System.debug('  TCV__c: 1,146,000');
System.debug('  Active_ARR__c: 573,000');
System.debug('  MRR__c: 95,500');
System.debug('');

// Asset analysis
Date today = Date.today();
System.debug('ASSET ANALYSIS (Today: ' + today + '):');

System.debug('Asset 1: 02iPn000003S5xVIAS');
System.debug('  Period: 2025-07-04 to 2026-07-03 (FUTURE)');
System.debug('  ARR: 75,000 | Family: Software Subscriptions');

System.debug('Asset 2: 02iPn000003S5z7IAC');
System.debug('  Period: 2026-07-04 to 2027-07-03 (FUTURE)');
System.debug('  ARR: 75,000 | Family: Software Subscriptions');

System.debug('Asset 3: 02ifJ000000D9C6QAK');
System.debug('  Period: 2025-07-04 to 2026-07-03 (FUTURE)');
System.debug('  ARR: 498,000 | Family: Software Subscriptions');

System.debug('Asset 4: 02ifJ000000ED74QAG');
System.debug('  Period: 2024-07-04 to 2025-07-03 (EXPIRED)');
System.debug('  ARR: 498,000 | Family: Software Subscriptions');
System.debug('');

// Calculate what the values SHOULD be
Decimal expectedARR_ActiveOnly = 0;
Decimal expectedACV_ActiveOnly = 0;
Decimal expectedTCV_All = 0;
Integer activeAssets = 0;
Integer futureAssets = 0;
Integer expiredAssets = 0;

// Asset 1 (FUTURE)
if (Date.newInstance(2025, 7, 4) <= today && Date.newInstance(2026, 7, 3) >= today) {
    expectedARR_ActiveOnly += 75000;
    expectedACV_ActiveOnly += 75000;
    activeAssets++;
} else {
    futureAssets++;
}
expectedTCV_All += 75000;

// Asset 2 (FUTURE)
if (Date.newInstance(2026, 7, 4) <= today && Date.newInstance(2027, 7, 3) >= today) {
    expectedARR_ActiveOnly += 75000;
    expectedACV_ActiveOnly += 75000;
    activeAssets++;
} else {
    futureAssets++;
}
expectedTCV_All += 75000;

// Asset 3 (FUTURE)
if (Date.newInstance(2025, 7, 4) <= today && Date.newInstance(2026, 7, 3) >= today) {
    expectedARR_ActiveOnly += 498000;
    expectedACV_ActiveOnly += 498000;
    activeAssets++;
} else {
    futureAssets++;
}
expectedTCV_All += 498000;

// Asset 4 (EXPIRED)
if (Date.newInstance(2024, 7, 4) <= today && Date.newInstance(2025, 7, 3) >= today) {
    expectedARR_ActiveOnly += 498000;
    expectedACV_ActiveOnly += 498000;
    activeAssets++;
} else {
    expiredAssets++;
}
expectedTCV_All += 498000;

System.debug('EXPECTED VALUES (Based on Asset Status):');
System.debug('  Active Assets: ' + activeAssets);
System.debug('  Future Assets: ' + futureAssets);
System.debug('  Expired Assets: ' + expiredAssets);
System.debug('  Expected ARR (Active Only): ' + expectedARR_ActiveOnly);
System.debug('  Expected ACV (Active Only): ' + expectedACV_ActiveOnly);
System.debug('  Expected TCV (All Assets): ' + expectedTCV_All);
System.debug('  Expected Active_ARR: ' + expectedARR_ActiveOnly);
System.debug('');

System.debug('IDENTIFIED ISSUES:');

// ARR Issue
if (1146000 != expectedARR_ActiveOnly) {
    System.debug('🚨 ARR ISSUE: Contract shows 1,146,000 but should be ' + expectedARR_ActiveOnly);
    System.debug('   Problem: Contract ARR includes assets that are not currently active');
}

// ACV Issue  
if (1146000 != expectedACV_ActiveOnly) {
    System.debug('🚨 ACV ISSUE: Contract shows 1,146,000 but should be ' + expectedACV_ActiveOnly);
    System.debug('   Problem: Contract ACV includes assets that are not currently active');
}

// TCV Issue
if (1146000 != expectedTCV_All) {
    System.debug('🚨 TCV ISSUE: Contract shows 1,146,000 but should be ' + expectedTCV_All);
    System.debug('   Problem: Contract TCV should include ALL assets regardless of status');
}

// Active_ARR Issue
if (573000 != expectedARR_ActiveOnly) {
    System.debug('🚨 ACTIVE_ARR ISSUE: Contract shows 573,000 but should be ' + expectedARR_ActiveOnly);
    System.debug('   Problem: Active_ARR calculation is incorrect');
}

System.debug('');
System.debug('ROOT CAUSE:');
System.debug('The batch logic is NOT correctly identifying asset status (active vs future vs expired)');
System.debug('OR the batch is not running on this contract at all (LastModified: 20:09:44 before our recent batches)');

System.debug('');
System.debug('=== Analysis Complete ===');
