# GTM-138 Field Definitions

**Document Version:** 1.0  
**Last Updated:** August 26, 2025

## Field Architecture Overview

This document provides detailed specifications for all 33 fields being created/modified in the GTM-138 Exchange Rate Manager project.

## Exchange Rate Fields (4 fields)

### Universal Exchange Rate Field Pattern
- **API Name:** `Exchange_Rate__c`
- **Type:** Number(18, 6)
- **Label:** Exchange Rate
- **Description:** Exchange rate for USD conversion locked at business trigger points
- **Required:** Yes
- **Default Value:** Current exchange rate at creation
- **Field-Level Security:** Read/Edit for all 9 profiles
- **Page Layout Visibility:** Hidden from all layouts
- **Field History Tracking:** Enabled
- **Help Text:** "Exchange rate locked at record creation/approval for consistent USD conversions"

#### Objects with Exchange Rate Fields
1. **Quote** (Enhanced existing field)
2. **QuoteLineItem** (New field)
3. **Asset** (New field)
4. **Contract** (Uses Asset rates for rollups)

## USD Conversion Fields by Object

### QuoteLineItem USD Fields (6 fields)

#### Annual_Amount_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Annual_Amount__c * Exchange_Rate__c`
- **Label:** Annual Amount (USD)
- **Description:** Annual amount converted to USD using locked exchange rate

#### List_Price_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `List_Price__c * Exchange_Rate__c`
- **Label:** List Price (USD)
- **Description:** List price converted to USD using locked exchange rate

#### ListPrice_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `ListPrice * Exchange_Rate__c`
- **Label:** List Price Standard (USD)
- **Description:** Standard list price converted to USD using locked exchange rate

#### Total_Price_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Total_Price__c * Exchange_Rate__c`
- **Label:** Total Price Custom (USD)
- **Description:** Custom total price converted to USD using locked exchange rate

#### TotalPrice_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `TotalPrice * Exchange_Rate__c`
- **Label:** Total Price Standard (USD)
- **Description:** Standard total price converted to USD using locked exchange rate

#### UnitPrice_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `UnitPrice * Exchange_Rate__c`
- **Label:** Unit Price (USD)
- **Description:** Unit price converted to USD using locked exchange rate

### Asset USD Fields (8 fields)

#### ARR_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `ARR__c * Exchange_Rate__c`
- **Label:** ARR (USD)
- **Description:** Annual Recurring Revenue converted to USD using locked exchange rate

#### MRR_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `MRR__c * Exchange_Rate__c`
- **Label:** MRR (USD)
- **Description:** Monthly Recurring Revenue converted to USD using locked exchange rate

#### Price_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Price * Exchange_Rate__c`
- **Label:** Price (USD)
- **Description:** Asset price converted to USD using locked exchange rate

#### Total_Price_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Total_Price__c * Exchange_Rate__c`
- **Label:** Total Price (USD)
- **Description:** Total asset price converted to USD using locked exchange rate

#### Total_Value_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Total_Value__c * Exchange_Rate__c`
- **Label:** Total Value (USD)
- **Description:** Total asset value converted to USD using locked exchange rate

#### Unit_ARR_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Unit_ARR__c * Exchange_Rate__c`
- **Label:** Unit ARR (USD)
- **Description:** Unit Annual Recurring Revenue converted to USD using locked exchange rate

#### Unit_MRR_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Unit_MRR__c * Exchange_Rate__c`
- **Label:** Unit MRR (USD)
- **Description:** Unit Monthly Recurring Revenue converted to USD using locked exchange rate

#### Unit_Value_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Unit_Value__c * Exchange_Rate__c`
- **Label:** Unit Value (USD)
- **Description:** Unit value converted to USD using locked exchange rate

### Quote USD Fields (5 fields)

#### Annual_Total_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Annual_Total__c * Exchange_Rate__c`
- **Label:** Annual Total (USD)
- **Description:** Annual total converted to USD using locked exchange rate

#### First_Payment_Due_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `First_Payment_Due__c * Exchange_Rate__c`
- **Label:** First Payment Due (USD)
- **Description:** First payment due converted to USD using locked exchange rate

#### One_Off_Charges_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `One_Off_Charges__c * Exchange_Rate__c`
- **Label:** One-Off Charges (USD)
- **Description:** One-off charges converted to USD using locked exchange rate

#### Total_Payment_Due_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Total_Payment_Due__c * Exchange_Rate__c`
- **Label:** Total Payment Due (USD)
- **Description:** Total payment due converted to USD using locked exchange rate

#### TotalPrice_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `TotalPrice * Exchange_Rate__c`
- **Label:** Total Price (USD)
- **Description:** Quote total price converted to USD using locked exchange rate

### Contract USD Fields (11 fields)

