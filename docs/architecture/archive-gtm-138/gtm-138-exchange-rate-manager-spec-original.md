# GTM-138 Exchange Rate Manager - Technical Specification

## Executive Summary

**Epic:** GTM-138 Exchange Rate Manager  
**Objective:** Implement comprehensive exchange rate management across all revenue objects with consistent rate locking and conversion logic  
**Target Date:** September 14, 2025  
**Primary Constraint:** Integration with existing homegrown CPQ system while maintaining ACM functionality for Opportunities

## Project Scope Overview

### Core Business Challenge
- **Current State:** Advanced Currency Management (ACM) only supports Opportunities; Contracts, Assets, Quotes use current rates creating inconsistent reporting
- **Desired State:** Predictable, locked exchange rates across all objects based on business trigger points with accurate multi-currency rollups
- **Secondary Issues:** Account currency rollups disabled by ACM, currency corrections post-migration may have incorrect rates

### Success Metrics
- Consistent exchange rates across all revenue objects (Opportunity, Quote, Contract, Asset)
- Accurate historical reporting immune to currency fluctuations
- Automated rate locking at business-critical moments
- Seamless rollup calculations from Assets to Contracts with mixed currencies
- Admin capability to override/correct exchange rates for historical backfill and error correction
- **Enhancement (Non-Blocking):** Corporate currency (USD) display with proper $ symbols

## Data Architecture & Object Relationships

### Exchange Rate Locking Strategy

#### Rate Locking Trigger Points
- **OpportunityLineItem:** Continue using ACM (no changes needed)
- **QuoteLineItem:** Inherit OLI exchange rate at creation, lock at Quote approval submission  
- **Quote:** Lock rate when status changes to "Needs Review"
- **Asset:** Lock rate at creation (before insert)
- **Contract:** Aggregate from Asset locked rates

#### Object Exchange Rate Flow
```
Opportunity (ACM) ──┐
                   ├─→ QuoteLineItem (inherit OLI rate) ──┐
OpportunityLineItem ──┘                                  ├─→ Quote (lock at "Needs Review")
                                                         │
Asset (lock at creation) ──────────────────────────────────→ Contract (rollup from Assets)
```

### Field Architecture

#### New Fields Required

**QuoteLineItem Object:**
- `Exchange_Rate__c` (Number, 18,6) - Exchange rate for USD conversion *(All Profiles, Hidden from Layouts)*
- **USD Conversion Fields** *(Formula/Read-Only)*:
  - `Annual_Amount_USD__c` (Number, 16,2) - Annual_Amount__c converted to USD
  - `List_Price_USD__c` (Number, 16,2) - List_Price__c converted to USD  
  - `ListPrice_USD__c` (Number, 16,2) - ListPrice converted to USD
  - `Total_Price_USD__c` (Number, 16,2) - Total_Price__c converted to USD
  - `TotalPrice_USD__c` (Number, 16,2) - TotalPrice converted to USD
  - `UnitPrice_USD__c` (Number, 16,2) - UnitPrice converted to USD

**Asset Object:**
- `Exchange_Rate__c` (Number, 18,6) - Exchange rate for USD conversion *(All Profiles, Hidden from Layouts)*
- **USD Conversion Fields** *(Formula/Read-Only)*:
  - `ARR_USD__c` (Number, 16,2) - ARR__c converted to USD
  - `MRR_USD__c` (Number, 16,2) - MRR__c converted to USD
  - `Price_USD__c` (Number, 16,2) - Price converted to USD
  - `Total_Price_USD__c` (Number, 16,2) - Total_Price__c converted to USD
  - `Total_Value_USD__c` (Number, 16,2) - Total_Value__c converted to USD
  - `Unit_ARR_USD__c` (Number, 16,2) - Unit_ARR__c converted to USD
  - `Unit_MRR_USD__c` (Number, 16,2) - Unit_MRR__c converted to USD
  - `Unit_Value_USD__c` (Number, 16,2) - Unit_Value__c converted to USD

**Contract Object:**
- **USD Rollup Fields** *(Updated by existing daily batch flow)*:
  - `Active_ARR_USD__c` (Number, 16,2) - Rollup from Asset.ARR_USD__c
  - `ACV_USD__c` (Number, 16,2) - Calculated from Asset USD amounts
  - `ARR_USD__c` (Number, 16,2) - Rollup from Asset.ARR_USD__c
  - `Incremental_ARR_USD__c` (Number, 16,2) - Business logic calculation
  - `MRR_USD__c` (Number, 16,2) - Rollup from Asset.MRR_USD__c
  - `Previous_ACV_USD__c` (Number, 16,2) - Historical comparison field
  - `Previous_ARR_USD__c` (Number, 16,2) - Historical comparison field
  - `Previous_MRR_USD__c` (Number, 16,2) - Historical comparison field
  - `Previous_TCV_USD__c` (Number, 16,2) - Historical comparison field
  - `TCV_USD__c` (Number, 16,2) - Rollup from Asset.Total_Value_USD__c

