# GTM-146 Revenue Automation - Updated Technical Specification

## Executive Summary

**Epic:** GTM-146 Revenue Automation  
**Objective:** Eliminate manual operations work and automate contract/asset creation processes  
**Target Date:** September 14, 2025  
**Primary Constraint:** Development time allocation across concurrent projects (GTM-138, GlobalData Integration)

## Project Scope Overview

### Core Business Challenge
- **Current State:** Manual operations team creates contracts and assets after opportunity closure
- **Desired State:** Automated contract/asset creation triggered by opportunity closure with minimal human oversight
- **Secondary Issues:** Exchange rate sync challenges (addressed in separate GTM-138 epic)

### Success Metrics
- Eliminate manual contract/asset creation workload
- Ensure seamless object relationships (Opportunity → Contract → Asset)
- Maintain revenue recognition accuracy through automated date calculations
- Provide operational visibility through proactive notifications

## Data Architecture & Object Relationships

### Opportunity Structure Redesign

#### Record Types (GTM-197)
- **New Contract:** First contract for account or additional contracts for existing accounts
- **Existing Contract:** Modifications to existing contracts (Change Orders)

#### Deal Types (GTM-197)
- **New Logo:** First contract with new customer account
- **Existing Logo:** Additional contract with existing customer account  
- **Renewal:** Contract renewal creating successor contract
- **Change Order:** Modifications to existing active contract
- **Churn:** Contract cancellation or non-renewal (retained for reporting)

### Contract Lifecycle Model

```
Account
├── Contract A (Original)
│   ├── Assets (Status: Expired - dates have passed)
│   └── Related Opportunities (Closed)
├── Contract B (PO #2 - Current) 
│   ├── Assets (Status: Active - within date range)
│   └── Related Opportunities (Closed/Pipeline)
└── Contract C (PO #3 - Future)
    ├── Assets (Status: Draft - future start dates)
    └── Related Opportunities (Closed/Pipeline)
```

### Asset Status Framework (GTM-196, GTM-198)

#### Status Types
- **Draft:** Asset.Start_Date > Today
- **Active:** Today between Asset.Start_Date and Asset.End_Date
- **Expired:** Asset.End_Date < Today  
- **Cancelled:** Manual override status
- **One-Time:** Asset classification for non-recurring products

#### Date-Driven Automation
- Asset status updates via daily batch processing based on date field evaluation
- Multiple contracts can be simultaneously active with different Asset date ranges
- Contract state context derived from Asset composition, not maintained separately

### Account Status Lifecycle Framework (Enhanced GTM-115, GTM-210)

#### Complete 5-State Status Lifecycle
- **Null → Prospect:** Initial lead/contact creation
- **Prospect → Contracted:** Deal closure with future contract start date (GTM-210)
- **Contracted → Active:** Contract start date reached with active assets
- **Active → Active (Churning):** Lost renewal detection (Closed Lost + Deal Type = "Churn")
- **Active (Churning) → Churned:** Contract expiration without renewal

#### Daily Batch Processing Architecture
- **Scheduled Flow:** `Scheduled_Flow_Daily_Update_Accounts`
- **Revenue Calculations:** ARR/TCV/ACV/MRR across ALL contracts (MRR = ARR/12)
- **Contract Categorization:** Active/Future/Expired counting and classification
- **Revenue Field Management:** Nullification and recalculation patterns
- **Decision Logic:** Multiple conditional outcomes with comprehensive status management

## Core Automation Workflows

### Forward Flow: Opportunity → Contract → Asset

#### Automation Decision Logic
```
Opportunity.StageName = Closed Won
├── Deal_Type__c = "Change Order" + ContractId populated
│   └── UPDATE existing Contract → CREATE new Assets
│   └── SYNC OLIs marked "Sync to Renewal = Yes" to related renewal opportunity
├── Deal_Type__c = "Renewal"
│   └── CREATE new Contract (PO #X naming) → CREATE Assets
├── Record_Type = "New Contract" + Deal_Type__c = "Existing Logo"  
│   └── CREATE new Contract (additional contract for account) → CREATE Assets
└── Record_Type = "New Contract" + Deal_Type__c = "New Logo"
    └── CREATE new Contract (first contract for account) → CREATE Assets
```

#### Asset Creation Standards (GTM-172, GTM-196)
- **Trigger:** Automatic on Contract creation/update
- **Data Flow:** OLI fields → Asset fields with term dates and prorations
- **Multi-Year Handling:** Standardized date calculations for varying term lengths
- **Historical Preservation:** Change Orders only ADD assets, never modify existing
- **Revenue Calculations:** Asset dates drive all financial recognition periods
- **Renewal Integration:** OLI "Sync to Renewal" field determines which assets sync to future renewal opportunities

