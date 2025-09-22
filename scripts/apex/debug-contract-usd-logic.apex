// Debug script to investigate why EUR contract USD fields aren't being populated
System.debug('=== DEBUGGING CONTRACT USD LOGIC ===');

// Query the specific EUR contract
Contract testContract = [SELECT Id, Status, ARR__c, ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
                                (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                                        Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
                                 FROM Assets__r 
                                 WHERE Exclude_from_Status_Updates__c = false)
                        FROM Contract 
                        WHERE Id = '800Pn00000k2FjoIAE' LIMIT 1];

System.debug('Contract Status: ' + testContract.Status);
System.debug('Contract ARR: ' + testContract.ARR__c);
System.debug('Contract USD Fields:');
System.debug('  ARR_USD__c: ' + testContract.ARR_USD__c);
System.debug('  ACV_USD__c: ' + testContract.ACV_USD__c);
System.debug('  TCV_USD__c: ' + testContract.TCV_USD__c);
System.debug('  MRR_USD__c: ' + testContract.MRR_USD__c);
System.debug('  Active_ARR_USD__c: ' + testContract.Active_ARR_USD__c);

// Test shouldPopulateUSD condition
Boolean shouldPopulateUSD = (String.isBlank(testContract.ARR_USD__c) || 
                            String.isBlank(testContract.TCV_USD__c) || 
                            String.isBlank(testContract.ACV_USD__c) ||
                            String.isBlank(testContract.MRR_USD__c) ||
                            String.isBlank(testContract.Active_ARR_USD__c));

System.debug('shouldPopulateUSD: ' + shouldPopulateUSD);

if (shouldPopulateUSD) {
    System.debug('USD condition MET - processing assets...');
    
    Date today = Date.today();
    Decimal varARR_Total = 0;
    Decimal varTCV_Total = 0;
    
    for (Asset asset : testContract.Assets__r) {
        System.debug('Asset: ' + asset.Id + ' | ARR: ' + asset.ARR__c + ' | Exchange: ' + asset.Exchange_Rate__c);
        System.debug('  Start: ' + asset.Start_Date__c + ' | End: ' + asset.End_Date__c + ' | Family: ' + asset.ProductFamily);
        
        // TCV calculation
        Decimal forTCV_USD = (asset.Total_Value__c != null ? asset.Total_Value__c : 0) / 
                             (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
        varTCV_Total += forTCV_USD;
        System.debug('  TCV_USD: ' + forTCV_USD + ' | Running Total: ' + varTCV_Total);
        
        // Active asset check
        if (asset.Start_Date__c <= today && 
            asset.End_Date__c >= today && 
            asset.ProductFamily != 'Professional Service') {
            
            Decimal forARR_USD = (asset.ARR__c != null ? asset.ARR__c : 0) / 
                                 (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
            varARR_Total += forARR_USD;
            System.debug('  ACTIVE ASSET - ARR_USD: ' + forARR_USD + ' | Running Total: ' + varARR_Total);
        } else {
            System.debug('  NOT ACTIVE: Start=' + asset.Start_Date__c + ', End=' + asset.End_Date__c + ', Family=' + asset.ProductFamily);
        }
    }
    
    System.debug('Final USD Totals:');
    System.debug('  varARR_Total: ' + varARR_Total);
    System.debug('  varTCV_Total: ' + varTCV_Total);
    
    // Test currency formatter
    try {
        CurrencyFormatterHelper.FormatInput request = new CurrencyFormatterHelper.FormatInput();
        request.amount = varARR_Total;
        List<CurrencyFormatterHelper.FormatInput> requests = new List<CurrencyFormatterHelper.FormatInput>{request};
        List<CurrencyFormatterHelper.FormatOutput> responses = CurrencyFormatterHelper.formatCurrency(requests);
        System.debug('Formatted ARR_USD: ' + responses[0].formattedAmount);
    } catch (Exception e) {
        System.debug('Currency formatting error: ' + e.getMessage());
    }
    
} else {
    System.debug('USD condition NOT MET - skipping USD calculations');
}

System.debug('=== END DEBUG ===');
