// FIX: Correct Exchange Rates by storing RAW ConversionRate (no inversion)
// Our ExchangeRateManager handles inversion, so we should store raw rates from DatedConversionRate

System.debug('=== FIXING EXCHANGE RATES - NO INVERSION ===');

DateTime startTime = DateTime.now();
Integer totalProcessed = 0;
Integer exchangeRatesFixed = 0;

// Query ALL assets that need exchange rate correction
List<Asset> allAssets = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c,
           Original_Opportunity__r.CloseDate,
           Original_Opportunity__r.CurrencyIsoCode
    FROM Asset 
    WHERE Original_Opportunity__r.CloseDate != null
    AND Original_Opportunity__r.CurrencyIsoCode != null
    ORDER BY Original_Opportunity__r.CloseDate DESC
];

System.debug('Total assets found: ' + allAssets.size());

// Pre-fetch all DatedConversionRate data
Map<String, List<DatedConversionRate>> exchangeRatesByCurrency = new Map<String, List<DatedConversionRate>>();
List<DatedConversionRate> allRates = [
    SELECT ConversionRate, IsoCode, StartDate, NextStartDate
    FROM DatedConversionRate 
    ORDER BY IsoCode, StartDate
];

for(DatedConversionRate rate : allRates) {
    if(!exchangeRatesByCurrency.containsKey(rate.IsoCode)) {
        exchangeRatesByCurrency.put(rate.IsoCode, new List<DatedConversionRate>());
    }
    exchangeRatesByCurrency.get(rate.IsoCode).add(rate);
}

System.debug('Loaded exchange rates for currencies: ' + exchangeRatesByCurrency.keySet());

// Helper method to find RAW exchange rate (NO INVERSION)
Decimal getRawExchangeRateForDate(String currencyCode, Date effectiveDate) {
    if(currencyCode == 'USD') {
        return 1.0; // Corporate currency
    }
    
    List<DatedConversionRate> rates = exchangeRatesByCurrency.get(currencyCode);
    if(rates == null || rates.isEmpty()) {
        return 1.0; // Fallback
    }
    
    for(DatedConversionRate rate : rates) {
        if(rate.StartDate <= effectiveDate && 
           (rate.NextStartDate > effectiveDate || rate.NextStartDate == null)) {
            // CRITICAL FIX: Return RAW rate - NO INVERSION
            return rate.ConversionRate;
        }
    }
    
    return 1.0; // Fallback if no rate found
}

// Process in batches
Integer batchSize = 200;
List<Asset> assetsToUpdate = new List<Asset>();
Integer batchCounter = 0;

for(Integer i = 0; i < allAssets.size(); i++) {
    Asset asset = allAssets[i];
    totalProcessed++;
    
    // Get the correct RAW exchange rate (no inversion)
    Decimal correctRawRate = getRawExchangeRateForDate(
        asset.CurrencyIsoCode, 
        asset.Original_Opportunity__r.CloseDate
    );
    
    // Check if we need to fix the exchange rate
    if(correctRawRate != null && asset.Exchange_Rate__c != correctRawRate) {
        Decimal oldRate = asset.Exchange_Rate__c;
        asset.Exchange_Rate__c = correctRawRate;
        exchangeRatesFixed++;
        assetsToUpdate.add(asset);
        
        // Log the correction for review
        System.debug('FIXING Asset ' + asset.Id + ' (' + asset.CurrencyIsoCode + '): ' + 
                    'WRONG=' + oldRate + ' → CORRECT=' + correctRawRate + 
                    ' Date=' + asset.Original_Opportunity__r.CloseDate);
    }
    
    // Process batch when we reach batch size or end of list
    if(assetsToUpdate.size() >= batchSize || i == allAssets.size() - 1) {
        if(!assetsToUpdate.isEmpty()) {
            batchCounter++;
            System.debug('Processing correction batch ' + batchCounter + ' with ' + assetsToUpdate.size() + ' assets...');
            
            try {
                Database.SaveResult[] results = Database.update(assetsToUpdate, false);
                
                Integer batchSuccesses = 0;
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        batchSuccesses++;
                    } else {
                        System.debug('ERROR fixing Asset ' + result.getId() + ': ' + result.getErrors()[0].getMessage());
                    }
                }
                
                System.debug('Correction batch ' + batchCounter + ' completed: ' + batchSuccesses + '/' + assetsToUpdate.size() + ' successful');
                
            } catch(Exception e) {
                System.debug('BATCH ERROR: ' + e.getMessage());
            }
            
            assetsToUpdate.clear();
        }
    }
}

// Final summary
DateTime endTime = DateTime.now();
Long executionTimeMs = endTime.getTime() - startTime.getTime();

System.debug('=== EXCHANGE RATE CORRECTION COMPLETE ===');
System.debug('Total Assets Processed: ' + totalProcessed);
System.debug('Exchange Rates Fixed: ' + exchangeRatesFixed);
System.debug('Execution Time: ' + executionTimeMs + ' ms');
System.debug('Batches Processed: ' + batchCounter);

// Verification samples
System.debug('=== CORRECTED SAMPLES ===');

// Check EUR samples - should show RAW rates (e.g., ~0.85, not ~1.18)
List<Asset> eurSample = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CloseDate
    FROM Asset 
    WHERE CurrencyIsoCode = 'EUR' 
    LIMIT 3
];
for(Asset asset : eurSample) {
    System.debug('EUR Asset ' + asset.Id + ': RAW Rate=' + asset.Exchange_Rate__c + 
                ' Date=' + asset.Original_Opportunity__r.CloseDate);
}

// Check GBP samples - should show RAW rates (e.g., ~0.74, not ~1.35)
List<Asset> gbpSample = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CloseDate
    FROM Asset 
    WHERE CurrencyIsoCode = 'GBP' 
    LIMIT 3
];
for(Asset asset : gbpSample) {
    System.debug('GBP Asset ' + asset.Id + ': RAW Rate=' + asset.Exchange_Rate__c + 
                ' Date=' + asset.Original_Opportunity__r.CloseDate);
}

System.debug('=== CORRECTION COMPLETE - EXCHANGE RATES NOW STORE RAW VALUES ===');