### Reverse Flow: Contract → Opportunity → Asset Sync

#### Contract-Initiated Opportunity Creation (GTM-174)
```
User clicks "Create Opportunity" on Contract
└── Screen Flow Decision Point
    ├── "Change Order" selected
    │   └── CREATE Opportunity (Deal_Type = "Change Order", ContractId pre-populated)
    └── "Renewal" selected
        └── Check if Renewal Opportunity exists
            ├── EXISTS: Navigate to existing Opportunity
            └── DOESN'T EXIST: CREATE Renewal Opportunity
```

**Enhanced Implementation Features:**
- Smart conditional logic based on `Contract.Renewal_Opportunity__c`
- Dynamic UI options with sophisticated UX workflows
- Complete OCR and OLI creation from contract assets
- Asset-to-OpportunityLineItem conversion automation
- Advanced Salesforce Flow XML structure with proper element grouping

#### Enhanced Asset Selection Framework (GTM-212)

**OLI-Level Renewal Selection (Primary Method):**
- **Field Addition:** "Sync to Renewal" (Yes/No) field on every OLI  
- **Validation:** Required field - all OLIs must have Yes/No selection before Change Order close (GTM-212)
- **Performance Optimization:** Conditional logic with admin exclusions for user experience
- **Sync Logic:** Only OLIs marked "Yes" sync to related renewal opportunity
- **User Experience:** Rep decides during deal progression which products continue to renewal

**Standard Sync Capability:**
- **"Sync Latest Products" Button:** Auto-populate all Software Subscription assets as OLIs
- **Use Case:** Quick refresh for standard renewals after change orders

**Advanced Selection Interface (Legacy/Backup):**
- **"Select Products" Button:** Screen Flow with Asset data table (maintained for edge cases)
- **Functionality:** 
  - Multi-select grid displaying all Contract Assets
  - Filter options (Product Family, Asset Type, Status)
  - Selective OLI creation from chosen Assets
- **Strategic Value:** Include Professional Services, one-time revenue, custom configurations

### Renewal Automation Process (GTM-195)

#### Automatic Renewal Creation
- **Trigger:** Deal closure (any Deal_Type that creates new contract)
- **Logic:** Create follow-on renewal opportunity for contract continuation
- **Product Population:** Auto-create OLIs from Software Subscription assets on the related contract
- **Timing:** Immediate upon contract creation
- **Ownership:** Inherit from closed opportunity or assign via territory rules

## Implementation Phases

### Phase 1: Data Foundation & Process Architecture ✅ COMPLETE

**P1.1 - Opportunity Process Restructure**
- **GTM-197:** ✅ Implement new Record Types and Deal Types
- **GTM-176:** ✅ Separate New Contract logic from New Logo classification

**P1.2 - Asset Classification & Lifecycle Framework**  
- **GTM-198:** ✅ Implement comprehensive Asset status model
- **GTM-196:** 🔄 Build One-Time vs Recurring Asset handling with date standards

**P1.3 - Account Status Lifecycle Enhancement**
- **GTM-210:** ✅ Contracted Status Logic for deals closed but contracts not started
- **GTM-115:** 🔄 Enhanced Account Status Lifecycle automation with 5-state progression

### Phase 2: Core Contract-Opportunity Integration ✅ LARGELY COMPLETE

**P2.1 - New Contract Creation**
- **GTM-169:** ✅ Automate Contract creation from Opportunity closure
- **GTM-195:** ✅ Implement automatic Renewal Opportunity creation with Software Subscription asset population

**P2.2 - Change Order Processing**
- **GTM-170:** ✅ Automate Contract updates for existing contract modifications
- **Contract Identification:** Use ContractId field for relationship integrity

**P2.3 - Asset Generation & Management**
- **GTM-172:** ✅ Automate Asset creation from OLI with comprehensive date handling
- **GTM-196:** 🔄 Apply One-Time vs Recurring logic with proper term calculations

**P2.4 - Quote-Opportunity Line Item Synchronization (GTM-213)**
- **Enhancement:** ✅ Enhanced QuoteSyncService Apex class with 7 new custom field mappings
- **New QLI Fields:** ✅ Created `Include_in_ARR__c`, `Include_in_ARR_Sum__c`
- **Field Permissions:** ✅ Deployed to all 9 relevant user profiles
- **Project Optimization:** ✅ Streamlined project structure (removed 28 unnecessary profile files)
- **End-to-End Consistency:** ✅ Quote → OLI → Asset data consistency achieved

### Phase 3: Advanced Workflow Integration 🔄 IN PROGRESS

