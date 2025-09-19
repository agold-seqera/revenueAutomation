# GTM-138 Integration Guide

**Document Version:** 1.0  
**Last Updated:** August 26, 2025  
**Integration Scope:** CPQ System, Revenue Automation (GTM-146), ACM Coordination

## Integration Overview

This document details the integration requirements and coordination points for the GTM-138 Exchange Rate Manager project with existing Salesforce systems and external processes.

## System Integration Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Opportunity     │    │ Quote System     │    │ Revenue         │
│ (ACM Enabled)   │───▶│ (CPQ)           │───▶│ Automation      │
│                 │    │                  │    │ (GTM-146)       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ OLI             │    │ QLI + Quote      │    │ Asset           │
│ (ACM Rates)     │    │ (Locked Rates)   │    │ (Locked Rates)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │ Contract        │
                                                │ (USD Rollups)   │
                                                └─────────────────┘
```

## Critical Integration Points

### 1. Advanced Currency Management (ACM) Coordination

#### Current ACM Implementation
- **Scope:** OpportunityLineItem only
- **Functionality:** Automatic exchange rate management based on close date
- **Constraint:** Must remain unchanged for GTM-138

#### GTM-138 ACM Interaction
- **Principle:** Zero impact on existing ACM functionality
- **Implementation:** Extend rate locking pattern without modifying ACM
- **Validation:** Comprehensive testing to ensure ACM continues working as expected

#### Integration Requirements
```apex
// Maintain existing ACM behavior
public class OpportunityTriggerHandler {
    // Existing ACM logic remains unchanged
    public void handleACMRateUpdates(List<Opportunity> opportunities) {
        // No modifications for GTM-138
    }
}

// New GTM-138 logic runs independently
public class QuoteLineItemEnhancement {
    public void assignExchangeRates(List<QuoteLineItem> qlis) {
        // New logic for QLI rate assignment
        // Uses current exchange rates, not ACM rates
    }
}
```

### 2. CPQ System Integration

#### Existing CPQ Workflow
```
Opportunity Creation ──┐
                      ├─→ Quote Creation ──┐
Opportunity Update ───┘                    ├─→ QuoteLineItem Creation
                                          │
                      Quote Sync ◄────────┘
```

#### Enhanced CPQ Workflow with GTM-138
```
Opportunity Creation ──┐
                      ├─→ Quote Creation ──┐
Opportunity Update ───┘                    ├─→ QuoteLineItem Creation
                                          │   ├─→ Exchange Rate Assignment (NEW)
                      Quote Sync ◄────────┘   └─→ USD Field Calculation (NEW)
                           │
                           ▼
                      Rate Locking on "Needs Review" Status (NEW)
```

#### Integration Points

##### Quote Creation from Opportunity
```apex
// Existing CPQ logic (unchanged)
public class QuoteCreationService {
    public Quote createQuoteFromOpportunity(Id opportunityId) {
        // Existing quote creation logic
        Quote newQuote = new Quote(/* existing field mappings */);
        
        // NEW: Exchange rate assignment integration
        ExchangeRateManager.assignQLIRates(newQuoteLineItems);
        
        return newQuote;
    }
}
```

##### QuoteLineItem Enhancement
- **Integration Method:** Enhance existing QLI creation logic
- **Rate Assignment:** Use `ExchangeRateManager.getCurrentExchangeRate(currencyCode)`
- **Timing:** During QLI creation, before insert
- **Performance Impact:** Minimal (single additional field assignment)

##### Quote Status Integration
- **Trigger Point:** Quote status change to "Needs Review"
- **Action:** Exchange rates already locked by field-level security
- **Audit Trail:** Field history tracking captures all rate changes
- **No Additional Logic Required:** Field security handles rate protection

### 3. Revenue Automation Integration (GTM-146)

#### Current Revenue Automation Workflow
```
Opportunity Closed-Won ──┐
                        ├─→ Asset Creation ──┐
Contract Execution ─────┘                   ├─→ Contract Updates
                                           │
                        Daily Batch ◄──────┘
```

#### Enhanced Revenue Automation with GTM-138
```
Opportunity Closed-Won ──┐
                        ├─→ Asset Creation ──┐
