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
- **Secondary Issues:** Account currency rollups disabled by ACM, currency corrections post-migration may have incorrect rates, native converted fields no longer available for reporting

### Success Metrics
- Consistent exchange rates across all revenue objects (Opportunity, Quote, Contract, Asset, Account)
- Accurate historical reporting immune to currency fluctuations
- Automated rate locking at business-critical moments
- Seamless rollup calculations from Assets to Contracts with mixed currencies
- Admin capability to override/correct exchange rates for historical backfill and error correction
- USD conversion fields with proper currency formatting for SFDC reports
- **Enhancement (Non-Blocking):** Corporate currency (USD) display with proper $ symbols

## Data Architecture & Object Relationships

### Exchange Rate Locking Strategy

#### Rate Locking Trigger Points
- **OpportunityLineItem:** Continue using ACM, stamp Exchange_Rate__c field for audit purposes
- **QuoteLineItem:** Get current exchange rate at creation, lock at Quote approval submission  
- **Quote:** Lock rate when status changes to "Needs Review"
- **Quote-to-Opportunity Sync:** Stamp current exchange rate on OLIs during sync from approved Quotes
- **Asset:** Inherit exchange rate from related OLI at creation
- **Contract:** Aggregate from Asset locked rates
- **Account:** Use inherited exchange rates from related records

#### Object Exchange Rate Flow
```
Opportunity (ACM + audit stamp) ──┐
                                  ├─→ QuoteLineItem (get current rate) ──┐
                                  │                                       ├─→ Quote (lock at "Needs Review")
                                  │                                       │
                                  └─→ OLI Sync Update (get current rate) ←┘
                                  │
                                  └─→ Asset (inherit OLI rate) ──────────────→ Contract (rollup from Assets)
                                                                              │
                                                                              └─→ Account (rollup from Contracts)
```

### Field Architecture

#### New Fields Required

**OpportunityLineItem Object:**
- `Exchange_Rate__c` (Number, 18,6) - Exchange rate for USD conversion *(All Profiles, Hidden from Layouts, Audit Purposes)*

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

**Quote Object:**
- Extend existing `Exchange_Rate__c` functionality *(All Profiles, Hidden from Layouts)*
- **Field History Tracking:** Enable field history on Exchange_Rate__c for audit trail
- **USD Conversion Fields** *(Formula/Read-Only)*:
  - `Annual_Total_USD__c` (Number, 16,2) - Annual_Total__c converted to USD
  - `First_Payment_Due_USD__c` (Number, 16,2) - First_Payment_Due__c converted to USD
  - `One_Off_Charges_USD__c` (Number, 16,2) - One_Off_Charges__c converted to USD
  - `Total_Payment_Due_USD__c` (Number, 16,2) - Total_Payment_Due__c converted to USD
  - `TotalPrice_USD__c` (Number, 16,2) - TotalPrice converted to USD

**Contract Object:**
- `Multi_Currency_Summary__c` (Long Text Area) - Summary of currencies represented *(Formula/Read-Only)*
- **USD Conversion Fields** *(Formula/Read-Only)*:
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
  - `Initial_ACV_USD__c` (Number, 16,2) - Initial_ACV__c converted to USD (if field exists)
  - `Initial_ARR_USD__c` (Number, 16,2) - Initial_ARR__c converted to USD (if field exists)
  - `Initial_MRR_USD__c` (Number, 16,2) - Initial_MRR__c converted to USD (if field exists)
  - `Initial_TCV_USD__c` (Number, 16,2) - Initial_TCV__c converted to USD (if field exists)

**Account Object:**
- **USD Conversion Fields** *(Formula/Read-Only)*:
  - `ACV_USD__c` (Number, 16,2) - ACV__c converted to USD
  - `ARR_USD__c` (Number, 16,2) - ARR__c converted to USD
  - `Incremental_ARR_USD__c` (Number, 16,2) - Incremental_ARR__c converted to USD
  - `MRR_USD__c` (Number, 16,2) - MRR__c converted to USD
  - `Previous_Year_ACV_USD__c` (Number, 16,2) - Previous_Year_ACV__c converted to USD
  - `Previous_Year_ARR_USD__c` (Number, 16,2) - Previous_Year_ARR__c converted to USD
  - `Previous_Year_MRR_USD__c` (Number, 16,2) - Previous_Year_MRR__c converted to USD
  - `Previous_Year_TCV_USD__c` (Number, 16,2) - Previous_Year_TCV__c converted to USD
  - `TCV_USD__c` (Number, 16,2) - TCV__c converted to USD
  - `AnnualRevenue_USD__c` (Number, 16,2) - AnnualRevenue converted to USD

