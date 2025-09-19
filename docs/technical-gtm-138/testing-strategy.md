# GTM-138 Testing Strategy

**Document Version:** 1.0  
**Last Updated:** August 26, 2025  
**Testing Approach:** Comprehensive multi-phase validation

## Testing Overview

This document outlines the testing strategy for the GTM-138 Exchange Rate Manager project, covering unit testing, integration testing, and user acceptance testing across all 5 implementation phases.

## Testing Principles

### Core Testing Requirements
- **Test Coverage:** Minimum 85% code coverage for all custom Apex classes
- **Test Data:** Use TestFactoryData for all test classes (per project guidelines)
- **Bulk Testing:** Validate bulk operations up to 200 records per transaction
- **Performance:** Ensure no degradation in existing functionality
- **Cross-Currency:** Test multiple currency scenarios (USD, EUR, GBP, JPY)

### Testing Environments
- **Development:** Initial unit testing and validation
- **QA Sandbox:** Integration testing and performance validation
- **UAT Sandbox:** User acceptance testing with business stakeholders
- **Production:** Phased rollout with monitoring

## Phase-by-Phase Testing Strategy

## Phase 1 Testing: Field Architecture & Profile Setup

**Jira Tickets:** GTM-184, GTM-183

### Unit Tests Required

#### Field Creation Tests
```apex
@isTest
public class ExchangeRateFieldTest {
    @TestSetup
    static void setupTestData() {
        // Use TestFactoryData for test record creation
    }
    
    @isTest
    static void testQuoteLineItemExchangeRateField() {
        // Verify Exchange_Rate__c field exists and is accessible
    }
    
    @isTest
    static void testAssetExchangeRateField() {
        // Verify Exchange_Rate__c field exists and is accessible
    }
    
    @isTest
    static void testUSDFormulaFieldCalculations() {
        // Test all 29 USD formula fields calculate correctly
    }
}
```

#### Profile Security Tests
```apex
@isTest
public class ExchangeRateSecurityTest {
    @isTest
    static void testProfileFieldAccess() {
        // Verify all 9 profiles can read/edit Exchange_Rate__c fields
    }
    
    @isTest
    static void testFieldHistoryTracking() {
        // Verify field history is captured for Exchange_Rate__c changes
    }
}
```

### Integration Tests
- **SFDX Deployment:** Validate metadata deployment across all environments
- **Formula Compilation:** Ensure all USD formula fields compile without errors
- **Profile Assignment:** Verify field permissions assigned to all 9 profiles
- **Field History:** Confirm field history tracking is enabled and functional

### Test Data Scenarios
1. **Single Currency Records:** USD only for baseline validation
2. **Multi-Currency Records:** EUR, GBP, JPY with various exchange rates
3. **Null Handling:** Test formula field behavior with null Exchange_Rate__c
4. **Extreme Values:** Test with very large and very small exchange rates

## Phase 2 Testing: Exchange Rate Assignment Logic

**Jira Tickets:** GTM-190, GTM-188, GTM-189, GTM-187

### Unit Tests Required

#### ExchangeRateManager Enhancement Tests
```apex
@isTest
public class ExchangeRateManagerTest {
    @isTest
    static void testAssignQLIRates() {
        // Test QuoteLineItem exchange rate assignment
    }
    
    @isTest
    static void testAssignAssetRates() {
        // Test Asset exchange rate assignment
    }
    
    @isTest
    static void testBulkRateAssignment() {
        // Test bulk operations (200 records)
    }
    
    @isTest
    static void testCurrencyConversion() {
        // Test convertToUSD utility method
    }
}
```

#### Asset Trigger Tests
```apex
@isTest
public class AssetTriggerTest {
    @isTest
    static void testAssetExchangeRateAssignment() {
        // Verify exchange rate assigned on Asset creation
    }
    
    @isTest
    static void testBulkAssetCreation() {
        // Test bulk Asset creation with exchange rates
    }
    
    @isTest
    static void testRevenueAutomationIntegration() {
        // Verify integration with GTM-146 workflows
    }
}
```

### Integration Tests
- **CPQ Integration:** End-to-end Quote creation with QLI rate assignment
- **Revenue Automation:** Asset creation coordination with GTM-146
- **Performance Testing:** Bulk operations under governor limits
- **Error Handling:** Graceful failure scenarios and error messages

### Test Scenarios
1. **Quote Creation from Opportunity:** Verify QLI inherits current exchange rates
2. **Asset Creation Workflows:** Multiple currencies in single transaction
3. **Error Conditions:** Missing currency codes, invalid exchange rates
4. **Bulk Operations:** 200 Assets with mixed currencies

## Phase 3 Testing: Rollup Integration & Formula Validation

**Jira Tickets:** GTM-189, GTM-185, GTM-191

### Unit Tests Required

#### Contract Rollup Tests
```apex
@isTest
public class ContractRollupTest {
    @isTest
    static void testUSDRollupCalculations() {
        // Test Contract USD field rollups from Assets
    }
    
    @isTest
    static void testMixedCurrencyRollups() {
        // Test rollups with Assets in different currencies
    }
    
    @isTest
    static void testDailyBatchFlowIntegration() {
        // Test modified daily batch flow execution
    }
}
```

#### Formula Field Validation Tests
```apex
@isTest
public class FormulaFieldValidationTest {
    @isTest
    static void testAllUSDFormulaFields() {
        // Comprehensive test of all 29 USD formula fields
    }
    
    @isTest
    static void testExchangeRateUpdates() {
        // Test formula recalculation when Exchange_Rate__c changes
    }
    
    @isTest
    static void testPerformanceWithLargeDatasets() {
        // Performance testing with large record volumes
    }
}
```

