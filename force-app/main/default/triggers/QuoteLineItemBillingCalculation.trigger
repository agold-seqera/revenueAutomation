/**
 * Trigger for QuoteLineItem billing calculation
 * Replaces Flow C due to Before Save flow limitation with Apex Actions
 * 
 * Uses proper trigger handler pattern for maintainability
 */
trigger QuoteLineItemBillingCalculation on QuoteLineItem (before insert, before update, after insert, after update, after delete, after undelete) {
    QuoteLineItemTriggerHandler.handleTrigger();
}