#### Formula Field Pattern for USD Conversion

**Formula Logic (USD Only with Currency Formatting):**
```apex
IF(ISBLANK(Exchange_Rate__c), 
    NULL, 
    "$" + TEXT(ROUND([Revenue_Field__c] * Exchange_Rate__c, 2))
)
```

**Total USD Conversion Fields Required:**
- OpportunityLineItem: 1 Exchange_Rate__c field (audit only)
- QuoteLineItem: 6 USD conversion fields + 1 Exchange_Rate__c field
- Quote: 5 USD conversion fields
- Asset: 8 USD conversion fields + 1 Exchange_Rate__c field
- Contract: 14 USD conversion fields
- Account: 10 USD conversion fields
- **Total: 43 USD formula fields + 4 Exchange_Rate__c fields = 47 new fields**

### Current vs Target State

#### Current ExchangeRateManager Capabilities
- Schedulable interface for daily maintenance
- Generic object support via configuration map
- DatedConversionRate integration for current rates
- Flow-invocable methods

#### Target ExchangeRateManager Enhancements
- Event-driven rate locking at business trigger points
- Multi-object inheritance logic (OLI → Asset)
- Quote-to-Opportunity sync rate stamping
- Historical rate preservation with audit trails
- Currency rollup calculations with mixed-rate support

## Core Automation Workflows

### Rate Assignment: QLI Creation

#### Business Logic
```
QuoteLineItem Creation (via existing Quote creation from Opportunity logic)
└── FOR each QuoteLineItem being created
    └── QLI.Exchange_Rate__c = getCurrentExchangeRate(QLI.CurrencyIsoCode)
```

### Rate Stamping: Quote-to-Opportunity Sync

#### Business Logic
```
Quote-to-Opportunity Sync (after Quote approval, existing CPQ process)
└── FOR each OpportunityLineItem being created/updated from approved QuoteLineItems
    └── OLI.Exchange_Rate__c = getCurrentExchangeRate(OLI.CurrencyIsoCode)
```

#### Integration with Existing CPQ Sync Process
- **Enhancement:** Add exchange rate stamping to existing OLI creation/update logic
- **ACM Compatibility:** ACM continues to function normally, stamped rate provides audit trail
- **Timing:** Rate stamped at sync execution time, not inherited from locked QLI rates

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

### Rate Inheritance: Asset Creation

#### Business Logic
```
Asset creation (Opportunity Close)
└── FOR each Asset record being created
    ├── Asset.Exchange_Rate__c = relatedOLI.Exchange_Rate__c
    └── USD fields automatically calculate via formulas using Asset.Exchange_Rate__c
```

#### Implementation Approach
- **Rate Source:** Inherit locked rate from related OpportunityLineItem
- **Business Justification:** Asset represents actual contracted commitment using opportunity close rates
- **Integration:** Coordinate with Revenue Automation (GTM-146) Asset creation workflows
- **Data Consistency:** Ensures Asset rates match final Opportunity execution rates

### Currency Rollups: Asset → Contract → Account

#### Integration with Existing Daily Batch Flow
```
Existing Daily Scheduled Batch Flow (Modified)
└── Update rollup logic to use new Asset USD fields instead of original currency fields
    ├── Contract.ARR_USD__c = SUM(Asset.ARR_USD__c for all related Assets)
    ├── Contract.MRR_USD__c = SUM(Asset.MRR_USD__c for all related Assets)
    ├── Contract.TCV_USD__c = SUM(Asset.Total_Value_USD__c for all related Assets)
    └── Account rollups from Contract USD fields via existing processes
```

#### Implementation Approach
- **Leverage Existing Infrastructure:** Modify existing daily batch flow instead of creating new triggers
- **Field Updates:** Change rollup calculations to use new USD formula fields
- **Performance:** Continue using established batch processing approach

