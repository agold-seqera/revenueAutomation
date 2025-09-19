/**
 * Helper class for QuoteLineItem billing calculations
 * Handles formula field access limitations in Before Save flows
 */
public class QuoteLineItemCalculationHelper {
    
    /**
     * Calculate prorated billing amount for QuoteLineItems
     * Uses existing formula fields that Flow cannot access in Before Save context
     * Populates Alex's existing Total_Price__c field with calculated values
     * 
     * @param quoteLineItemIds List of QuoteLineItem IDs to calculate billing for
     * @return List of calculated billing amounts (Decimal)
     */
    @InvocableMethod(
        label='Calculate Prorated Billing Amount' 
        description='Calculates billing amount using Annual_Amount__c and service period formula fields'
    )
    public static List<Decimal> calculateBillingAmount(List<Id> quoteLineItemIds) {
        
        // Query QuoteLineItems with required fields (including formula fields)
        List<QuoteLineItem> qlis = [
            SELECT Id, 
                   Annual_Amount__c, 
                   Service_Period_Days__c, 
                   Days_In_Service_Year__c,
                   Product_Family__c
            FROM QuoteLineItem 
            WHERE Id IN :quoteLineItemIds
        ];
        
        List<Decimal> results = new List<Decimal>();
        
        for (QuoteLineItem qli : qlis) {
            Decimal billingAmount = 0;
            
            // Only calculate for Software Subscriptions with valid data
            if (qli.Product_Family__c == 'Software Subscriptions' &&
                qli.Annual_Amount__c != null && 
                qli.Service_Period_Days__c != null && 
                qli.Days_In_Service_Year__c != null &&
                qli.Days_In_Service_Year__c > 0) {
                
                // Calculate prorated amount: Annual × (ServiceDays / DaysInYear)
                billingAmount = qli.Annual_Amount__c * (qli.Service_Period_Days__c / qli.Days_In_Service_Year__c);
                
            } else if (qli.Product_Family__c != 'Software Subscriptions') {
                // For non-subscriptions, return 0 (Flow will handle differently)
                billingAmount = 0;
            }
            
            results.add(billingAmount);
        }
        
        return results;
    }
    
    /**
     * Get the "Standard Price Book" pricebook ID
     * Uses specific pricebook ID: 01sfJ00000063T3QAI
     * 
     * @return Id of the Standard Price Book pricebook
     */
    public static Id getStandardPriceBookId() {
        return '01sfJ00000063T3QAI';
    }
}