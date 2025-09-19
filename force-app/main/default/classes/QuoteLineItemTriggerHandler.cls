// Trigger handler for QuoteLineItem operations
// Calculates Total_Price__c based on Annual_Amount__c and term length
// Updates Quote Order dates based on QLI effective dates
public class QuoteLineItemTriggerHandler {
    
    private static Boolean hasRunBillingCalculation = false;
    
    // Main trigger handler entry point
    public static void handleTrigger() {
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            handleBeforeSave();
        }
        
        if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete)) {
            handleAfterSave();
        }
        
        // Reset static variable after each trigger execution to allow proper recalculation on subsequent operations
        hasRunBillingCalculation = false;
    }
    
    // Handle before insert and before update operations
    private static void handleBeforeSave() {
        if (hasRunBillingCalculation) {
            return;
        }
        
        // GTM-138: Ensure all QLIs have exchange rates (inherit from OLI or use current rate)
        if (Trigger.isInsert) {
            ensureQLIExchangeRates(Trigger.new);
        }
        
        calculateBillingAmounts(Trigger.new);
        hasRunBillingCalculation = true;
    }
    
    // Handle after insert, update, and delete operations
    private static void handleAfterSave() {
        updateQuoteOrderDates();
    }
    
    // Update Quote Order dates based on QLI effective dates (override Opportunity inheritance)
    private static void updateQuoteOrderDates() {
        Set<Id> quoteIds = new Set<Id>();
        
        // Collect Quote IDs from trigger records
        if (Trigger.isDelete) {
            for (QuoteLineItem qli : (List<QuoteLineItem>) Trigger.old) {
                quoteIds.add(qli.QuoteId);
            }
        } else {
            for (QuoteLineItem qli : (List<QuoteLineItem>) Trigger.new) {
                quoteIds.add(qli.QuoteId);
            }
        }
        
        if (quoteIds.isEmpty()) return;
        
        // Get current quotes with their opportunity contract dates for fallback
        Map<Id, Quote> quotesMap = new Map<Id, Quote>([
            SELECT Id, Order_Start_Date__c, Order_End_Date__c, 
                   Opportunity.Contract_Start_Date__c, Opportunity.Contract_End_Date__c
            FROM Quote 
            WHERE Id IN :quoteIds
        ]);
        
        // Query all QLIs for affected quotes to calculate aggregated dates
        List<AggregateResult> dateAggregates = [
            SELECT QuoteId, MIN(Effective_Start_Date__c) earliestStart, MAX(Effective_End_Date__c) latestEnd,
                   COUNT(Id) qliCount, COUNT(Effective_Start_Date__c) qliWithDatesCount
            FROM QuoteLineItem 
            WHERE QuoteId IN :quoteIds 
            GROUP BY QuoteId
        ];
        
        // Prepare Quote updates
        List<Quote> quotesToUpdate = new List<Quote>();
        
        for (AggregateResult ar : dateAggregates) {
            Id quoteId = (Id) ar.get('QuoteId');
            Quote existingQuote = quotesMap.get(quoteId);
            Integer qliWithDates = (Integer) ar.get('qliWithDatesCount');
            
            Date newStartDate;
            Date newEndDate;
            
            if (qliWithDates > 0) {
                // QLIs have effective dates - use aggregated QLI dates
                newStartDate = (Date) ar.get('earliestStart');
                newEndDate = (Date) ar.get('latestEnd');
            } else {
                // No QLI effective dates - fallback to Opportunity dates
                newStartDate = existingQuote.Opportunity.Contract_Start_Date__c;
                newEndDate = existingQuote.Opportunity.Contract_End_Date__c;
            }
            
            // Only update if dates actually changed
            if (newStartDate != existingQuote.Order_Start_Date__c || newEndDate != existingQuote.Order_End_Date__c) {
                Quote quote = new Quote(
                    Id = quoteId,
                    Order_Start_Date__c = newStartDate,
                    Order_End_Date__c = newEndDate
                );
                quotesToUpdate.add(quote);
            }
        }
        
        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
    }
    
    // Calculate billing amounts for all QuoteLineItems with valid UnitPrice
    // Annual_Amount__c is calculated for ALL products regardless of family
    // Total_Price__c applies proration only for Software Subscriptions
    private static void calculateBillingAmounts(List<QuoteLineItem> quoteLineItems) {
        for (QuoteLineItem qli : quoteLineItems) {
            if (hasValidUnitPrice(qli)) {
                calculateBillingAmount(qli);
            }
        }
    }
    
    // Calculate billing amount for a single QuoteLineItem
    private static void calculateBillingAmount(QuoteLineItem qli) {
        try {
            // UnitPrice is the annual amount (what reps work with)
            // Calculate base amount: UnitPrice × Quantity
            Decimal baseAmount = qli.UnitPrice * (qli.Quantity != null ? qli.Quantity : 1);
            
            // Apply discount to get the actual annual amount
            Decimal discountMultiplier = 1 - ((qli.Discount != null ? qli.Discount : 0) / 100);
            Decimal actualAnnualAmount = baseAmount * discountMultiplier;
            
            // Always calculate Annual_Amount__c for consistency and accuracy
            // This ensures discount changes are immediately reflected
            qli.Annual_Amount__c = actualAnnualAmount;
            
            // Calculate List_Price__c (customer-facing unit price) and Total_Price__c
            if (qli.Product_Family__c == 'Software Subscriptions') {
                // Use formula field Term_Length_Months__c if available, otherwise calculate
                Decimal termLengthMonths = (qli.Term_Length_Months__c != null) ? 
                    qli.Term_Length_Months__c : getTermLengthMonths(qli);
                
                if (termLengthMonths < 12) {
                    // <1 year: Show prorated amounts (what customer actually pays)
                    // List_Price__c shows prorated unit price for customer display (NO discount applied)
                    qli.List_Price__c = qli.UnitPrice * (termLengthMonths / 12);
                    
                    // Total_Price__c is the total prorated line amount WITH discount applied
                    Decimal proratedAmount = qli.List_Price__c * (qli.Quantity != null ? qli.Quantity : 1);
                    qli.Total_Price__c = proratedAmount * discountMultiplier;
                } else {
                    // ≥1 year: Show annualized unit price but total contract value
                    // List_Price__c shows annual unit price for customer display (NO discount applied)
                    qli.List_Price__c = qli.UnitPrice;
                    
                    // Total_Price__c is the total contract value (annual amount × years) WITH discount applied
                    Decimal totalContractValue = actualAnnualAmount * (termLengthMonths / 12);
                    qli.Total_Price__c = totalContractValue;
                }
            } else {
                // For all other products (Professional Services, etc.): no proration
                // List_Price__c shows full unit price (NO discount applied)
                qli.List_Price__c = qli.UnitPrice;
                
                // Total_Price__c is the total line amount WITH discount applied
                qli.Total_Price__c = actualAnnualAmount;
            }
        } catch (Exception e) {
            qli.addError('Error calculating billing amount: ' + e.getMessage());
        }
    }
    
    // Get term length in whole months with 1-month minimum
    // Uses Effective_Start_Date__c and Effective_End_Date__c which implement the 3-level hierarchy
    private static Decimal getTermLengthMonths(QuoteLineItem qli) {
        // Try Service dates first (user overrides)
        if (qli.Service_Start_Date__c != null && qli.Service_End_Date__c != null) {
            Integer servicePeriodDays = qli.Service_Start_Date__c.daysBetween(qli.Service_End_Date__c) + 1;
            return Math.max(1, Math.round(servicePeriodDays / 30.44));
        }
        
        // Fallback to Effective dates (formula field hierarchy)
        if (qli.Effective_Start_Date__c != null && qli.Effective_End_Date__c != null) {
            Integer effectivePeriodDays = qli.Effective_Start_Date__c.daysBetween(qli.Effective_End_Date__c) + 1;
            return Math.max(1, Math.round(effectivePeriodDays / 30.44));
        }
        
        // Default to 12 months (annual term) if no dates available - business default
        return 12;
    }
    
    // Check if QuoteLineItem has valid UnitPrice for calculation
    private static Boolean hasValidUnitPrice(QuoteLineItem qli) {
        return qli.UnitPrice != null && qli.UnitPrice > 0;
    }
    
    // GTM-138: Ensure all QLIs have exchange rates - inherit from OLI or use current rate
    // All objects should always have rates, never null
    private static void ensureQLIExchangeRates(List<QuoteLineItem> quoteLineItems) {
        // First, try to inherit from related OLIs (for copy button scenarios)
        inheritRatesFromOLI(quoteLineItems);
        
        // Then, set current rates for any QLIs that still don't have rates
        setCurrentRatesForQLIs(quoteLineItems);
    }
    
    // GTM-138: Inherit Exchange_Rate__c from related OpportunityLineItems (copy button workflow)
    private static void inheritRatesFromOLI(List<QuoteLineItem> quoteLineItems) {
        // Collect OpportunityLineItem IDs from QLIs that reference them
        Set<Id> oliIds = new Set<Id>();
        
        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.OpportunityLineItemId != null) {
                oliIds.add(qli.OpportunityLineItemId);
            }
        }
        
        if (oliIds.isEmpty()) {
            return; // No OLI relationships to process
        }
        
        // Query OLI exchange rates
        Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem>([
            SELECT Id, Exchange_Rate__c 
            FROM OpportunityLineItem 
            WHERE Id IN :oliIds
            AND Exchange_Rate__c != null
        ]);
        
        // Assign exchange rates to QLIs from their source OLIs
        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.OpportunityLineItemId != null && qli.Exchange_Rate__c == null) {
                OpportunityLineItem relatedOLI = oliMap.get(qli.OpportunityLineItemId);
                if (relatedOLI != null && relatedOLI.Exchange_Rate__c != null) {
                    qli.Exchange_Rate__c = relatedOLI.Exchange_Rate__c;
                    
                    System.debug(LoggingLevel.INFO, 
                        'GTM-138: Inherited exchange rate ' + relatedOLI.Exchange_Rate__c + 
                        ' to QLI from OLI ' + qli.OpportunityLineItemId);
                }
            }
        }
    }
    
    // GTM-138: Set current exchange rates for QLIs that don't have them yet
    private static void setCurrentRatesForQLIs(List<QuoteLineItem> quoteLineItems) {
        // Get Quote currencies for QLIs that still need rates
        Set<Id> quoteIds = new Set<Id>();
        List<QuoteLineItem> qlisNeedingRates = new List<QuoteLineItem>();
        
        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.Exchange_Rate__c == null) {
                quoteIds.add(qli.QuoteId);
                qlisNeedingRates.add(qli);
            }
        }
        
        if (qlisNeedingRates.isEmpty()) return;
        
        // Query Quote currencies
        Map<Id, Quote> quoteMap = new Map<Id, Quote>([
            SELECT Id, CurrencyIsoCode
            FROM Quote 
            WHERE Id IN :quoteIds
            AND CurrencyIsoCode != null
        ]);
        
        // Set current exchange rates
        for (QuoteLineItem qli : qlisNeedingRates) {
            Quote relatedQuote = quoteMap.get(qli.QuoteId);
            if (relatedQuote != null && relatedQuote.CurrencyIsoCode != null) {
                Decimal currentRate = ExchangeRateManager.getCurrentExchangeRate(relatedQuote.CurrencyIsoCode);
                if (currentRate != null) {
                    qli.Exchange_Rate__c = currentRate;
                    
                    System.debug(LoggingLevel.INFO, 
                        'GTM-138: Set current exchange rate ' + currentRate + 
                        ' on QLI for currency ' + relatedQuote.CurrencyIsoCode);
                }
            }
        }
    }
    
    // Reset static variables for testing
    @TestVisible
    private static void resetStaticVariables() {
        hasRunBillingCalculation = false;
    }
}