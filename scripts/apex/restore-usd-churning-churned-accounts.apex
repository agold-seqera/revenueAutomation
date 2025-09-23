// ONE-TIME SCRIPT: Restore USD and USD Reporting fields for Active (Churning) and Churned accounts
// This script fixes the issue where USD fields were cleared when accounts moved to Churning/Churned status

System.debug('=== STARTING USD RESTORATION FOR CHURNING/CHURNED ACCOUNTS ===');

// Step 1: Find all accounts that need USD field restoration
List<Account> accountsToUpdate = [
    SELECT Id, Name, Status__c, CurrencyIsoCode,
           ARR__c, ACV__c, TCV__c, MRR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
           (SELECT Id, Exchange_Rate__c FROM Assets WHERE Exchange_Rate__c != null LIMIT 1)
    FROM Account 
    WHERE Status__c IN ('Active (Churning)', 'Churned') 
    AND ARR__c > 0
    AND (ARR_USD__c = '$0' OR ARR_USD__c = null OR ARR_USD_Reporting__c = 0 OR ARR_USD_Reporting__c = null)
];

System.debug('Found ' + accountsToUpdate.size() + ' accounts needing USD restoration');

List<Account> accountsToSave = new List<Account>();

for (Account account : accountsToUpdate) {
    System.debug('Processing account: ' + account.Name + ' (' + account.Status__c + ')');
    
    // Get exchange rate for conversion (default to 1.0 for USD)
    Decimal exchangeRate = 1.0;
    if (account.CurrencyIsoCode != 'USD' && !account.Assets.isEmpty()) {
        exchangeRate = account.Assets[0].Exchange_Rate__c;
    }
    
    Boolean needsUpdate = false;
    
    // Restore USD fields by converting from base currency fields
    if (account.CurrencyIsoCode == 'USD') {
        // USD accounts: direct copy from base currency
        if (account.ARR__c != null && (account.ARR_USD__c == null || account.ARR_USD__c == '$0')) {
            account.ARR_USD__c = '$' + String.valueOf(account.ARR__c.format());
            needsUpdate = true;
        }
        if (account.ACV__c != null && (account.ACV_USD__c == null || account.ACV_USD__c == '$0')) {
            account.ACV_USD__c = '$' + String.valueOf(account.ACV__c.format());
            needsUpdate = true;
        }
        if (account.TCV__c != null && (account.TCV_USD__c == null || account.TCV_USD__c == '$0')) {
            account.TCV_USD__c = '$' + String.valueOf(account.TCV__c.format());
            needsUpdate = true;
        }
        if (account.MRR__c != null && (account.MRR_USD__c == null || account.MRR_USD__c == '$0')) {
            account.MRR_USD__c = '$' + String.valueOf(account.MRR__c.format());
            needsUpdate = true;
        }
        
        // USD Reporting fields (direct copy for USD)
        if (account.ARR__c != null && (account.ARR_USD_Reporting__c == null || account.ARR_USD_Reporting__c == 0)) {
            account.ARR_USD_Reporting__c = account.ARR__c;
            needsUpdate = true;
        }
        if (account.ACV__c != null && (account.ACV_USD_Reporting__c == null || account.ACV_USD_Reporting__c == 0)) {
            account.ACV_USD_Reporting__c = account.ACV__c;
            needsUpdate = true;
        }
        if (account.TCV__c != null && (account.TCV_USD_Reporting__c == null || account.TCV_USD_Reporting__c == 0)) {
            account.TCV_USD_Reporting__c = account.TCV__c;
            needsUpdate = true;
        }
        if (account.MRR__c != null && (account.MRR_USD_Reporting__c == null || account.MRR_USD_Reporting__c == 0)) {
            account.MRR_USD_Reporting__c = account.MRR__c;
            needsUpdate = true;
        }
        
    } else {
        // Non-USD accounts: convert using exchange rate
        if (account.ARR__c != null && (account.ARR_USD__c == null || account.ARR_USD__c == '$0')) {
            Decimal usdValue = account.ARR__c / exchangeRate;
            account.ARR_USD__c = '$' + String.valueOf(usdValue.setScale(2).format());
            needsUpdate = true;
        }
        if (account.ACV__c != null && (account.ACV_USD__c == null || account.ACV_USD__c == '$0')) {
            Decimal usdValue = account.ACV__c / exchangeRate;
            account.ACV_USD__c = '$' + String.valueOf(usdValue.setScale(2).format());
            needsUpdate = true;
        }
        if (account.TCV__c != null && (account.TCV_USD__c == null || account.TCV_USD__c == '$0')) {
            Decimal usdValue = account.TCV__c / exchangeRate;
            account.TCV_USD__c = '$' + String.valueOf(usdValue.setScale(2).format());
            needsUpdate = true;
        }
        if (account.MRR__c != null && (account.MRR_USD__c == null || account.MRR_USD__c == '$0')) {
            Decimal usdValue = account.MRR__c / exchangeRate;
            account.MRR_USD__c = '$' + String.valueOf(usdValue.setScale(2).format());
            needsUpdate = true;
        }
        
        // USD Reporting fields (convert for non-USD)
        if (account.ARR__c != null && (account.ARR_USD_Reporting__c == null || account.ARR_USD_Reporting__c == 0)) {
            account.ARR_USD_Reporting__c = account.ARR__c / exchangeRate;
            needsUpdate = true;
        }
        if (account.ACV__c != null && (account.ACV_USD_Reporting__c == null || account.ACV_USD_Reporting__c == 0)) {
            account.ACV_USD_Reporting__c = account.ACV__c / exchangeRate;
            needsUpdate = true;
        }
        if (account.TCV__c != null && (account.TCV_USD_Reporting__c == null || account.TCV_USD_Reporting__c == 0)) {
            account.TCV_USD_Reporting__c = account.TCV__c / exchangeRate;
            needsUpdate = true;
        }
        if (account.MRR__c != null && (account.MRR_USD_Reporting__c == null || account.MRR_USD_Reporting__c == 0)) {
            account.MRR_USD_Reporting__c = account.MRR__c / exchangeRate;
            needsUpdate = true;
        }
    }
    
    if (needsUpdate) {
        accountsToSave.add(account);
        System.debug('Account ' + account.Name + ' queued for update');
    }
}

System.debug('Updating ' + accountsToSave.size() + ' accounts...');

if (!accountsToSave.isEmpty()) {
    try {
        update accountsToSave;
        System.debug('SUCCESS: Updated ' + accountsToSave.size() + ' accounts with restored USD fields');
        
        // Verification query
        List<Account> verification = [
            SELECT Id, Name, Status__c, ARR__c, ARR_USD__c, ARR_USD_Reporting__c 
            FROM Account 
            WHERE Id IN :accountsToSave
            ORDER BY Name
        ];
        
        System.debug('=== VERIFICATION RESULTS ===');
        for (Account verifyAccount : verification) {
            System.debug('✓ ' + verifyAccount.Name + ' (' + verifyAccount.Status__c + '): ARR=' + verifyAccount.ARR__c + ', ARR_USD=' + verifyAccount.ARR_USD__c + ', ARR_USD_Reporting=' + verifyAccount.ARR_USD_Reporting__c);
        }
        
    } catch (Exception e) {
        System.debug('ERROR updating accounts: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
    }
} else {
    System.debug('No accounts needed updates');
}

System.debug('=== USD RESTORATION COMPLETE ===');
