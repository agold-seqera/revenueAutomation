// Handler for Quote sync and related after-update processing
// NOTE: Approval processing now handled by native Salesforce approval processes
// via Quote_After_Save_Launch_Approval_Process flow (August 10, 2025)
public class QuoteProcessOrchestratorHandler {
    
    public static void handleTrigger() {
        if (Trigger.isBefore && Trigger.isInsert) {
            handleBeforeInsert(Trigger.new);
        }
        
        if (Trigger.isAfter && Trigger.isUpdate) {
            handleAfterUpdate((Map<Id, Quote>)Trigger.newMap, (Map<Id, Quote>)Trigger.oldMap);
        }
    }
    
    // GTM-138: Set initial exchange rates on Quote creation
    // All objects should always have rates, never null
    private static void handleBeforeInsert(List<Quote> quotes) {
        for (Quote quote : quotes) {
            if (quote.Exchange_Rate__c == null && quote.CurrencyIsoCode != null) {
                // Get current exchange rate for the Quote's currency
                Decimal currentRate = ExchangeRateManager.getCurrentExchangeRate(quote.CurrencyIsoCode);
                if (currentRate != null) {
                    quote.Exchange_Rate__c = currentRate;
                    
                    System.debug(LoggingLevel.INFO, 
                        'GTM-138: Set initial exchange rate ' + currentRate + 
                        ' on Quote creation for currency ' + quote.CurrencyIsoCode);
                }
            }
        }
    }

    private static void handleAfterUpdate(Map<Id, Quote> newQuotes, Map<Id, Quote> oldQuotes) {
        System.debug('QuoteProcessOrchestratorHandler: Processing ' + newQuotes.size() + ' Quote updates');
        
        // GTM-138: Lock exchange rates when quotes are approved
        lockExchangeRatesOnApproval(newQuotes, oldQuotes);
        
        // NOTE: Automatic sync on status change has been disabled per user requirements
        // Sync now only happens manually via Quote_Button_Sync_Quote_to_Opportunity button
        // which invokes QuoteSyncService.syncQuotesToOpportunities() directly
        
        // Approval processing is also handled by:
        // - Quote_After_Save_Launch_Approval_Process (flow)
        // - Quote_Dual_Approval (native approval process)
        // - Quote_First_Override_Approval (native approval process) 
        // - Quote_Second_Override_Approval (native approval process)
    }
    
    // GTM-138: Lock exchange rates when Quote status changes to "Approved"
    // This ensures rates are locked at approval, not sync
    private static void lockExchangeRatesOnApproval(Map<Id, Quote> newQuotes, Map<Id, Quote> oldQuotes) {
        List<Id> approvedQuoteIds = new List<Id>();
        
        // Find quotes that just became "Approved"
        for (Id quoteId : newQuotes.keySet()) {
            Quote newQuote = newQuotes.get(quoteId);
            Quote oldQuote = oldQuotes.get(quoteId);
            
            // Check if status changed to "Approved"
            if (newQuote.Status == 'Approved' && 
                oldQuote.Status != 'Approved') {
                approvedQuoteIds.add(quoteId);
            }
        }
        
        if (!approvedQuoteIds.isEmpty()) {
            stampExchangeRatesOnApproval(approvedQuoteIds);
            stampQLIExchangeRatesOnApproval(approvedQuoteIds);
        }
    }
    
    // GTM-138: Set exchange rates on Quotes when they are approved (if not already set)
    // After approval, rates become "locked" - no more automated rate changes
    private static void stampExchangeRatesOnApproval(List<Id> quoteIds) {
        // Query quotes with currency and exchange rate fields
        List<Quote> quotesToUpdate = [
            SELECT Id, CurrencyIsoCode, Exchange_Rate__c
            FROM Quote 
            WHERE Id IN :quoteIds
            AND Exchange_Rate__c = null
            AND CurrencyIsoCode != null
        ];
        
        if (quotesToUpdate.isEmpty()) return;
        
        List<Quote> finalQuotesToUpdate = new List<Quote>();
        
        for (Quote quote : quotesToUpdate) {
            // Get current exchange rate for the Quote's currency
            Decimal currentRate = ExchangeRateManager.getCurrentExchangeRate(quote.CurrencyIsoCode);
            
            if (currentRate != null) {
                quote.Exchange_Rate__c = currentRate;
                finalQuotesToUpdate.add(quote);
                
                System.debug(LoggingLevel.INFO, 
                    'GTM-138: Set exchange rate ' + currentRate + 
                    ' on Quote ' + quote.Id + ' at approval for currency ' + quote.CurrencyIsoCode);
            }
        }
        
        if (!finalQuotesToUpdate.isEmpty()) {
            update finalQuotesToUpdate;
        }
    }
    
    // GTM-138: Stamp exchange rates on QLIs when their Quote is approved
    // This locks the QLI exchange rates at the time of Quote approval
    private static void stampQLIExchangeRatesOnApproval(List<Id> quoteIds) {
        // Query QLIs that need exchange rates stamped
        List<QuoteLineItem> qlisToUpdate = [
            SELECT Id, QuoteId, Quote.CurrencyIsoCode, Exchange_Rate__c
            FROM QuoteLineItem 
            WHERE QuoteId IN :quoteIds
            AND Exchange_Rate__c = null
            AND Quote.CurrencyIsoCode != null
        ];
        
        if (qlisToUpdate.isEmpty()) return;
        
        List<QuoteLineItem> finalQLIsToUpdate = new List<QuoteLineItem>();
        
        for (QuoteLineItem qli : qlisToUpdate) {
            // Get current exchange rate for the Quote's currency
            Decimal currentRate = ExchangeRateManager.getCurrentExchangeRate(qli.Quote.CurrencyIsoCode);
            
            if (currentRate != null) {
                qli.Exchange_Rate__c = currentRate;
                finalQLIsToUpdate.add(qli);
                
                System.debug(LoggingLevel.INFO, 
                    'GTM-138: Locked exchange rate ' + currentRate + 
                    ' on QLI ' + qli.Id + ' at Quote approval for currency ' + qli.Quote.CurrencyIsoCode);
            }
        }
        
        if (!finalQLIsToUpdate.isEmpty()) {
            update finalQLIsToUpdate;
        }
    }
}