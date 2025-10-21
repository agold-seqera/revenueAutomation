public class AssetTriggerHandler {
    
    public static void handleTrigger() {
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            handleBeforeSave();
        }
    }

    private static void handleBeforeSave() {
        assignExchangeRatesFromOLI(Trigger.new);
    }
    
    private static void assignExchangeRatesFromOLI(List<Asset> assets) {
        Set<Id> oliIds = new Set<Id>();
        
        for (Asset asset : assets) {
            if (asset.Originating_OLI__c != null) {
                oliIds.add(asset.Originating_OLI__c);
            }
        }
        
        if (oliIds.isEmpty()) {
            return; 
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
                        'Assigned exchange rate ' + relatedOLI.Exchange_Rate__c + 
                        ' to Asset from OLI ' + asset.Originating_OLI__c);
                }
            }
        }
    }
}