# GTM-138 Technical Architecture

**Document Version:** 1.0  
**Last Updated:** August 26, 2025

## Architecture Overview

This document details the technical implementation approach for the GTM-138 Exchange Rate Manager project.

## Object Relationship Model

```
OpportunityLineItem (ACM) ──┐
                           ├─→ QuoteLineItem (inherit rate) ──┐
Opportunity (ACM) ──────────┘                                ├─→ Quote (lock at "Needs Review")
                                                             │
Asset (lock at creation) ────────────────────────────────────→ Contract (rollup from Assets)
```

## Exchange Rate Locking Strategy

### Rate Locking Trigger Points
- **OpportunityLineItem:** Continue using ACM (no changes needed)
- **QuoteLineItem:** Inherit current exchange rate at creation, lock at Quote approval submission
- **Quote:** Lock rate when status changes to "Needs Review"
- **Asset:** Lock rate at creation (before insert)
- **Contract:** Aggregate from Asset locked rates

### Business Logic Flow

#### QuoteLineItem Creation
```apex
// Integration with existing Quote creation logic
QuoteLineItem Creation (via existing Quote-from-Opportunity logic)
└── FOR each QuoteLineItem being created
    └── QLI.Exchange_Rate__c = ExchangeRateManager.getCurrentExchangeRate(OLI.CurrencyIsoCode)
```

#### Asset Creation
```apex
// New Asset trigger
Asset before insert
└── FOR each Asset record
    ├── Asset.Exchange_Rate__c = ExchangeRateManager.getCurrentExchangeRate(Asset.CurrencyIsoCode)
    └── USD fields automatically calculate via formulas using Asset.Exchange_Rate__c
```

#### Contract Rollups
```apex
// Modified existing daily batch flow
Existing Daily Scheduled Batch Flow (Modified)
└── Update rollup logic to use new Asset USD fields instead of original currency fields
    ├── Contract.ARR_USD__c = SUM(Asset.ARR_USD__c for all related Assets)
    ├── Contract.MRR_USD__c = SUM(Asset.MRR_USD__c for all related Assets)
    ├── Contract.TCV_USD__c = SUM(Asset.Total_Value_USD__c for all related Assets)
    └── Additional business logic calculations as needed
```

## Field Architecture

### Exchange Rate Fields
All Exchange_Rate__c fields follow consistent pattern:
- **Type:** Number(18,6)
- **Visibility:** Hidden from all page layouts
- **Security:** Read/Edit enabled for all 9 profiles
- **History Tracking:** Enabled for audit trail

### USD Conversion Fields
All USD fields are formula fields:
- **Type:** Number(16,2)
- **Formula Pattern:** `OriginalField__c * Exchange_Rate__c`
- **Display:** Visible on relevant page layouts
- **Currency:** USD with proper $ symbol formatting

### Field Inventory

#### QuoteLineItem (6 fields)
- Exchange_Rate__c (Number, 18,6)
- Annual_Amount_USD__c (Formula)
- List_Price_USD__c (Formula)
- ListPrice_USD__c (Formula)
- Total_Price_USD__c (Formula)
- TotalPrice_USD__c (Formula)
- UnitPrice_USD__c (Formula)

#### Asset (9 fields)
- Exchange_Rate__c (Number, 18,6)
- ARR_USD__c (Formula)
- MRR_USD__c (Formula)
- Price_USD__c (Formula)
- Total_Price_USD__c (Formula)
- Total_Value_USD__c (Formula)
- Unit_ARR_USD__c (Formula)
- Unit_MRR_USD__c (Formula)
- Unit_Value_USD__c (Formula)

#### Quote (6 fields)
- Exchange_Rate__c (Enhanced existing field)
- Annual_Total_USD__c (Formula)
- First_Payment_Due_USD__c (Formula)
- One_Off_Charges_USD__c (Formula)
- Total_Payment_Due_USD__c (Formula)
- TotalPrice_USD__c (Formula)

#### Contract (11 fields)
- Multi_Currency_Summary__c (Formula)
- Active_ARR_USD__c (Formula)
- ACV_USD__c (Formula)
- ARR_USD__c (Formula)
- Incremental_ARR_USD__c (Formula)
- MRR_USD__c (Formula)
- Previous_ACV_USD__c (Formula)
- Previous_ARR_USD__c (Formula)
- Previous_MRR_USD__c (Formula)
- Previous_TCV_USD__c (Formula)
- TCV_USD__c (Formula)

