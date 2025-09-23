// Debug the exact test scenario to see what's happening

// Recreate the test scenario exactly as the failing test does
Account testAccount = [SELECT Id FROM Account LIMIT 1];

Contract populatedContract = new Contract(
    AccountId = testAccount.Id,
    ContractTerm = 12,
    StartDate = Date.today(),
    EndDate = Date.today().addMonths(12),
    Status = 'Draft'
);
// Don't set CurrencyIsoCode - let it default

populatedContract.Status = 'Draft';
populatedContract.StartDate = Date.today().addDays(-10);
populatedContract.EndDate = Date.today().addDays(355);
populatedContract.ARR__c = 100000;
populatedContract.ARR_USD__c = '$50,000.00'; // Intentionally misaligned value
populatedContract.TCV_USD__c = '$75,000.00'; // Intentionally misaligned value
insert populatedContract;

// Create Product2 with correct family for revenue calculations
Product2 testProduct = new Product2(
    Name = 'Test Product',
    Family = 'Software Subscriptions',
    IsActive = true
);
insert testProduct;

// Create asset with proper contract relationship and product family
Asset testAsset = new Asset(
    AccountId = testAccount.Id,
    Contract__c = populatedContract.Id,
    Status = 'Active',
    Name = 'Test Asset'
);
testAsset.Start_Date__c = Date.today().addDays(-10);
testAsset.End_Date__c = Date.today().addDays(355);
testAsset.Product2Id = testProduct.Id; // Link to Product2 for ProductFamily
testAsset.Price = 100000; // Set Price to drive ARR calculation
testAsset.Quantity = 1; // Set Quantity for Total_Price calculation
testAsset.Exchange_Rate__c = 1.0; // USD conversion rate
insert testAsset;

// Update to Activated (following proper lifecycle)
populatedContract.Status = 'Activated';
update populatedContract;

// Now query the contract to see its state before processing
Contract beforeContract = [SELECT Id, ContractNumber, CurrencyIsoCode, ARR__c, ARR_USD__c, 
                          ACV__c, ACV_USD__c, Status, Exclude_from_Status_Updates__c,
                          (SELECT Exchange_Rate__c, ProductFamily FROM Assets__r)
                          FROM Contract WHERE Id = :populatedContract.Id];

System.debug('=== TEST CONTRACT BEFORE PROCESSING ===');
System.debug('Contract: ' + beforeContract.ContractNumber);
System.debug('Status: ' + beforeContract.Status);
System.debug('CurrencyIsoCode: ' + beforeContract.CurrencyIsoCode);
System.debug('ARR__c: ' + beforeContract.ARR__c);
System.debug('ARR_USD__c: ' + beforeContract.ARR_USD__c);
System.debug('ACV__c: ' + beforeContract.ACV__c);
System.debug('ACV_USD__c: ' + beforeContract.ACV_USD__c);
System.debug('Exclude_from_Status_Updates__c: ' + beforeContract.Exclude_from_Status_Updates__c);
System.debug('Assets count: ' + beforeContract.Assets__r.size());
if (!beforeContract.Assets__r.isEmpty()) {
    System.debug('Asset Exchange_Rate__c: ' + beforeContract.Assets__r[0].Exchange_Rate__c);
    System.debug('Asset ProductFamily: ' + beforeContract.Assets__r[0].ProductFamily);
}

// Now test our logic step by step
Boolean shouldPopulateRevenue = false;
if (beforeContract.Status == 'Activated') {
    shouldPopulateRevenue = true;
    System.debug('shouldPopulateRevenue = true (Activated contract)');
}

Boolean shouldPopulateUSD = false;
if (beforeContract.Exclude_from_Status_Updates__c != true && shouldPopulateRevenue) {
    shouldPopulateUSD = true;
    System.debug('shouldPopulateUSD = true');
} else {
    System.debug('shouldPopulateUSD = false');
    System.debug('  Exclude_from_Status_Updates__c: ' + beforeContract.Exclude_from_Status_Updates__c);
    System.debug('  shouldPopulateRevenue: ' + shouldPopulateRevenue);
}

if (shouldPopulateUSD) {
    System.debug('=== WOULD EXECUTE USD LOGIC ===');
    
    Decimal exchangeRate = 1.0;
    if (!beforeContract.Assets__r.isEmpty() && beforeContract.Assets__r[0].Exchange_Rate__c != null) {
        exchangeRate = beforeContract.Assets__r[0].Exchange_Rate__c;
    }
    
    Decimal varARR_Total = 0;
    if (beforeContract.CurrencyIsoCode == 'USD') {
        System.debug('USD Contract - Direct Copy');
        varARR_Total = (beforeContract.ARR__c != null ? beforeContract.ARR__c : 0);
    } else {
        System.debug('Non-USD Contract - Conversion with rate: ' + exchangeRate);
        varARR_Total = (beforeContract.ARR__c != null ? beforeContract.ARR__c / exchangeRate : 0);
    }
    
    System.debug('Calculated varARR_Total: ' + varARR_Total);
    System.debug('Expected formatted result: $100,000.00');
} else {
    System.debug('USD logic would be skipped');
}
