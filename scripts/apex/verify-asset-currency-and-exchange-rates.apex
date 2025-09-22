// Comprehensive Verification: Asset Currency Alignment & Exchange Rate Population
// Verifies both currency alignment with opportunities and exchange rate accuracy

System.debug('=== COMPREHENSIVE ASSET CURRENCY & EXCHANGE RATE VERIFICATION ===');

// 1. CURRENCY ALIGNMENT VERIFICATION
System.debug('=== CURRENCY ALIGNMENT CHECKS ===');

// Check for any remaining currency mismatches
List<Asset> currencyMismatches = [
    SELECT Id, CurrencyIsoCode, Original_Opportunity__r.CurrencyIsoCode, 
           Original_Opportunity__r.Id, Name
    FROM Asset 
    WHERE CurrencyIsoCode != Original_Opportunity__r.CurrencyIsoCode
    AND Original_Opportunity__r.CurrencyIsoCode != null
    LIMIT 10
];

System.debug('Currency mismatches found: ' + currencyMismatches.size() + ' (should be 0)');
for(Asset asset : currencyMismatches) {
    System.debug('MISMATCH: Asset ' + asset.Id + ' (' + asset.Name + ') - Asset: ' + 
                asset.CurrencyIsoCode + ' vs Opportunity: ' + asset.Original_Opportunity__r.CurrencyIsoCode);
}

// Currency distribution after alignment
List<AggregateResult> currencyStats = [
    SELECT CurrencyIsoCode, COUNT(Id) totalCount, 
           COUNT(Exchange_Rate__c) withRates,
           AVG(Exchange_Rate__c) avgRate,
           MIN(Exchange_Rate__c) minRate,
           MAX(Exchange_Rate__c) maxRate
    FROM Asset 
    WHERE Original_Opportunity__r.CloseDate != null
    GROUP BY CurrencyIsoCode
    ORDER BY CurrencyIsoCode
];

System.debug('=== CURRENCY DISTRIBUTION & RATES POST-ALIGNMENT ===');
for(AggregateResult stat : currencyStats) {
    String currency = (String)stat.get('CurrencyIsoCode');
    Integer total = (Integer)stat.get('totalCount');
    Integer withRates = (Integer)stat.get('withRates');
    Decimal avgRate = (Decimal)stat.get('avgRate');
    Decimal minRate = (Decimal)stat.get('minRate');
    Decimal maxRate = (Decimal)stat.get('maxRate');
    
    System.debug(currency + ': ' + total + ' assets, ' + withRates + ' with rates (' + 
                ((Decimal)withRates/total*100).setScale(1) + '%), Avg: ' + 
                (avgRate != null ? avgRate.setScale(4) : 'null') + 
                ', Range: ' + (minRate != null ? minRate.setScale(4) : 'null') + 
                ' - ' + (maxRate != null ? maxRate.setScale(4) : 'null'));
}

// 2. EXCHANGE RATE ACCURACY VERIFICATION
System.debug('=== EXCHANGE RATE ACCURACY CHECKS ===');

// Check for any remaining null exchange rates
List<Asset> nullRates = [
    SELECT Id, CurrencyIsoCode, Original_Opportunity__r.CloseDate 
    FROM Asset 
    WHERE Exchange_Rate__c = null 
    AND Original_Opportunity__r.CloseDate != null
    LIMIT 10
];

System.debug('Assets with null Exchange_Rate__c: ' + nullRates.size() + ' (should be 0)');
for(Asset asset : nullRates) {
    System.debug('NULL RATE: Asset ' + asset.Id + ' (' + asset.CurrencyIsoCode + ') Date: ' + asset.Original_Opportunity__r.CloseDate);
}

// Validate exchange rate accuracy by comparing with ExchangeRateManager
System.debug('=== EXCHANGE RATE ACCURACY SPOT CHECKS ===');

// Check EUR assets from different time periods
List<Asset> eurAssets = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CloseDate
    FROM Asset 
    WHERE CurrencyIsoCode = 'EUR' 
    AND Original_Opportunity__r.CloseDate != null
    ORDER BY Original_Opportunity__r.CloseDate DESC
    LIMIT 5
];

for(Asset asset : eurAssets) {
    Decimal expectedRate = ExchangeRateManager.getExchangeRateForDate('EUR', asset.Original_Opportunity__r.CloseDate);
    Boolean matches = (asset.Exchange_Rate__c == expectedRate);
    
    System.debug('EUR Asset ' + asset.Id + ' Date: ' + asset.Original_Opportunity__r.CloseDate + 
                ' StoredRate: ' + asset.Exchange_Rate__c + ' ExpectedRate: ' + expectedRate + 
                ' Matches: ' + matches);
    
    if(!matches) {
        System.debug('*** RATE MISMATCH DETECTED ***');
    }
}

