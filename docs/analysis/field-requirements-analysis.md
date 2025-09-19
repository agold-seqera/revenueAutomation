# Field Mapping Requirements Analysis

**Date:** August 27, 2025  
**Source:** RevAuto_ Field Mapping - Mappings.csv

## CSV Structure Understanding
- **Column 1:** Source Object (Opportunity, OLI)
- **Column 2:** Target Object (Contract, Asset)
- **Column 3:** Source Field (what we're mapping FROM)
- **Column 4:** Target Field (what we're mapping TO)

## Field Analysis: Existing vs Required

### Contract Fields - ALREADY EXIST ✅
| Field Name | Status | Notes |
|------------|--------|--------|
| `Previous_ACV__c` | ✅ EXISTS | Historical ACV tracking |
| `Previous_ARR__c` | ✅ EXISTS | Historical ARR tracking |
| `Previous_MRR__c` | ✅ EXISTS | Historical MRR tracking |
| `Previous_TCV__c` | ✅ EXISTS | Historical TCV tracking |
| `Renewal_Opportunity__c` | ✅ EXISTS | Renewal opp reference |
| `Term_Length_Months__c` | ✅ EXISTS | Contract term length |

### Contract Fields - NEED TO CREATE 🔨
| Field Name | Type | Source | Notes |
|------------|------|---------|-------|
| `Billing_Frequency__c` | Picklist | Opportunity.Contract_Billing_Frequency__c | Payment frequency |
| `Payment_Terms__c` | Text | Opportunity.Payment_Terms__c | Payment terms |
| `Previous_Contract__c` | Lookup(Contract) | Opportunity.ContractId | Reference to predecessor |

### Asset Fields - ALREADY EXIST ✅
| Field Name | Status | Notes |
|------------|--------|--------|
| `Contract__c` | ✅ EXISTS | Contract reference |
| `CPUh__c` | ✅ EXISTS | CPU hours |
| `End_Date__c` | ✅ EXISTS | Asset end date |
| `Original_Opportunity__c` | ✅ EXISTS | Original opportunity reference |
| `Secondary_Product_Type__c` | ✅ EXISTS | Secondary product type |
| `Start_Date__c` | ✅ EXISTS | Asset start date |
| `Term_Length_Months__c` | ✅ EXISTS | Asset term length |

### Asset Fields - NEED TO CREATE 🔨
| Field Name | Type | Source | Notes |
|------------|------|---------|-------|
| `Annual_Unit_Price__c` | Currency | OLI.Annual_Unit_Price__c | Yearly pricing |
| `Billing_Amount__c` | Currency | OLI.Billing_Amount__c | Billing calculations |
| `Discount__c` | Percent | OLI.Discount | Discount percentage |
| `Originating_OLI__c` | Lookup(OLI) | OLI.Id | Source line item |
| `Include_in_ARR_Override__c` | Checkbox | OLI.Include_in_ARR__c | ARR override flag |
| `Include_in_ARR_Sum__c` | Checkbox | OLI.Include_in_ARR_Sum__c | ARR sum inclusion |
| `PricebookEntry__c` | Lookup(PBE) | OLI.PricebookEntryId | Price book reference |
| `Prorated_Unit_Price__c` | Currency | OLI.Prorated_Unit_Price__c | Prorated pricing |

## Complex Logic Mappings
- **CustomerSignedTitle/Id:** Lookup to OCR with Role = "Primary Contact"
- **Secondary_Product_Type__c:** Formula field looking up to Product2

## Profile Assignment Required
All new fields must be assigned to 9 profiles from Profiles - Sheet1.csv:
- Custom SysAdmin, Minimum Access, Seqera Customer Service, Seqera Executive, 
- Seqera Marketing, Seqera Sales, Seqera SDR, System Administrator, 
- System Administrator (Service Account)
