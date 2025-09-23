// ONE-TIME LOAD: Populate missing Exchange_Rate__c for assets using DatedExchangeRate from org
System.debug('=== ONE-TIME ASSET EXCHANGE RATE POPULATION ===');

// Asset IDs that need exchange rates populated (from CSV)
Set<Id> assetIds = new Set<Id>{
    '02iPn000004NkhNIAS', '02iPn000004NkhOIAS', '02iPn000004NkhPIAS', 
    '02iPn000004Nl2LIAS', '02iPn000004Nm6TIAS', '02iPn000004Nm6UIAS', 
    '02iPn000004Nn2YIAS', '02iPn000004Nn2ZIAS', '02iPn000004Nn7NIAS', 
    '02iPn000004NoHzIAK', '02iPn000004NoI0IAK', '02iPn000004NoOSIA0', 
    '02iPn000004NoRdIAK', '02iPn000004NoReIAK', '02iPn000004NoRfIAK', 
    '02iPn000004NoTHIA0', '02iPn000004NoY9IAK', '02iPn000004NoYAIA0', 
    '02iPn000004NozVIAS', '02iPn000004NpqjIAC', '02iPn000004NpqkIAC', 
    '02iPn000004NqJmIAK', '02iPn000004NqJnIAK', '02iPn000004NqJoIAK', 
    '02iPn000004NsBvIAK', '02iPn000004NsBwIAK', '02iPn000004Nt4jIAC', 
    '02iPn000004Nt4kIAC', '02iPn000004Nt4lIAC', '02iPn000004O6BpIAK'
};

// Get assets with their opportunity close dates and currency codes
List<Asset> assetsToUpdate = [
    SELECT Id, Exchange_Rate__c, CurrencyIsoCode,
           Original_Opportunity__r.CloseDate, Original_Opportunity__r.CurrencyIsoCode
    FROM Asset 
    WHERE Id IN :assetIds
    AND (Exchange_Rate__c = null OR Exchange_Rate__c = 0)
];

System.debug('Found ' + assetsToUpdate.size() + ' assets needing exchange rate population');

// Group assets by currency and close date for efficient DatedExchangeRate queries
Map<String, List<Asset>> assetsByCurrency = new Map<String, List<Asset>>();
Set<Date> uniqueCloseDates = new Set<Date>();

for (Asset asset : assetsToUpdate) {
    String currencyCode = asset.Original_Opportunity__r.CurrencyIsoCode != null ? 
                          asset.Original_Opportunity__r.CurrencyIsoCode : asset.CurrencyIsoCode;
    
    if (currencyCode != 'USD') { // Only need rates for non-USD currencies
        if (!assetsByCurrency.containsKey(currencyCode)) {
            assetsByCurrency.put(currencyCode, new List<Asset>());
        }
        assetsByCurrency.get(currencyCode).add(asset);
        
        if (asset.Original_Opportunity__r.CloseDate != null) {
            uniqueCloseDates.add(asset.Original_Opportunity__r.CloseDate);
        }
    }
}

System.debug('Currencies needing rates: ' + assetsByCurrency.keySet());
System.debug('Unique close dates: ' + uniqueCloseDates.size());

// Query CurrencyType for current exchange rates (simpler and available)
Map<String, Decimal> exchangeRateMap = new Map<String, Decimal>();

// Always process USD assets + any non-USD currencies found
Set<String> allCurrencies = new Set<String>{'USD'};
allCurrencies.addAll(assetsByCurrency.keySet());

List<CurrencyType> exchangeRates = [
    SELECT IsoCode, ConversionRate
    FROM CurrencyType 
    WHERE IsoCode IN :allCurrencies
];

System.debug('Found ' + exchangeRates.size() + ' exchange rate records');

// Build rate map by currency  
Map<String, CurrencyType> latestRatesByCurrency = new Map<String, CurrencyType>();

for (CurrencyType rate : exchangeRates) {
    latestRatesByCurrency.put(rate.IsoCode, rate);
    System.debug('  ' + rate.IsoCode + ': ' + rate.ConversionRate);
}

// Update assets with appropriate exchange rates
List<Asset> updatedAssets = new List<Asset>();

for (Asset asset : assetsToUpdate) {
    String currencyCode = asset.Original_Opportunity__r.CurrencyIsoCode != null ? 
                          asset.Original_Opportunity__r.CurrencyIsoCode : asset.CurrencyIsoCode;
    
    if (currencyCode == 'USD') {
        // USD assets should have rate of 1.0
        asset.Exchange_Rate__c = 1.0;
        updatedAssets.add(asset);
        System.debug('  Asset ' + asset.Id + ': USD → Rate = 1.0');
    } else if (latestRatesByCurrency.containsKey(currencyCode)) {
        CurrencyType rate = latestRatesByCurrency.get(currencyCode);
        asset.Exchange_Rate__c = rate.ConversionRate;
        updatedAssets.add(asset);
        System.debug('  Asset ' + asset.Id + ': ' + currencyCode + ' → Rate = ' + rate.ConversionRate);
    } else {
        System.debug('  ⚠️  Asset ' + asset.Id + ': No exchange rate found for ' + currencyCode);
    }
}

// Execute the update
if (!updatedAssets.isEmpty()) {
    try {
        update updatedAssets;
        System.debug('✅ SUCCESS: Updated ' + updatedAssets.size() + ' assets with exchange rates');
    } catch (DmlException e) {
        System.debug('❌ ERROR updating assets: ' + e.getMessage());
    }
} else {
    System.debug('ℹ️ No assets found needing exchange rate updates');
}

System.debug('=== ONE-TIME ASSET EXCHANGE RATE FIX COMPLETE ===');