// Check GBP assets
List<Asset> gbpAssets = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CloseDate
    FROM Asset 
    WHERE CurrencyIsoCode = 'GBP' 
    AND Original_Opportunity__r.CloseDate != null
    LIMIT 5
];

for(Asset asset : gbpAssets) {
    Decimal expectedRate = ExchangeRateManager.getExchangeRateForDate('GBP', asset.Original_Opportunity__r.CloseDate);
    Boolean matches = (asset.Exchange_Rate__c == expectedRate);
    
    System.debug('GBP Asset ' + asset.Id + ' Date: ' + asset.Original_Opportunity__r.CloseDate + 
                ' StoredRate: ' + asset.Exchange_Rate__c + ' ExpectedRate: ' + expectedRate + 
                ' Matches: ' + matches);
    
    if(!matches) {
        System.debug('*** RATE MISMATCH DETECTED ***');
    }
}

// Check USD consistency (should all be 1.0)
List<Asset> usdAssets = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c
    FROM Asset 
    WHERE CurrencyIsoCode = 'USD' 
    AND Exchange_Rate__c != 1.0
    LIMIT 5
];

System.debug('=== USD RATE CONSISTENCY (should all be 1.0) ===');
System.debug('USD assets with rate != 1.0: ' + usdAssets.size() + ' (should be 0)');
for(Asset asset : usdAssets) {
    System.debug('USD ISSUE: Asset ' + asset.Id + ' Rate: ' + asset.Exchange_Rate__c);
}

// 3. DATA INTEGRITY VERIFICATION
System.debug('=== DATA INTEGRITY CHECKS ===');

// Verify no amount fields were accidentally modified (spot check by looking for obvious issues)
List<Asset> integrityCheck = [
    SELECT Id, ARR__c, Price, Quantity, TotalPrice, CurrencyIsoCode, Name
    FROM Asset 
    WHERE (ARR__c < 0 OR Price < 0 OR TotalPrice < 0)
    OR (ARR__c = 0 AND Price > 0)  // Potential data corruption indicators
    LIMIT 5
];

System.debug('Potential data integrity issues: ' + integrityCheck.size());
for(Asset asset : integrityCheck) {
    System.debug('INTEGRITY CHECK: Asset ' + asset.Id + ' (' + asset.Name + ') ' + 
                asset.CurrencyIsoCode + ' - ARR: ' + asset.ARR__c + 
                ', Price: ' + asset.Price + ', TotalPrice: ' + asset.TotalPrice);
}

// 4. COVERAGE SUMMARY
List<AggregateResult> coverageSummary = [
    SELECT COUNT(Id) totalAssets,
           COUNT(Exchange_Rate__c) withExchangeRates,
           MIN(Original_Opportunity__r.CloseDate) earliestDate,
           MAX(Original_Opportunity__r.CloseDate) latestDate
    FROM Asset 
    WHERE Original_Opportunity__r.CloseDate != null
];

if(!coverageSummary.isEmpty()) {
    AggregateResult summary = coverageSummary[0];
    Integer total = (Integer)summary.get('totalAssets');
    Integer withRates = (Integer)summary.get('withExchangeRates');
    Date earliest = (Date)summary.get('earliestDate');
    Date latest = (Date)summary.get('latestDate');
    
    System.debug('=== FINAL COVERAGE SUMMARY ===');
    System.debug('Total Assets: ' + total);
    System.debug('Assets with Exchange Rates: ' + withRates + ' (' + 
                (total > 0 ? ((Decimal)withRates/total*100).setScale(1) : 0) + '%)');
    System.debug('Date Range: ' + earliest + ' to ' + latest);
}

// 5. SAMPLE SUCCESS CASES
System.debug('=== SAMPLE SUCCESS CASES ===');

List<Asset> successSamples = [
    SELECT Id, Name, CurrencyIsoCode, Exchange_Rate__c, 
           Original_Opportunity__r.CurrencyIsoCode, Original_Opportunity__r.CloseDate,
           ARR__c, TotalPrice
    FROM Asset 
    WHERE Exchange_Rate__c != null 
    AND CurrencyIsoCode = Original_Opportunity__r.CurrencyIsoCode
    AND Original_Opportunity__r.CloseDate != null
    ORDER BY Original_Opportunity__r.CloseDate DESC
    LIMIT 3
];

for(Asset asset : successSamples) {
    System.debug('SUCCESS: Asset ' + asset.Id + ' (' + asset.Name + ') ' + 
                asset.CurrencyIsoCode + ' Rate: ' + asset.Exchange_Rate__c + 
                ' Date: ' + asset.Original_Opportunity__r.CloseDate + 
                ' ARR: ' + asset.ARR__c + ' TotalPrice: ' + asset.TotalPrice);
}

System.debug('=== COMPREHENSIVE VERIFICATION COMPLETE ===');
