// GTM-138: Asset Trigger Handler - Exchange Rate Management
// 
// Handles Asset trigger operations for exchange rate inheritance from OpportunityLineItems.
// This ensures consistent exchange rates across the Quote → Opportunity → Asset workflow.
// 
// @author Alex Goldstein / Syl Architecture
// @date September 2025
// @version 1.0
public class AssetTriggerHandler {
    
    // Main trigger handler entry point
    // Routes to appropriate handler methods based on trigger context
    public static void handleTrigger() {
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            handleBeforeSave();
        }
    }
    
    // Handle before insert and before update operations
    // Assigns exchange rates from related OpportunityLineItems
    private static void handleBeforeSave() {
        assignExchangeRatesFromOLI(Trigger.new);
    }
    
    // GTM-138: Assign Exchange_Rate__c to Assets from related OpportunityLineItems
    // Called during Asset creation/update to ensure consistent exchange rates across Quote-Opportunity-Asset flow
    // 
    // @param assets List of Asset records being processed
    private static void assignExchangeRatesFromOLI(List<Asset> assets) {
        // Collect OpportunityLineItem IDs from Assets that reference them
        Set<Id> oliIds = new Set<Id>();
        
        for (Asset asset : assets) {
            if (asset.Originating_OLI__c != null) {
                oliIds.add(asset.Originating_OLI__c);
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
        
        // Assign exchange rates to Assets
        for (Asset asset : assets) {
            if (asset.Originating_OLI__c != null && asset.Exchange_Rate__c == null) {
                OpportunityLineItem relatedOLI = oliMap.get(asset.Originating_OLI__c);
                if (relatedOLI != null && relatedOLI.Exchange_Rate__c != null) {
                    asset.Exchange_Rate__c = relatedOLI.Exchange_Rate__c;
                    
                    System.debug(LoggingLevel.INFO, 
                        'GTM-138: Assigned exchange rate ' + relatedOLI.Exchange_Rate__c + 
                        ' to Asset from OLI ' + asset.Originating_OLI__c);
                }
            }
        }
    }
}