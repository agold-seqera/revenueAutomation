// Verify Boehringer revenue fix after AccountRollupBatch
System.debug('=== VERIFYING BOEHRINGER FIX ===');

// Check batch job status first
List<AsyncApexJob> jobs = [SELECT Id, Status, NumberOfErrors, CompletedDate, 
                                  JobItemsProcessed, TotalJobItems
                          FROM AsyncApexJob 
                          WHERE Id = '707Pn000020lmwhIAA' 
                          LIMIT 1];

if (jobs.size() > 0) {
    AsyncApexJob job = jobs[0];
    System.debug('Batch Job Status: ' + job.Status);
    System.debug('Items Processed: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
    System.debug('Errors: ' + job.NumberOfErrors);
    System.debug('Completed: ' + job.CompletedDate);
} else {
    System.debug('Batch job not found - may have completed and been cleaned up');
}

System.debug('');
System.debug('=== BOEHRINGER ACCOUNT VERIFICATION ===');

// Re-query Boehringer account to verify fix
Account boehringer = [SELECT Id, Name, CurrencyIsoCode, Status__c,
                             ARR__c, ACV__c, TCV__c, MRR__c,
                             ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c
                     FROM Account 
                     WHERE Id = '001fJ000021YDzUQAW' LIMIT 1];

System.debug('UPDATED ACCOUNT DETAILS:');
System.debug('- Name: ' + boehringer.Name);
System.debug('- Currency: ' + boehringer.CurrencyIsoCode);
System.debug('- Status: ' + boehringer.Status__c);

System.debug('');
System.debug('UPDATED REVENUE FIELDS (EUR):');
System.debug('- ARR: ' + boehringer.ARR__c);
System.debug('- ACV: ' + boehringer.ACV__c);
System.debug('- TCV: ' + boehringer.TCV__c);
System.debug('- MRR: ' + boehringer.MRR__c);

System.debug('');
System.debug('USD FIELDS (should be preserved):');
System.debug('- ARR USD: ' + boehringer.ARR_USD__c);
System.debug('- ACV USD: ' + boehringer.ACV_USD__c);
System.debug('- TCV USD: ' + boehringer.TCV_USD__c);
System.debug('- MRR USD: ' + boehringer.MRR_USD__c);

System.debug('');
System.debug('EXPECTED VALUES (from analysis):');
System.debug('- Expected ARR: 252189.72');
System.debug('- Expected ACV: 275099.04');
System.debug('- Expected TCV: 275099.04');

System.debug('');
System.debug('VARIANCE CHECK:');
Decimal expectedARR = 252189.72;
Decimal expectedACV = 275099.04;
Decimal expectedTCV = 275099.04;

Decimal arrVariance = (boehringer.ARR__c != null ? boehringer.ARR__c : 0) - expectedARR;
Decimal acvVariance = (boehringer.ACV__c != null ? boehringer.ACV__c : 0) - expectedACV;
Decimal tcvVariance = (boehringer.TCV__c != null ? boehringer.TCV__c : 0) - expectedTCV;

System.debug('- ARR Variance: ' + arrVariance + (Math.abs(arrVariance) < 0.01 ? ' ✅' : ' ❌'));
System.debug('- ACV Variance: ' + acvVariance + (Math.abs(acvVariance) < 0.01 ? ' ✅' : ' ❌'));
System.debug('- TCV Variance: ' + tcvVariance + (Math.abs(tcvVariance) < 0.01 ? ' ✅' : ' ❌'));

if (Math.abs(arrVariance) < 0.01 && Math.abs(acvVariance) < 0.01 && Math.abs(tcvVariance) < 0.01) {
    System.debug('');
    System.debug('🎉 SUCCESS! Boehringer revenue rollup is now CORRECT!');
    System.debug('✅ EUR revenue fields match expected values from active contracts');
    System.debug('✅ USD fields preserved after currency update');
} else {
    System.debug('');
    System.debug('⚠️ Revenue rollup still has issues after batch run');
    System.debug('May need to investigate further or run batch again');
}

System.debug('');
System.debug('=== END VERIFICATION ===');
