// Debug script to test USD field calculation logic for a simple test case

// Query a contract to test with
List<Contract> testContracts = [SELECT Id, ContractNumber, CurrencyIsoCode, ARR__c, ARR_USD__c, 
                              ACV__c, ACV_USD__c, Status, 
                              (SELECT Exchange_Rate__c FROM Assets__r LIMIT 1)
                              FROM Contract 
                              WHERE Status = 'Activated' AND ARR__c > 0 
                              LIMIT 1];

if (!testContracts.isEmpty()) {
    Contract testContract = testContracts[0];
    System.debug('=== BEFORE PROCESSING ===');
    System.debug('Contract: ' + testContract.ContractNumber);
    System.debug('Status: ' + testContract.Status);
    System.debug('CurrencyIsoCode: ' + testContract.CurrencyIsoCode);
    System.debug('ARR__c: ' + testContract.ARR__c);
    System.debug('ARR_USD__c: ' + testContract.ARR_USD__c);
    System.debug('ACV__c: ' + testContract.ACV__c);
    System.debug('ACV_USD__c: ' + testContract.ACV_USD__c);
    
    // Manually check shouldPopulateRevenue logic
    Boolean shouldPopulateRevenue = false;
    if (testContract.Status == 'Activated') {
        shouldPopulateRevenue = true;
        System.debug('shouldPopulateRevenue = true (Activated contract)');
    }
    
    // Manually check shouldPopulateUSD logic  
    Boolean shouldPopulateUSD = false;
    if (shouldPopulateRevenue) {
        shouldPopulateUSD = true;
        System.debug('shouldPopulateUSD = true (shouldPopulateRevenue is true)');
    }
    
    if (shouldPopulateUSD) {
        System.debug('=== USD CALCULATION LOGIC ===');
        
        Decimal exchangeRate = 1.0;
        if (!testContract.Assets__r.isEmpty() && testContract.Assets__r[0].Exchange_Rate__c != null) {
            exchangeRate = testContract.Assets__r[0].Exchange_Rate__c;
        }
        System.debug('Exchange Rate: ' + exchangeRate);
        
        Decimal varARR_Total = 0;
        Decimal varACV_Total = 0;
        
        if (testContract.CurrencyIsoCode == 'USD') {
            System.debug('USD Contract - Direct Copy');
            varARR_Total = (testContract.ARR__c != null ? testContract.ARR__c : 0);
            varACV_Total = (testContract.ACV__c != null ? testContract.ACV__c : 0);
        } else {
            System.debug('Non-USD Contract - Conversion');
            varARR_Total = (testContract.ARR__c != null ? testContract.ARR__c / exchangeRate : 0);
            varACV_Total = (testContract.ACV__c != null ? testContract.ACV__c / exchangeRate : 0);
        }
        
        System.debug('Calculated varARR_Total: ' + varARR_Total);
        System.debug('Calculated varACV_Total: ' + varACV_Total);
        
        // Test currency formatting
        CurrencyFormatterHelper.FormatInput request1 = new CurrencyFormatterHelper.FormatInput();
        request1.amount = varARR_Total;
        List<CurrencyFormatterHelper.FormatInput> requests1 = new List<CurrencyFormatterHelper.FormatInput>{request1};
        List<CurrencyFormatterHelper.FormatOutput> responses1 = CurrencyFormatterHelper.formatCurrency(requests1);
        
        System.debug('Formatted ARR_USD result: ' + responses1[0].formattedAmount);
        System.debug('Should be assigned to ARR_USD__c');
    } else {
        System.debug('USD calculation skipped - shouldPopulateUSD = false');
    }
} else {
    System.debug('No activated contracts with ARR > 0 found for testing');
}
