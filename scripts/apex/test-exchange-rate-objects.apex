// Test what exchange rate objects are available
System.debug('=== TESTING EXCHANGE RATE OBJECTS ===');

// Test CurrencyType
try {
    List<CurrencyType> currTypes = [SELECT IsoCode, ConversionRate FROM CurrencyType LIMIT 3];
    System.debug('✅ CurrencyType works: ' + currTypes.size() + ' records');
    for (CurrencyType ct : currTypes) {
        System.debug('  ' + ct.IsoCode + ': ' + ct.ConversionRate);
    }
} catch (Exception e) {
    System.debug('❌ CurrencyType error: ' + e.getMessage());
}

// Test DatedExchangeRate
try {
    List<SObject> datedRates = Database.query('SELECT IsoCode, ConversionRate FROM DatedExchangeRate LIMIT 3');
    System.debug('✅ DatedExchangeRate works: ' + datedRates.size() + ' records');
} catch (Exception e) {
    System.debug('❌ DatedExchangeRate error: ' + e.getMessage());
}

System.debug('=== TEST COMPLETE ===');
