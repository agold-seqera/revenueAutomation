# GTM-138 Deployment Guide

**Document Version:** 1.0  
**Last Updated:** August 26, 2025  
**Deployment Strategy:** Phased deployment with comprehensive testing

## Deployment Overview

This guide provides step-by-step instructions for deploying the GTM-138 Exchange Rate Manager components across 5 implementation phases.

## Pre-Deployment Checklist

### Environment Preparation
- [ ] **Org Access:** Verify deployment permissions in target org
- [ ] **SFDX Setup:** Confirm SFDX CLI authentication and project configuration
- [ ] **Backup:** Create org backup before deployment
- [ ] **Dependencies:** Verify existing ExchangeRateManager class is present
- [ ] **ACM Status:** Confirm Advanced Currency Management is enabled

### Metadata Retrieval
```bash
# Pull latest metadata from org
sf org login web -a <target-org-alias>
sf project retrieve start --metadata Profile,PermissionSet,CustomObject,CustomField
```

## Phase 1 Deployment: Field Architecture & Profile Setup

**Timeline:** Weeks 1-2  
**Jira Tickets:** GTM-184, GTM-183

### Step 1.1: Create Exchange Rate Fields (GTM-184)

#### QuoteLineItem Exchange Rate Field
```bash
# Deploy QuoteLineItem Exchange_Rate__c field
sf project deploy start --metadata CustomField:QuoteLineItem.Exchange_Rate__c
```

**Field Specification:**
- API Name: `Exchange_Rate__c`
- Type: Number(18, 6)
- Label: Exchange Rate
- Required: Yes
- Default Value: 1.000000

#### Asset Exchange Rate Field
```bash
# Deploy Asset Exchange_Rate__c field
sf project deploy start --metadata CustomField:Asset.Exchange_Rate__c
```

**Field Specification:**
- API Name: `Exchange_Rate__c`
- Type: Number(18, 6)
- Label: Exchange Rate
- Required: Yes
- Default Value: 1.000000

### Step 1.2: Create USD Formula Fields (GTM-184)

#### Deploy QuoteLineItem USD Fields (6 fields)
```bash
sf project deploy start --metadata CustomField:QuoteLineItem.Annual_Amount_USD__c,CustomField:QuoteLineItem.List_Price_USD__c,CustomField:QuoteLineItem.ListPrice_USD__c,CustomField:QuoteLineItem.Total_Price_USD__c,CustomField:QuoteLineItem.TotalPrice_USD__c,CustomField:QuoteLineItem.UnitPrice_USD__c
```

#### Deploy Asset USD Fields (8 fields)
```bash
sf project deploy start --metadata CustomField:Asset.ARR_USD__c,CustomField:Asset.MRR_USD__c,CustomField:Asset.Price_USD__c,CustomField:Asset.Total_Price_USD__c,CustomField:Asset.Total_Value_USD__c,CustomField:Asset.Unit_ARR_USD__c,CustomField:Asset.Unit_MRR_USD__c,CustomField:Asset.Unit_Value_USD__c
```

#### Deploy Quote USD Fields (5 fields)
```bash
sf project deploy start --metadata CustomField:Quote.Annual_Total_USD__c,CustomField:Quote.First_Payment_Due_USD__c,CustomField:Quote.One_Off_Charges_USD__c,CustomField:Quote.Total_Payment_Due_USD__c,CustomField:Quote.TotalPrice_USD__c
```

#### Deploy Contract USD Fields (11 fields)
```bash
sf project deploy start --metadata CustomField:Contract.Multi_Currency_Summary__c,CustomField:Contract.Active_ARR_USD__c,CustomField:Contract.ACV_USD__c,CustomField:Contract.ARR_USD__c,CustomField:Contract.Incremental_ARR_USD__c,CustomField:Contract.MRR_USD__c,CustomField:Contract.Previous_ACV_USD__c,CustomField:Contract.Previous_ARR_USD__c,CustomField:Contract.Previous_MRR_USD__c,CustomField:Contract.Previous_TCV_USD__c,CustomField:Contract.TCV_USD__c
```

