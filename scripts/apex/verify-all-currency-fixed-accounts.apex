// Verify revenue rollups for ALL accounts we just fixed with currency updates
System.debug('=== VERIFYING ALL CURRENCY-FIXED ACCOUNTS ===');

// Check the batch job that just completed
List<AsyncApexJob> jobs = [SELECT Id, Status, NumberOfErrors, CompletedDate, 
                                  JobItemsProcessed, TotalJobItems, ExtendedStatus
                          FROM AsyncApexJob 
                          WHERE Id = '707Pn000020lmwhIAA' 
                          LIMIT 1];

if (jobs.size() > 0) {
    AsyncApexJob job = jobs[0];
    System.debug('BATCH JOB DETAILS:');
    System.debug('- Status: ' + job.Status);
    System.debug('- Items Processed: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
    System.debug('- Errors: ' + job.NumberOfErrors);
    System.debug('- Completed: ' + job.CompletedDate);
    System.debug('- Extended Status: ' + job.ExtendedStatus);
    System.debug('');
}

// List of all accounts we fixed with currency updates (19 accounts + Boehringer manually)
List<String> fixedAccountIds = new List<String>{
    '001fJ000021Y8qoQAC', // Champalimaud Foundation (USD → EUR)
    '001fJ000021Y9rwQAC', // Shift Bioscience (USD → GBP)
    '001fJ000021YBQ3QAO', // Nucleome Therapeutics (USD → EUR)
    '001fJ000021YCbNQAW', // Almirall (USD → EUR)
    '001fJ000021YCoZQAW', // GenomeUp (USD → EUR)
    '001fJ000021YCorQAG', // Cosyne (USD → EUR)
    '001fJ000021YD40QAG', // Healx (USD → EUR)
    '001fJ000021YD4VQAW', // Lonza (USD → EUR)
    '001fJ000021YDMoQAO', // AB Enzymes (USD → EUR)
    '001fJ000021YDNJQA4', // Single Cell Discoveries (USD → EUR)
    '001fJ000021YDZhQAO', // Nonacus (USD → GBP)
    '001fJ000021YDgvQAG', // Rijk Zwaan Zaadteelt en Zaadhandel B.V (USD → EUR)
    '001fJ000021YDrtQAG', // IEO Istituto Europeo di Oncologia (USD → EUR)
    '001fJ000021YDxRQAW', // Genomics England (USD → EUR)
    '001fJ000021YDxfQAG', // EBI / EMBL (USD → EUR)
    '001fJ000021YDxsQAG', // SciLifeLab Clinical (USD → EUR)
    '001fJ000021YDzNQAW', // IARC (USD → EUR)
    '001fJ000021YDzZQAW', // Biomodal (USD → EUR)
    '001fJ000021YEZ5QAO', // Eligo Bioscience (USD → EUR)
    '001fJ000021YDzUQAW'  // Boehringer Ingelheim GmbH (manually updated to EUR)
};

// Query all fixed accounts to verify rollups
List<Account> fixedAccounts = [SELECT Id, Name, CurrencyIsoCode,
                                      ARR__c, ACV__c, TCV__c, MRR__c,
                                      ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                                      LastModifiedDate,
                                      (SELECT Id, CurrencyIsoCode, ARR__c, ACV__c, TCV__c
                                       FROM Contracts 
                                       WHERE StartDate <= TODAY AND EndDate >= TODAY
                                       ORDER BY StartDate DESC)
                              FROM Account 
                              WHERE Id IN :fixedAccountIds
                              ORDER BY Name];

System.debug('PROCESSING ' + fixedAccounts.size() + ' CURRENCY-FIXED ACCOUNTS:');
System.debug('');

Integer accountsWithRollupIssues = 0;
Integer accountsWithCorrectRollups = 0;

for (Account account : fixedAccounts) {
    System.debug('=== ' + account.Name + ' ===');
    System.debug('- ID: ' + account.Id);
    System.debug('- Currency: ' + account.CurrencyIsoCode);
    System.debug('- Last Modified: ' + account.LastModifiedDate);
    System.debug('- Active Contracts: ' + account.Contracts.size());
    
    // Calculate expected revenue from active contracts
    Decimal expectedARR = 0;
    Decimal expectedACV = 0;
    Decimal expectedTCV = 0;
    
    for (Contract contract : account.Contracts) {
        expectedARR += (contract.ARR__c != null ? contract.ARR__c : 0);
        expectedACV += (contract.ACV__c != null ? contract.ACV__c : 0);
        expectedTCV += (contract.TCV__c != null ? contract.TCV__c : 0);
    }
    
    System.debug('REVENUE COMPARISON:');
    System.debug('  Expected ARR: ' + expectedARR);
    System.debug('  Actual ARR: ' + account.ARR__c);
    System.debug('  Expected ACV: ' + expectedACV);
    System.debug('  Actual ACV: ' + account.ACV__c);
    System.debug('  Expected TCV: ' + expectedTCV);
    System.debug('  Actual TCV: ' + account.TCV__c);
    
    // Check for variance
    Decimal arrVariance = (account.ARR__c != null ? account.ARR__c : 0) - expectedARR;
    Decimal acvVariance = (account.ACV__c != null ? account.ACV__c : 0) - expectedACV;
    Decimal tcvVariance = (account.TCV__c != null ? account.TCV__c : 0) - expectedTCV;
    
    Boolean hasVariance = (Math.abs(arrVariance) >= 0.01 || Math.abs(acvVariance) >= 0.01 || Math.abs(tcvVariance) >= 0.01);
    
    if (hasVariance) {
        System.debug('  ❌ VARIANCE DETECTED:');
        if (Math.abs(arrVariance) >= 0.01) System.debug('    ARR Variance: ' + arrVariance);
        if (Math.abs(acvVariance) >= 0.01) System.debug('    ACV Variance: ' + acvVariance);
        if (Math.abs(tcvVariance) >= 0.01) System.debug('    TCV Variance: ' + tcvVariance);
        accountsWithRollupIssues++;
    } else {
        System.debug('  ✅ ROLLUP CORRECT');
        accountsWithCorrectRollups++;
    }
    
    System.debug('USD FIELDS:');
    System.debug('  ARR USD: ' + account.ARR_USD__c);
    System.debug('  ACV USD: ' + account.ACV_USD__c);
    System.debug('  TCV USD: ' + account.TCV_USD__c);
    System.debug('');
}

System.debug('=== SUMMARY ===');
System.debug('BATCH JOB: Processed ' + (jobs.size() > 0 ? String.valueOf(jobs[0].JobItemsProcessed) : 'unknown') + ' account batches');
System.debug('CURRENCY-FIXED ACCOUNTS: ' + fixedAccounts.size() + ' total');
System.debug('✅ Accounts with correct rollups: ' + accountsWithCorrectRollups);
System.debug('❌ Accounts with rollup issues: ' + accountsWithRollupIssues);

if (accountsWithRollupIssues == 0) {
    System.debug('');
    System.debug('🎉 ALL CURRENCY-FIXED ACCOUNTS HAVE CORRECT REVENUE ROLLUPS!');
    System.debug('✅ The AccountRollupBatch successfully recalculated all accounts after currency updates');
} else {
    System.debug('');
    System.debug('⚠️ Some accounts still have rollup issues after the batch run');
    System.debug('May need additional investigation or another batch run');
}

System.debug('');
System.debug('=== END VERIFICATION ===');
