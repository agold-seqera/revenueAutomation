# Flow Template - GTM-138 Exchange Rate Manager

## Flow Design Template

### Flow Naming Convention
- `GTM138_[Object]_[Action]_[Trigger]`
- Example: `GTM138_Quote_ExchangeRateLock_StatusChange`

### Flow Types for GTM-138

#### Record-Triggered Flow Template
```
Flow Name: GTM138_[Object]_ExchangeRateAssignment_Creation
API Name: GTM138_[Object]_ExchangeRateAssignment_Creation
Object: [Quote/Asset]
Trigger: A record is created or updated
Condition Requirements: [Specific conditions]
Optimization: Fast Field Updates
```

#### Auto-Launched Flow Template
```
Flow Name: GTM138_[Process]_[Action]
API Name: GTM138_[Process]_[Action]
Type: Auto-Launched Flow
Input Variables: [Define required inputs]
Output Variables: [Define outputs if needed]
```

## Flow Elements

### Get Records Element
```
Element: Get Exchange Rate
API Name: Get_Exchange_Rate
Object: DatedConversionRate
Filter Conditions:
  - IsoCode = {!$Record.CurrencyIsoCode}
  - StartDate <= {!$Flow.CurrentDate}
  - NextStartDate > {!$Flow.CurrentDate} OR NextStartDate = null
Sort Order: StartDate (Descending)
Limit: 1
```

### Assignment Element
```
Element: Assign Exchange Rate
API Name: Assign_Exchange_Rate
Variable Assignments:
  - {!$Record.Exchange_Rate__c} = {!Get_Exchange_Rate.ConversionRate}
```

### Update Records Element
```
Element: Update Record with Exchange Rate
API Name: Update_Record_Exchange_Rate
Record: {!$Record}
Fields to Update:
  - Exchange_Rate__c = {!$Record.Exchange_Rate__c}
```

### Decision Element
```
Element: Check Currency Code
API Name: Check_Currency_Code
Outcomes:
  1. Has Currency
     - Condition: {!$Record.CurrencyIsoCode} Is null = false
  2. Default (No Currency)
```

### Apex Action Template
```
Element: Call Exchange Rate Manager
API Name: Call_ExchangeRateManager
Apex Class: ExchangeRateManager
Method: getCurrentExchangeRate
Input Parameters:
  - currencyCode = {!$Record.CurrencyIsoCode}
Store Output: exchangeRateValue
```

## Flow Documentation Template

### Flow Purpose
**Objective:** [Describe what this flow accomplishes]
**Business Process:** [Describe the business process this supports]
**Integration:** [Describe how this integrates with GTM-138 components]

### Flow Logic
1. **Trigger Condition:** [When this flow executes]
2. **Data Retrieval:** [What data is gathered]
3. **Processing Logic:** [How data is processed]
4. **Updates/Actions:** [What updates are made]
5. **Error Handling:** [How errors are managed]

### Flow Variables
| Variable Name | Data Type | Purpose | Default Value |
|---------------|-----------|---------|---------------|
| exchangeRate | Number | Current exchange rate | 1.000000 |
| currencyCode | Text | ISO currency code | USD |
| errorMessage | Text | Error handling | null |

### Flow Constants
| Constant Name | Value | Purpose |
|---------------|-------|---------|
| DEFAULT_EXCHANGE_RATE | 1.000000 | Fallback rate |
| USD_CURRENCY_CODE | USD | Base currency |

## Error Handling in Flows

### Fault Path Template
```
Element: Handle Exchange Rate Error
API Name: Handle_Exchange_Rate_Error
Type: Screen or Assignment
Actions:
  - Log error details
  - Set default exchange rate
  - Send notification (if critical)
```

### Debug Logging
```
Element: Debug Exchange Rate Assignment
API Name: Debug_Exchange_Rate
Type: Assignment
Variables:
  - debugMessage = "GTM-138: Exchange rate assigned - Currency: {!currencyCode}, Rate: {!exchangeRate}"
```

## Flow Testing Checklist

### Test Scenarios
- [ ] **Single Record:** Test with one record of each currency
- [ ] **Bulk Records:** Test with 200+ records in batch
- [ ] **Missing Currency:** Test with null/invalid currency codes
- [ ] **No Exchange Rate:** Test when DatedConversionRate is unavailable
- [ ] **Mixed Currencies:** Test with multiple currency types
- [ ] **Performance:** Verify execution within time limits

### Test Data Requirements
```
Required Test Data:
- DatedConversionRate records for: USD, EUR, GBP, JPY
- [Object] records with various currency codes
- [Object] records with null currency codes
- Historical DatedConversionRate records for date testing
```

## Flow Performance Guidelines

### Best Practices
1. **Minimize SOQL Queries:** Use Get Records efficiently
2. **Batch Processing:** Handle bulk scenarios appropriately
3. **Error Handling:** Include comprehensive fault paths
4. **Debug Logging:** Add debug elements for troubleshooting
5. **Governor Limits:** Monitor DML and SOQL usage

### Flow Limits to Monitor
- SOQL Queries: 100 per transaction
- DML Statements: 150 per transaction
- Total Records Retrieved: 50,000
- CPU Time: 10,000ms for synchronous

## Integration Points

### Apex Integration
```
Apex Action: ExchangeRateManager.assignQLIRates
Input: Collection of QuoteLineItems
Output: Success/Failure status
```

### Platform Event Integration
```
Create Platform Event: Exchange_Rate_Update__e
Fields:
  - Object_Type__c
  - Record_Id__c
  - Old_Rate__c
  - New_Rate__c
  - Update_Reason__c
```

## Flow Deployment

### Deployment Checklist
- [ ] Flow built and tested in development
- [ ] Test coverage verified (scenarios above)
- [ ] Performance validated
- [ ] Documentation complete
- [ ] Flow activated in target environment
- [ ] Post-deployment testing completed

### Version Control
- Track flow versions in deployment notes
- Document changes between versions
- Maintain rollback procedures for flow deactivation
