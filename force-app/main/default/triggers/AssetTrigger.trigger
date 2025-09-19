/**
 * GTM-138: Asset trigger for exchange rate inheritance
 * Ensures Assets inherit Exchange_Rate__c from related OpportunityLineItems
 * 
 * @author Alex Goldstein / Syl Architecture
 * @date September 2025
 */
trigger AssetTrigger on Asset (before insert, before update) {
    AssetTriggerHandler.handleTrigger();
}