#### Multi_Currency_Summary__c
- **Type:** Formula (Long Text Area)
- **Formula:** `"Currencies: " + TEXT(COUNT(Assets__r.CurrencyIsoCode)) + " (" + Assets__r.CurrencyIsoCode + ")"`
- **Label:** Multi-Currency Summary
- **Description:** Summary of currencies represented in related Assets

#### Active_ARR_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Active_ARR__c * VLOOKUP($Setup.DatedConversionRate__c.ConversionRate, $Setup.DatedConversionRate__c.IsoCode, "USD")`
- **Label:** Active ARR (USD)
- **Description:** Active ARR converted to USD using current corporate rate

#### ACV_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `ACV__c * VLOOKUP($Setup.DatedConversionRate__c.ConversionRate, $Setup.DatedConversionRate__c.IsoCode, "USD")`
- **Label:** ACV (USD)
- **Description:** Annual Contract Value converted to USD using current corporate rate

#### ARR_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `ARR__c * VLOOKUP($Setup.DatedConversionRate__c.ConversionRate, $Setup.DatedConversionRate__c.IsoCode, "USD")`
- **Label:** ARR (USD)
- **Description:** Annual Recurring Revenue converted to USD using current corporate rate

#### Incremental_ARR_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Incremental_ARR__c * VLOOKUP($Setup.DatedConversionRate__c.ConversionRate, $Setup.DatedConversionRate__c.IsoCode, "USD")`
- **Label:** Incremental ARR (USD)
- **Description:** Incremental ARR converted to USD using current corporate rate

#### MRR_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `MRR__c * VLOOKUP($Setup.DatedConversionRate__c.ConversionRate, $Setup.DatedConversionRate__c.IsoCode, "USD")`
- **Label:** MRR (USD)
- **Description:** Monthly Recurring Revenue converted to USD using current corporate rate

#### Previous_ACV_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Previous_ACV__c * VLOOKUP($Setup.DatedConversionRate__c.ConversionRate, $Setup.DatedConversionRate__c.IsoCode, "USD")`
- **Label:** Previous ACV (USD)
- **Description:** Previous ACV converted to USD using current corporate rate

#### Previous_ARR_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Previous_ARR__c * VLOOKUP($Setup.DatedConversionRate__c.ConversionRate, $Setup.DatedConversionRate__c.IsoCode, "USD")`
- **Label:** Previous ARR (USD)
- **Description:** Previous ARR converted to USD using current corporate rate

#### Previous_MRR_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Previous_MRR__c * VLOOKUP($Setup.DatedConversionRate__c.ConversionRate, $Setup.DatedConversionRate__c.IsoCode, "USD")`
- **Label:** Previous MRR (USD)
- **Description:** Previous MRR converted to USD using current corporate rate

#### Previous_TCV_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `Previous_TCV__c * VLOOKUP($Setup.DatedConversionRate__c.ConversionRate, $Setup.DatedConversionRate__c.IsoCode, "USD")`
- **Label:** Previous TCV (USD)
- **Description:** Previous TCV converted to USD using current corporate rate

#### TCV_USD__c
- **Type:** Formula (Number, 16, 2)
- **Formula:** `TCV__c * VLOOKUP($Setup.DatedConversionRate__c.ConversionRate, $Setup.DatedConversionRate__c.IsoCode, "USD")`
- **Label:** TCV (USD)
- **Description:** Total Contract Value converted to USD using current corporate rate

## Profile Security Configuration

### Required Profile Assignments
All Exchange_Rate__c fields must be assigned to these 9 profiles:

1. **Custom SysAdmin**
2. **Minimum Access - Salesforce**
3. **Seqera Customer Service**
4. **Seqera Executive**
5. **Seqera Marketing**
6. **Seqera Sales**
7. **Seqera SDR**
8. **System Administrator**
9. **System Administrator (Service Account)**

### Field-Level Security Settings
- **Read Access:** Enabled for all 9 profiles
- **Edit Access:** Enabled for all 9 profiles
- **Page Layout Visibility:** Hidden from all page layouts
- **Field History Tracking:** Enabled for Exchange_Rate__c fields

## Deployment Considerations

### Field Dependencies
1. **Exchange_Rate__c fields must be deployed first**
2. **USD formula fields depend on Exchange_Rate__c fields**
3. **Profile assignments must be included in deployment**
4. **Field history tracking settings included in metadata**

### Performance Impact
- **Formula Fields:** Minimal performance impact for read operations
- **Bulk Operations:** Consider batch processing for large data volumes
- **Reporting:** USD fields improve reporting performance vs. real-time conversion

### Validation Rules
- **Exchange Rate Required:** Ensure Exchange_Rate__c is populated on all relevant records
- **Positive Exchange Rates:** Validate Exchange_Rate__c > 0
- **Historical Consistency:** Prevent unauthorized changes to locked exchange rates

---
**Next Review:** Field deployment validation  
**Related Documents:** technical-architecture.md, deployment-guide.md
