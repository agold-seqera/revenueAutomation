// BOEHRINGER INGELHEIM GmbH REVENUE ROLLUP ANALYSIS
// Analyze why revenue isn't rolling up correctly after EUR currency update
System.debug('=== BOEHRINGER INGELHEIM GmbH REVENUE ANALYSIS ===');

// Query the Boehringer account with all related data
Account boehringer = [SELECT Id, Name, CurrencyIsoCode, Status__c,
                             ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
                             ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                             (SELECT Id, CurrencyIsoCode, Status, StartDate, EndDate,
                                     ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Incremental_ARR__c,
                                     ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
                                     (SELECT Id, Name, CurrencyIsoCode, ARR__c, Total_Value__c, Total_Price__c,
                                             Start_Date__c, End_Date__c, ProductFamily, Exchange_Rate__c,
                                             ARR_USD__c, Total_Value_USD__c, Total_Price_USD__c
                                      FROM Assets__r
                                      WHERE Exclude_from_Status_Updates__c = false)
                              FROM Contracts
                              ORDER BY StartDate DESC)
                     FROM Account 
                     WHERE Id = '001fJ000021YDzUQAW' LIMIT 1];

System.debug('ACCOUNT DETAILS:');
System.debug('- ID: ' + boehringer.Id);
System.debug('- Name: ' + boehringer.Name);
System.debug('- Currency: ' + boehringer.CurrencyIsoCode);
System.debug('- Status: ' + boehringer.Status__c);
System.debug('- Contracts: ' + boehringer.Contracts.size());

System.debug('');
System.debug('ACCOUNT REVENUE FIELDS:');
System.debug('- ARR: ' + boehringer.ARR__c);
System.debug('- ACV: ' + boehringer.ACV__c);
System.debug('- TCV: ' + boehringer.TCV__c);
System.debug('- MRR: ' + boehringer.MRR__c);
System.debug('- Incremental ARR: ' + boehringer.Incremental_ARR__c);

System.debug('');
System.debug('ACCOUNT USD FIELDS:');
System.debug('- ARR USD: ' + boehringer.ARR_USD__c);
System.debug('- ACV USD: ' + boehringer.ACV_USD__c);
System.debug('- TCV USD: ' + boehringer.TCV_USD__c);
System.debug('- MRR USD: ' + boehringer.MRR_USD__c);

System.debug('');
System.debug('=== CONTRACT ANALYSIS ===');

Date today = Date.today();
Decimal totalExpectedARR = 0;
Decimal totalExpectedTCV = 0;
Decimal totalExpectedACV = 0;
Decimal totalExpectedARR_USD = 0;
Decimal totalExpectedTCV_USD = 0;
Decimal totalExpectedACV_USD = 0;

for (Contract contract : boehringer.Contracts) {
    String contractStatus = 'FUTURE';
    if (contract.StartDate <= today && contract.EndDate >= today) {
        contractStatus = 'ACTIVE';
    } else if (contract.EndDate < today) {
        contractStatus = 'EXPIRED';
    }
    
    System.debug('');
    System.debug('Contract ' + contract.Id + ' (' + contractStatus + '):');
    System.debug('  Currency: ' + contract.CurrencyIsoCode);
    System.debug('  Status: ' + contract.Status);
    System.debug('  Dates: ' + contract.StartDate + ' to ' + contract.EndDate);
    System.debug('  Assets: ' + contract.Assets__r.size());
    
    System.debug('  CONTRACT REVENUE:');
    System.debug('    ARR: ' + contract.ARR__c);
    System.debug('    ACV: ' + contract.ACV__c);
    System.debug('    TCV: ' + contract.TCV__c);
    System.debug('    MRR: ' + contract.MRR__c);
    System.debug('    Active ARR: ' + contract.Active_ARR__c);
    System.debug('    Incremental ARR: ' + contract.Incremental_ARR__c);
    
    System.debug('  CONTRACT USD:');
    System.debug('    ARR USD: ' + contract.ARR_USD__c);
    System.debug('    ACV USD: ' + contract.ACV_USD__c);
    System.debug('    TCV USD: ' + contract.TCV_USD__c);
    System.debug('    MRR USD: ' + contract.MRR_USD__c);
    System.debug('    Active ARR USD: ' + contract.Active_ARR_USD__c);
    
    // Only include ACTIVE contracts in rollup calculation
    if (contractStatus == 'ACTIVE') {
        totalExpectedARR += (contract.ARR__c != null ? contract.ARR__c : 0);
        totalExpectedACV += (contract.ACV__c != null ? contract.ACV__c : 0);
        totalExpectedTCV += (contract.TCV__c != null ? contract.TCV__c : 0);
        
        // Parse USD values
        if (String.isNotBlank(contract.ARR_USD__c)) {
            String cleanARR = contract.ARR_USD__c.replace('$', '').replace(',', '');
            totalExpectedARR_USD += Decimal.valueOf(cleanARR);
        }
        if (String.isNotBlank(contract.ACV_USD__c)) {
            String cleanACV = contract.ACV_USD__c.replace('$', '').replace(',', '');
            totalExpectedACV_USD += Decimal.valueOf(cleanACV);
        }
        if (String.isNotBlank(contract.TCV_USD__c)) {
            String cleanTCV = contract.TCV_USD__c.replace('$', '').replace(',', '');
            totalExpectedTCV_USD += Decimal.valueOf(cleanTCV);
        }
    }
    
    System.debug('  ASSET DETAILS:');
    for (Asset asset : contract.Assets__r) {
        String assetStatus = 'FUTURE';
        if (asset.Start_Date__c <= today && asset.End_Date__c >= today) {
            assetStatus = 'ACTIVE';
        } else if (asset.End_Date__c < today) {
            assetStatus = 'EXPIRED';
        }
        
        System.debug('    Asset ' + asset.Id + ' (' + assetStatus + '):');
        System.debug('      Name: ' + asset.Name);
        System.debug('      Currency: ' + asset.CurrencyIsoCode);
        System.debug('      Exchange Rate: ' + asset.Exchange_Rate__c);
        System.debug('      Product Family: ' + asset.ProductFamily);
        System.debug('      Dates: ' + asset.Start_Date__c + ' to ' + asset.End_Date__c);
        System.debug('      ARR: ' + asset.ARR__c);
        System.debug('      Total Value: ' + asset.Total_Value__c);
        System.debug('      Total Price: ' + asset.Total_Price__c);
        System.debug('      ARR USD: ' + asset.ARR_USD__c);
        System.debug('      Total Value USD: ' + asset.Total_Value_USD__c);
        System.debug('      Total Price USD: ' + asset.Total_Price_USD__c);
    }
}

