// Analyze all Contracted accounts to see USD vs Reporting field alignment
System.debug('=== ANALYZING CONTRACTED ACCOUNTS REPORTING FIELDS ===');

// Get all Contracted accounts with their revenue fields
List<Account> contractedAccounts = [
    SELECT Id, Name, Status__c, Type,
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
            WHERE StartDate > :Date.today()
            AND Status = 'Draft'
            ORDER BY StartDate)
    FROM Account
    WHERE Status__c = 'Contracted'
    ORDER BY Name
];

System.debug('Found ' + contractedAccounts.size() + ' Contracted accounts');

for (Account account : contractedAccounts) {
    System.debug('--- ACCOUNT: ' + account.Name + ' ---');
    System.debug('  Type: ' + account.Type);
    System.debug('  ARR: ' + account.ARR__c + ' | USD: ' + account.ARR_USD__c + ' | Reporting: ' + account.ARR_USD_Reporting__c);
    System.debug('  ACV: ' + account.ACV__c + ' | USD: ' + account.ACV_USD__c + ' | Reporting: ' + account.ACV_USD_Reporting__c);
    System.debug('  TCV: ' + account.TCV__c + ' | USD: ' + account.TCV_USD__c + ' | Reporting: ' + account.TCV_USD_Reporting__c);
    System.debug('  MRR: ' + account.MRR__c + ' | USD: ' + account.MRR_USD__c + ' | Reporting: ' + account.MRR_USD_Reporting__c);
    
    // Check for misalignment between USD and Reporting fields
    Boolean hasReportingMismatch = false;
    
    if (account.ARR_USD__c != null && account.ARR_USD__c != '$0' && account.ARR_USD__c != '$0.00' && 
        (account.ARR_USD_Reporting__c == null || account.ARR_USD_Reporting__c == 0)) {
        System.debug('  ⚠️  ARR: USD populated (' + account.ARR_USD__c + ') but Reporting is 0');
        hasReportingMismatch = true;
    }
    
    if (account.ACV_USD__c != null && account.ACV_USD__c != '$0' && account.ACV_USD__c != '$0.00' && 
        (account.ACV_USD_Reporting__c == null || account.ACV_USD_Reporting__c == 0)) {
        System.debug('  ⚠️  ACV: USD populated (' + account.ACV_USD__c + ') but Reporting is 0');
        hasReportingMismatch = true;
    }
    
    if (account.TCV_USD__c != null && account.TCV_USD__c != '$0' && account.TCV_USD__c != '$0.00' && 
        (account.TCV_USD_Reporting__c == null || account.TCV_USD_Reporting__c == 0)) {
        System.debug('  ⚠️  TCV: USD populated (' + account.TCV_USD__c + ') but Reporting is 0');
        hasReportingMismatch = true;
    }
    
    if (account.MRR_USD__c != null && account.MRR_USD__c != '$0' && account.MRR_USD__c != '$0.00' && 
        (account.MRR_USD_Reporting__c == null || account.MRR_USD_Reporting__c == 0)) {
        System.debug('  ⚠️  MRR: USD populated (' + account.MRR_USD__c + ') but Reporting is 0');
        hasReportingMismatch = true;
    }
    
    if (!hasReportingMismatch) {
        System.debug('  ✅ All USD and Reporting fields are aligned');
    }
    
    // Show future contracts for context
    if (!account.Contracts.isEmpty()) {
        System.debug('  Future Contracts:');
        for (Contract contract : account.Contracts) {
            System.debug('    Contract ' + contract.Id + ' (' + contract.Status + ', starts: ' + contract.StartDate + ')');
            System.debug('      ARR: ' + contract.ARR__c + ' | USD: ' + contract.ARR_USD__c + ' | Reporting: ' + contract.ARR_USD_Reporting__c);
            System.debug('      ACV: ' + contract.ACV__c + ' | USD: ' + contract.ACV_USD__c + ' | Reporting: ' + contract.ACV_USD_Reporting__c);
            System.debug('      TCV: ' + contract.TCV__c + ' | USD: ' + contract.TCV_USD__c + ' | Reporting: ' + contract.TCV_USD_Reporting__c);
            System.debug('      MRR: ' + contract.MRR__c + ' | USD: ' + contract.MRR_USD__c + ' | Reporting: ' + contract.MRR_USD_Reporting__c);
        }
    }
    
    System.debug('');
}

System.debug('=== ANALYSIS COMPLETE ===');
