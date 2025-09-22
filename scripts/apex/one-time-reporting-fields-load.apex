// One-time load script to populate all Number reporting fields from existing USD text fields
System.debug('=== Starting One-Time Reporting Fields Load ===');

// Step 1: Load Contract Reporting Fields
System.debug('\n--- Step 1: Loading Contract Reporting Fields ---');

List<Contract> contractsToUpdate = [
    SELECT Id, Name, ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, 
           MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c
    FROM Contract 
    WHERE (ARR_USD__c != null OR ACV_USD__c != null OR TCV_USD__c != null OR MRR_USD__c != null OR Active_ARR_USD__c != null)
    AND Status != 'Draft'
];

System.debug('Found ' + contractsToUpdate.size() + ' contracts with USD fields to load');

Integer contractUpdates = 0;
for (Contract c : contractsToUpdate) {
    Boolean needsUpdate = false;
    
    // Parse USD text fields to Number reporting fields
    if (c.ARR_USD__c != null && c.ARR_USD_Reporting__c == null) {
        String cleanARR = c.ARR_USD__c.replace('$', '').replace(',', '');
        try {
            c.ARR_USD_Reporting__c = Decimal.valueOf(cleanARR);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing ARR_USD for Contract ' + c.Id + ': ' + c.ARR_USD__c);
        }
    }
    
    if (c.ACV_USD__c != null && c.ACV_USD_Reporting__c == null) {
        String cleanACV = c.ACV_USD__c.replace('$', '').replace(',', '');
        try {
            c.ACV_USD_Reporting__c = Decimal.valueOf(cleanACV);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing ACV_USD for Contract ' + c.Id + ': ' + c.ACV_USD__c);
        }
    }
    
    if (c.TCV_USD__c != null && c.TCV_USD_Reporting__c == null) {
        String cleanTCV = c.TCV_USD__c.replace('$', '').replace(',', '');
        try {
            c.TCV_USD_Reporting__c = Decimal.valueOf(cleanTCV);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing TCV_USD for Contract ' + c.Id + ': ' + c.TCV_USD__c);
        }
    }
    
    if (c.MRR_USD__c != null && c.MRR_USD_Reporting__c == null) {
        String cleanMRR = c.MRR_USD__c.replace('$', '').replace(',', '');
        try {
            c.MRR_USD_Reporting__c = Decimal.valueOf(cleanMRR);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing MRR_USD for Contract ' + c.Id + ': ' + c.MRR_USD__c);
        }
    }
    
    if (c.Active_ARR_USD__c != null && c.Active_ARR_USD_Reporting__c == null) {
        String cleanActiveARR = c.Active_ARR_USD__c.replace('$', '').replace(',', '');
        try {
            c.Active_ARR_USD_Reporting__c = Decimal.valueOf(cleanActiveARR);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing Active_ARR_USD for Contract ' + c.Id + ': ' + c.Active_ARR_USD__c);
        }
    }
    
    if (needsUpdate) {
        contractUpdates++;
    }
}

if (contractUpdates > 0) {
    System.debug('Updating ' + contractUpdates + ' contracts with reporting field values');
    update contractsToUpdate;
    System.debug('✅ Contract reporting fields updated successfully');
} else {
    System.debug('ℹ️ No contracts needed reporting field updates');
}

// Step 2: Load Account Reporting Fields (from USD text fields only)
System.debug('\n--- Step 2: Loading Account Reporting Fields ---');

List<Account> accountsToUpdate = [
    SELECT Id, Name, ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c
    FROM Account 
    WHERE (ARR_USD__c != null OR ACV_USD__c != null OR TCV_USD__c != null OR MRR_USD__c != null)
    AND Has_Contracts__c = true
];

System.debug('Found ' + accountsToUpdate.size() + ' accounts with USD fields to load');

