// Comprehensive analysis of batch execution results
System.debug('=== COMPREHENSIVE POST-BATCH ANALYSIS ===');
System.debug('Analysis Time: ' + DateTime.now());

// PRIORITY 1: Contracted Accounts Analysis (6 total expected)
System.debug('');
System.debug('🎯 PRIORITY 1: CONTRACTED ACCOUNTS ANALYSIS');
System.debug('============================================');

List<Account> contractedAccounts = [
    SELECT Id, Name, Status__c, Type, LastModifiedDate,
           ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
           TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
           MRR__c, MRR_USD__c, MRR_USD_Reporting__c
    FROM Account
    WHERE Status__c = 'Contracted'
    ORDER BY Name
];

System.debug('Found ' + contractedAccounts.size() + ' Contracted accounts');

for (Account account : contractedAccounts) {
    System.debug('--- ' + account.Name + ' (' + account.Id + ') ---');
    System.debug('  Type: ' + account.Type + ' | LastModified: ' + account.LastModifiedDate);
    
    // Check field alignment
    Boolean arrAligned = (account.ARR__c > 0 && account.ARR_USD__c != null && account.ARR_USD__c != '$0' && account.ARR_USD_Reporting__c > 0);
    Boolean acvAligned = (account.ACV__c > 0 && account.ACV_USD__c != null && account.ACV_USD__c != '$0' && account.ACV_USD_Reporting__c > 0);
    Boolean tcvAligned = (account.TCV__c > 0 && account.TCV_USD__c != null && account.TCV_USD__c != '$0' && account.TCV_USD_Reporting__c > 0);
    Boolean mrrAligned = (account.MRR__c > 0 && account.MRR_USD__c != null && account.MRR_USD__c != '$0' && account.MRR_USD_Reporting__c > 0);
    
    System.debug('  ARR: ' + account.ARR__c + ' | USD: ' + account.ARR_USD__c + ' | Reporting: ' + account.ARR_USD_Reporting__c + ' ' + (arrAligned ? '✅' : '⚠️'));
    System.debug('  ACV: ' + account.ACV__c + ' | USD: ' + account.ACV_USD__c + ' | Reporting: ' + account.ACV_USD_Reporting__c + ' ' + (acvAligned ? '✅' : '⚠️'));
    System.debug('  TCV: ' + account.TCV__c + ' | USD: ' + account.TCV_USD__c + ' | Reporting: ' + account.TCV_USD_Reporting__c + ' ' + (tcvAligned ? '✅' : '⚠️'));
    System.debug('  MRR: ' + account.MRR__c + ' | USD: ' + account.MRR_USD__c + ' | Reporting: ' + account.MRR_USD_Reporting__c + ' ' + (mrrAligned ? '✅' : '⚠️'));
    System.debug('');
}

// PRIORITY 2: Churning/Churned Accounts Analysis  
System.debug('🎯 PRIORITY 2: CHURNING/CHURNED ACCOUNTS ANALYSIS');
System.debug('=================================================');

List<Account> churningChurnedAccounts = [
    SELECT Id, Name, Status__c, Type, LastModifiedDate,
           ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
           TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
           MRR__c, MRR_USD__c, MRR_USD_Reporting__c
    FROM Account
    WHERE Status__c IN ('Active (Churning)', 'Churned')
    AND ARR__c > 0  // Only accounts with revenue to preserve
    ORDER BY Status__c, Name
];

System.debug('Found ' + churningChurnedAccounts.size() + ' Churning/Churned accounts with revenue');