### Integration Tests
- **Daily Batch Flow:** Modified rollup calculations using new Asset USD fields
- **Formula Recalculation:** Real-time updates when exchange rates change
- **Mixed Currency Scenarios:** Assets with different currencies rolling up to Contract
- **Performance Benchmarks:** Large dataset performance validation

### Test Scenarios
1. **Contract with 100+ Assets:** Mixed currencies rollup performance
2. **Exchange Rate Changes:** Formula field recalculation accuracy
3. **Daily Batch Execution:** Complete rollup calculation validation
4. **Historical Data:** Formula behavior with existing records

## Phase 4 Testing: Layout Updates & User Experience

**Jira Tickets:** GTM-191, GTM-193, GTM-192

### UI/UX Testing

#### Page Layout Tests
- **Field Visibility:** USD fields visible on appropriate page layouts
- **Field Ordering:** Logical grouping and section organization
- **Related Lists:** USD fields included in relevant views
- **Mobile Responsiveness:** Field display on mobile devices

#### User Acceptance Testing
```
User Story: Sales Rep creating Quote from Opportunity
Given: Opportunity with EUR currency and current exchange rate 1.08
When: Sales rep creates Quote from Opportunity
Then: All QLI USD fields should display converted amounts using rate 1.08
And: Exchange rates should be locked and not change after Quote approval
```

### Test Scenarios
1. **Quote Creation Workflow:** End-to-end user experience
2. **Asset Review Process:** Contract rollup visibility for Account Managers
3. **Admin Rate Corrections:** Inspector/CLI access for exchange rate overrides
4. **Reporting Experience:** USD field usage in reports and dashboards

## Phase 5 Testing: Enhancements (Non-Blocking)

### Enhancement Validation
- **Currency Formatting:** Proper $ symbols and number formatting
- **Dashboard Performance:** Executive reporting with USD conversions
- **Mobile Experience:** Enhanced mobile layout and field access

## Performance Testing Requirements

### Load Testing Benchmarks
- **Quote Creation:** < 3 seconds with QLI exchange rate assignment
- **Asset Creation:** < 2 seconds with exchange rate locking (single record)
- **Bulk Asset Creation:** < 30 seconds for 200 Assets with exchange rates
- **Contract Rollups:** Complete within existing daily batch window
- **Formula Calculations:** < 1 second for record detail page load

### Governor Limit Testing
- **SOQL Queries:** Efficient exchange rate caching within transaction
- **DML Operations:** Bulk update optimization for Contract rollups
- **CPU Time:** Formula field calculation efficiency
- **Heap Size:** Memory usage optimization for large datasets

## User Acceptance Testing Plan

### Business Stakeholder Testing

#### Sales Team Testing
- **Quote Creation:** Existing workflow with USD conversion visibility
- **Rate Locking:** Understanding of locked rates during approval process
- **Multi-Currency Deals:** Complex scenarios with multiple currencies

#### Finance Team Testing
- **Reporting Accuracy:** USD conversion consistency across objects
- **Historical Data:** Accurate historical reporting with locked rates
- **Admin Overrides:** Exchange rate correction procedures

#### Executive Team Testing
- **Dashboard Views:** High-level USD reporting and rollups
- **Performance Impact:** No degradation in system responsiveness
- **Data Integrity:** Confidence in USD conversion accuracy

### UAT Success Criteria
- [ ] **Sales Process:** No disruption to existing Quote creation workflows
- [ ] **Reporting Accuracy:** USD amounts match manual calculations
- [ ] **Performance:** System responsiveness maintained
- [ ] **Training:** Users comfortable with new USD fields and processes
- [ ] **Admin Procedures:** Exchange rate correction processes validated

## Automated Testing Infrastructure

### Continuous Integration
```yaml
# .sfdx/ci/test-pipeline.yml
stages:
  - unit-tests
  - integration-tests
  - deployment-validation
  - performance-tests

unit-tests:
  script:
    - sf apex run test --test-level RunLocalTests --wait 10
    - sf apex get test --result-format junit --output-dir test-results

integration-tests:
  script:
    - sf apex run test --test-level RunAllTestsInOrg --wait 20
    - sf data query --query "SELECT COUNT() FROM Asset WHERE Exchange_Rate__c = null"
```

### Test Data Management
- **TestFactoryData Usage:** All test classes use centralized test data factory
- **Currency Scenarios:** Pre-defined test data for multiple currency combinations
- **Performance Data:** Large dataset generation for performance validation
- **Clean-up Procedures:** Automated test data cleanup after test execution

## Risk Mitigation Testing

### Critical Risk Scenarios
1. **ACM Impact:** Verify no impact on existing Opportunity ACM functionality
2. **CPQ Integration:** Ensure seamless operation with existing Quote systems
3. **Performance Degradation:** Validate no slowdown in critical business processes
4. **Data Integrity:** Accurate currency conversions in all scenarios

### Rollback Testing
- **Metadata Rollback:** Test ability to remove new fields if needed
- **Logic Rollback:** Revert to previous ExchangeRateManager version
- **Data Recovery:** Restore previous state if issues occur

## Test Documentation & Reporting

### Test Report Template
```
GTM-138 Test Execution Report
Phase: [1-5]
Test Date: [Date]
Environment: [Dev/QA/UAT/Prod]
Test Coverage: [%]
Pass Rate: [%]
Critical Issues: [Count]
Performance Metrics: [Benchmarks]
Sign-off Status: [Pending/Complete]
```

### Evidence Requirements
- **Screenshots:** UI testing evidence for page layouts
- **Performance Logs:** Execution time measurements
- **Coverage Reports:** Code coverage metrics
- **User Feedback:** UAT session notes and approvals

---
**Testing Contact:** QA Lead  
**Test Environment Access:** Available via SFDX CLI  
**Next Review:** Test plan validation with development team
