// Populate exchange rates using ExchangeRateManager
System.debug('=== POPULATING EXCHANGE RATES ===');

try {
    // Run the exchange rate manager to populate all missing exchange rates
    ExchangeRateManager.updateExchangeRatesForAllConfiguredObjects();
    System.debug('Successfully ran ExchangeRateManager.updateExchangeRatesForAllConfiguredObjects()');
} catch(Exception e) {
    System.debug('ERROR running ExchangeRateManager: ' + e.getMessage());
}

// Check a few assets after processing
List<Asset> assets = [SELECT Id, Name, Exchange_Rate__c, CurrencyIsoCode 
                     FROM Asset 
                     WHERE CurrencyIsoCode != 'USD' 
                     LIMIT 3];

System.debug('Sample assets after exchange rate processing:');
for(Asset a : assets) {
    System.debug('Asset: ' + a.Id + ' | Currency: ' + a.CurrencyIsoCode + ' | Exchange_Rate: ' + a.Exchange_Rate__c);
}

System.debug('=== END EXCHANGE RATE POPULATION ===');