Integer accountUpdates = 0;
for (Account a : accountsToUpdate) {
    Boolean needsUpdate = false;
    
    // Parse USD text fields to Number reporting fields - ONLY from USD counterparts
    if (a.ARR_USD__c != null && a.ARR_USD_Reporting__c == null) {
        String cleanARR = a.ARR_USD__c.replace('$', '').replace(',', '');
        try {
            a.ARR_USD_Reporting__c = Decimal.valueOf(cleanARR);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing ARR_USD for Account ' + a.Id + ': ' + a.ARR_USD__c);
        }
    }
    
    if (a.ACV_USD__c != null && a.ACV_USD_Reporting__c == null) {
        String cleanACV = a.ACV_USD__c.replace('$', '').replace(',', '');
        try {
            a.ACV_USD_Reporting__c = Decimal.valueOf(cleanACV);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing ACV_USD for Account ' + a.Id + ': ' + a.ACV_USD__c);
        }
    }
    
    if (a.TCV_USD__c != null && a.TCV_USD_Reporting__c == null) {
        String cleanTCV = a.TCV_USD__c.replace('$', '').replace(',', '');
        try {
            a.TCV_USD_Reporting__c = Decimal.valueOf(cleanTCV);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing TCV_USD for Account ' + a.Id + ': ' + a.TCV_USD__c);
        }
    }
    
    if (a.MRR_USD__c != null && a.MRR_USD_Reporting__c == null) {
        String cleanMRR = a.MRR_USD__c.replace('$', '').replace(',', '');
        try {
            a.MRR_USD_Reporting__c = Decimal.valueOf(cleanMRR);
            needsUpdate = true;
        } catch (Exception e) {
            System.debug('Error parsing MRR_USD for Account ' + a.Id + ': ' + a.MRR_USD__c);
        }
    }
    
    if (needsUpdate) {
        accountUpdates++;
    }
}

if (accountUpdates > 0) {
    System.debug('Updating ' + accountUpdates + ' accounts with reporting field values');
    update accountsToUpdate;
    System.debug('✅ Account reporting fields updated successfully');
} else {
    System.debug('ℹ️ No accounts needed reporting field updates');
}

// Step 3: Summary Report
System.debug('\n--- Step 3: Load Summary Report ---');

// Count populated reporting fields
Integer totalContracts = [SELECT COUNT() FROM Contract WHERE Status != 'Draft'];
Integer contractsWithReporting = [SELECT COUNT() FROM Contract WHERE Status != 'Draft' AND ARR_USD_Reporting__c != null];

Integer totalAccounts = [SELECT COUNT() FROM Account WHERE Has_Contracts__c = true];
Integer accountsWithReporting = [SELECT COUNT() FROM Account WHERE Has_Contracts__c = true AND ARR_USD_Reporting__c != null];

System.debug('📊 Contract Reporting Fields Summary:');
System.debug('  Total Contracts: ' + totalContracts);
System.debug('  Contracts with Reporting Fields: ' + contractsWithReporting);

System.debug('📊 Account Reporting Fields Summary:');
System.debug('  Total Accounts: ' + totalAccounts);
System.debug('  Accounts with Reporting Fields: ' + accountsWithReporting);

// Show sample results
List<Contract> sampleContracts = [
    SELECT Id, Name, ARR_USD__c, ARR_USD_Reporting__c, ACV_USD_Reporting__c
    FROM Contract 
    WHERE ARR_USD_Reporting__c != null
    LIMIT 5
];

System.debug('📊 Sample Contract Results:');
for (Contract c : sampleContracts) {
    System.debug('  ' + c.Name + ': ARR_USD=' + c.ARR_USD__c + ' → ARR_Reporting=' + c.ARR_USD_Reporting__c);
}

List<Account> sampleAccounts = [
    SELECT Id, Name, ARR_USD__c, ARR_USD_Reporting__c, ACV_USD_Reporting__c
    FROM Account 
    WHERE ARR_USD_Reporting__c != null
    LIMIT 5
];

System.debug('📊 Sample Account Results:');
for (Account a : sampleAccounts) {
    System.debug('  ' + a.Name + ': ARR_USD=' + a.ARR_USD__c + ' → ARR_Reporting=' + a.ARR_USD_Reporting__c);
}

System.debug('\n=== One-Time Reporting Fields Load Complete ===');
System.debug('✅ Contract reporting fields populated ONLY from their USD text field counterparts');
System.debug('✅ Account reporting fields populated ONLY from their USD text field counterparts');
System.debug('🎯 Ready for Salesforce reporting and aggregation!');
