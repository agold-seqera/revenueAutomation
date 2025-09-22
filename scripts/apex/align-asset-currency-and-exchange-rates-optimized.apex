// Optimized Asset Currency & Exchange Rate Alignment
// Phase 1: Align Asset currency with Original Opportunity currency (preserving amounts)
// Phase 2: Populate correct historical Exchange_Rate__c values
// OPTIMIZED: Pre-fetch all exchange rates to avoid SOQL limits

System.debug('=== STARTING OPTIMIZED ASSET CURRENCY & EXCHANGE RATE ALIGNMENT ===');

DateTime startTime = DateTime.now();
Integer totalProcessed = 0;
Integer currencyAligned = 0;
Integer exchangeRatesUpdated = 0;
Integer batchCounter = 0;

// Query ALL assets with required fields
List<Asset> allAssets = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c,
           Original_Opportunity__r.CloseDate,
           Original_Opportunity__r.CurrencyIsoCode,
           Original_Opportunity__r.Id,
           Name, ARR__c, Price, Quantity
    FROM Asset 
    WHERE Original_Opportunity__r.CloseDate != null
    AND Original_Opportunity__r.CurrencyIsoCode != null
    ORDER BY Original_Opportunity__r.CloseDate DESC
];

System.debug('Total assets found: ' + allAssets.size());

// Pre-fetch all DatedConversionRate data to avoid repeated queries
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

// Helper method to find exchange rate for a specific date and currency
Decimal getExchangeRateForDate(String currencyCode, Date effectiveDate) {
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
            return 1 / rate.ConversionRate; // Invert for our formula usage
        }
    }
    
    return 1.0; // Fallback if no rate found
}

// Process in batches to respect governor limits (200 records per batch)
Integer batchSize = 200;
List<Asset> assetsToUpdate = new List<Asset>();

for(Integer i = 0; i < allAssets.size(); i++) {
    Asset asset = allAssets[i];
    totalProcessed++;
    Boolean needsUpdate = false;
    
    // Store original values for logging
    String originalAssetCurrency = asset.CurrencyIsoCode;
    Decimal originalExchangeRate = asset.Exchange_Rate__c;
    String opportunityCurrency = asset.Original_Opportunity__r.CurrencyIsoCode;
    
    // PHASE 1: Currency Alignment (preserving amount fields)
    if(asset.CurrencyIsoCode != opportunityCurrency) {
        System.debug('Currency mismatch - Asset ' + asset.Id + ': Asset=' + asset.CurrencyIsoCode + 
                    ' vs Opportunity=' + opportunityCurrency + ' (amounts preserved)');
        
        // Update currency to match opportunity - amounts stay the same
        asset.CurrencyIsoCode = opportunityCurrency;
        currencyAligned++;
        needsUpdate = true;
    }
    
    // PHASE 2: Exchange Rate Population (using corrected currency)
    Decimal correctRate = getExchangeRateForDate(asset.CurrencyIsoCode, asset.Original_Opportunity__r.CloseDate);
    
    // Update exchange rate if different or null
    if(correctRate != null && (asset.Exchange_Rate__c == null || asset.Exchange_Rate__c != correctRate)) {
        asset.Exchange_Rate__c = correctRate;
        exchangeRatesUpdated++;
        needsUpdate = true;
        
        // Log significant rate changes for review
        if(originalExchangeRate != null && Math.abs(originalExchangeRate - correctRate) > 0.01) {
            System.debug('Exchange rate change for Asset ' + asset.Id + ' (' + asset.CurrencyIsoCode + '): ' + 
                        originalExchangeRate + ' → ' + correctRate + ' (Date: ' + asset.Original_Opportunity__r.CloseDate + ')');
        }
    }
    
    // Add to update batch if any changes needed
    if(needsUpdate) {
        assetsToUpdate.add(asset);
    }
    
    // Process batch when we reach batch size or end of list
    if(assetsToUpdate.size() >= batchSize || i == allAssets.size() - 1) {
        if(!assetsToUpdate.isEmpty()) {
            batchCounter++;
            System.debug('Processing batch ' + batchCounter + ' with ' + assetsToUpdate.size() + ' assets...');
            
            try {
                Database.SaveResult[] results = Database.update(assetsToUpdate, false); // Allow partial success
                
                // Count successful updates
                Integer batchSuccesses = 0;
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        batchSuccesses++;
                    } else {
                        System.debug('ERROR updating Asset ' + result.getId() + ': ' + result.getErrors()[0].getMessage());
                    }
                }
                
                System.debug('Batch ' + batchCounter + ' completed: ' + batchSuccesses + '/' + assetsToUpdate.size() + ' successful');
                
            } catch(Exception e) {
                System.debug('BATCH ERROR: ' + e.getMessage());
            }
            
            // Clear batch for next iteration
            assetsToUpdate.clear();
        }
    }
}

// Final summary
DateTime endTime = DateTime.now();
Long executionTimeMs = endTime.getTime() - startTime.getTime();

System.debug('=== ASSET CURRENCY & EXCHANGE RATE ALIGNMENT COMPLETE ===');
System.debug('Total Assets Processed: ' + totalProcessed);
System.debug('Currency Alignments: ' + currencyAligned);
System.debug('Exchange Rate Updates: ' + exchangeRatesUpdated);
System.debug('Total Updates: ' + (currencyAligned + exchangeRatesUpdated));
System.debug('Execution Time: ' + executionTimeMs + ' ms');
System.debug('Batches Processed: ' + batchCounter);

// VERIFICATION PHASE: Sample verification queries
System.debug('=== SAMPLE VERIFICATION ===');

// Check USD assets
List<Asset> usdSample = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CurrencyIsoCode 
    FROM Asset 
    WHERE CurrencyIsoCode = 'USD' 
    LIMIT 3
];
for(Asset asset : usdSample) {
    System.debug('USD Asset ' + asset.Id + ': Currency=' + asset.CurrencyIsoCode + 
                ' (Opp: ' + asset.Original_Opportunity__r.CurrencyIsoCode + ') Rate=' + asset.Exchange_Rate__c);
}

// Check EUR assets  
List<Asset> eurSample = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CloseDate, Original_Opportunity__r.CurrencyIsoCode
    FROM Asset 
    WHERE CurrencyIsoCode = 'EUR' 
    LIMIT 3
];
for(Asset asset : eurSample) {
    System.debug('EUR Asset ' + asset.Id + ': Currency=' + asset.CurrencyIsoCode + 
                ' (Opp: ' + asset.Original_Opportunity__r.CurrencyIsoCode + ') Rate=' + asset.Exchange_Rate__c + 
                ' Date=' + asset.Original_Opportunity__r.CloseDate);
}

// Check GBP assets
List<Asset> gbpSample = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CloseDate, Original_Opportunity__r.CurrencyIsoCode
    FROM Asset 
    WHERE CurrencyIsoCode = 'GBP' 
    LIMIT 3
];
for(Asset asset : gbpSample) {
    System.debug('GBP Asset ' + asset.Id + ': Currency=' + asset.CurrencyIsoCode + 
                ' (Opp: ' + asset.Original_Opportunity__r.CurrencyIsoCode + ') Rate=' + asset.Exchange_Rate__c + 
                ' Date=' + asset.Original_Opportunity__r.CloseDate);
}

System.debug('=== OPTIMIZED ALIGNMENT COMPLETE ===');
