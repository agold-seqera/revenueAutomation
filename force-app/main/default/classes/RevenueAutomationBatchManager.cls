/**
 * Master orchestrator for sequential revenue automation batch processing
 * Replaces the three scheduled flows with guaranteed sequential execution
 * 
 * Execution Chain:
 * 1. AssetStatusBatch (Asset status updates)
 * 2. ContractRevenueBatch (Contract revenue calculations and status)  
 * 3. AccountRollupBatch (Account revenue rollups and v42 status logic)
 * 
 * Scheduling:
 * - Scheduled to run at 12:15 AM EDT (04:15 UTC) daily
 * - Replaces the problematic 15-minute interval scheduled flows
 * - Ensures sequential execution with no timing conflicts
 */
public class RevenueAutomationBatchManager implements Schedulable {
    
    /**
     * Schedulable interface implementation
     * Triggered by System.schedule() for daily execution
     */
    public void execute(SchedulableContext sc) {
        // Start the sequential chain with Asset processing
        // Each batch will chain to the next one in its finish() method
        Database.executeBatch(new AssetStatusBatch(), 200);
        
        System.debug('RevenueAutomationBatchManager: Sequential revenue automation started');
        System.debug('Chain: AssetStatusBatch → ContractRevenueBatch → AccountRollupBatch');
    }
    
    /**
     * Utility method to schedule the daily revenue automation
     * Call this once to set up the scheduled job
     * 
     * Usage:
     * RevenueAutomationBatchManager.scheduleDaily();
     */
    public static void scheduleDaily() {
        // Schedule for 12:15 AM EDT daily (04:15 UTC)
        String cronExpression = '0 15 4 * * ?'; // Seconds Minutes Hours DayOfMonth Month DayOfWeek
        
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
    
    /**
     * Utility method to manually trigger the sequential processing
     * Useful for testing and immediate execution
     */
    public static void executeNow() {
        Database.executeBatch(new AssetStatusBatch(), 200);
        System.debug('RevenueAutomationBatchManager: Manual execution started');
    }
    
    /**
     * Utility method to check the status of the sequential processing
     * Returns information about running batch jobs
     */
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