# GTM-138 Exchange Rate Manager - Project Specification

**Document Version:** 1.0  
**Created:** August 26, 2025  
**Source:** gtm-138-exchange-rate-manager-spec.md  
**Status:** Architecture Reference

## Quick Reference

This document provides a clean architectural reference for the GTM-138 Exchange Rate Manager project, derived from the original specification.

### Project Overview
- **Epic:** GTM-138 Exchange Rate Manager
- **Objective:** Implement comprehensive exchange rate management across all revenue objects
- **Target Date:** September 14, 2025
- **Scope:** Quote, QuoteLineItem, Asset, Contract objects with USD conversion fields

### Key Architecture Components

#### Objects & Fields
- **4 Exchange Rate Fields:** `Exchange_Rate__c` (Number, 18,6)
- **29 USD Conversion Fields:** Formula fields across all objects
- **Profile Security:** 9 profiles with field-level access
- **Audit Trail:** Field history tracking enabled

#### Rate Locking Strategy
```
OpportunityLineItem (ACM) ──┐
                           ├─→ QuoteLineItem (inherit rate)
Opportunity (ACM) ──────────┘    └─→ Quote (lock at "Needs Review")
                                 
Asset (lock at creation) ──────────→ Contract (rollup from Assets)
```

#### Implementation Phases
1. **Phase 1:** Field Architecture & Profile Setup
2. **Phase 2:** Exchange Rate Assignment Logic  
3. **Phase 3:** Rollup Integration & Formula Validation
4. **Phase 4:** Layout Updates & User Experience
5. **Phase 5:** Enhancements (Non-Blocking)

### Integration Points
- **CPQ System:** Enhanced Quote/QLI creation workflows
- **Revenue Automation (GTM-146):** Asset creation coordination
- **ACM System:** Zero impact on existing Opportunity functionality
- **Daily Batch Flow:** Modified Contract rollup calculations

---
**Reference:** Complete specification in project root: `gtm-138-exchange-rate-manager-spec.md`
