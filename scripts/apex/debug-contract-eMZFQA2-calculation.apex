// Debug contract 800fJ000007eMZFQA2 ARR calculation
System.debug('=== Debugging Contract 800fJ000007eMZFQA2 ===');

// Current contract values
System.debug('CURRENT CONTRACT VALUES:');
System.debug('  ARR__c: 149250 (contract shows)');
System.debug('  ACV__c: 149250 (contract shows)');
System.debug('  TCV__c: 149250 (contract shows)');
System.debug('  Active_ARR__c: 70000 (contract shows)');
System.debug('  ARR_USD__c: $70,000.00 (contract shows)');

System.debug('\nASSET ANALYSIS:');
Date today = Date.today();
System.debug('Today: ' + today);

// Active assets (should contribute to ARR/ACV/Active_ARR)
System.debug('\n--- ACTIVE ASSETS (Start ≤ Today ≤ End) ---');
Decimal expectedARR = 0;
Decimal expectedACV = 0;
Decimal expectedActiveARR = 0;

// Asset 1: 02ifJ000000D7tQQAS
System.debug('Asset 1: Pipeline Hyperperformance');
System.debug('  Start: 2025-04-01 | End: 2026-03-31 | Status: Active');
System.debug('  ARR: 0 | Total_Value: 0 | Total_Price: 0');
System.debug('  Is Active? Start ≤ Today: ' + (Date.valueOf('2025-04-01') <= today) + 
             ', End ≥ Today: ' + (Date.valueOf('2026-03-31') >= today));
if (Date.valueOf('2025-04-01') <= today && Date.valueOf('2026-03-31') >= today) {
    expectedARR += 0;
    expectedACV += 0;
    expectedActiveARR += 0;
    System.debug('  ✅ ACTIVE - Added 0 to totals');
} else {
    System.debug('  ❌ NOT ACTIVE');
}

// Asset 2: 02ifJ000000D8B5QAK
System.debug('\nAsset 2: Seqera Platform License');
System.debug('  Start: 2025-04-01 | End: 2026-03-31 | Status: Active');
System.debug('  ARR: 25000 | Total_Value: 25000 | Total_Price: 25000');
System.debug('  Is Active? Start ≤ Today: ' + (Date.valueOf('2025-04-01') <= today) + 
             ', End ≥ Today: ' + (Date.valueOf('2026-03-31') >= today));
if (Date.valueOf('2025-04-01') <= today && Date.valueOf('2026-03-31') >= today) {
    expectedARR += 25000;
    expectedACV += 25000;
    expectedActiveARR += 25000;
    System.debug('  ✅ ACTIVE - Added 25000 to totals');
} else {
    System.debug('  ❌ NOT ACTIVE');
}

// Asset 3: 02ifJ000000DApaQAG
System.debug('\nAsset 3: Enterprise Pipelines User License');
System.debug('  Start: 2025-04-01 | End: 2026-03-31 | Status: Active');
System.debug('  ARR: 45000 | Total_Value: 45000 | Total_Price: 45000');
System.debug('  Is Active? Start ≤ Today: ' + (Date.valueOf('2025-04-01') <= today) + 
             ', End ≥ Today: ' + (Date.valueOf('2026-03-31') >= today));
if (Date.valueOf('2025-04-01') <= today && Date.valueOf('2026-03-31') >= today) {
    expectedARR += 45000;
    expectedACV += 45000;
    expectedActiveARR += 45000;
    System.debug('  ✅ ACTIVE - Added 45000 to totals');
} else {
    System.debug('  ❌ NOT ACTIVE');
}

System.debug('\n--- FUTURE ASSETS (Start > Today) ---');
Decimal expectedTCV = expectedARR; // Start with active asset values

// Asset 4: 02ifJ000000EF7FQAW
System.debug('Asset 4: Future Seqera Platform License');
System.debug('  Start: 2026-04-01 | End: 2027-03-31 | Status: Purchased');
System.debug('  ARR: 25000 | Total_Value: 25000 | Total_Price: 25000');
System.debug('  Is Active? Start ≤ Today: ' + (Date.valueOf('2026-04-01') <= today) + 
             ', End ≥ Today: ' + (Date.valueOf('2027-03-31') >= today));
expectedTCV += 25000; // TCV includes all assets
System.debug('  ❌ FUTURE - Not active, but added 25000 to TCV');

// Asset 5: 02ifJ000000EF8rQAG
System.debug('\nAsset 5: Future Pipeline Hyperperformance');
System.debug('  Start: 2026-04-01 | End: 2027-03-31 | Status: Purchased');
System.debug('  ARR: 6250 | Total_Value: 6250 | Total_Price: 6250');
System.debug('  Is Active? Start ≤ Today: ' + (Date.valueOf('2026-04-01') <= today) + 
             ', End ≥ Today: ' + (Date.valueOf('2027-03-31') >= today));
expectedTCV += 6250; // TCV includes all assets
System.debug('  ❌ FUTURE - Not active, but added 6250 to TCV');

// Asset 6: 02ifJ000000EFATQA4
System.debug('\nAsset 6: Future Enterprise Pipelines User License');
System.debug('  Start: 2026-04-01 | End: 2027-03-31 | Status: Purchased');
System.debug('  ARR: 48000 | Total_Value: 48000 | Total_Price: 48000');
System.debug('  Is Active? Start ≤ Today: ' + (Date.valueOf('2026-04-01') <= today) + 
             ', End ≥ Today: ' + (Date.valueOf('2027-03-31') >= today));
expectedTCV += 48000; // TCV includes all assets
System.debug('  ❌ FUTURE - Not active, but added 48000 to TCV');

System.debug('\n--- EXPECTED VALUES ---');
System.debug('Expected ARR (active only): ' + expectedARR);
System.debug('Expected ACV (active only): ' + expectedACV);
System.debug('Expected Active_ARR (active only): ' + expectedActiveARR);
System.debug('Expected TCV (all assets): ' + expectedTCV);

System.debug('\n--- ACTUAL vs EXPECTED ---');
System.debug('ARR: Actual=149250, Expected=' + expectedARR + ' ❌ WRONG (includes future assets)');
System.debug('ACV: Actual=149250, Expected=' + expectedACV + ' ❌ WRONG (includes future assets)');  
System.debug('Active_ARR: Actual=70000, Expected=' + expectedActiveARR + ' ✅ CORRECT');
System.debug('TCV: Actual=149250, Expected=' + expectedTCV + ' ❌ WRONG (missing future assets)');

System.debug('\n--- THE PROBLEM ---');
System.debug('1. ARR/ACV are including ALL assets (149250) instead of just active (70000)');
System.debug('2. TCV is missing future assets (shows 149250, should be ' + expectedTCV + ')');
System.debug('3. Active_ARR is somehow correct at 70000 (active assets only)');
System.debug('4. This suggests different logic is being applied inconsistently');

System.debug('\n=== Analysis Complete ===');
