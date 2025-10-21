/**
 * Master orchestrator for sequential revenue automation batch processing
 * Scheduled to run at 12:15 AM EDT (04:15 UTC) daily
 * 
 * Execution Chain:
 * 1. AssetStatusBatch (Asset status updates)
 * 2. ContractRevenueBatch (Contract revenue calculations and status)  
 * 3. AccountRollupBatch (Account revenue rollups and status logic)
 */
public class RevenueAutomationBatchManager implements Schedulable {

    public void execute(SchedulableContext sc) {

        Database.executeBatch(new AssetStatusBatch(), 200);
        
        System.debug('RevenueAutomationBatchManager: Sequential revenue automation started');
        System.debug('Chain: AssetStatusBatch → ContractRevenueBatch → AccountRollupBatch');
    }
    
    // Utility method to schedule the daily revenue automation
    public static void scheduleDaily() {
        String cronExpression = '0 15 4 * * ?'; 
        
        // Remove any existing scheduled job with the same name
        List<CronTrigger> existingJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Revenue Automation - Sequential Processing'
            AND State != 'DELETED'
        ];
        
        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
        }
        
        // Schedule the new job
        System.schedule('Revenue Automation - Sequential Processing', 
                       cronExpression, 
                       new RevenueAutomationBatchManager());
        
        System.debug('RevenueAutomationBatchManager: Scheduled for daily execution at 04:15 UTC (12:15 AM EDT)');
    }
    
    // Utility method to manually trigger the sequential processing
    public static void executeNow() {
        Database.executeBatch(new AssetStatusBatch(), 200);
        System.debug('RevenueAutomationBatchManager: Manual execution started');
    }
    
    // Utility method to check the status of the sequential processing
    public static List<AsyncApexJob> getProcessingStatus() {
        return [
            SELECT Id, JobType, Status, JobItemsProcessed, TotalJobItems, 
                   CreatedDate, CompletedDate, ExtendedStatus, ApexClass.Name
            FROM AsyncApexJob 
            WHERE ApexClass.Name IN ('AssetStatusBatch', 'ContractRevenueBatch', 'AccountRollupBatch')
            AND CreatedDate = TODAY
            ORDER BY CreatedDate DESC
        ];
    }
}