### Step 1.3: Configure Profile Permissions (GTM-183)

#### Update All 9 Profiles
```bash
# Deploy profile updates for Exchange_Rate__c field permissions
sf project deploy start --metadata Profile:CustomSysAdmin,Profile:MinimumAccess-Salesforce,Profile:SeqeraCustomerService,Profile:SeqeraExecutive,Profile:SeqeraMarketing,Profile:SeqeraSales,Profile:SeqeraSDR,Profile:SystemAdministrator,Profile:SystemAdministratorServiceAccount
```

#### Field-Level Security Configuration
- **Read Permission:** Enabled for all 9 profiles
- **Edit Permission:** Enabled for all 9 profiles
- **Page Layout Visibility:** Hidden from all layouts (admin access via inspector/CLI)

### Step 1.4: Enable Field History Tracking (GTM-183)
```bash
# Enable field history tracking on Exchange_Rate__c fields
sf project deploy start --metadata CustomObject:Quote,CustomObject:QuoteLineItem,CustomObject:Asset
```

## Phase 2 Deployment: Exchange Rate Assignment Logic

**Timeline:** Weeks 3-4  
**Jira Tickets:** GTM-190, GTM-188, GTM-189, GTM-187

### Step 2.1: Enhanced ExchangeRateManager Class (GTM-190)
```bash
# Deploy enhanced ExchangeRateManager with new methods
sf project deploy start --source-dir force-app/main/default/classes/ExchangeRateManager*
```

**New Methods Added:**
- `assignQLIRates(List<QuoteLineItem> qlis)`
- `assignAssetRates(List<Asset> assets)`
- `convertToUSD(Decimal amount, Decimal exchangeRate)`

### Step 2.2: QuoteLineItem Enhancement (GTM-188)
```bash
# Deploy QLI creation logic enhancement
sf project deploy start --source-dir force-app/main/default/classes/*QuoteLineItem*
```

**Integration Points:**
- Existing Quote creation from Opportunity workflow
- Exchange rate assignment at QLI creation
- Rate inheritance from current exchange rates

### Step 2.3: Asset Trigger Implementation (GTM-189, GTM-187)
```bash
# Deploy Asset trigger and handler
sf project deploy start --source-dir force-app/main/default/triggers/AssetTrigger.trigger
sf project deploy start --source-dir force-app/main/default/classes/AssetTriggerHandler.cls
```

**Trigger Logic:**
- Before insert: Assign Exchange_Rate__c using current rates
- Integration with Revenue Automation (GTM-146)
- Bulk operation support

## Phase 3 Deployment: Rollup Integration & Formula Validation

**Timeline:** Weeks 5-6  
**Jira Tickets:** GTM-189, GTM-185, GTM-191

### Step 3.1: Modified Daily Batch Flow (GTM-189, GTM-185)
```bash
# Deploy updated Contract rollup logic
sf project deploy start --source-dir force-app/main/default/classes/*Contract*Batch*
```

**Rollup Changes:**
- Contract.ARR_USD__c = SUM(Asset.ARR_USD__c)
- Contract.MRR_USD__c = SUM(Asset.MRR_USD__c)
- Contract.TCV_USD__c = SUM(Asset.Total_Value_USD__c)

### Step 3.2: Formula Validation Testing (GTM-191)
```bash
# Deploy test classes for formula validation
sf project deploy start --source-dir force-app/main/default/classes/*Test*USD*
```

**Test Coverage:**
- All 29 USD formula fields
- Exchange rate update scenarios
- Mixed currency rollup calculations

## Phase 4 Deployment: Layout Updates & User Experience

**Timeline:** Weeks 7-8  
**Jira Tickets:** GTM-191, GTM-193, GTM-192

