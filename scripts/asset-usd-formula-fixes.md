# Asset USD Formula Field Fixes

## Current Problem
Asset USD fields are using multiplication when they should use division since Exchange_Rate__c now stores raw DatedConversionRate values.

## Current Formulas (WRONG)
```
ARR_USD__c = ARR__c * Exchange_Rate__c
MRR_USD__c = MRR__c * Exchange_Rate__c  
Total_Price_USD__c = Total_Price__c * Exchange_Rate__c
Total_Value_USD__c = Total_Value__c * Exchange_Rate__c
Price_USD__c = Price * Exchange_Rate__c
Unit_ARR_USD__c = Unit_ARR__c * Exchange_Rate__c
Unit_MRR_USD__c = Unit_MRR__c * Exchange_Rate__c
Unit_Value_USD__c = Unit_Value__c * Exchange_Rate__c
```

## New Corrected Formulas (INVERTED)
```
ARR_USD__c = ARR__c / Exchange_Rate__c
MRR_USD__c = MRR__c / Exchange_Rate__c  
Total_Price_USD__c = Total_Price__c / Exchange_Rate__c
Total_Value_USD__c = Total_Value__c / Exchange_Rate__c
Price_USD__c = Price / Exchange_Rate__c
Unit_ARR_USD__c = Unit_ARR__c / Exchange_Rate__c
Unit_MRR_USD__c = Unit_MRR__c / Exchange_Rate__c
Unit_Value_USD__c = Unit_Value__c / Exchange_Rate__c
```

## Example Fix Validation
- EUR Asset: €126,000 ARR
- Exchange_Rate__c: 0.846475 (raw rate)
- OLD (wrong): €126,000 × 0.846475 = $106,655.85
- NEW (correct): €126,000 ÷ 0.846475 = $148,838.71

The formulas need to be updated to use DIVISION (/) instead of MULTIPLICATION (*).
