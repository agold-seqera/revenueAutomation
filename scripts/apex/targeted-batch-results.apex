// Monitor targeted batch results for specific accounts
System.debug('=== TARGETED BATCH RESULTS ANALYSIS ===');

// Check job statuses first
List<Id> jobIds = new List<Id>{'707Pn0000211lcDIAQ', '707Pn0000211lcFIAQ', '707Pn0000211lcHIAQ'};

List<AsyncApexJob> jobs = [
    SELECT Id, ApexClass.Name, Status, JobItemsProcessed, TotalJobItems,
           NumberOfErrors, CompletedDate, CreatedDate
    FROM AsyncApexJob 
    WHERE Id IN :jobIds
    ORDER BY CreatedDate
];

System.debug('=== BATCH JOB STATUS ===');
for (AsyncApexJob job : jobs) {
    System.debug(job.ApexClass.Name + ' (' + job.Id + '):');
    System.debug('  Status: ' + job.Status);
    System.debug('  Items: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
    System.debug('  Errors: ' + job.NumberOfErrors);
    System.debug('  Created: ' + job.CreatedDate);
    System.debug('  Completed: ' + job.CompletedDate);
    System.debug('');
}

// Get updated account details after batch processing
List<Account> targetAccounts = [
    SELECT Id, Name, Status__c, Type, Has_Contracts__c,
           ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
           TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
           MRR__c, MRR_USD__c, MRR_USD_Reporting__c,
           LastModifiedDate,
           (SELECT Id, Status, StartDate, EndDate, LastModifiedDate,
                   ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
                   ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
                   TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
                   MRR__c, MRR_USD__c, MRR_USD_Reporting__c,
                   CurrencyIsoCode, Exclude_from_Status_Updates__c
            FROM Contracts
            WHERE Exclude_from_Status_Updates__c = false)
    FROM Account
    WHERE Id IN ('001fJ000021YDvaQAG', '001fJ000022JGzmQAG')
    ORDER BY Name
];

System.debug('=== POST-BATCH ACCOUNT STATE ===');
for (Account account : targetAccounts) {
    System.debug('--- ' + account.Name + ' (' + account.Id + ') ---');
    System.debug('  Status: ' + account.Status__c + ' | Type: ' + account.Type);
    System.debug('  Has_Contracts: ' + account.Has_Contracts__c);
    System.debug('  LastModified: ' + account.LastModifiedDate);
    
    // Check for field alignment
    Boolean arrAligned = (account.ARR__c == 0 && account.ARR_USD__c == '$0' && account.ARR_USD_Reporting__c == 0) ||
                        (account.ARR__c > 0 && account.ARR_USD__c != null && account.ARR_USD__c != '$0' && account.ARR_USD_Reporting__c > 0);
    Boolean acvAligned = (account.ACV__c == 0 && account.ACV_USD__c == '$0' && account.ACV_USD_Reporting__c == 0) ||
                        (account.ACV__c > 0 && account.ACV_USD__c != null && account.ACV_USD__c != '$0' && account.ACV_USD_Reporting__c > 0);
    Boolean tcvAligned = (account.TCV__c == 0 && account.TCV_USD__c == '$0' && account.TCV_USD_Reporting__c == 0) ||
                        (account.TCV__c > 0 && account.TCV_USD__c != null && account.TCV_USD__c != '$0' && account.TCV_USD_Reporting__c > 0);
    Boolean mrrAligned = (account.MRR__c == 0 && account.MRR_USD__c == '$0' && account.MRR_USD_Reporting__c == 0) ||
                        (account.MRR__c > 0 && account.MRR_USD__c != null && account.MRR_USD__c != '$0' && account.MRR_USD_Reporting__c > 0);
    
    System.debug('  ARR: ' + account.ARR__c + ' | USD: ' + account.ARR_USD__c + ' | Reporting: ' + account.ARR_USD_Reporting__c + ' ' + (arrAligned ? '✅' : '⚠️'));
    System.debug('  ACV: ' + account.ACV__c + ' | USD: ' + account.ACV_USD__c + ' | Reporting: ' + account.ACV_USD_Reporting__c + ' ' + (acvAligned ? '✅' : '⚠️'));
    System.debug('  TCV: ' + account.TCV__c + ' | USD: ' + account.TCV_USD__c + ' | Reporting: ' + account.TCV_USD_Reporting__c + ' ' + (tcvAligned ? '✅' : '⚠️'));
    System.debug('  MRR: ' + account.MRR__c + ' | USD: ' + account.MRR_USD__c + ' | Reporting: ' + account.MRR_USD_Reporting__c + ' ' + (mrrAligned ? '✅' : '⚠️'));
    
    System.debug('  Contracts (' + account.Contracts.size() + ' total):');
    for (Contract contract : account.Contracts) {
        System.debug('    ' + contract.Id + ' (' + contract.Status + ') Start: ' + contract.StartDate + ' End: ' + contract.EndDate);
        
        // Check contract field alignment
        Boolean contractArrAligned = (contract.ARR__c == 0 && contract.ARR_USD__c == '$0.00' && contract.ARR_USD_Reporting__c == 0) ||
                                   (contract.ARR__c > 0 && contract.ARR_USD__c != null && contract.ARR_USD__c != '$0.00' && contract.ARR_USD_Reporting__c > 0);
        Boolean contractAcvAligned = (contract.ACV__c == 0 && contract.ACV_USD__c == '$0.00' && contract.ACV_USD_Reporting__c == 0) ||
                                   (contract.ACV__c > 0 && contract.ACV_USD__c != null && contract.ACV_USD__c != '$0.00' && contract.ACV_USD_Reporting__c > 0);
        Boolean contractTcvAligned = (contract.TCV__c == 0 && contract.TCV_USD__c == '$0.00' && contract.TCV_USD_Reporting__c == 0) ||
                                   (contract.TCV__c > 0 && contract.TCV_USD__c != null && contract.TCV_USD__c != '$0.00' && contract.TCV_USD_Reporting__c > 0);
        
        System.debug('      ARR: ' + contract.ARR__c + ' | USD: ' + contract.ARR_USD__c + ' | Reporting: ' + contract.ARR_USD_Reporting__c + ' ' + (contractArrAligned ? '✅' : '⚠️'));
        System.debug('      ACV: ' + contract.ACV__c + ' | USD: ' + contract.ACV_USD__c + ' | Reporting: ' + contract.ACV_USD_Reporting__c + ' ' + (contractAcvAligned ? '✅' : '⚠️'));
        System.debug('      TCV: ' + contract.TCV__c + ' | USD: ' + contract.TCV_USD__c + ' | Reporting: ' + contract.TCV_USD_Reporting__c + ' ' + (contractTcvAligned ? '✅' : '⚠️'));
        System.debug('      LastModified: ' + contract.LastModifiedDate);
    }
    System.debug('');
}

// Summary analysis
System.debug('=== ANALYSIS SUMMARY ===');
System.debug('Key Issues Identified in Pre-Batch State:');
System.debug('1. AlloX: Had TCV value but $0 ARR/ACV/MRR - contract shows $0 ARR');
System.debug('2. e-therapeutics plc: Had TCV value but $0 ARR/ACV/MRR - one expired contract with revenue');
System.debug('');
System.debug('Expected Post-Batch Behavior:');
System.debug('1. Both accounts should maintain their Active status');
System.debug('2. Revenue fields should align with active contract calculations');
System.debug('3. Expired contracts should preserve their USD values');
System.debug('4. Active contracts with $0 revenue should remain $0');

System.debug('=== TARGETED BATCH ANALYSIS COMPLETE ===');
