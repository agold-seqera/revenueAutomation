// Invokable class for Quote sync operations
// Can be called from screen flows triggered by custom action buttons
public class QuoteSyncInvocable {
    
    // Input parameters for the invokable method
    public class SyncQuoteInput {
        @InvocableVariable(label='Quote ID' description='ID of the Quote to sync' required=true)
        public Id quoteId;
    }
    
    // Output parameters for the invokable method
    public class SyncQuoteOutput {
        @InvocableVariable(label='Success' description='Whether the sync was successful')
        public Boolean success;
        
        @InvocableVariable(label='Message' description='Result message')
        public String message;
        
        @InvocableVariable(label='Synced OLI Count' description='Number of OpportunityLineItems created')
        public Integer syncedOliCount;
    }
    
    // Invokable method to sync a quote to opportunity
    @InvocableMethod(label='Sync Quote to Opportunity' 
                     description='Syncs a Quote (Approved, Presented, or Accepted) to its related Opportunity and creates OpportunityLineItems'
                     category='Quote Management')
    public static List<SyncQuoteOutput> syncQuoteToOpportunity(List<SyncQuoteInput> inputs) {
        List<SyncQuoteOutput> results = new List<SyncQuoteOutput>();
        
        for (SyncQuoteInput input : inputs) {
            SyncQuoteOutput result = new SyncQuoteOutput();
            
            try {
                // Validate input
                if (input.quoteId == null) {
                    result.success = false;
                    result.message = 'Quote ID is required';
                    result.syncedOliCount = 0;
                    results.add(result);
                    continue;
                }
                
                // Get the quote with necessary fields
                Quote quote = getQuoteForSync(input.quoteId);
                
                if (quote == null) {
                    result.success = false;
                    result.message = 'Quote not found';
                    result.syncedOliCount = 0;
                    results.add(result);
                    continue;
                }
                
                // Validate quote can be synced
                String validationMessage = validateQuoteForSync(quote);
                if (validationMessage != null) {
                    result.success = false;
                    result.message = validationMessage;
                    result.syncedOliCount = 0;
                    results.add(result);
                    continue;
                }
                
                // Count QLIs before sync
                Integer qliCount = [SELECT COUNT() FROM QuoteLineItem WHERE QuoteId = :quote.Id];
                
                // Perform the sync
                QuoteSyncService.syncQuotesToOpportunities(new List<Quote>{quote});
                
                result.success = true;
                result.message = 'Quote successfully synced to opportunity';
                result.syncedOliCount = qliCount;
                
            } catch (Exception e) {
                result.success = false;
                result.message = 'Error during sync: ' + e.getMessage();
                result.syncedOliCount = 0;
                System.debug('QuoteSyncInvocable error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Get quote with all necessary fields for sync
    private static Quote getQuoteForSync(Id quoteId) {
        try {
            return [
                SELECT Id, Status, OpportunityId, IsSyncing, Synced_Quote__c,
                       Billing_Frequency__c, Contract_Signer__c, Contract_Start_Date__c,
                       Payment_Terms__c, Term_Length_Months__c
                FROM Quote 
                WHERE Id = :quoteId
                LIMIT 1
            ];
        } catch (QueryException e) {
            return null;
        }
    }
    
    // Validate that quote can be synced
    private static String validateQuoteForSync(Quote quote) {
        Set<String> validStatuses = new Set<String>{'Approved', 'Presented', 'Accepted'};
        
        if (!validStatuses.contains(quote.Status)) {
            return 'Quote must be Approved, Presented, or Accepted before syncing (Current Status: ' + quote.Status + ')';
        }
        
        if (quote.OpportunityId == null) {
            return 'Quote must be associated with an Opportunity';
        }
        
        if (quote.IsSyncing) {
            return 'Quote is currently being synced. Please wait for the current sync to complete.';
        }
        
        // Check if there are any QuoteLineItems
        Integer qliCount = [SELECT COUNT() FROM QuoteLineItem WHERE QuoteId = :quote.Id];
        if (qliCount == 0) {
            return 'Quote must have at least one Quote Line Item to sync';
        }
        
        return null; // No validation errors
    }
}