Contract Execution ─────┘   ├─→ Exchange Rate Assignment (NEW)
                           └─→ USD Field Calculation (NEW)
                                          │
                        Daily Batch ◄─────┼─→ Contract USD Rollups (MODIFIED)
```

#### Integration Requirements

##### Asset Creation Coordination
```apex
// GTM-146 Revenue Automation (existing)
public class RevenueAutomationService {
    public void createAssetsFromOpportunity(Id opportunityId) {
        List<Asset> newAssets = buildAssetsFromOLI(opportunityId);
        
        // GTM-138 integration point: Exchange rate assignment
        ExchangeRateManager.assignAssetRates(newAssets);
        
        insert newAssets; // Exchange rates assigned before insert
        
        // Continue with existing Revenue Automation logic
        handleContractUpdates(newAssets);
    }
}

// New Asset Trigger for GTM-138
trigger AssetTrigger on Asset (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        AssetTriggerHandler.assignExchangeRates(Trigger.new);
    }
}
```

##### Contract Rollup Coordination
```apex
// Modified daily batch flow (existing batch job enhanced)
public class ContractRollupBatch implements Database.Batchable<sObject> {
    public void execute(Database.BatchableContext context, List<Contract> contracts) {
        for (Contract contract : contracts) {
            // MODIFIED: Use new Asset USD fields instead of original currency fields
            contract.ARR_USD__c = calculateRollupFromAssetUSD(contract.Id, 'ARR_USD__c');
            contract.MRR_USD__c = calculateRollupFromAssetUSD(contract.Id, 'MRR_USD__c');
            contract.TCV_USD__c = calculateRollupFromAssetUSD(contract.Id, 'Total_Value_USD__c');
        }
        update contracts;
    }
}
```

### 4. ExchangeRateManager Class Integration

#### Current ExchangeRateManager Capabilities
```apex
public class ExchangeRateManager {
    // Existing methods (keep unchanged)
    public static Decimal getCurrentExchangeRate(String currencyCode) { ... }
    public static void updateExchangeRatesForAllConfiguredObjects() { ... }
    
    // Existing configuration
    private static final Map<String, String> OBJECT_CURRENCY_FIELDS = new Map<String, String>{
        'Quote' => 'CurrencyIsoCode'
    };
}
```

#### Enhanced ExchangeRateManager for GTM-138
```apex
public class ExchangeRateManager {
    // Existing methods (unchanged)
    public static Decimal getCurrentExchangeRate(String currencyCode) { ... }
    public static void updateExchangeRatesForAllConfiguredObjects() { ... }
    
    // NEW: GTM-138 specific methods
    public static void assignQLIRates(List<QuoteLineItem> qlis) {
        Map<String, Decimal> currencyRateMap = new Map<String, Decimal>();
        
        for (QuoteLineItem qli : qlis) {
            String currencyCode = qli.CurrencyIsoCode;
            if (!currencyRateMap.containsKey(currencyCode)) {
                currencyRateMap.put(currencyCode, getCurrentExchangeRate(currencyCode));
            }
            qli.Exchange_Rate__c = currencyRateMap.get(currencyCode);
        }
    }
    
    public static void assignAssetRates(List<Asset> assets) {
        Map<String, Decimal> currencyRateMap = new Map<String, Decimal>();
        
        for (Asset asset : assets) {
            String currencyCode = asset.CurrencyIsoCode;
            if (!currencyRateMap.containsKey(currencyCode)) {
                currencyRateMap.put(currencyCode, getCurrentExchangeRate(currencyCode));
            }
            asset.Exchange_Rate__c = currencyRateMap.get(currencyCode);
        }
    }
    
    public static Decimal convertToUSD(Decimal amount, Decimal exchangeRate) {
        return (amount != null && exchangeRate != null) ? amount * exchangeRate : null;
    }
    
    // Enhanced configuration for GTM-138
    private static final Map<String, String> EXCHANGE_RATE_FIELDS = new Map<String, String>{
        'Quote' => 'Exchange_Rate__c',
        'QuoteLineItem' => 'Exchange_Rate__c',
        'Asset' => 'Exchange_Rate__c'
    };
}
```

## Flow Integration Specifications

### Quote Approval Flow Integration

#### Existing Approval Flow
```
Quote Status Change ──┐
                     ├─→ Approval Process Trigger ──┐
User Action ─────────┘                              ├─→ Status Update to "Needs Review"
                                                   │
                      Approval Completion ◄───────┘
