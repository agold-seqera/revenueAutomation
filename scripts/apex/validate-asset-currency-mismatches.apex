// Pre-Execution Validation: Asset Currency Mismatch Analysis
// Check how many assets have currency mismatches with their original opportunities

System.debug('=== ASSET CURRENCY MISMATCH VALIDATION ===');

// Query all assets to analyze currency alignment
List<Asset> allAssets = [
    SELECT Id, Name, CurrencyIsoCode, Exchange_Rate__c,
           Original_Opportunity__r.Id, Original_Opportunity__r.CurrencyIsoCode,
           Original_Opportunity__r.CloseDate, Original_Opportunity__r.Name
    FROM Asset 
    WHERE Original_Opportunity__r.CurrencyIsoCode != null
    ORDER BY CurrencyIsoCode, Original_Opportunity__r.CurrencyIsoCode
];

System.debug('Total assets analyzed: ' + allAssets.size());

// Analyze currency mismatches
Integer totalAssets = allAssets.size();
Integer matchingCurrencies = 0;
Integer mismatchedCurrencies = 0;
Integer nullExchangeRates = 0;
Integer needsExchangeRateUpdate = 0;

List<Asset> mismatchExamples = new List<Asset>();
Map<String, Integer> mismatchPatterns = new Map<String, Integer>();

for(Asset asset : allAssets) {
    // Check currency alignment
    if(asset.CurrencyIsoCode == asset.Original_Opportunity__r.CurrencyIsoCode) {
        matchingCurrencies++;
    } else {
        mismatchedCurrencies++;
        
        // Track mismatch patterns
        String pattern = asset.CurrencyIsoCode + ' → ' + asset.Original_Opportunity__r.CurrencyIsoCode;
        Integer count = mismatchPatterns.get(pattern);
        mismatchPatterns.put(pattern, (count != null ? count + 1 : 1));
        
        // Collect examples (limit to 10 for logging)
        if(mismatchExamples.size() < 10) {
            mismatchExamples.add(asset);
        }
    }
    
    // Check exchange rate status
    if(asset.Exchange_Rate__c == null) {
        nullExchangeRates++;
        needsExchangeRateUpdate++;
    }
}

// Summary Statistics
System.debug('=== CURRENCY ALIGNMENT SUMMARY ===');
System.debug('Total Assets: ' + totalAssets);
System.debug('Matching Currencies: ' + matchingCurrencies + ' (' + 
            (totalAssets > 0 ? ((Decimal)matchingCurrencies/totalAssets*100).setScale(1) : 0) + '%)');
System.debug('Mismatched Currencies: ' + mismatchedCurrencies + ' (' + 
            (totalAssets > 0 ? ((Decimal)mismatchedCurrencies/totalAssets*100).setScale(1) : 0) + '%)');

System.debug('=== EXCHANGE RATE STATUS ===');
System.debug('Assets with null Exchange_Rate__c: ' + nullExchangeRates);
System.debug('Assets needing Exchange Rate updates: ' + needsExchangeRateUpdate + ' (' + 
            (totalAssets > 0 ? ((Decimal)needsExchangeRateUpdate/totalAssets*100).setScale(1) : 0) + '%)');

// Mismatch Patterns Analysis
System.debug('=== CURRENCY MISMATCH PATTERNS ===');
for(String pattern : mismatchPatterns.keySet()) {
    Integer count = mismatchPatterns.get(pattern);
    System.debug('Pattern "' + pattern + '": ' + count + ' assets');
}

// Examples of mismatched assets
System.debug('=== MISMATCH EXAMPLES (up to 10) ===');
for(Asset asset : mismatchExamples) {
    System.debug('Asset ' + asset.Id + ' (' + asset.Name + '): Asset=' + asset.CurrencyIsoCode + 
                ' vs Opportunity=' + asset.Original_Opportunity__r.CurrencyIsoCode + 
                ' (Opp: ' + asset.Original_Opportunity__r.Name + ')' +
                ' ExchangeRate: ' + asset.Exchange_Rate__c);
}

// Currency distribution analysis
System.debug('=== CURRENT ASSET CURRENCY DISTRIBUTION ===');
List<AggregateResult> assetCurrencies = [
    SELECT CurrencyIsoCode, COUNT(Id) assetCount
    FROM Asset 
    WHERE Original_Opportunity__r.CurrencyIsoCode != null
    GROUP BY CurrencyIsoCode
    ORDER BY CurrencyIsoCode
];

for(AggregateResult result : assetCurrencies) {
    String currencyCode = (String)result.get('CurrencyIsoCode');
    Integer count = (Integer)result.get('assetCount');
    System.debug('Asset Currency ' + currencyCode + ': ' + count + ' assets');
}

System.debug('=== OPPORTUNITY CURRENCY DISTRIBUTION ===');
List<AggregateResult> oppCurrencies = [
    SELECT Original_Opportunity__r.CurrencyIsoCode currencyCode, COUNT(Id) assetCount
    FROM Asset 
    WHERE Original_Opportunity__r.CurrencyIsoCode != null
    GROUP BY Original_Opportunity__r.CurrencyIsoCode
    ORDER BY Original_Opportunity__r.CurrencyIsoCode
];

for(AggregateResult result : oppCurrencies) {
    String currencyCode = (String)result.get('currencyCode');
    Integer count = (Integer)result.get('assetCount');
    System.debug('Opportunity Currency ' + currencyCode + ': ' + count + ' assets');
}

// Impact Assessment
System.debug('=== IMPACT ASSESSMENT ===');
if(mismatchedCurrencies == 0 && needsExchangeRateUpdate == 0) {
    System.debug('✅ PERFECT ALIGNMENT: No currency mismatches or exchange rate updates needed!');
} else if(mismatchedCurrencies == 0 && needsExchangeRateUpdate > 0) {
    System.debug('✅ CURRENCY ALIGNED: Only exchange rate updates needed (' + needsExchangeRateUpdate + ' assets)');
} else {
    System.debug('🔧 UPDATES NEEDED:');
    if(mismatchedCurrencies > 0) {
        System.debug('   - Currency alignment: ' + mismatchedCurrencies + ' assets');
    }
    if(needsExchangeRateUpdate > 0) {
        System.debug('   - Exchange rate updates: ' + needsExchangeRateUpdate + ' assets');
    }
}

System.debug('=== VALIDATION COMPLETE ===');
System.debug('Recommendation: ' + (mismatchedCurrencies > 0 || needsExchangeRateUpdate > 0 ? 
            'Proceed with align-asset-currency-and-exchange-rates.apex script' : 
            'No updates needed - assets are already properly aligned'));
