// Comprehensive fix for any accounts and contracts with missing reporting field values
System.debug('=== Fixing All Remaining Reporting Fields ===');

// Step 1: Fix Accounts where USD fields exist but reporting fields are 0 or null
System.debug('\n--- Step 1: Fixing Account Reporting Fields ---');

List<Account> accountsToFix = [
    SELECT Id, Name, ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c
    FROM Account 
    WHERE Has_Contracts__c = true
    AND (
        (ARR_USD__c != null AND (ARR_USD_Reporting__c = null OR ARR_USD_Reporting__c = 0)) OR
        (ACV_USD__c != null AND (ACV_USD_Reporting__c = null OR ACV_USD_Reporting__c = 0)) OR
        (TCV_USD__c != null AND (TCV_USD_Reporting__c = null OR TCV_USD_Reporting__c = 0)) OR
        (MRR_USD__c != null AND (MRR_USD_Reporting__c = null OR MRR_USD_Reporting__c = 0))
    )
];

System.debug('Found ' + accountsToFix.size() + ' accounts needing reporting field fixes');

Integer accountFixCount = 0;
for (Account a : accountsToFix) {
    Boolean needsUpdate = false;
    
    // Fix ARR
    if (a.ARR_USD__c != null && (a.ARR_USD_Reporting__c == null || a.ARR_USD_Reporting__c == 0)) {
        String cleaned = a.ARR_USD__c.replace('$', '').replace(',', '');
        try {
            a.ARR_USD_Reporting__c = Decimal.valueOf(cleaned);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing ARR_USD for Account ' + a.Id + ': ' + a.ARR_USD__c);
        }
    }
    
    // Fix ACV
    if (a.ACV_USD__c != null && (a.ACV_USD_Reporting__c == null || a.ACV_USD_Reporting__c == 0)) {
        String cleaned = a.ACV_USD__c.replace('$', '').replace(',', '');
        try {
            a.ACV_USD_Reporting__c = Decimal.valueOf(cleaned);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing ACV_USD for Account ' + a.Id + ': ' + a.ACV_USD__c);
        }
    }
    
    // Fix TCV
    if (a.TCV_USD__c != null && (a.TCV_USD_Reporting__c == null || a.TCV_USD_Reporting__c == 0)) {
        String cleaned = a.TCV_USD__c.replace('$', '').replace(',', '');
        try {
            a.TCV_USD_Reporting__c = Decimal.valueOf(cleaned);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing TCV_USD for Account ' + a.Id + ': ' + a.TCV_USD__c);
        }
    }
    
    // Fix MRR
    if (a.MRR_USD__c != null && (a.MRR_USD_Reporting__c == null || a.MRR_USD_Reporting__c == 0)) {
        String cleaned = a.MRR_USD__c.replace('$', '').replace(',', '');
        try {
            a.MRR_USD_Reporting__c = Decimal.valueOf(cleaned);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing MRR_USD for Account ' + a.Id + ': ' + a.MRR_USD__c);
        }
    }
    
    if (needsUpdate) {
        accountFixCount++;
    }
}

if (accountFixCount > 0) {
    System.debug('Updating ' + accountFixCount + ' accounts...');
    update accountsToFix;
    System.debug('✅ Account reporting fields fixed successfully');
} else {
    System.debug('ℹ️ No accounts needed reporting field fixes');
}

// Step 2: Fix Contracts where USD fields exist but reporting fields are 0 or null
System.debug('\n--- Step 2: Fixing Contract Reporting Fields ---');

List<Contract> contractsToFix = [
    SELECT Id, Name, ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, 
           MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c
    FROM Contract 
    WHERE Status != 'Draft'
    AND (
        (ARR_USD__c != null AND (ARR_USD_Reporting__c = null OR ARR_USD_Reporting__c = 0)) OR
        (ACV_USD__c != null AND (ACV_USD_Reporting__c = null OR ACV_USD_Reporting__c = 0)) OR
        (TCV_USD__c != null AND (TCV_USD_Reporting__c = null OR TCV_USD_Reporting__c = 0)) OR
        (MRR_USD__c != null AND (MRR_USD_Reporting__c = null OR MRR_USD_Reporting__c = 0)) OR
        (Active_ARR_USD__c != null AND (Active_ARR_USD_Reporting__c = null OR Active_ARR_USD_Reporting__c = 0))
    )
];