### Step 4.1: Page Layout Updates (GTM-191)
```bash
# Deploy updated page layouts with USD fields
sf project deploy start --metadata Layout:Quote-*,Layout:QuoteLineItem-*,Layout:Asset-*,Layout:Contract-*
```

**Layout Changes:**
- Add USD conversion fields to relevant sections
- Organize fields for optimal user experience
- Update related list views to include USD fields

### Step 4.2: List View Updates
```bash
# Deploy updated list views
sf project deploy start --metadata ListView:Quote.*,ListView:Asset.*,ListView:Contract.*
```

## Phase 5 Deployment: Enhancements (Non-Blocking)

**Timeline:** Weeks 9-10  
**Enhancement Features**

### Step 5.1: Enhanced Currency Formatting
```bash
# Deploy currency formatting improvements
sf project deploy start --source-dir force-app/main/default/components/*Currency*
```

## Validation & Testing Procedures

### Post-Deployment Validation

#### Phase 1 Validation
```bash
# Verify field creation
sf data query --query "SELECT Id, Exchange_Rate__c FROM QuoteLineItem LIMIT 1" --target-org <alias>
sf data query --query "SELECT Id, Exchange_Rate__c FROM Asset LIMIT 1" --target-org <alias>
```

#### Phase 2 Validation
```bash
# Test exchange rate assignment
sf apex run --file scripts/apex/test-exchange-rate-assignment.apex --target-org <alias>
```

#### Phase 3 Validation
```bash
# Validate formula calculations
sf data query --query "SELECT Id, ARR__c, ARR_USD__c, Exchange_Rate__c FROM Asset WHERE ARR__c != null LIMIT 5" --target-org <alias>
```

### Test Data Creation
```bash
# Create test records for validation
sf data import tree --plan data/test-data-plan.json --target-org <alias>
```

## Rollback Procedures

### Field Rollback (Emergency Only)
```bash
# Remove custom fields (destructive - use with caution)
sf project deploy start --metadata CustomField --destructive-changes destructiveChanges.xml
```

### Logic Rollback
```bash
# Revert to previous class versions
sf project deploy start --source-dir backup/classes/
```

## Performance Monitoring

### Key Metrics to Monitor
- Quote creation time with QLI exchange rate assignment
- Asset creation performance with trigger execution
- Daily batch flow execution time for Contract rollups
- Formula field calculation performance in reports

### Monitoring Commands
```bash
# Check recent deployments
sf project deploy report --target-org <alias>

# Monitor debug logs
sf apex log tail --target-org <alias>
```

## Troubleshooting Guide

### Common Issues

#### Formula Field Errors
- **Issue:** Formula compilation errors
- **Solution:** Verify field API names and data types
- **Command:** `sf project deploy validate --source-dir force-app/main/default/objects/`

#### Profile Permission Issues
- **Issue:** Users cannot see Exchange_Rate__c fields
- **Solution:** Verify profile field-level security settings
- **Command:** `sf org display user --target-org <alias>`

#### Trigger Execution Errors
- **Issue:** Asset trigger failing on bulk operations
- **Solution:** Review governor limits and bulk processing logic
- **Command:** `sf apex log get --number 10 --target-org <alias>`

## Success Criteria

### Phase Completion Checklist
- [ ] **Phase 1:** All 33 fields created and accessible via profiles
- [ ] **Phase 2:** Exchange rate assignment working for QLI and Asset creation
- [ ] **Phase 3:** Formula fields calculating correctly, rollups functional
- [ ] **Phase 4:** User acceptance testing passed
- [ ] **Phase 5:** Enhancement features deployed and tested

### Performance Benchmarks
- Quote creation: < 3 seconds with QLI rate assignment
- Asset creation: < 2 seconds with exchange rate locking
- Contract rollups: Complete within daily batch window
- Formula recalculation: < 1 second for standard record views

---
**Deployment Contact:** Technical Lead  
**Emergency Rollback:** Available 24/7 during deployment phases  
**Next Review:** Post-deployment performance analysis