**P3.1 - Bidirectional Contract-Opportunity Workflows**
- **GTM-174:** 🔄 Contract-initiated Opportunity creation (sophisticated UX implementation)
- **GTM-212:** ✅ OLI-level "Sync to Renewal" field implementation with validation rules

**P3.2 - Process Optimization**
- **GTM-175:** ✅ Renewal Opportunity handling confirmation and optimization
- **GTM-116:** 📋 Nextflow Conversion Approval integration (separate from quote-triggered flows)

**P3.3 - Data Quality & Validation**
- **GTM-204:** 🔄 OLI Validation Rules
- **GTM-205:** 🔄 QLI Sync Audit  
- **GTM-209:** 📋 Mandatory Fields for closing (Opp Record Type, Account Segment/Vertical, etc.)

### Phase 4: Operational Intelligence & Lifecycle Monitoring 📋 PENDING

**P4.1 - Core Notification Infrastructure**
- **GTM-177:** 📋 Deal Desk Slack Channel integration configuration (deprioritized)
- **GTM-178:** 📋 Opportunity, Contract, and Asset Slack layout optimization

**P4.2 - Lifecycle Event Monitoring**
- **GTM-156:** 🔄 Contract Expiration Notification System
  - Monthly batch process for contracts expiring within defined window
  - Automated alerts to sales-ops channel
- **GTM-211:** 📋 Notification to Team-Commercial for 6 months before contract expires
- **GTM-115:** 🔄 Enhanced Churn Notice Process
  - Real-time notifications for Opportunity Closed Lost
  - Contract cancellation alerts across multiple channels
  - Account status lifecycle management

**P4.3 - Status Intelligence**
- **GTM-171:** 📋 Contract status automation (leverage existing revenue rollup where applicable)
- **GTM-173:** 📋 Asset status automation with date-driven batch processing
- **GTM-167:** 🔄 Remove automatic batch account status updates

**P4.4 - Revenue Management**
- **GTM-208:** 📋 Active Revenue Academic → Switch to Commercial

### Phase 5: Change Management & Knowledge Transfer 📋 PENDING

**P5.1 - Documentation & Training**
- **GTM-179:** 📋 Sales team documentation creation
- **GTM-180:** 📋 Training program for contract and opportunity management

## Technical Architecture Decisions

### Automation Framework Strategy

#### Heavy DML Processing Consideration
**Challenge:** Multiple object creation/updates on Opportunity closure  
**Decision:** Hybrid approach selected
- **Flow Builder:** Complex logic with proper element connectivity and sophisticated decision trees
- **Apex Actions:** QuoteSyncService enhancements for bulk operations
- **Memory-Guided Development:** Systematic application of flow connectivity rules

#### Status Management Processing
**Asset/Contract Status Updates:**
- **Daily Batch Processing:** `Scheduled_Flow_Daily_Update_Accounts` for routine status updates
- **Real-Time Triggers:** Critical events like deal closure and contract creation
- **Revenue Calculation Formulas:** Automated MRR = ARR/12 calculations

### Integration Specifications

