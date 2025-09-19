// Service class for Quote to Opportunity sync operations
// Replaces Quote_After_Save_Sync_Approved_Quote flow logic
public class QuoteSyncService {
    
    // Main method to sync quotes to opportunities
    public static void syncQuotesToOpportunities(List<Quote> quotes) {
        if (quotes.isEmpty()) return;
        

        
        // Process each quote
        for (Quote quote : quotes) {
            try {
                syncSingleQuote(quote);
            } catch (Exception e) {
                // Log error but continue processing other quotes
                System.debug('Error syncing quote ' + quote.Id + ': ' + e.getMessage());
            }
        }
    }
    
    // Sync a single quote - main sync logic from flow
    private static void syncSingleQuote(Quote quote) {
        // 1. Get Quote Line Items for sync
        List<QuoteLineItem> qlis = getQuoteLineItemsForSync(quote.Id);
        
        // 2. Delete existing OpportunityLineItems
        deleteExistingOpportunityLineItems(quote.OpportunityId);
        
        // 3. Create new OpportunityLineItems from QuoteLineItems
        if (!qlis.isEmpty()) {
            List<OpportunityLineItem> newOlis = createOpportunityLineItemsFromQLIs(qlis, quote);
            insert newOlis;
        }
        
        // 4. Sync Quote-level fields to Opportunity
        syncQuoteLevelFields(quote);
        
        // 5. Set this quote as synced and mark others as not synced
        updateSyncedQuoteStatus(quote);
    }
    
    // Get QuoteLineItems for sync
    private static List<QuoteLineItem> getQuoteLineItemsForSync(Id quoteId) {
        return [
            SELECT Id, Product2Id, PricebookEntryId, Quantity, UnitPrice, List_Price__c,
                   Annual_Amount__c, Product_Family__c, Description, Discount, ServiceDate,
                   Effective_Start_Date__c, Effective_End_Date__c, Total_Price__c, Term_Length_Months__c,
                   Exchange_Rate__c
            FROM QuoteLineItem 
            WHERE QuoteId = :quoteId
        ];
    }
    
    // Delete existing OpportunityLineItems
    private static void deleteExistingOpportunityLineItems(Id opportunityId) {
        List<OpportunityLineItem> existingOlis = [
            SELECT Id 
            FROM OpportunityLineItem 
            WHERE OpportunityId = :opportunityId
        ];
        
        if (!existingOlis.isEmpty()) {
            delete existingOlis;
        }
    }
    
    // Create OpportunityLineItems from QuoteLineItems with field mappings
    private static List<OpportunityLineItem> createOpportunityLineItemsFromQLIs(
        List<QuoteLineItem> qlis, Quote quote) {
        
        List<OpportunityLineItem> newOlis = new List<OpportunityLineItem>();
        
        for (QuoteLineItem qli : qlis) {
            OpportunityLineItem oli = new OpportunityLineItem();
            
            // Standard fields
            oli.OpportunityId = quote.OpportunityId;
            oli.Product2Id = qli.Product2Id;
            oli.PricebookEntryId = qli.PricebookEntryId;
            oli.Quantity = qli.Quantity;
            oli.Description = qli.Description;
            oli.Discount = qli.Discount;
            oli.ServiceDate = qli.ServiceDate;
            
            // Standard Salesforce OLI behavior: UnitPrice × Quantity = TotalPrice (auto-calculated)
            // OLIs are annual by default for forecasting, so use annual unit price
            oli.UnitPrice = qli.UnitPrice;  // Annual unit price (standard Salesforce forecasting)
            // TotalPrice will be auto-calculated as UnitPrice × Quantity
            
            // Revenue-critical field mappings for visibility
            oli.Prorated_Unit_Price__c = qli.List_Price__c;  // Prorated unit price for term
            oli.Annual_Unit_Price__c = qli.UnitPrice;  // Annual unit price for sales rep visibility
            oli.Billing_Amount__c = qli.Total_Price__c;  // Operational billing visibility (prorated total)
            oli.Product_Family__c = qli.Product_Family__c;  // Revenue categorization
            
            // Term/Effective Date mappings for asset lifecycle management
            oli.Term_Start_Date__c = qli.Effective_Start_Date__c;
            oli.Term_End_Date__c = qli.Effective_End_Date__c;
            oli.Term_Length_Months__c = qli.Term_Length_Months__c;  // Term duration in months
            
            // GTM-138 Exchange Rate Manager integration - Phase 3 point-in-time transfer
            oli.Exchange_Rate__c = qli.Exchange_Rate__c;  // Preserve approved exchange rate from quote
            
            // New lookup fields for tracking
            oli.Quote__c = quote.Id;
            oli.QuoteLineItem__c = qli.Id;
            
            newOlis.add(oli);
        }
        
        return newOlis;
    }
    