### Field Security & Profile Management

#### Profile-Based Access Control
```
All 9 Core Profiles (Field Assignment Required for ALL new fields):
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
├── Exchange_Rate__c Fields: Read/Edit enabled for all profiles, hidden from layouts
├── USD Conversion Formula Fields: Read enabled for all profiles, visible on layouts as needed
└── Admin Access: Use inspector/CLI to edit Exchange_Rate__c fields

Total Field Assignments Required:
├── Exchange_Rate__c fields: 4 fields × 9 profiles = 36 assignments
├── USD Conversion fields: 43 fields × 9 profiles = 387 assignments  
└── Total: 423 profile field assignments
```

#### Audit Trail Management
- **Field History Tracking:** Enable on Exchange_Rate__c fields across all objects
- **Automatic Tracking:** Salesforce tracks who changed field and when
- **No Custom Fields Required:** Leverage platform auditing capabilities

## Implementation Phases

### Phase 1: Field Architecture & Profile Setup

**P1.1 - Field Creation & Formula Fields**
- **GTM-184:** Create Exchange_Rate__c fields on OLI, QuoteLineItem and Asset objects
- **GTM-184:** Create all USD conversion formula fields (43 total across Quote, QLI, Asset, Contract, Account)
- **GTM-183:** Enable field history tracking on all Exchange_Rate__c fields

**P1.2 - Profile & Security Configuration**
- **GTM-183:** Assign all new fields to 9 core profiles (423 total assignments)
- **GTM-183:** Keep Exchange_Rate__c fields hidden from all page layouts
- **GTM-183:** Configure USD conversion fields visibility on appropriate layouts
- **GTM-183:** Verify inspector/CLI access for admin editing

### Phase 2: Exchange Rate Assignment Logic

**P2.1 - QLI Rate Assignment**
- **GTM-190:** Enhance existing QLI creation logic to assign Exchange_Rate__c
- **GTM-188:** Integration testing with existing Quote creation process

**P2.2 - CPQ Sync Enhancement**
- **GTM-190:** Add OLI exchange rate stamping to existing Quote-to-Opportunity sync
- **GTM-188:** Ensure ACM compatibility with stamped exchange rates

**P2.3 - Asset Rate Inheritance**
- **GTM-189:** Build Asset trigger to inherit Exchange_Rate__c from related OLI
- **GTM-187:** Integration with Revenue Automation asset creation

### Phase 3: Rollup Integration & Formula Validation

**P3.1 - Daily Batch Flow Updates**
- **GTM-189:** Modify existing daily batch flow to use new Asset USD fields
- **GTM-185:** Update Contract rollup calculations for all USD fields
- **GTM-185:** Extend Account rollup calculations to use Contract USD fields

**P3.2 - Formula Field Validation**
- **GTM-191:** Validate all 43 USD conversion formulas calculate correctly
- **GTM-191:** Test currency formatting with "$" symbol and proper decimal places
- **GTM-185:** Test formula recalculation when Exchange_Rate__c is updated

### Phase 4: Layout Updates & User Experience

**P4.1 - Page Layout Configuration**
- **GTM-191:** Add USD conversion fields to relevant page layouts
- **GTM-191:** Configure field sections and ordering for optimal user experience
- **GTM-191:** Update related list views to include USD fields where appropriate

**P4.2 - Reporting Migration & Documentation**
- **GTM-193:** Document reporting migration from native converted fields to USD fields
- **GTM-193:** Create admin procedures for exchange rate corrections
- **GTM-192:** Develop testing procedures for USD field calculations
- **GTM-192:** User training on new USD fields for report creation

### Phase 5: Enhancements (Non-Blocking)

**P5.1 - Display & Formatting Improvements**
- **Enhancement:** Enhanced currency field formatting across objects
- **Enhancement:** Currency summary dashboards and reports
- **Enhancement:** Historical rate analysis and trending reports

## Technical Architecture Decisions

### ExchangeRateManager Class Extensions

#### Enhanced Method Requirements

