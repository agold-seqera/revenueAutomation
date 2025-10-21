/**
 * Status Logic:
 * - Processes assets with Status = 'Purchased' OR 'Active'
 * - Updates to 'Active' if: Start_Date__c <= TODAY AND End_Date__c >= TODAY 
 *   AND Status != 'Active' AND Status != 'Cancelled' AND Exclude_from_Status_Updates__c = false
 * - Updates to 'Inactive' if: Start_Date__c < TODAY AND End_Date__c < TODAY
 *   AND Status != 'Inactive' AND Status != 'Cancelled' AND Exclude_from_Status_Updates__c = false
 */
public class AssetStatusBatch implements Database.Batchable<sObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status, Start_Date__c, End_Date__c, Exclude_from_Status_Updates__c
            FROM Asset 
            WHERE (Status = 'Purchased' OR Status = 'Active')
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Asset> assets) {
        List<Asset> assetsToUpdate = new List<Asset>();
        Date today = Date.today();
        
        for (Asset asset : assets) {
            String newStatus = determineAssetStatus(asset, today);
            
            if (newStatus != null && newStatus != asset.Status) {
                asset.Status = newStatus;
                assetsToUpdate.add(asset);
            }
        }
        
        if (!assetsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(assetsToUpdate, false);
                
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        System.debug(LoggingLevel.ERROR, 
                            'AssetStatusBatch: Failed to update Asset ' + assetsToUpdate[i].Id + 
                            ': ' + results[i].getErrors());
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'AssetStatusBatch: Exception during update: ' + e.getMessage());
            }
        }
    }
    
    // Chain to Contract processing after Asset processing completes
    public void finish(Database.BatchableContext bc) {
        Database.executeBatch(new ContractRevenueBatch(), 50);
        System.debug('AssetStatusBatch: Processing complete, chaining to ContractRevenueBatch');
    }
    
    // Schedulable interface - allows this to be scheduled
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200); // Process 200 assets per batch
    }
    
    private String determineAssetStatus(Asset asset, Date today) {
        // Skip if excluded from status updates
        if (asset.Exclude_from_Status_Updates__c == true) {
            return null; 
        }
        
        // Skip if cancelled
        if (asset.Status == 'Cancelled') {
            return null; 
        }
        
        // Should Asset be Active
        if (asset.Start_Date__c <= today && 
            asset.End_Date__c >= today && 
            asset.Status != 'Active' && 
            asset.Status != 'Cancelled') {
            return 'Active';
        }
        
        // Should Asset be Inactive
        else if (asset.Start_Date__c < today && 
            asset.End_Date__c < today && 
            asset.Status != 'Inactive' && 
            asset.Status != 'Cancelled') {
            return 'Inactive';
        }
        
        // Default: No change needed
        else {
            return null;
        }
    }
}