**Contract Object:**
- `Multi_Currency_Summary__c` (Long Text Area) - Summary of currencies represented *(Formula/Read-Only)*
- **USD Rollup Fields** *(Formula/Read-Only)*:
  - `Active_ARR_USD__c` (Number, 16,2) - Active_ARR__c converted to USD
  - `ACV_USD__c` (Number, 16,2) - ACV__c converted to USD
  - `ARR_USD__c` (Number, 16,2) - ARR__c converted to USD
  - `Incremental_ARR_USD__c` (Number, 16,2) - Incremental_ARR__c converted to USD
  - `MRR_USD__c` (Number, 16,2) - MRR__c converted to USD
  - `Previous_ACV_USD__c` (Number, 16,2) - Previous_ACV__c converted to USD
  - `Previous_ARR_USD__c` (Number, 16,2) - Previous_ARR__c converted to USD
  - `Previous_MRR_USD__c` (Number, 16,2) - Previous_MRR__c converted to USD
  - `Previous_TCV_USD__c` (Number, 16,2) - Previous_TCV__c converted to USD
  - `TCV_USD__c` (Number, 16,2) - TCV__c converted to USD

#### Enhanced Quote Object Fields
- Extend existing `Exchange_Rate__c` functionality *(All Profiles, Hidden from Layouts)*
- **Field History Tracking:** Enable field history on Exchange_Rate__c for audit trail
- **USD Conversion Fields** *(Formula/Read-Only)*:
  - `Annual_Total_USD__c` (Number, 16,2) - Annual_Total__c converted to USD
  - `First_Payment_Due_USD__c` (Number, 16,2) - First_Payment_Due__c converted to USD
  - `One_Off_Charges_USD__c` (Number, 16,2) - One_Off_Charges__c converted to USD
  - `Total_Payment_Due_USD__c` (Number, 16,2) - Total_Payment_Due__c converted to USD
  - `TotalPrice_USD__c` (Number, 16,2) - TotalPrice converted to USD

### Current vs Target State

#### Current ExchangeRateManager Capabilities
- Schedulable interface for daily maintenance
- Generic object support via configuration map
- DatedConversionRate integration for current rates
- Flow-invocable methods

#### Target ExchangeRateManager Enhancements
- Event-driven rate locking at business trigger points
- Multi-object inheritance logic (OLI → QLI)
- Historical rate preservation with audit trails
- Currency rollup calculations with mixed-rate support

## Core Automation Workflows

### Rate Inheritance: OLI → QLI

#### Business Logic
```
QuoteLineItem Creation (via existing Quote creation from Opportunity logic)
└── FOR each QuoteLineItem being created
    └── QLI.Exchange_Rate__c = getCurrentExchangeRate(OLI.CurrencyIsoCode)
```

#### Implementation Approach
- **Integration:** Add exchange rate assignment to existing QLI creation logic
- **Simplicity:** Just assign current exchange rate, no complex inheritance decision tree
- **Data Source:** Use ExchangeRateManager.getCurrentExchangeRate() method

### Rate Locking: Quote Approval Submission

#### Business Logic
```
Quote.Status changed to "Needs Review"
└── FOR Quote and all related QuoteLineItems
    └── Exchange rates already set and protected by field-level security
```

#### Integration with Existing Flow Approvals
- **No Additional Logic Required:** Exchange rates are already captured and protected by profile permissions
- **Field History Tracking:** Automatically tracks any admin changes to exchange rates
- **Audit Trail:** Field history provides complete audit trail of rate changes

### Rate Locking: Asset Creation

#### Business Logic
```
Asset before insert
└── FOR each Asset record
    ├── Asset.Exchange_Rate__c = getCurrentExchangeRate(Asset.CurrencyIsoCode)
    └── USD fields automatically calculate via formulas using Asset.Exchange_Rate__c
```

#### Date-Based Considerations
- **Rate Date:** Use current exchange rate at Asset creation
- **Business Justification:** Asset represents contractual commitment at signing
- **Integration:** Coordinate with Revenue Automation (GTM-146) Asset creation workflows

### Currency Rollups: Asset → Contract