```apex
public class ExchangeRateManager {
    
    // Existing methods (keep unchanged)
    public static Decimal getCurrentExchangeRate(String currencyCode) { ... }
    public static void updateExchangeRatesForAllConfiguredObjects() { ... }
    
    // New methods for enhanced functionality
    public static void assignQLIRates(List<QuoteLineItem> qlis);
    public static void stampOLIRates(List<OpportunityLineItem> olis);
    public static void inheritAssetRates(List<Asset> assets, Map<Id, OpportunityLineItem> oliMap);
    
    // Currency conversion utilities (for formula field reference if needed)
    public static Decimal convertToUSD(Decimal amount, Decimal exchangeRate);
}
```

#### Enhanced Configuration Management

**Object-Specific Configuration:**
```apex
private static final Map<String, String> EXCHANGE_RATE_FIELDS = new Map<String, String>{
    'OpportunityLineItem' => 'Exchange_Rate__c',
    'Quote' => 'Exchange_Rate__c',
    'QuoteLineItem' => 'Exchange_Rate__c', 
    'Asset' => 'Exchange_Rate__c'
};
```

### Trigger Strategy & Architecture

#### OLI Enhancement (New Audit Functionality)
- **Integration:** Add exchange rate stamping for audit purposes during CPQ sync
- **Trigger Point:** Enhance existing Quote-to-Opportunity sync logic
- **Performance:** Single additional assignment, minimal performance impact

#### QLI Enhancement (Existing Logic Extension)
- **Integration:** Add exchange rate assignment to existing QLI creation process
- **Trigger Point:** Enhance existing Quote-from-Opportunity creation logic
- **Performance:** Single additional assignment, minimal performance impact

#### Asset Trigger (Modified)
- **Events:** before insert (rate inheritance from OLI)
- **Logic:** Inherit exchange rate from related OpportunityLineItem
- **Performance:** Single query to retrieve related OLI exchange rates

#### No Quote Trigger Required
- **Rationale:** Exchange rates protected by field-level security
- **Audit:** Field history tracking provides complete audit trail

### Governor Limit Management

#### Bulk Processing Strategy
- **SOQL Limits:** Cache exchange rates and OLI lookups within transaction context
- **DML Limits:** Batch updates for Contract rollups using existing daily flow
- **CPU Time:** Optimize calculation loops, use Map-based lookups for OLI inheritance

#### Asynchronous Processing Options
- **Queueable Apex:** For large Contract rollup calculations
- **Batch Apex:** For historical data migration and maintenance
- **Platform Events:** For real-time cross-object notifications

## Integration Specifications

### CPQ System Coordination

#### Quote Creation from Opportunity
- **Current Process:** Copies OLI data to QLI
- **Enhancement:** Add exchange rate assignment logic using current rates
- **Validation:** Ensure rate assignment occurs for all QLIs

#### Quote-to-Opportunity Sync
- **Rate Stamping:** Add current exchange rate to OLIs during sync
- **ACM Preservation:** ACM continues to manage rate history, stamped rate for audit
- **Business Rule:** Opportunity rates can continue changing via ACM after sync
- **Data Integrity:** Quote reflects point-in-time approval rates

### Revenue Automation Integration (GTM-146)

#### Asset Creation Coordination
- **Trigger Order:** Exchange rate inheritance before Revenue Automation processing
- **Data Flow:** OLI → Asset with exchange rate inheritance
- **Contract Rollups:** Coordinate with Contract creation workflows using USD fields

### Approval System Integration

#### Flow-Based Approval Enhancement
- **Status Detection:** Monitor Quote status changes to "Needs Review"
- **Field Protection:** Exchange rate locking via field-level security
- **Validation Rules:** Prevent changes to locked exchange rates after approval

## Data Migration & Deployment

### Historical Data Processing

#### Backfill Strategy for Exchange_Rate__c Fields
1. **Existing Assets:** Batch process to assign Exchange_Rate__c based on creation date lookup
2. **Existing QLIs:** Assign current exchange rate or attempt historical rate lookup
3. **Existing OLIs:** Assign current exchange rate for audit trail initialization
4. **Formula Field Population:** USD fields automatically populate once Exchange_Rate__c is assigned

#### Profile & Layout Deployment
1. **Field Assignments:** Deploy all new fields to 9 core profiles (423 assignments)
2. **Layout Updates:** Add USD fields to appropriate page layouts
3. **Field History:** Enable field history tracking on Exchange_Rate__c fields
4. **Permission Testing:** Verify field access across all profile types