## ExchangeRateManager Class Architecture

### Enhanced Method Requirements

```apex
public class ExchangeRateManager {
    
    // Existing methods (keep unchanged)
    public static Decimal getCurrentExchangeRate(String currencyCode) { ... }
    public static void updateExchangeRatesForAllConfiguredObjects() { ... }
    
    // New simplified methods
    public static void assignQLIRates(List<QuoteLineItem> qlis);
    public static void assignAssetRates(List<Asset> assets);
    
    // Currency conversion utilities
    public static Decimal convertToUSD(Decimal amount, Decimal exchangeRate);
}
```

### Configuration Management

```apex
private static final Map<String, String> EXCHANGE_RATE_FIELDS = new Map<String, String>{
    'Quote' => 'Exchange_Rate__c',
    'QuoteLineItem' => 'Exchange_Rate__c', 
    'Asset' => 'Exchange_Rate__c'
};
```

## Trigger Strategy

### QLI Enhancement (Existing Logic Extension)
- **Integration:** Add exchange rate assignment to existing QLI creation process
- **Trigger Point:** Enhance existing Quote-from-Opportunity creation logic
- **Performance:** Single additional assignment, minimal performance impact

### Asset Trigger (New)
- **Events:** before insert (rate assignment only)
- **Logic:** Simple current exchange rate assignment
- **Performance:** Single SOQL query cached per currency per transaction

### No Quote Trigger Required
- **Rationale:** Exchange rates protected by field-level security
- **Audit:** Field history tracking provides complete audit trail

## Integration Points

### CPQ System Coordination
- **Quote Creation from Opportunity:** Add exchange rate inheritance logic
- **Quote-to-Opportunity Sync:** Maintain locked Quote rates during sync
- **Data Integrity:** Quote reflects point-in-time approval rates

### Revenue Automation Integration (GTM-146)
- **Asset Creation Coordination:** Exchange rate locking before Revenue Automation processing
- **Data Flow:** OLI → Asset with exchange rate capture
- **Contract Rollups:** Coordinate with Contract creation workflows

## Performance Considerations

### Governor Limit Management
- **SOQL Limits:** Cache exchange rates within transaction context
- **DML Limits:** Batch updates for Contract rollups
- **CPU Time:** Optimize calculation loops, use Map-based lookups

### Bulk Processing Strategy
- **Queueable Apex:** For large Contract rollup calculations
- **Batch Apex:** For historical data migration and maintenance
- **Platform Events:** For real-time cross-object notifications

## Security Architecture

### Profile-Based Access Control
```
All 9 Profiles (Field Assignment Required):
├── Custom SysAdmin
├── Minimum Access - Salesforce  
├── Seqera Customer Service
├── Seqera Executive
├── Seqera Marketing
├── Seqera Sales
├── Seqera SDR
├── System Administrator
└── System Administrator (Service Account)

Exchange Rate Field Security:
├── Field Permissions: Read/Edit enabled for all profiles
├── Layout Visibility: Hidden from all page layouts
└── Admin Access: Use inspector/CLI to edit Exchange_Rate__c fields
```

### Audit Trail Management
- **Field History Tracking:** Enable on Exchange_Rate__c fields across all objects
- **Automatic Tracking:** Salesforce tracks who changed field and when
- **No Custom Fields Required:** Leverage platform auditing capabilities

## Data Migration Strategy

### Historical Data Processing
1. **Existing Assets:** Batch process to assign Exchange_Rate__c based on creation date lookup
2. **Existing QLIs:** Assign current exchange rate or attempt historical rate lookup
3. **Formula Field Population:** USD fields automatically populate once Exchange_Rate__c is assigned

### Migration Approach Options
1. **Data Loader:** For simple current rate assignment
2. **Apex Batch Job:** For historical rate lookup based on creation dates
3. **Hybrid Approach:** Current rates for recent data, historical lookup for older records

---
**Next Review:** Technical architecture validation meeting  
**Dependencies:** Field deployment strategy and performance testing results