for (Account account : churningChurnedAccounts) {
    System.debug('--- ' + account.Name + ' (' + account.Status__c + ') ---');
    System.debug('  Type: ' + account.Type + ' | LastModified: ' + account.LastModifiedDate);
    
    // Revenue preservation validation
    Boolean arrPreserved = (account.ARR__c > 0 && account.ARR_USD__c != null && account.ARR_USD__c != '$0' && account.ARR_USD_Reporting__c > 0);
    Boolean acvPreserved = (account.ACV__c == 0 || (account.ACV__c > 0 && account.ACV_USD__c != null && account.ACV_USD__c != '$0' && account.ACV_USD_Reporting__c > 0));
    Boolean tcvPreserved = (account.TCV__c == 0 || (account.TCV__c > 0 && account.TCV_USD__c != null && account.TCV_USD__c != '$0' && account.TCV_USD_Reporting__c > 0));
    Boolean mrrPreserved = (account.MRR__c == 0 || (account.MRR__c > 0 && account.MRR_USD__c != null && account.MRR_USD__c != '$0' && account.MRR_USD_Reporting__c > 0));
    
    System.debug('  ARR: ' + account.ARR__c + ' | USD: ' + account.ARR_USD__c + ' | Reporting: ' + account.ARR_USD_Reporting__c + ' ' + (arrPreserved ? '✅' : '❌'));
    System.debug('  ACV: ' + account.ACV__c + ' | USD: ' + account.ACV_USD__c + ' | Reporting: ' + account.ACV_USD_Reporting__c + ' ' + (acvPreserved ? '✅' : '❌'));
    System.debug('  TCV: ' + account.TCV__c + ' | USD: ' + account.TCV_USD__c + ' | Reporting: ' + account.TCV_USD_Reporting__c + ' ' + (tcvPreserved ? '✅' : '❌'));
    System.debug('  MRR: ' + account.MRR__c + ' | USD: ' + account.MRR_USD__c + ' | Reporting: ' + account.MRR_USD_Reporting__c + ' ' + (mrrPreserved ? '✅' : '❌'));
    System.debug('');
}

// PRIORITY 3: Atlas Data Storage - Future Contract Verification
System.debug('🎯 PRIORITY 3: ATLAS DATA STORAGE - FUTURE CONTRACT VERIFICATION');
System.debug('===============================================================');

Account atlasAccount = [
    SELECT Id, Name, Status__c, Type, LastModifiedDate,
           ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
           TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
           MRR__c, MRR_USD__c, MRR_USD_Reporting__c,
           (SELECT Id, Status, StartDate, EndDate,
                   ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
                   ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
                   TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
                   MRR__c, MRR_USD__c, MRR_USD_Reporting__c
            FROM Contracts
            WHERE StartDate > :Date.today())
    FROM Account
    WHERE Name = 'Atlas Data Storage'
    LIMIT 1
];

System.debug('--- Atlas Data Storage Account ---');
System.debug('  Status: ' + atlasAccount.Status__c + ' | Type: ' + atlasAccount.Type);
System.debug('  LastModified: ' + atlasAccount.LastModifiedDate);
System.debug('  ARR: ' + atlasAccount.ARR__c + ' | USD: ' + atlasAccount.ARR_USD__c + ' | Reporting: ' + atlasAccount.ARR_USD_Reporting__c);
System.debug('  ACV: ' + atlasAccount.ACV__c + ' | USD: ' + atlasAccount.ACV_USD__c + ' | Reporting: ' + atlasAccount.ACV_USD_Reporting__c);
System.debug('  TCV: ' + atlasAccount.TCV__c + ' | USD: ' + atlasAccount.TCV_USD__c + ' | Reporting: ' + atlasAccount.TCV_USD_Reporting__c);
System.debug('  MRR: ' + atlasAccount.MRR__c + ' | USD: ' + atlasAccount.MRR_USD__c + ' | Reporting: ' + atlasAccount.MRR_USD_Reporting__c);

for (Contract contract : atlasAccount.Contracts) {
    System.debug('  Future Contract: ' + contract.Id + ' (' + contract.Status + ', starts: ' + contract.StartDate + ')');
    System.debug('    ARR: ' + contract.ARR__c + ' | USD: ' + contract.ARR_USD__c + ' | Reporting: ' + contract.ARR_USD_Reporting__c);
    System.debug('    ACV: ' + contract.ACV__c + ' | USD: ' + contract.ACV_USD__c + ' | Reporting: ' + contract.ACV_USD_Reporting__c);
    System.debug('    TCV: ' + contract.TCV__c + ' | USD: ' + contract.TCV_USD__c + ' | Reporting: ' + contract.TCV_USD_Reporting__c);
    System.debug('    MRR: ' + contract.MRR__c + ' | USD: ' + contract.MRR_USD__c + ' | Reporting: ' + contract.MRR_USD_Reporting__c);
}

System.debug('');
System.debug('=== COMPREHENSIVE ANALYSIS COMPLETE ===');
