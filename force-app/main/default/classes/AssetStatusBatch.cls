/**
 * Batch class to replace Scheduled_Flow_Daily_Update_Assets
 * Replicates EXACT flow business logic for asset status updates
 * 
 * Flow Logic Replicated:
 * - Processes assets with Status = 'Purchased' OR 'Active'
 * - Updates to 'Active' if: Start_Date__c <= TODAY AND End_Date__c >= TODAY 
 *   AND Status != 'Active' AND Status != 'Cancelled' AND Exclude_from_Status_Updates__c = false
 * - Updates to 'Inactive' if: Start_Date__c < TODAY AND End_Date__c < TODAY
 *   AND Status != 'Inactive' AND Status != 'Cancelled' AND Exclude_from_Status_Updates__c = false
 */
public class AssetStatusBatch implements Database.Batchable<sObject>, Schedulable {
    
    /**
     * Query assets matching exact flow criteria:
     * Status = 'Purchased' OR Status = 'Active'
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status, Start_Date__c, End_Date__c, Exclude_from_Status_Updates__c
            FROM Asset 
            WHERE (Status = 'Purchased' OR Status = 'Active')
        ]);
    }
    
    /**
     * Process each batch of assets using exact flow decision logic
     */
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
        
        // Bulk update - matches flow's Update_Asset element
        if (!assetsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(assetsToUpdate, false);
                
                // Log any failures (flow would fail silently)
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
    
    /**
     * Chain to Contract processing after Asset processing completes
     */
    public void finish(Database.BatchableContext bc) {
        // Sequential execution: Asset → Contract → Account
        Database.executeBatch(new ContractRevenueBatch(), 50);
        System.debug('AssetStatusBatch: Processing complete, chaining to ContractRevenueBatch');
    }
    
    /**
     * Schedulable interface - allows this to be scheduled
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200); // Process 200 assets per batch
    }
    
    /**
     * Replicate exact flow decision logic for asset status determination
     * 
     * Flow Decision 1: Should_Asset_be_Active
     * Conditions (ALL must be true):
     * - Start_Date__c <= TODAY
     * - End_Date__c >= TODAY  
     * - Status != 'Active'
     * - Status != 'Cancelled'
     * - Exclude_from_Status_Updates__c = false
     * 
     * Flow Decision 2: Should_Asset_be_Inactive  
     * Conditions (ALL must be true):
     * - Start_Date__c < TODAY
     * - End_Date__c < TODAY
     * - Status != 'Inactive'
     * - Status != 'Cancelled'
     * - Exclude_from_Status_Updates__c = false
     */
    private String determineAssetStatus(Asset asset, Date today) {
        // Skip if excluded from status updates
        if (asset.Exclude_from_Status_Updates__c == true) {
            return null; // No change
        }
        
        // Skip if already cancelled
        if (asset.Status == 'Cancelled') {
            return null; // No change
        }
        
        // Flow Decision 1: Should_Asset_be_Active
        if (asset.Start_Date__c <= today && 
            asset.End_Date__c >= today && 
            asset.Status != 'Active' && 
            asset.Status != 'Cancelled') {
            return 'Active';
        }
        
        // Flow Decision 2: Should_Asset_be_Inactive
        if (asset.Start_Date__c < today && 
            asset.End_Date__c < today && 
            asset.Status != 'Inactive' && 
            asset.Status != 'Cancelled') {
            return 'Inactive';
        }
        
        // Default: No change needed
        return null;
    }
}