#### Integration with Existing Daily Batch Flow
```
Existing Daily Scheduled Batch Flow (Modified)
└── Update rollup logic to use new Asset USD fields instead of original currency fields
    ├── Contract.ARR_USD__c = SUM(Asset.ARR_USD__c for all related Assets)
    ├── Contract.MRR_USD__c = SUM(Asset.MRR_USD__c for all related Assets)
    ├── Contract.TCV_USD__c = SUM(Asset.Total_Value_USD__c for all related Assets)
    └── Additional business logic calculations as needed
```

#### Implementation Approach
- **Leverage Existing Infrastructure:** Modify existing daily batch flow instead of creating new triggers
- **Field Updates:** Change rollup calculations to use new Asset USD fields
- **Performance:** Continue using established batch processing approach

### Field Security & Profile Management

#### Profile-Based Access Control
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

#### Audit Trail Management
- **Field History Tracking:** Enable on Exchange_Rate__c fields across all objects
- **Automatic Tracking:** Salesforce tracks who changed field and when
- **No Custom Fields Required:** Leverage platform auditing capabilities

## Implementation Phases

### Phase 1: Field Architecture & Profile Setup

**P1.1 - Field Creation & Formula Fields**
- **GTM-184:** Create Exchange_Rate__c fields on QuoteLineItem and Asset objects
- **GTM-184:** Create all USD conversion formula fields (29 total across Quote, QLI, Asset, Contract)
- **GTM-183:** Enable field history tracking on all Exchange_Rate__c fields

**P1.2 - Profile & Security Configuration**
- **GTM-183:** Assign Exchange_Rate__c field permissions to all 9 profiles
- **GTM-183:** Keep Exchange_Rate__c fields hidden from all page layouts
- **GTM-183:** Verify inspector/CLI access for admin editing

### Phase 2: Exchange Rate Assignment Logic

**P2.1 - QLI Rate Assignment**
- **GTM-190:** Enhance existing QLI creation logic to assign Exchange_Rate__c
- **GTM-188:** Integration testing with existing Quote creation process

**P2.2 - Asset Rate Assignment**
- **GTM-189:** Build Asset trigger to assign Exchange_Rate__c at creation
- **GTM-187:** Integration with Revenue Automation asset creation

### Phase 3: Rollup Integration & Formula Validation

**P3.1 - Daily Batch Flow Updates**
- **GTM-189:** Modify existing daily batch flow to use new Asset USD fields
- **GTM-185:** Update Contract rollup calculations for all USD fields

**P3.2 - Formula Field Validation**
- **GTM-191:** Validate all 29 USD conversion formulas calculate correctly
- **GTM-185:** Test formula recalculation when Exchange_Rate__c is updated

### Phase 4: Layout Updates & User Experience

**P4.1 - Page Layout Configuration**
- **GTM-191:** Add USD conversion fields to relevant page layouts
- **GTM-191:** Configure field sections and ordering for optimal user experience
- **GTM-191:** Update related list views to include USD fields where appropriate

**P4.2 - Documentation & Testing**
- **GTM-193:** Document admin procedures for exchange rate corrections
- **GTM-192:** Create testing procedures for USD field calculations

### Phase 5: Enhancements (Non-Blocking)

**P5.1 - Display & Formatting Improvements**
- **Enhancement:** Corporate currency (USD) display with proper $ symbols
- **Enhancement:** Improved currency field formatting across objects
- **Enhancement:** Currency summary dashboards and reports

## Technical Architecture Decisions

### ExchangeRateManager Class Extensions

#### Simplified Method Requirements

```apex
public class ExchangeRateManager {
    
    // Existing methods (keep unchanged)
    public static Decimal getCurrentExchangeRate(String currencyCode) { ... }
    public static void updateExchangeRatesForAllConfiguredObjects() { ... }
    
    // New simplified methods
    public static void assignQLIRates(List<QuoteLineItem> qlis);
    public static void assignAssetRates(List<Asset> assets);
    
    // Currency conversion utilities (for formula field reference if needed)
    public static Decimal convertToUSD(Decimal amount, Decimal exchangeRate);
}
```

#### Simplified Configuration Management

**Object-Specific Configuration:**
```apex
private static final Map<String, String> EXCHANGE_RATE_FIELDS = new Map<String, String>{
    'Quote' => 'Exchange_Rate__c',
    'QuoteLineItem' => 'Exchange_Rate__c', 
    'Asset' => 'Exchange_Rate__c'
};
```

### Trigger Strategy & Architecture

#### QLI Enhancement (Existing Logic Extension)
- **Integration:** Add exchange rate assignment to existing QLI creation process
- **Trigger Point:** Enhance existing Quote-from-Opportunity creation logic
- **Performance:** Single additional assignment, minimal performance impact

#### Asset Trigger (New)
- **Events:** before insert (rate assignment only)
- **Logic:** Simple current exchange rate assignment
- **Performance:** Single SOQL query cached per currency per transaction

