// Exchange Rate Manager - Enterprise Exchange Rate Management
// 
// Provides centralized exchange rate management across multiple Salesforce objects.
// Implements Schedulable interface for daily maintenance and provides utility methods
// for real-time exchange rate operations.
// 
// Current Objects Supported: Quote, QuoteLineItem, OpportunityLineItem, Asset
// Future Extensibility: Opportunity, Contract, Custom Objects
// 
// @author Alex Goldstein / Syl Architecture
// @date January 2025
// @version 1.0
public class ExchangeRateManager implements Schedulable {
    
    // Configuration map for objects and their exchange rate fields
    // GTM-138: Extended configuration for comprehensive exchange rate management
    private static final Map<String, String> OBJECT_FIELD_CONFIG = new Map<String, String>{
        'Quote' => 'Exchange_Rate__c',
        'QuoteLineItem' => 'Exchange_Rate__c',
        'OpportunityLineItem' => 'Exchange_Rate__c',
        'Asset' => 'Exchange_Rate__c'
        // Future objects can be added here:
        // 'Opportunity' => 'Exchange_Rate_at_Creation__c',
        // 'Contract' => 'Exchange_Rate_at_Creation__c'
    };
    
    // Maximum records to process per execution (governor limit management)
    private static final Integer MAX_RECORDS_PER_EXECUTION = 200;
    
    // Schedulable interface implementation
    // Executes daily at scheduled time (typically 12:01 AM)
    // 
    // @param ctx SchedulableContext provided by Salesforce scheduler
    public void execute(SchedulableContext ctx) {
        try {
            updateExchangeRatesForAllConfiguredObjects();
        } catch (Exception e) {
            // Log error for monitoring (production orgs should integrate with logging framework)
            System.debug(LoggingLevel.ERROR, 'ExchangeRateManager scheduled execution failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            
            // In production, consider sending error notifications or creating case records
            // for admin visibility into scheduled job failures
        }
    }
    
    // Main orchestration method - processes all configured objects
    // Called by scheduled execution and available for manual invocation
    public static void updateExchangeRatesForAllConfiguredObjects() {
        Integer totalRecordsProcessed = 0;
        
        for (String objectApiName : OBJECT_FIELD_CONFIG.keySet()) {
            String exchangeRateField = OBJECT_FIELD_CONFIG.get(objectApiName);
            
            try {
                Integer recordsProcessed = updateExchangeRatesForObject(objectApiName, exchangeRateField);
                totalRecordsProcessed += recordsProcessed;
                
                System.debug(LoggingLevel.INFO, 
                    'ExchangeRateManager: Updated ' + recordsProcessed + ' ' + objectApiName + ' records');
                
            } catch (Exception e) {
                // Log error but continue processing other objects
                System.debug(LoggingLevel.ERROR, 
                    'ExchangeRateManager: Failed to update ' + objectApiName + ': ' + e.getMessage());
            }
        }
        
        System.debug(LoggingLevel.INFO, 
            'ExchangeRateManager: Total records processed: ' + totalRecordsProcessed);
    }
    
    // Generic method to update exchange rates for any Salesforce object
    // Uses dynamic SOQL and DML for maximum flexibility
    // 
    // @param objectApiName API name of the object to update (e.g., 'Quote', 'Opportunity')
    // @param exchangeRateFieldName API name of the exchange rate field (e.g., 'Exchange_Rate_at_Creation__c')
    // @return Integer number of records updated
    public static Integer updateExchangeRatesForObject(String objectApiName, String exchangeRateFieldName) {
        // Build dynamic SOQL query to find records missing exchange rates
        String soqlQuery = 'SELECT Id, CurrencyIsoCode, ' + exchangeRateFieldName + ' ' +
                          'FROM ' + objectApiName + ' ' +
                          'WHERE ' + exchangeRateFieldName + ' = null ' +
                          'AND CurrencyIsoCode != null ' +
                          'LIMIT ' + MAX_RECORDS_PER_EXECUTION;
        
        List<SObject> recordsToUpdate = Database.query(soqlQuery);
        
        if (recordsToUpdate.isEmpty()) {
            return 0; // No records need updating
        }
        
        // Group records by currency for efficient exchange rate lookup
        Map<String, List<SObject>> recordsByCurrency = new Map<String, List<Sobject>>();
        
        for (SObject record : recordsToUpdate) {
            String currencyCode = (String) record.get('CurrencyIsoCode');
            
            if (!recordsByCurrency.containsKey(currencyCode)) {
                recordsByCurrency.put(currencyCode, new List<SObject>());
            }
            recordsByCurrency.get(currencyCode).add(record);
        }
        
        // Update exchange rates for each currency group
        List<SObject> finalRecordsToUpdate = new List<SObject>();
        
        for (String currencyCode : recordsByCurrency.keySet()) {
            Decimal exchangeRate = getCurrentExchangeRate(currencyCode);
            
            if (exchangeRate != null) {
                for (SObject record : recordsByCurrency.get(currencyCode)) {
                    record.put(exchangeRateFieldName, exchangeRate);
                    finalRecordsToUpdate.add(record);
                }
            }
        }
        
        // Bulk update all records
        if (!finalRecordsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(finalRecordsToUpdate, false); // Allow partial success
                return countSuccessfulUpdates(results);
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 
                    'ExchangeRateManager: DML error updating ' + objectApiName + ': ' + e.getMessage());
                return 0;
            }
        }
        
