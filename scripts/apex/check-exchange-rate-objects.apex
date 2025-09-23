// Check what exchange rate objects are available
System.debug('=== CHECKING EXCHANGE RATE OBJECTS ===');

// Try to query CurrencyType first
try {
    List<CurrencyType> currencies = [SELECT IsoCode, ConversionRate FROM CurrencyType LIMIT 5];
    System.debug('CurrencyType found: ' + currencies.size() + ' records');
    for (CurrencyType curr : currencies) {
        System.debug('  ' + curr.IsoCode + ': ' + curr.ConversionRate);
    }
} catch (Exception e) {
    System.debug('CurrencyType error: ' + e.getMessage());
}

System.debug('=== CHECK COMPLETE ===');