### Reporting Migration Strategy

#### SFDC Report Updates Required
- **Challenge:** Native converted fields no longer work with ACM enabled
- **Solution:** Update existing reports to use new USD formula fields
- **Impact:** All revenue reports using converted amounts need modification
- **Timeline:** Coordinate with user training and documentation

#### Report Migration Process
1. **Inventory:** Catalog all reports using native converted fields
2. **Update:** Replace converted field references with new USD fields
3. **Testing:** Validate calculations match expected results
4. **Training:** User education on new field usage

## Risk Mitigation & Success Factors

### Critical Dependencies
- **ACM Preservation:** Maintain existing Opportunity functionality
- **CPQ Integration:** Seamless operation with existing Quote system
- **Performance Impact:** Minimize trigger execution time for bulk operations
- **Data Integrity:** Accurate currency conversions across all scenarios
- **Reporting Continuity:** Smooth migration from converted fields to USD fields

### Success Criteria
- **Critical (Blocking):** Rate consistency - Locked rates maintain values regardless of market fluctuations  
- **Critical (Blocking):** Business process integration - Seamless operation with existing approval workflows
- **Critical (Blocking):** Reporting accuracy - USD amounts calculated consistently across all objects with proper formatting
- **Critical (Blocking):** System performance - No degradation in Quote or Asset creation times
- **Critical (Blocking):** User experience - Transparent rate locking with clear status indicators
- **Critical (Blocking):** Profile deployment - All 423 field assignments completed successfully
- **Enhancement (Non-Blocking):** Advanced reporting features and currency analysis tools

### Testing Strategy

#### Unit Testing Requirements
- **Rate Assignment:** OLI audit stamping, QLI rate assignment, Asset rate inheritance from OLI
- **Formula Fields:** USD conversion calculations across all 43 formula fields
- **Currency Formatting:** Proper "$" symbol and decimal formatting in formula fields
- **Daily Batch Flow:** Modified rollup calculations using new Asset USD fields
- **Field History:** Exchange rate change tracking and audit capabilities
- **Profile Security:** Field access verification across all 9 profiles (423 total assignments)

#### Integration Testing Scenarios
- **CPQ Workflows:** End-to-end Quote creation with QLI exchange rate assignment
- **Quote-to-Opportunity Sync:** OLI exchange rate stamping during CPQ sync process
- **Revenue Automation:** Asset creation with exchange rate inheritance from OLI
- **Daily Rollups:** Contract USD field updates using existing batch flow (GTM-216)
- **Account Rollups:** Account USD field calculations from Contract data
- **Admin Corrections:** Exchange rate override using inspector/CLI access
- **Formula Recalculation:** USD field updates when Exchange_Rate__c changes across all objects
- **Reporting Migration:** Validation that new USD fields work correctly in SFDC reports
- **Page Layout Testing:** Verify USD field visibility and user experience (GTM-217)

#### Performance Testing
- **Bulk Operations:** Test QLI creation, Asset creation, and daily rollups with large data volumes
- **Formula Field Impact:** Validate formula field calculations don't exceed governor limits
- **Reporting Performance:** Ensure USD formula fields perform adequately in complex reports

## Outstanding Technical Decisions

### Decision Points Requiring Resolution

#### Data Migration Execution
1. **Backfill Timing:** Execute historical Exchange_Rate__c assignment before or after formula field deployment?
2. **Historical Rate Sources:** Use creation date-based lookup or assign current rates for historical records?
3. **Migration Rollback:** Strategy for reverting changes if deployment issues occur?

#### Reporting Transition
1. **Dual Field Period:** Maintain both converted fields and USD fields during transition period?
2. **User Communication:** Timeline and method for notifying users of field changes?
3. **Report Inventory:** Automated or manual process for identifying reports needing updates?

### Implementation Sequence
1. **Phase 1:** Field creation and profile assignments
2. **Phase 2:** Data migration and backfill processes
3. **Phase 3:** Trigger and automation logic implementation
4. **Phase 4:** User interface and reporting updates
5. **Phase 5:** Testing and validation across all scenarios

---

**Document Version:** 2.0  
**Last Updated:** September 9, 2025  
**Next Review:** Data migration strategy finalization and deployment timeline confirmation