        return 0;
    }
    
    // Get current exchange rate for specified currency
    // Looks up the most recent DatedConversionRate record
    // 
    // @param currencyCode ISO currency code (e.g., 'USD', 'EUR', 'GBP')
    // @return Decimal current exchange rate, or 1.0 for corporate currency, or null if not found
    public static Decimal getCurrentExchangeRate(String currencyCode) {
        if (String.isBlank(currencyCode)) {
            return null;
        }
        
        try {
            // Query for the most recent exchange rate
            // Use dynamic SOQL to handle orgs where multi-currency might not be enabled
            List<DatedConversionRate> rates = [
                SELECT ConversionRate, IsoCode
                FROM DatedConversionRate 
                WHERE IsoCode = :currencyCode
                AND StartDate <= TODAY 
                AND (NextStartDate > TODAY OR NextStartDate = null)
                LIMIT 1
            ];
            
            if (!rates.isEmpty()) {
                // GTM-138: Invert ConversionRate to match Salesforce standard conversion logic
                // DatedConversionRate stores corporate currency per foreign currency units
                // We need foreign currency per corporate currency units for USD conversions
                return 1 / rates[0].ConversionRate;
            } else {
                // If no rate found, assume corporate currency (rate = 1.0)
                System.debug(LoggingLevel.WARN, 
                    'ExchangeRateManager: No exchange rate found for currency ' + currencyCode + ', using 1.0');
                return 1.0;
            }
            
        } catch (QueryException e) {
            // Handle case where DatedConversionRate might not be accessible (single currency orgs)
            System.debug(LoggingLevel.INFO, 
                'ExchangeRateManager: DatedConversionRate not accessible, assuming single currency org');
            return 1.0;
        }
    }
    
    // Flow-callable method for real-time exchange rate updates
    // Allows flows to trigger exchange rate updates on demand
    // 
    // @param objectNames List of object API names to update
    // @return List<String> Status messages for each object processed
    @InvocableMethod(
        label='Update Exchange Rates for Objects'
        description='Updates exchange rates for specified Salesforce objects'
        category='Exchange Rate Management'
    )
    public static List<String> updateExchangeRatesInvocable(List<String> objectNames) {
        List<String> results = new List<String>();
        
        for (String objectName : objectNames) {
            if (OBJECT_FIELD_CONFIG.containsKey(objectName)) {
                try {
                    Integer recordsUpdated = updateExchangeRatesForObject(
                        objectName, 
                        OBJECT_FIELD_CONFIG.get(objectName)
                    );
                    results.add(objectName + ': ' + recordsUpdated + ' records updated');
                } catch (Exception e) {
                    results.add(objectName + ': Error - ' + e.getMessage());
                }
            } else {
                results.add(objectName + ': Not configured for exchange rate management');
            }
        }
        
        return results;
    }
    
    // Utility method to get exchange rate for a specific currency at a specific date
    // Useful for historical data processing or custom integrations
    // 
    // @param currencyCode ISO currency code
    // @param effectiveDate Date for which to retrieve the exchange rate
    // @return Decimal exchange rate for the specified date, or null if not found
    public static Decimal getExchangeRateForDate(String currencyCode, Date effectiveDate) {
        if (String.isBlank(currencyCode) || effectiveDate == null) {
            return null;
        }
        
        try {
            List<DatedConversionRate> rates = [
                SELECT ConversionRate
                FROM DatedConversionRate 
                WHERE IsoCode = :currencyCode
                AND StartDate <= :effectiveDate
                AND (NextStartDate > :effectiveDate OR NextStartDate = null)
                LIMIT 1
            ];
            
            // GTM-138: Invert ConversionRate to match Salesforce standard conversion logic
            return rates.isEmpty() ? 1.0 : (1 / rates[0].ConversionRate);
            
        } catch (QueryException e) {
            return 1.0; // Default for single currency orgs
        }
    }
    
    // Helper method to count successful database operations
    // Used for accurate reporting of update operations
    // 
    // @param results Array of Database.SaveResult from Database.update operations
    // @return Integer count of successful updates
    private static Integer countSuccessfulUpdates(Database.SaveResult[] results) {
        Integer successCount = 0;
        
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            } else {
                // Log individual record failures for troubleshooting
                System.debug(LoggingLevel.WARN, 
                    'ExchangeRateManager: Failed to update record ' + result.getId() + 
                    ': ' + result.getErrors()[0].getMessage());
            }
        }
        
        return successCount;
    }
    
    // Utility method to add new objects to exchange rate management
    // Allows dynamic configuration without code deployment
    // 
    // @param objectApiName API name of object to add
    // @param exchangeRateFieldName API name of exchange rate field on the object
    // @return Boolean true if successfully added, false if already exists
    public static Boolean addObjectToConfiguration(String objectApiName, String exchangeRateFieldName) {
        // Note: This modifies static configuration for current execution only
        // For persistent configuration, consider Custom Metadata Types in future versions
        if (!OBJECT_FIELD_CONFIG.containsKey(objectApiName)) {
            OBJECT_FIELD_CONFIG.put(objectApiName, exchangeRateFieldName);
            return true;
        }
        return false;
    }
    
    // Get list of objects currently configured for exchange rate management
    // Useful for admin interfaces and configuration validation
    // 
    // @return Set<String> Set of object API names currently configured
    public static Set<String> getConfiguredObjects() {
        return OBJECT_FIELD_CONFIG.keySet();
    }
    
    // GTM-138: Assign exchange rates to QLIs from related OLIs
    // Called during QLI creation to ensure consistent exchange rates
    // 
    // @param qliIds Set of QuoteLineItem IDs to process
    // @return Integer Number of QLIs updated with exchange rates
    public static Integer assignQLIRatesFromOLI(Set<Id> qliIds) {
        if (qliIds.isEmpty()) return 0;
        
        List<QuoteLineItem> qlisToUpdate = [
            SELECT Id, OpportunityLineItemId, Exchange_Rate__c
            FROM QuoteLineItem 
            WHERE Id IN :qliIds
            AND OpportunityLineItemId != null
            AND Exchange_Rate__c = null
        ];
        
        if (qlisToUpdate.isEmpty()) return 0;
        
        Set<Id> oliIds = new Set<Id>();
        for (QuoteLineItem qli : qlisToUpdate) {
            if (qli.OpportunityLineItemId != null) {
                oliIds.add(qli.OpportunityLineItemId);
            }
        }
        
        Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem>([
            SELECT Id, Exchange_Rate__c 
            FROM OpportunityLineItem 
            WHERE Id IN :oliIds
            AND Exchange_Rate__c != null
        ]);
        
        List<QuoteLineItem> finalQLIsToUpdate = new List<QuoteLineItem>();
        for (QuoteLineItem qli : qlisToUpdate) {
            Id oliId = qli.OpportunityLineItemId;
            if (oliId != null && oliMap.containsKey(oliId)) {
                OpportunityLineItem relatedOLI = oliMap.get(oliId);
                qli.Exchange_Rate__c = relatedOLI.Exchange_Rate__c;
                finalQLIsToUpdate.add(qli);
            }
        }
        
        if (!finalQLIsToUpdate.isEmpty()) {
            update finalQLIsToUpdate;
        }
        
        return finalQLIsToUpdate.size();
    }
    
    // GTM-138: Stamp exchange rates on OLIs during CPQ sync
    // Called during Quote-to-Opportunity sync to transfer QLI rates to OLIs
    // 
    // @param oliIds Set of OpportunityLineItem IDs to process
    // @return Integer Number of OLIs updated with exchange rates
    public static Integer stampOLIRatesFromQLI(Set<Id> oliIds) {
        if (oliIds.isEmpty()) return 0;
        
        List<OpportunityLineItem> olisToUpdate = [
            SELECT Id, QuoteLineItem__c, Exchange_Rate__c
            FROM OpportunityLineItem 
            WHERE Id IN :oliIds
            AND QuoteLineItem__c != null
            AND Exchange_Rate__c = null
        ];
        
        if (olisToUpdate.isEmpty()) return 0;
        
        Set<Id> qliIds = new Set<Id>();
        for (OpportunityLineItem oli : olisToUpdate) {
            qliIds.add(oli.QuoteLineItem__c);
        }
        
        Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>([
            SELECT Id, Exchange_Rate__c 
            FROM QuoteLineItem 
            WHERE Id IN :qliIds
            AND Exchange_Rate__c != null
        ]);
        
        List<OpportunityLineItem> finalOLIsToUpdate = new List<OpportunityLineItem>();
        for (OpportunityLineItem oli : olisToUpdate) {
            QuoteLineItem relatedQLI = qliMap.get(oli.QuoteLineItem__c);
            if (relatedQLI != null) {
                oli.Exchange_Rate__c = relatedQLI.Exchange_Rate__c;
                finalOLIsToUpdate.add(oli);
            }
        }
        
        if (!finalOLIsToUpdate.isEmpty()) {
            update finalOLIsToUpdate;
        }
        
        return finalOLIsToUpdate.size();
    }
    
    // GTM-138: Assign exchange rates to Assets from related OLIs
    // Called during Asset creation to ensure consistent exchange rates
    // 
    // @param assetIds Set of Asset IDs to process
    // @return Integer Number of Assets updated with exchange rates
    public static Integer inheritAssetRatesFromOLI(Set<Id> assetIds) {
        if (assetIds.isEmpty()) return 0;
        
        List<Asset> assetsToUpdate = [
            SELECT Id, Originating_OLI__c, Exchange_Rate__c
            FROM Asset 
            WHERE Id IN :assetIds
            AND Originating_OLI__c != null
            AND Exchange_Rate__c = null
        ];
        
        if (assetsToUpdate.isEmpty()) return 0;
        
        Set<Id> oliIds = new Set<Id>();
        for (Asset asset : assetsToUpdate) {
            oliIds.add(asset.Originating_OLI__c);
        }
        
        Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem>([
            SELECT Id, Exchange_Rate__c 
            FROM OpportunityLineItem 
            WHERE Id IN :oliIds
            AND Exchange_Rate__c != null
        ]);
        
        List<Asset> finalAssetsToUpdate = new List<Asset>();
        for (Asset asset : assetsToUpdate) {
            OpportunityLineItem relatedOLI = oliMap.get(asset.Originating_OLI__c);
            if (relatedOLI != null) {
                asset.Exchange_Rate__c = relatedOLI.Exchange_Rate__c;
                finalAssetsToUpdate.add(asset);
            }
        }
        
        if (!finalAssetsToUpdate.isEmpty()) {
            update finalAssetsToUpdate;
        }
        
        return finalAssetsToUpdate.size();
    }
    
    // GTM-138: Convert amount to USD using exchange rate
    // Utility method for manual USD conversions
    // 
    // @param amount Amount to convert
    // @param exchangeRate Exchange rate to use for conversion
    // @return Decimal USD amount
    public static Decimal convertToUSD(Decimal amount, Decimal exchangeRate) {
        if (amount == null || exchangeRate == null) return null;
        return amount * exchangeRate;
    }
}