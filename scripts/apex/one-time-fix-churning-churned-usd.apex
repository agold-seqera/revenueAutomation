// ONE-TIME LOAD: Fix USD and reporting fields for churning/churned accounts
// This directly updates accounts based on their corrected contract values

System.debug('=== ONE-TIME USD FIX FOR CHURNING/CHURNED ACCOUNTS ===');

// Find all churning/churned accounts that need USD field fixes
List<Account> accountsToFix = [
    SELECT Id, Name, Status__c, CurrencyIsoCode,
           ARR__c, ACV__c, TCV__c, MRR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
           (SELECT Id, ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                   Status
            FROM Contracts
            WHERE Status IN ('Expired', 'Activated'))
    FROM Account
    WHERE Status__c IN ('Active (Churning)', 'Churned')
    AND ARR__c > 0
    AND (ARR_USD__c = '$0' OR ARR_USD__c = null OR ARR_USD_Reporting__c = 0)
];

System.debug('Found ' + accountsToFix.size() + ' accounts needing USD field fixes');

List<Account> updatedAccounts = new List<Account>();

for (Account account : accountsToFix) {
    Boolean needsUpdate = false;
    
    // Sum USD values from ALL contracts (expired + active) for churning/churned accounts
    Decimal totalARR_USD = 0;
    Decimal totalACV_USD = 0;
    Decimal totalTCV_USD = 0;
    Decimal totalMRR_USD = 0;
    
    Decimal totalARR_Reporting = 0;
    Decimal totalACV_Reporting = 0;
    Decimal totalTCV_Reporting = 0;
    Decimal totalMRR_Reporting = 0;
    
    System.debug('Processing account: ' + account.Name + ' (' + account.Status__c + ')');
    
    for (Contract contract : account.Contracts) {
        System.debug('  Contract: ' + contract.Id + ' (' + contract.Status + ') - ARR_USD: ' + contract.ARR_USD__c);
        
        if (contract.ARR_USD__c != null && contract.ARR_USD__c != '$0.00' && contract.ARR_USD__c != '$0') {
            // Parse USD currency string to decimal
            String usdString = contract.ARR_USD__c.replace('$', '').replace(',', '');
            try {
                totalARR_USD += Decimal.valueOf(usdString);
            } catch (Exception e) {
                System.debug('  ERROR parsing ARR_USD: ' + contract.ARR_USD__c);
            }
        }
        
        if (contract.ACV_USD__c != null && contract.ACV_USD__c != '$0.00' && contract.ACV_USD__c != '$0') {
            String usdString = contract.ACV_USD__c.replace('$', '').replace(',', '');
            try {
                totalACV_USD += Decimal.valueOf(usdString);
            } catch (Exception e) {
                System.debug('  ERROR parsing ACV_USD: ' + contract.ACV_USD__c);
            }
        }
        
        if (contract.TCV_USD__c != null && contract.TCV_USD__c != '$0.00' && contract.TCV_USD__c != '$0') {
            String usdString = contract.TCV_USD__c.replace('$', '').replace(',', '');
            try {
                totalTCV_USD += Decimal.valueOf(usdString);
            } catch (Exception e) {
                System.debug('  ERROR parsing TCV_USD: ' + contract.TCV_USD__c);
            }
        }
        
        if (contract.MRR_USD__c != null && contract.MRR_USD__c != '$0.00' && contract.MRR_USD__c != '$0') {
            String usdString = contract.MRR_USD__c.replace('$', '').replace(',', '');
            try {
                totalMRR_USD += Decimal.valueOf(usdString);
            } catch (Exception e) {
                System.debug('  ERROR parsing MRR_USD: ' + contract.MRR_USD__c);
            }
        }
        
        // Sum reporting fields
        if (contract.ARR_USD_Reporting__c != null) {
            totalARR_Reporting += contract.ARR_USD_Reporting__c;
        }
        if (contract.ACV_USD_Reporting__c != null) {
            totalACV_Reporting += contract.ACV_USD_Reporting__c;
        }
        if (contract.TCV_USD_Reporting__c != null) {
            totalTCV_Reporting += contract.TCV_USD_Reporting__c;
        }
        if (contract.MRR_USD_Reporting__c != null) {
            totalMRR_Reporting += contract.MRR_USD_Reporting__c;
        }
    }
    
    // Update account USD fields if we found non-zero totals
    if (totalARR_USD > 0) {
        account.ARR_USD__c = '$' + String.valueOf(totalARR_USD.setScale(2).format());
        needsUpdate = true;
    }
    if (totalACV_USD > 0) {
        account.ACV_USD__c = '$' + String.valueOf(totalACV_USD.setScale(2).format());
        needsUpdate = true;
    }
    if (totalTCV_USD > 0) {
        account.TCV_USD__c = '$' + String.valueOf(totalTCV_USD.setScale(2).format());
        needsUpdate = true;
    }
    if (totalMRR_USD > 0) {
        account.MRR_USD__c = '$' + String.valueOf(totalMRR_USD.setScale(2).format());
        needsUpdate = true;
    }
    
    // Update reporting fields
    if (totalARR_Reporting > 0) {
        account.ARR_USD_Reporting__c = totalARR_Reporting;
        needsUpdate = true;
    }
    if (totalACV_Reporting > 0) {
        account.ACV_USD_Reporting__c = totalACV_Reporting;
        needsUpdate = true;
    }
    if (totalTCV_Reporting > 0) {
        account.TCV_USD_Reporting__c = totalTCV_Reporting;
        needsUpdate = true;
    }
    if (totalMRR_Reporting > 0) {
        account.MRR_USD_Reporting__c = totalMRR_Reporting;
        needsUpdate = true;
    }
    
    if (needsUpdate) {
        updatedAccounts.add(account);
        System.debug('  ✓ UPDATED: ARR_USD=' + account.ARR_USD__c + ', ARR_Reporting=' + account.ARR_USD_Reporting__c);
    } else {
        System.debug('  ✗ NO UPDATE NEEDED');
    }
}

// Execute the update
if (!updatedAccounts.isEmpty()) {
    try {
        update updatedAccounts;
        System.debug('✅ SUCCESS: Updated ' + updatedAccounts.size() + ' accounts with corrected USD fields');
        
        for (Account acc : updatedAccounts) {
            System.debug('  ✓ ' + acc.Name + ': ARR_USD=' + acc.ARR_USD__c + ', ARR_Reporting=' + acc.ARR_USD_Reporting__c);
        }
    } catch (DmlException e) {
        System.debug('❌ ERROR updating accounts: ' + e.getMessage());
    }
} else {
    System.debug('ℹ️ No accounts found needing USD field updates');
}

System.debug('=== ONE-TIME USD FIX COMPLETE ===');