    // Sync Quote-level fields to Opportunity
    private static void syncQuoteLevelFields(Quote quote) {
        // Query quote with all needed fields including Order dates
        Quote quoteWithFields = [
            SELECT Id, OpportunityId, Billing_Frequency__c, Contract_Signer__c, 
                   Payment_Terms__c, Term_Length_Months__c,
                   Order_Start_Date__c, Order_End_Date__c
            FROM Quote 
            WHERE Id = :quote.Id
            LIMIT 1
        ];
        
        // Update opportunity with quote-level data and stamp our custom synced quote reference
        // Note: SyncedQuoteId is a standard field that is read-only in trigger context, so we use Synced_Quote__c
        Opportunity opp = new Opportunity(
            Id = quoteWithFields.OpportunityId,
            Contract_Billing_Frequency__c = quoteWithFields.Billing_Frequency__c,
            Contract_Signer__c = quoteWithFields.Contract_Signer__c,
            Contract_Start_Date__c = quoteWithFields.Order_Start_Date__c,  // Quote Order Start = Opp Contract Start
            Contract_End_Date_Override__c = quoteWithFields.Order_End_Date__c,  // Quote Order End = Opp Contract End Override
            Payment_Terms__c = quoteWithFields.Payment_Terms__c,
            Term_Length_Months__c = quoteWithFields.Term_Length_Months__c,
            Synced_Quote__c = quoteWithFields.Id  // Stamp our custom synced quote reference
        );
        
        update opp;
    }
    
    // Update Synced Quote status - set this quote to true, others to false
    private static void updateSyncedQuoteStatus(Quote quote) {
        // Get all quotes for this opportunity to manage sync status
        List<Quote> allQuotes = [
            SELECT Id, Synced_Quote__c, OpportunityId
            FROM Quote 
            WHERE OpportunityId = :quote.OpportunityId
        ];
        
        List<Quote> quotesToUpdate = new List<Quote>();
        
        // Mark all quotes appropriately
        for (Quote q : allQuotes) {
            if (q.Id == quote.Id && !q.Synced_Quote__c) {
                q.Synced_Quote__c = true;
                quotesToUpdate.add(q);
            } else if (q.Id != quote.Id && q.Synced_Quote__c) {
                q.Synced_Quote__c = false;
                quotesToUpdate.add(q);
            }
        }
        
        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
        
        // Ensure Opportunity SyncedQuote__c is consistent - clear if no synced quotes remain
        Boolean hasSyncedQuote = false;
        for (Quote q : allQuotes) {
            if (q.Id == quote.Id || q.Synced_Quote__c) {
                hasSyncedQuote = true;
                break;
            }
        }
        
        // If somehow no quotes are marked as synced, clear the Opportunity's custom SyncedQuote__c
        if (!hasSyncedQuote) {
            Opportunity oppToClear = new Opportunity(
                Id = quote.OpportunityId,
                Synced_Quote__c = null
            );
            update oppToClear;
        }
    }
}