#### No Quote Trigger Required
- **Rationale:** Exchange rates protected by field-level security
- **Audit:** Field history tracking provides complete audit trail

### Governor Limit Management

#### Bulk Processing Strategy
- **SOQL Limits:** Cache exchange rates within transaction context
- **DML Limits:** Batch updates for Contract rollups
- **CPU Time:** Optimize calculation loops, use Map-based lookups

#### Asynchronous Processing Options
- **Queueable Apex:** For large Contract rollup calculations
- **Batch Apex:** For historical data migration and maintenance
- **Platform Events:** For real-time cross-object notifications

## Integration Specifications

### CPQ System Coordination

#### Quote Creation from Opportunity
- **Current Process:** Copies OLI data to QLI
- **Enhancement:** Add exchange rate inheritance logic
- **Validation:** Ensure rate consistency between OLI and QLI

#### Quote-to-Opportunity Sync
- **Rate Preservation:** Maintain locked Quote rates during sync
- **Business Rule:** Opportunity rates can continue changing via ACM
- **Data Integrity:** Quote reflects point-in-time approval rates

### Revenue Automation Integration (GTM-146)

#### Asset Creation Coordination
- **Trigger Order:** Exchange rate locking before Revenue Automation processing
- **Data Flow:** OLI → Asset with exchange rate capture
- **Contract Rollups:** Coordinate with Contract creation workflows

### Approval System Integration

#### Flow-Based Approval Enhancement
- **Status Detection:** Monitor Quote status changes to "Needs Review"
- **Field Updates:** Trigger exchange rate locking via flow actions
- **Validation Rules:** Prevent changes to locked exchange rates

## Outstanding Technical Specifications

### Decision Points Requiring Resolution

### Decision Points Requiring Resolution

#### Formula Field Implementation
1. **USD Field Calculations:** Should USD fields be formula fields or calculated fields updated by triggers?
2. **Performance:** Formula fields vs. stored calculations for reporting performance?

#### Data Migration Strategy
1. **Backfill Approach:** Use Data Loader or write Apex batch job for historical Exchange_Rate__c assignment?
2. **Historical Rate Lookup:** Use creation date to assign historical exchange rates where possible?

### Data Migration Requirements

#### Historical Data Processing
1. **Existing Assets:** Batch process to assign Exchange_Rate__c based on creation date lookup
2. **Existing QLIs:** Assign current exchange rate or attempt historical rate lookup
3. **Formula Field Population:** USD fields automatically populate once Exchange_Rate__c is assigned

#### Profile & Layout Deployment
1. **Field Assignments:** Deploy Exchange_Rate__c permissions to all 9 profiles
2. **Layout Updates:** Add USD fields to appropriate page layouts
3. **Field History:** Enable field history tracking on Exchange_Rate__c fields

## Risk Mitigation & Success Factors

### Critical Dependencies
- **ACM Preservation:** Maintain existing Opportunity functionality
- **CPQ Integration:** Seamless operation with existing Quote system
- **Performance Impact:** Minimize trigger execution time for bulk operations
- **Data Integrity:** Accurate currency conversions across all scenarios

### Success Criteria
- **Critical (Blocking):** Rate consistency - Locked rates maintain values regardless of market fluctuations  
- **Critical (Blocking):** Business process integration - Seamless operation with existing approval workflows
- **Critical (Blocking):** Reporting accuracy - USD amounts calculated consistently across all objects
- **Critical (Blocking):** System performance - No degradation in Quote or Asset creation times
- **Critical (Blocking):** User experience - Transparent rate locking with clear status indicators
- **Enhancement (Non-Blocking):** Display formatting with proper currency symbols and formatting

### Testing Strategy

#### Unit Testing Requirements
- **Rate Assignment:** QLI and Asset exchange rate assignment accuracy
- **Formula Fields:** USD conversion calculations across all 29 fields
- **Daily Batch Flow:** Modified rollup calculations using new Asset USD fields
- **Field History:** Exchange rate change tracking and audit capabilities
- **Profile Security:** Field access verification across all 9 profiles

#### Integration Testing Scenarios
- **CPQ Workflows:** End-to-end Quote creation with QLI exchange rate assignment
- **Revenue Automation:** Asset creation with exchange rate coordination
- **Daily Rollups:** Contract USD field updates using existing batch flow
- **Admin Corrections:** Exchange rate override using inspector/CLI access
- **Formula Recalculation:** USD field updates when Exchange_Rate__c changes

---

**Document Version:** 1.0  
**Last Updated:** August 26, 2025  
**Next Review:** Technical architecture validation and field deployment strategy