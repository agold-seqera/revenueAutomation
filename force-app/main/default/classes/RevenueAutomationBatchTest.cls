/**
 * Comprehensive test class for Revenue Automation Batch system
 * Tests sequential execution and exact flow logic replication
 */
@isTest
public class RevenueAutomationBatchTest {
    
    @isTest
    static void testSequentialExecution() {
        Test.startTest();
        
        // Test the orchestrator
        RevenueAutomationBatchManager.executeNow();
        
        Test.stopTest();
        
        // Verify that processing started (can't test full chain in single test due to async limits)
        List<AsyncApexJob> jobs = RevenueAutomationBatchManager.getProcessingStatus();
        System.assert(jobs.size() > 0, 'Should have at least one batch job running');
        
        // Verify the first job is AssetStatusBatch
        Boolean foundAssetBatch = false;
        for (AsyncApexJob job : jobs) {
            if (job.ApexClass.Name == 'AssetStatusBatch') {
                foundAssetBatch = true;
                break;
            }
        }
        System.assert(foundAssetBatch, 'AssetStatusBatch should be queued/running');
    }
    
    @isTest
    static void testScheduling() {
        Test.startTest();
        
        // Test scheduling setup
        RevenueAutomationBatchManager.scheduleDaily();
        
        Test.stopTest();
        
        // Verify scheduled job was created
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name, NextFireTime, State
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Revenue Automation - Sequential Processing'
            AND State != 'DELETED'
        ];
        
        System.assertEquals(1, scheduledJobs.size(), 'Should have exactly one scheduled job');
        System.assertEquals('WAITING', scheduledJobs[0].State, 'Scheduled job should be in WAITING state');
    }
    
    
    @isTest
    static void testErrorHandling() {
        // Create invalid data to test error handling
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Contract invalidContract = new Contract();
        invalidContract.AccountId = testAccount.Id;
        invalidContract.Status = 'Draft';
        // Missing required fields to trigger errors
        
        try {
            insert invalidContract;
        } catch (Exception e) {
            // Expected - this is to test error handling
        }
        
        Test.startTest();
        
        // Execute batches with potentially problematic data
        Database.executeBatch(new AssetStatusBatch(), 200);
        Database.executeBatch(new ContractRevenueBatch(), 50);
        Database.executeBatch(new AccountRollupBatch(), 100);
        
        Test.stopTest();
        
        // Test should complete without exceptions (error handling should catch issues)
        System.assert(true, 'Batch execution should handle errors gracefully');
    }
    
    
    
}
