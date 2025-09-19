# Apex Class Template - GTM-138

## Class Structure Template

```apex
/**
 * @description [Brief description of class purpose]
 * @author [Developer Name]
 * @date [Creation Date]
 * @group GTM-138 Exchange Rate Manager
 * @see ExchangeRateManager
 */
public with sharing class [ClassName] {
    
    // Class constants
    private static final String EXCHANGE_RATE_FIELD = 'Exchange_Rate__c';
    private static final Integer DEFAULT_BATCH_SIZE = 200;
    
    // Class variables
    private static Map<String, Decimal> currencyCache = new Map<String, Decimal>();
    
    /**
     * @description [Method description]
     * @param [paramName] [Description]
     * @return [Return description]
     * @throws [Exception type and conditions]
     */
    public static [ReturnType] [methodName]([Parameters]) {
        try {
            // Implementation
            
        } catch (Exception e) {
            // Error handling
            System.debug(LoggingLevel.ERROR, '[ClassName].[methodName] Error: ' + e.getMessage());
            throw new [CustomException]('[Error message]', e);
        }
    }
    
    /**
     * @description Bulk processing method template
     * @param records List of records to process
     */
    public static void processBulkRecords(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        
        // Bulk processing logic with governor limit considerations
        Map<String, Decimal> exchangeRateMap = new Map<String, Decimal>();
        
        for (SObject record : records) {
            // Process each record
        }
    }
    
    /**
     * @description Error handling utility
     * @param context Context information
     * @param e Exception to handle
     */
    private static void handleError(String context, Exception e) {
        System.debug(LoggingLevel.ERROR, context + ': ' + e.getMessage());
        // Additional error handling logic
    }
}
```

## Test Class Template

```apex
/**
 * @description Test class for [ClassName]
 * @author [Developer Name]
 * @date [Creation Date]
 * @group GTM-138 Exchange Rate Manager Tests
 */
@isTest
public class [ClassName]Test {
    
    @TestSetup
    static void setupTestData() {
        // Use TestFactoryData for test record creation
        // Create test data required for all test methods
    }
    
    @isTest
    static void test[MethodName]_Success() {
        // Test successful execution path
        Test.startTest();
        
        // Execute method under test
        
        Test.stopTest();
        
        // Assertions
        System.assert([condition], '[Error message]');
    }
    
    @isTest
    static void test[MethodName]_BulkRecords() {
        // Test bulk processing (200 records)
        List<SObject> testRecords = new List<SObject>();
        for (Integer i = 0; i < 200; i++) {
            // Create test records
        }
        
        Test.startTest();
        
        // Execute bulk method
        
        Test.stopTest();
        
        // Bulk assertions
    }
    
    @isTest
    static void test[MethodName]_ErrorHandling() {
        // Test error scenarios
        Test.startTest();
        
        try {
            // Execute method that should fail
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception e) {
            // Verify expected exception
            System.assert(e.getMessage().contains('[Expected error text]'));
        }
        
        Test.stopTest();
    }
}
```

## Naming Conventions

### Class Names
- `[Object]ExchangeRateHandler` - Trigger handlers
- `[Object]ExchangeRateService` - Business logic services
- `ExchangeRate[Function]Batch` - Batch classes
- `ExchangeRate[Function]Queueable` - Queueable classes

### Method Names
- `assign[Object]Rates()` - Rate assignment methods
- `calculate[Field]USD()` - USD conversion methods
- `validate[Condition]()` - Validation methods
- `process[Action]()` - Processing methods

### Variable Names
- `exchangeRateMap` - Map of currency codes to rates
- `usdConversionFields` - List of USD field API names
- `currencyCache` - Cached exchange rates
- `batchSize` - Batch processing size

## Error Handling Patterns

### Custom Exceptions
```apex
public class ExchangeRateException extends Exception {}
public class CurrencyNotFoundException extends Exception {}
public class InvalidExchangeRateException extends Exception {}
```

### Logging Patterns
```apex
System.debug(LoggingLevel.INFO, 'GTM-138: Processing ' + records.size() + ' records');
System.debug(LoggingLevel.ERROR, 'GTM-138: Exchange rate assignment failed: ' + e.getMessage());
System.debug(LoggingLevel.WARN, 'GTM-138: Currency not found, using default rate: ' + currencyCode);
```

## Performance Considerations

### SOQL Best Practices
- Cache exchange rates within transaction
- Use Map-based lookups instead of repeated queries
- Limit query results to required fields only

### DML Best Practices
- Batch updates for large datasets
- Use Database.update with partial success for error handling
- Implement retry logic for transient failures

### Governor Limit Management
- Monitor CPU time for complex calculations
- Use efficient loops and collections
- Implement chunking for large data volumes
