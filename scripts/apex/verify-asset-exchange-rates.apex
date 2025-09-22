// Verification Script: Asset Exchange Rate Population Results
// Run this after the population script to validate results

System.debug('=== ASSET EXCHANGE RATE VERIFICATION ===');

// Get comprehensive statistics
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

System.debug('=== CURRENCY DISTRIBUTION & RATES ===');
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

// Check for any remaining null exchange rates
List<Asset> nullRates = [
    SELECT Id, CurrencyIsoCode, Original_Opportunity__r.CloseDate 
    FROM Asset 
    WHERE Exchange_Rate__c = null 
    AND Original_Opportunity__r.CloseDate != null
    LIMIT 10
];

System.debug('=== NULL EXCHANGE RATES (should be 0) ===');
System.debug('Assets with null Exchange_Rate__c: ' + nullRates.size());
for(Asset asset : nullRates) {
    System.debug('NULL: Asset ' + asset.Id + ' (' + asset.CurrencyIsoCode + ') Date: ' + asset.Original_Opportunity__r.CloseDate);
}

// Check historical rate accuracy for specific dates
System.debug('=== HISTORICAL RATE SPOT CHECKS ===');

// Check specific date ranges to validate historical accuracy
List<Asset> eurAssets2024 = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CloseDate
    FROM Asset 
    WHERE CurrencyIsoCode = 'EUR' 
    AND Original_Opportunity__r.CloseDate >= 2024-01-01
    AND Original_Opportunity__r.CloseDate < 2024-02-01
    LIMIT 2
];

for(Asset asset : eurAssets2024) {
    // Compare with what ExchangeRateManager would return for the same date
    Decimal manualRate = ExchangeRateManager.getExchangeRateForDate('EUR', asset.Original_Opportunity__r.CloseDate);
    Boolean matches = (asset.Exchange_Rate__c == manualRate);
    
    System.debug('EUR Jan 2024: Asset ' + asset.Id + ' Date: ' + asset.Original_Opportunity__r.CloseDate + 
                ' StoredRate: ' + asset.Exchange_Rate__c + ' ExpectedRate: ' + manualRate + ' Matches: ' + matches);
}

// Check GBP rates
List<Asset> gbpAssets = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CloseDate
    FROM Asset 
    WHERE CurrencyIsoCode = 'GBP' 
    LIMIT 2
];

for(Asset asset : gbpAssets) {
    Decimal manualRate = ExchangeRateManager.getExchangeRateForDate('GBP', asset.Original_Opportunity__r.CloseDate);
    Boolean matches = (asset.Exchange_Rate__c == manualRate);
    
    System.debug('GBP Check: Asset ' + asset.Id + ' Date: ' + asset.Original_Opportunity__r.CloseDate + 
                ' StoredRate: ' + asset.Exchange_Rate__c + ' ExpectedRate: ' + manualRate + ' Matches: ' + matches);
}

// Check USD consistency
List<Asset> usdAssets = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c
    FROM Asset 
    WHERE CurrencyIsoCode = 'USD' 
    AND Exchange_Rate__c != 1.0
    LIMIT 5
];

System.debug('=== USD RATE CONSISTENCY (should all be 1.0) ===');
System.debug('USD assets with rate != 1.0: ' + usdAssets.size());
for(Asset asset : usdAssets) {
    System.debug('USD Issue: Asset ' + asset.Id + ' Rate: ' + asset.Exchange_Rate__c);
}

// Date range analysis
List<AggregateResult> dateRange = [
    SELECT MIN(Original_Opportunity__r.CloseDate) minDate,
           MAX(Original_Opportunity__r.CloseDate) maxDate,
           COUNT(Id) totalAssets
    FROM Asset 
    WHERE Original_Opportunity__r.CloseDate != null
    AND Exchange_Rate__c != null
];

if(!dateRange.isEmpty()) {
    AggregateResult range = dateRange[0];
    System.debug('=== DATE RANGE COVERAGE ===');
    System.debug('Earliest Close Date: ' + range.get('minDate'));
    System.debug('Latest Close Date: ' + range.get('maxDate'));
    System.debug('Total Assets with Rates: ' + range.get('totalAssets'));
}

System.debug('=== VERIFICATION COMPLETE ===');