System.debug('');
System.debug('=== ROLLUP ANALYSIS ===');
System.debug('EXPECTED ACCOUNT TOTALS (from active contracts):');
System.debug('- Expected ARR: ' + totalExpectedARR);
System.debug('- Expected ACV: ' + totalExpectedACV);
System.debug('- Expected TCV: ' + totalExpectedTCV);
System.debug('- Expected ARR USD: $' + totalExpectedARR_USD.setScale(2));
System.debug('- Expected ACV USD: $' + totalExpectedACV_USD.setScale(2));
System.debug('- Expected TCV USD: $' + totalExpectedTCV_USD.setScale(2));

System.debug('');
System.debug('ACTUAL ACCOUNT TOTALS:');
System.debug('- Actual ARR: ' + boehringer.ARR__c);
System.debug('- Actual ACV: ' + boehringer.ACV__c);
System.debug('- Actual TCV: ' + boehringer.TCV__c);
System.debug('- Actual ARR USD: ' + boehringer.ARR_USD__c);
System.debug('- Actual ACV USD: ' + boehringer.ACV_USD__c);
System.debug('- Actual TCV USD: ' + boehringer.TCV_USD__c);

System.debug('');
System.debug('VARIANCE ANALYSIS:');
Decimal arrVariance = (boehringer.ARR__c != null ? boehringer.ARR__c : 0) - totalExpectedARR;
Decimal acvVariance = (boehringer.ACV__c != null ? boehringer.ACV__c : 0) - totalExpectedACV;
Decimal tcvVariance = (boehringer.TCV__c != null ? boehringer.TCV__c : 0) - totalExpectedTCV;

System.debug('- ARR Variance: ' + arrVariance + (arrVariance == 0 ? ' ✅' : ' ❌'));
System.debug('- ACV Variance: ' + acvVariance + (acvVariance == 0 ? ' ✅' : ' ❌'));
System.debug('- TCV Variance: ' + tcvVariance + (tcvVariance == 0 ? ' ✅' : ' ❌'));

// Check USD variance
String actualARR_USD = boehringer.ARR_USD__c != null ? boehringer.ARR_USD__c.replace('$', '').replace(',', '') : '0';
Decimal actualARR_USD_Decimal = Decimal.valueOf(actualARR_USD);
Decimal arrUSDVariance = actualARR_USD_Decimal - totalExpectedARR_USD;
System.debug('- ARR USD Variance: $' + arrUSDVariance.setScale(2) + (Math.abs(arrUSDVariance) < 0.01 ? ' ✅' : ' ❌'));

System.debug('');
System.debug('=== RECOMMENDATIONS ===');
if (arrVariance != 0 || acvVariance != 0 || tcvVariance != 0 || Math.abs(arrUSDVariance) >= 0.01) {
    System.debug('❌ REVENUE ROLLUP ISSUES DETECTED:');
    
    if (arrVariance != 0) {
        System.debug('  - ARR rollup incorrect by ' + arrVariance);
    }
    if (acvVariance != 0) {
        System.debug('  - ACV rollup incorrect by ' + acvVariance);
    }
    if (tcvVariance != 0) {
        System.debug('  - TCV rollup incorrect by ' + tcvVariance);
    }
    if (Math.abs(arrUSDVariance) >= 0.01) {
        System.debug('  - ARR USD rollup incorrect by $' + arrUSDVariance.setScale(2));
    }
    
    System.debug('');
    System.debug('SUGGESTED FIXES:');
    System.debug('1. Run AccountRollupBatch to recalculate account totals');
    System.debug('2. Check if contracts have correct currency after manual update');
    System.debug('3. Verify asset exchange rates are populated');
    System.debug('4. Ensure contract USD fields are populated');
    
} else {
    System.debug('✅ REVENUE ROLLUP IS CORRECT');
    System.debug('Account totals match expected values from active contracts.');
}

System.debug('');
System.debug('=== END BOEHRINGER ANALYSIS ===');