#### Contract Naming Convention
- **Initial Contract:** Standard naming convention  
- **Renewal Contracts:** Sequential naming (PO #2, PO #3, etc.)
- **Sequence Management:** Auto-increment based on Account's existing Contracts

#### Enhanced Field Management & Security
- **Profile Security Model:** Complete deployment across 9+ profiles
- **Field Permissions:** Systematic deployment across all user types
- **Metadata Management:** Focused project structure for maintainability

#### Notification Framework
**GTM-156 Contract Expiration:**
- **Timing:** Monthly batch process (first business day)
- **Criteria:** Contracts with Assets expiring within configurable timeframe (suggested 90 days)
- **Target:** Sales-ops Slack channel

**GTM-115 Enhanced Churn Process:**
- **Triggers:** Opportunity Closed Lost, Asset status change to Cancelled, Lost renewal detection
- **Account Status Management:** Complete 5-state lifecycle with daily batch processing
- **Revenue Impact:** Comprehensive field nullification and recalculation
- **Channels:** sales-closed-won, support eng (routing based on deal characteristics)
- **Format:** Real-time notifications with contextual deal information

## Outstanding Technical Specifications

### Decision Points Requiring Resolution

#### Asset Status Processing
1. **Batch Processing Schedule:** Daily overnight acceptable for status updates? ✅ **RESOLVED: Yes, implemented**
2. **Real-Time Requirements:** Which events require immediate processing vs batch? ✅ **RESOLVED: Hybrid approach**

#### Notification Parameters  
1. **Contract Expiration Window:** Standard timeframe for advance notifications?
2. **GTM-211 Implementation:** 6-month advance notification requirements and channels?
3. **Churn Event Scope:** Include Asset cancellations beyond Opportunity losses? ✅ **RESOLVED: Yes, comprehensive**

#### Performance Considerations
1. **Asset Selection Interface:** Maximum record limits for performance optimization?
2. **Bulk Processing:** Governor limit management for large-scale automation?
3. **OLI Validation Rules:** Performance impact of required field validation on Change Order close? ✅ **RESOLVED: Optimized with admin exclusions**

### Enhanced Requirements from Implementation

#### GTM-210 Contracted Status Logic
1. **Status Transition Logic:** Comprehensive decision tree for account status progression
2. **Revenue Field Management:** When to nullify vs. recalculate revenue fields
3. **Contract Categorization:** Active/Future/Expired counting methodology

#### Advanced Quote Sync (GTM-213)
1. **Field Mapping Completeness:** All 7 custom field mappings validated
2. **ARR Control Fields:** `Include_in_ARR__c` and `Include_in_ARR_Sum__c` business logic
3. **Profile Permissions:** Deployment validation across all user types

#### Data Quality & Validation
1. **GTM-204 OLI Validation:** Complete validation rule specifications
2. **GTM-209 Mandatory Fields:** Field requirements and exception handling
3. **GTM-205 QLI Sync Audit:** Comprehensive field mapping audit results

### Data Migration Requirements
1. **Existing Records:** Update historical data to align with new structure?
2. **Field Mapping:** Comprehensive mapping specifications for OLI → Asset conversion? ✅ **RESOLVED: Implemented**
3. **Account Status Backfill:** Historical account status assignment based on contract dates?

### Renewal Opportunity Creation Logic
1. **Asset Selection Criteria:** Only Software Subscription assets, or configurable product families? ✅ **RESOLVED: Software Subscription focus**
2. **Pricing Logic:** Use current Asset pricing or allow for renewal pricing adjustments?
3. **Opportunity Timing:** Create immediately on contract creation or schedule based on contract term? ✅ **RESOLVED: Immediate creation**

## Risk Mitigation & Success Factors

### Critical Dependencies
- **Concurrent Projects:** GTM-138 (multi-currency) and GlobalData Integration resource coordination
- **Existing Automation:** Assessment and integration of current revenue rollup flows ✅ **RESOLVED: Integrated**
- **User Adoption:** Training and change management for new workflows

### Success Criteria
- **Operational Efficiency:** Elimination of manual contract/asset creation ✅ **ACHIEVED: Core automation complete**
- **Data Integrity:** Seamless object relationships with accurate revenue calculations ✅ **ACHIEVED: End-to-end consistency**
- **Process Reliability:** Automated workflows with minimal exception handling requirements ✅ **ACHIEVED: Production-ready architecture**
- **Visibility Enhancement:** Proactive notification system for lifecycle management 🔄 **IN PROGRESS**

### Production Operations & Quality Assurance
- **Production Monitoring:** ✅ Scheduled flow failure detection and systematic bug resolution
- **Manual Testing Validation:** ✅ Comprehensive multi-scenario validation procedures
- **Bug Resolution Process:** ✅ Immediate response and deployment verification

## Implementation Status Summary

### ✅ **COMPLETED FEATURES (Major Milestones)**
- **GTM-210:** Complete Contracted Status Logic with account lifecycle management
- **GTM-213:** Enhanced Quote Sync Service with comprehensive field mapping
- **GTM-212:** OLI 'Sync to Renewal' validation rules with performance optimization
- **GTM-169, GTM-170, GTM-172:** Core contract and asset automation workflows
- **GTM-195, GTM-175, GTM-176:** Renewal opportunity automation and process optimization

### 🔄 **IN PROGRESS**
- **GTM-174:** Contract 'Create Opportunity' button (advanced UX workflows)
- **GTM-115:** Enhanced account status lifecycle (daily batch processing)
- **GTM-156:** Contract expiration notification system
- **GTM-204, GTM-205:** Data validation and audit processes

### 📋 **PENDING IMPLEMENTATION**
- **GTM-211:** 6-month contract expiration notifications
- **GTM-209:** Mandatory field validation for deal closure
- **GTM-208:** Academic to commercial revenue conversion
- **GTM-116:** Nextflow conversion approval integration
- **GTM-177, GTM-178:** Slack integration and notification layouts
- **GTM-171, GTM-173:** Advanced status intelligence automation
- **GTM-179, GTM-180:** Documentation and training programs

---

**Document Version:** 3.0  
**Last Updated:** September 5, 2025  
**Next Review:** Phase 4 implementation planning and technical architecture finalization  
**Implementation Progress:** ~70% Complete (Core automation and data foundation achieved)