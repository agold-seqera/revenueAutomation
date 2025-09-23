// Step by step debug of the exact test scenario with detailed logging

// Find our test contract again
List<Contract> testContracts = [SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c, CurrencyIsoCode,
                              ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
                              ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
                              ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c,
                              (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                                      Start_Date__c, End_Date__c, Product2.Family, ProductFamily, Exclude_from_Status_Updates__c
                               FROM Assets__r 
                               WHERE Exclude_from_Status_Updates__c = false)
                       FROM Contract 
                       WHERE ARR__c = 100000 AND CurrencyIsoCode = 'USD' 
                       ORDER BY CreatedDate DESC LIMIT 1];

if (!testContracts.isEmpty()) {
    Contract testContract = testContracts[0];
    
    System.debug('=== DETAILED TEST CONTRACT ANALYSIS ===');
    System.debug('Contract ID: ' + testContract.Id);
    System.debug('Status: ' + testContract.Status);
    System.debug('ARR__c: ' + testContract.ARR__c);
    System.debug('ARR_USD__c (BEFORE): ' + testContract.ARR_USD__c);
    System.debug('Exclude_from_Status_Updates__c: ' + testContract.Exclude_from_Status_Updates__c);
    System.debug('Assets count: ' + testContract.Assets__r.size());
    
    // Step 1: Test shouldPopulateRevenue logic
    Boolean shouldPopulateRevenue = false;
    if (testContract.Status == 'Draft' || testContract.Status == null) {
        // Legacy Draft/null: Only if revenue fields are empty
        if (testContract.ARR__c == null || testContract.ARR__c == 0) {
            shouldPopulateRevenue = true;
            System.debug('shouldPopulateRevenue = true (Draft with empty ARR)');
        } else {
            System.debug('shouldPopulateRevenue = false (Draft with existing ARR: ' + testContract.ARR__c + ')');
        }
    } else if (testContract.Status == 'Activated') {
        // Activated contracts: ALWAYS recalculate for accuracy (per user requirements)
        shouldPopulateRevenue = true;
        System.debug('shouldPopulateRevenue = true (Activated contract)');
    } else {
        System.debug('shouldPopulateRevenue = false (Status: ' + testContract.Status + ')');
    }
    
    // Step 2: Test shouldPopulateUSD logic
    Boolean shouldPopulateUSD = false;
    if (testContract.Exclude_from_Status_Updates__c != true && shouldPopulateRevenue) {
        shouldPopulateUSD = true;
        System.debug('shouldPopulateUSD = true');
    } else {
        System.debug('shouldPopulateUSD = false');
        System.debug('  Exclude_from_Status_Updates__c: ' + testContract.Exclude_from_Status_Updates__c);
        System.debug('  shouldPopulateRevenue: ' + shouldPopulateRevenue);
    }
    
    if (shouldPopulateUSD) {
        System.debug('=== USD CALCULATION WOULD EXECUTE ===');
        
        // Get exchange rate from first asset (or default to 1.0 for USD)
        Decimal exchangeRate = 1.0;
        if (!testContract.Assets__r.isEmpty() && testContract.Assets__r[0].Exchange_Rate__c != null) {
            exchangeRate = testContract.Assets__r[0].Exchange_Rate__c;
        }
        System.debug('Exchange Rate: ' + exchangeRate);
        
        // For USD conversion, use contract base currency fields (already calculated)
        Decimal varARR_Total = 0;
        if (testContract.CurrencyIsoCode == 'USD') {
            System.debug('USD Contract - Direct Copy');
            varARR_Total = (testContract.ARR__c != null ? testContract.ARR__c : 0);
        } else {
            System.debug('Non-USD Contract - Conversion');
            varARR_Total = (testContract.ARR__c != null ? testContract.ARR__c / exchangeRate : 0);
        }
        
        System.debug('Calculated varARR_Total: ' + varARR_Total);
        
        // Test currency formatting
        try {
            CurrencyFormatterHelper.FormatInput request1 = new CurrencyFormatterHelper.FormatInput();
            request1.amount = varARR_Total;
            List<CurrencyFormatterHelper.FormatInput> requests1 = new List<CurrencyFormatterHelper.FormatInput>{request1};
            List<CurrencyFormatterHelper.FormatOutput> responses1 = CurrencyFormatterHelper.formatCurrency(requests1);
            System.debug('Currency Formatter Result: ' + responses1[0].formattedAmount);
            System.debug('This SHOULD be assigned to ARR_USD__c');
        } catch (Exception e) {
            System.debug('ERROR in currency formatting: ' + e.getMessage());
        }
    } else {
        System.debug('USD logic WOULD BE SKIPPED');
    }
    
    // Now actually run ContractRevenueBatch to see what happens
    System.debug('=== RUNNING CONTRACTREVENUEBATCH ===');
    try {
        ContractRevenueBatch batch = new ContractRevenueBatch();
        List<Contract> contracts = new List<Contract>{testContract};
        batch.execute(null, contracts);
        System.debug('ContractRevenueBatch executed successfully');
    } catch (Exception e) {
        System.debug('ERROR in ContractRevenueBatch: ' + e.getMessage());
        System.debug('Stack: ' + e.getStackTraceString());
    }
    
    // Query final result
    Contract finalContract = [SELECT ARR_USD__c, ACV_USD__c FROM Contract WHERE Id = :testContract.Id];
    System.debug('=== FINAL RESULT ===');
    System.debug('ARR_USD__c (AFTER): ' + finalContract.ARR_USD__c);
    System.debug('ACV_USD__c (AFTER): ' + finalContract.ACV_USD__c);
    
} else {
    System.debug('No test contract found');
}
