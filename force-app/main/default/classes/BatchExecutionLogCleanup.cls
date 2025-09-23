/**
 * Scheduled job to clean up old Batch_Execution_Log__c records
 * Deletes records older than 10 days to prevent database clutter
 * 
 * Scheduling:
 * - Recommended to run daily at 2:00 AM UTC to avoid conflicts with revenue automation
 * - Use BatchExecutionLogCleanup.scheduleDaily() to set up the job
 * 
 * @author Revenue Automation Team
 * @date September 2025
 */
public class BatchExecutionLogCleanup implements Schedulable {
    
    // Number of days to retain log records
    private static final Integer RETENTION_DAYS = 10;
    
    /**
     * Schedulable interface implementation
     * Triggered by System.schedule() for daily execution
     */
    public void execute(SchedulableContext sc) {
        cleanupOldLogs();
    }
    
    /**
     * Main cleanup method - deletes Batch_Execution_Log__c records older than RETENTION_DAYS
     */
    public static void cleanupOldLogs() {
        try {
            // Calculate cutoff date (10 days ago)
            DateTime cutoffDate = DateTime.now().addDays(-RETENTION_DAYS);
            
            System.debug('BatchExecutionLogCleanup: Starting cleanup of records older than ' + cutoffDate);
            
            // Query old log records
            List<Batch_Execution_Log__c> oldLogs = [
                SELECT Id, CreatedDate, Contract_ID__c, Processing_Stage__c
                FROM Batch_Execution_Log__c 
                WHERE CreatedDate < :cutoffDate
                ORDER BY CreatedDate ASC
                LIMIT 10000  // Safety limit to prevent large deletions
            ];
            
            if (oldLogs.isEmpty()) {
                System.debug('BatchExecutionLogCleanup: No old records found to delete');
                return;
            }
            
            System.debug('BatchExecutionLogCleanup: Found ' + oldLogs.size() + ' records to delete');
            
            // Log some details about what's being deleted
            DateTime oldestDate = oldLogs[0].CreatedDate;
            DateTime newestDate = oldLogs[oldLogs.size() - 1].CreatedDate;
            System.debug('BatchExecutionLogCleanup: Deleting records from ' + oldestDate + ' to ' + newestDate);
            
            // Delete the records
            Database.DeleteResult[] deleteResults = Database.delete(oldLogs, false);
            
            // Process results and log any failures
            Integer successCount = 0;
            Integer failureCount = 0;
            
            for (Integer i = 0; i < deleteResults.size(); i++) {
                Database.DeleteResult result = deleteResults[i];
                if (result.isSuccess()) {
                    successCount++;
                } else {
                    failureCount++;
                    System.debug('BatchExecutionLogCleanup: Failed to delete record ' + oldLogs[i].Id + 
                               ' - Error: ' + result.getErrors()[0].getMessage());
                }
            }
            
            System.debug('BatchExecutionLogCleanup: Successfully deleted ' + successCount + ' records');
            if (failureCount > 0) {
                System.debug('BatchExecutionLogCleanup: Failed to delete ' + failureCount + ' records');
            }
            
        } catch (Exception e) {
            System.debug('BatchExecutionLogCleanup: ERROR during cleanup - ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * Utility method to schedule the daily cleanup job
     * Call this once to set up the scheduled job
     * 
     * Usage:
     * BatchExecutionLogCleanup.scheduleDaily();
     */
    public static void scheduleDaily() {
        // Schedule for 2:00 AM UTC daily (avoids conflict with revenue automation at 4:00 AM)
        String cronExpression = '0 0 2 * * ?'; // Seconds Minutes Hours DayOfMonth Month DayOfWeek
        
        // Remove any existing scheduled job with the same name
        List<CronTrigger> existingJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Batch Execution Log Cleanup - Daily'
            AND State != 'DELETED'
        ];
        
        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
            System.debug('BatchExecutionLogCleanup: Aborted existing scheduled job: ' + job.Id);
        }
        
        // Schedule the new job
        String jobId = System.schedule('Batch Execution Log Cleanup - Daily', 
                                     cronExpression, 
                                     new BatchExecutionLogCleanup());
        
        System.debug('BatchExecutionLogCleanup: Scheduled for daily execution at 02:00 UTC');
        System.debug('BatchExecutionLogCleanup: Job ID: ' + jobId);
        System.debug('BatchExecutionLogCleanup: Will delete records older than ' + RETENTION_DAYS + ' days');
    }
    
    /**
     * Utility method to manually trigger the cleanup
     * Useful for testing and immediate execution
     */
    public static void executeNow() {
        cleanupOldLogs();
    }
    
    /**
     * Utility method to check how many records would be deleted
     * Useful for monitoring and planning
     */
    public static Integer getRecordCountForCleanup() {
        DateTime cutoffDate = DateTime.now().addDays(-RETENTION_DAYS);
        AggregateResult result = [SELECT COUNT(Id) recordCount FROM Batch_Execution_Log__c WHERE CreatedDate < :cutoffDate];
        return (Integer) result.get('recordCount');
    }
    
    /**
     * Utility method to get the oldest record date
     * Useful for monitoring retention
     */
    public static DateTime getOldestRecordDate() {
        AggregateResult result = [
            SELECT MIN(CreatedDate) oldestDate 
            FROM Batch_Execution_Log__c
        ];
        
        if (result.get('oldestDate') == null) {
            return null;
        }
        
        return (DateTime) result.get('oldestDate');
    }
}
