// Populate Exchange_Rate__c for ALL Assets using Historical Rates
// This script processes all 535+ assets regardless of current Exchange_Rate__c value
// Uses ExchangeRateManager.getExchangeRateForDate() for accurate historical matching

System.debug('=== STARTING COMPREHENSIVE ASSET EXCHANGE RATE POPULATION ===');

// Get current timestamp for logging
DateTime startTime = DateTime.now();
Integer totalProcessed = 0;
Integer totalUpdated = 0;
Integer batchCounter = 0;

// Query ALL assets with required fields (no WHERE clause restrictions)
List<Asset> allAssets = [
    SELECT Id, CurrencyIsoCode, Exchange_Rate__c,
           Original_Opportunity__r.CloseDate,
           Original_Opportunity__r.Id,
           Name
    FROM Asset 
    WHERE Original_Opportunity__r.CloseDate != null
    ORDER BY Original_Opportunity__r.CloseDate DESC
];

System.debug('Total assets found: ' + allAssets.size());

// Process in batches to respect governor limits (200 records per batch)
Integer batchSize = 200;
List<Asset> assetsToUpdate = new List<Asset>();

for(Integer i = 0; i < allAssets.size(); i++) {
    Asset asset = allAssets[i];
    totalProcessed++;
    
    // Store original value for comparison
    Decimal originalRate = asset.Exchange_Rate__c;
    
    // Calculate correct exchange rate based on opportunity close date
    Decimal correctRate;
    
    if(asset.CurrencyIsoCode == 'USD') {
        // USD is corporate currency - always 1.0
        correctRate = 1.0;
    } else if(String.isNotBlank(asset.CurrencyIsoCode) && asset.Original_Opportunity__r.CloseDate != null) {
        // Use ExchangeRateManager to get historical rate for the exact date
        correctRate = ExchangeRateManager.getExchangeRateForDate(
            asset.CurrencyIsoCode, 
            asset.Original_Opportunity__r.CloseDate
        );
    } else {
        // Fallback to 1.0 for missing data
        correctRate = 1.0;
        System.debug('WARNING: Missing currency or date data for Asset ' + asset.Id);
    }
    
    // Always update the exchange rate (overwrite existing values)
    if(correctRate != null) {
        asset.Exchange_Rate__c = correctRate;
        assetsToUpdate.add(asset);
        
        // Log significant rate changes for review
        if(originalRate != null && Math.abs(originalRate - correctRate) > 0.01) {
            System.debug('Rate change for Asset ' + asset.Id + ' (' + asset.CurrencyIsoCode + '): ' + 
                        originalRate + ' → ' + correctRate + ' (Date: ' + asset.Original_Opportunity__r.CloseDate + ')');
        }
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
                        totalUpdated++;
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

System.debug('=== ASSET EXCHANGE RATE POPULATION COMPLETE ===');
System.debug('Total Assets Processed: ' + totalProcessed);
System.debug('Total Assets Updated: ' + totalUpdated);
System.debug('Success Rate: ' + (totalProcessed > 0 ? ((Decimal)totalUpdated / totalProcessed * 100).setScale(1) : 0) + '%');
System.debug('Execution Time: ' + executionTimeMs + ' ms');
System.debug('Batches Processed: ' + batchCounter);

// Sample verification queries (limit for log readability)
System.debug('=== SAMPLE VERIFICATION ===');

// Check USD assets
List<Asset> usdSample = [SELECT Id, CurrencyIsoCode, Exchange_Rate__c FROM Asset WHERE CurrencyIsoCode = 'USD' LIMIT 3];
for(Asset asset : usdSample) {
    System.debug('USD Asset ' + asset.Id + ': Rate = ' + asset.Exchange_Rate__c);
}

// Check EUR assets  
List<Asset> eurSample = [SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CloseDate 
                        FROM Asset WHERE CurrencyIsoCode = 'EUR' LIMIT 3];
for(Asset asset : eurSample) {
    System.debug('EUR Asset ' + asset.Id + ': Rate = ' + asset.Exchange_Rate__c + ' (Date: ' + asset.Original_Opportunity__r.CloseDate + ')');
}

// Check GBP assets
List<Asset> gbpSample = [SELECT Id, CurrencyIsoCode, Exchange_Rate__c, Original_Opportunity__r.CloseDate 
                        FROM Asset WHERE CurrencyIsoCode = 'GBP' LIMIT 3];
for(Asset asset : gbpSample) {
    System.debug('GBP Asset ' + asset.Id + ': Rate = ' + asset.Exchange_Rate__c + ' (Date: ' + asset.Original_Opportunity__r.CloseDate + ')');
}

System.debug('=== SCRIPT COMPLETE ===');