```

#### GTM-138 Integration (No Changes Required)
- **Field Security Protection:** Exchange_Rate__c fields protected by profile permissions
- **Automatic Audit:** Field history tracking captures any changes
- **Admin Override:** Inspector/CLI access for authorized rate corrections
- **Business Logic:** No additional flow logic required

### Data Migration Integration

#### Historical Data Processing
```apex
// Batch job for historical exchange rate assignment
public class HistoricalExchangeRateAssignment implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, CurrencyIsoCode, CreatedDate, Exchange_Rate__c 
            FROM Asset 
            WHERE Exchange_Rate__c = null
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<Asset> assets) {
        for (Asset asset : assets) {
            // Assign historical rate based on creation date
            asset.Exchange_Rate__c = getHistoricalExchangeRate(
                asset.CurrencyIsoCode, 
                asset.CreatedDate
            );
        }
        update assets;
    }
}
```

## Performance Integration Considerations

### Governor Limit Management

#### SOQL Query Optimization
```apex
// Efficient exchange rate caching within transaction
public class ExchangeRateCache {
    private static Map<String, Decimal> transactionCache = new Map<String, Decimal>();
    
    public static Decimal getCachedExchangeRate(String currencyCode) {
        if (!transactionCache.containsKey(currencyCode)) {
            transactionCache.put(currencyCode, 
                ExchangeRateManager.getCurrentExchangeRate(currencyCode));
        }
        return transactionCache.get(currencyCode);
    }
}
```

#### Bulk Processing Strategy
- **QLI Creation:** Process up to 200 QLIs per transaction with single exchange rate query per currency
- **Asset Creation:** Bulk Asset creation with exchange rate assignment before insert
- **Contract Rollups:** Continue using existing daily batch processing approach

### Integration Testing Requirements

#### CPQ Integration Testing
```apex
@isTest
public class CPQIntegrationTest {
    @isTest
    static void testQuoteCreationWithExchangeRates() {
        // Test end-to-end Quote creation from Opportunity
        // Verify QLI exchange rate assignment
        // Validate USD field calculations
    }
    
    @isTest
    static void testQuoteApprovalWorkflow() {
        // Test Quote approval process with locked exchange rates
        // Verify field history tracking
        // Validate rate protection
    }
}
```

#### Revenue Automation Integration Testing
```apex
@isTest
public class RevenueAutomationIntegrationTest {
    @isTest
    static void testAssetCreationWithExchangeRates() {
        // Test Asset creation from Opportunity
        // Verify exchange rate assignment coordination
        // Validate Contract rollup calculations
    }
}
```

## Error Handling & Rollback Procedures

### Integration Failure Scenarios

#### CPQ Integration Failures
- **Symptom:** QLI creation without exchange rates
- **Detection:** Validation rule on Exchange_Rate__c required field
- **Recovery:** Automated retry with exchange rate assignment
- **Monitoring:** Dashboard alerts for QLI creation failures

#### Revenue Automation Coordination Issues
- **Symptom:** Assets created without exchange rates
- **Detection:** Asset trigger validation
- **Recovery:** Before insert trigger assigns missing rates
- **Escalation:** Automated notification to technical team

### Rollback Coordination
```apex
// Coordinated rollback procedure
public class GTMRollbackService {
    public static void rollbackExchangeRateLogic() {
        // 1. Disable new triggers
        // 2. Remove field assignments from profiles
        // 3. Revert ExchangeRateManager enhancements
        // 4. Restore original CPQ and Revenue Automation logic
    }
}
```

## Monitoring & Maintenance

### Integration Health Monitoring
- **Daily Checks:** Verify QLI and Asset exchange rate assignment completion
- **Performance Metrics:** Monitor Quote and Asset creation times
- **Error Tracking:** Alert on integration failures or missing exchange rates
- **Data Integrity:** Regular validation of USD field calculations

### Maintenance Procedures
- **Weekly:** Review exchange rate assignment success rates
- **Monthly:** Performance analysis of integrated workflows
- **Quarterly:** Integration health assessment and optimization review

---
**Integration Contact:** Technical Integration Lead  
**Dependencies:** CPQ System Team, Revenue Automation Team (GTM-146)  
**Next Review:** Integration coordination meeting with all system owners