System.debug('Found ' + contractsToFix.size() + ' contracts needing reporting field fixes');

Integer contractFixCount = 0;
for (Contract c : contractsToFix) {
    Boolean needsUpdate = false;
    
    // Fix ARR
    if (c.ARR_USD__c != null && (c.ARR_USD_Reporting__c == null || c.ARR_USD_Reporting__c == 0)) {
        String cleaned = c.ARR_USD__c.replace('$', '').replace(',', '');
        try {
            c.ARR_USD_Reporting__c = Decimal.valueOf(cleaned);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing ARR_USD for Contract ' + c.Id + ': ' + c.ARR_USD__c);
        }
    }
    
    // Fix ACV
    if (c.ACV_USD__c != null && (c.ACV_USD_Reporting__c == null || c.ACV_USD_Reporting__c == 0)) {
        String cleaned = c.ACV_USD__c.replace('$', '').replace(',', '');
        try {
            c.ACV_USD_Reporting__c = Decimal.valueOf(cleaned);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing ACV_USD for Contract ' + c.Id + ': ' + c.ACV_USD__c);
        }
    }
    
    // Fix TCV
    if (c.TCV_USD__c != null && (c.TCV_USD_Reporting__c == null || c.TCV_USD_Reporting__c == 0)) {
        String cleaned = c.TCV_USD__c.replace('$', '').replace(',', '');
        try {
            c.TCV_USD_Reporting__c = Decimal.valueOf(cleaned);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing TCV_USD for Contract ' + c.Id + ': ' + c.TCV_USD__c);
        }
    }
    
    // Fix MRR
    if (c.MRR_USD__c != null && (c.MRR_USD_Reporting__c == null || c.MRR_USD_Reporting__c == 0)) {
        String cleaned = c.MRR_USD__c.replace('$', '').replace(',', '');
        try {
            c.MRR_USD_Reporting__c = Decimal.valueOf(cleaned);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing MRR_USD for Contract ' + c.Id + ': ' + c.MRR_USD__c);
        }
    }
    
    // Fix Active ARR
    if (c.Active_ARR_USD__c != null && (c.Active_ARR_USD_Reporting__c == null || c.Active_ARR_USD_Reporting__c == 0)) {
        String cleaned = c.Active_ARR_USD__c.replace('$', '').replace(',', '');
        try {
            c.Active_ARR_USD_Reporting__c = Decimal.valueOf(cleaned);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing Active_ARR_USD for Contract ' + c.Id + ': ' + c.Active_ARR_USD__c);
        }
    }
    
    if (needsUpdate) {
        contractFixCount++;
    }
}

if (contractFixCount > 0) {
    System.debug('Updating ' + contractFixCount + ' contracts...');
    update contractsToFix;
    System.debug('✅ Contract reporting fields fixed successfully');
} else {
    System.debug('ℹ️ No contracts needed reporting field fixes');
}

// Step 3: Final verification
System.debug('\n--- Step 3: Final Verification ---');

Integer totalAccountsWithReporting = [SELECT COUNT() FROM Account WHERE Has_Contracts__c = true AND ARR_USD_Reporting__c != null AND ARR_USD_Reporting__c != 0];
Integer totalContractsWithReporting = [SELECT COUNT() FROM Contract WHERE Status != 'Draft' AND ARR_USD_Reporting__c != null AND ARR_USD_Reporting__c != 0];

System.debug('📊 Final Status:');
System.debug('  Accounts with populated reporting fields: ' + totalAccountsWithReporting);
System.debug('  Contracts with populated reporting fields: ' + totalContractsWithReporting);

// Test the originally problematic account
Account testAccount = [
    SELECT Id, Name, ARR_USD__c, ARR_USD_Reporting__c
    FROM Account 
    WHERE Id = '001fJ000021YDzUQAW'
];

System.debug('🎯 Test Account (Boehringer): ARR_USD="' + testAccount.ARR_USD__c + '" → ARR_Reporting=' + testAccount.ARR_USD_Reporting__c);

System.debug('\n=== Comprehensive Fix Complete ===');
System.debug('✅ All reporting fields should now be correctly populated!');
