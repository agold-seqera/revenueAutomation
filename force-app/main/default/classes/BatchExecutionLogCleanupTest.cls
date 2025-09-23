/**
 * Test class for BatchExecutionLogCleanup
 * Tests the scheduled cleanup functionality for Batch_Execution_Log__c records
 * 
 * @author Revenue Automation Team
 * @date September 2025
 */
@IsTest
private class BatchExecutionLogCleanupTest {
    
    /**
     * Test the main cleanup functionality
     */
    @IsTest
    static void testCleanupOldLogs() {
        // Create test data - mix of old and recent records
        List<Batch_Execution_Log__c> testLogs = new List<Batch_Execution_Log__c>();
        
        // Create 5 old records (15 days old - should be deleted)
        for (Integer i = 0; i < 5; i++) {
            Batch_Execution_Log__c oldLog = new Batch_Execution_Log__c(
                Contract_ID__c = 'testcontract00' + i,
                Processing_Stage__c = 'PROCESSED',
                Execution_Context__c = 'SCHEDULED',
                Batch_Job_ID__c = 'testjob00' + i
            );
            testLogs.add(oldLog);
        }
        
        // Create 3 recent records (5 days old - should be kept)
        for (Integer i = 0; i < 3; i++) {
            Batch_Execution_Log__c recentLog = new Batch_Execution_Log__c(
                Contract_ID__c = 'recentcontract00' + i,
                Processing_Stage__c = 'UPDATED',
                Execution_Context__c = 'MANUAL',
                Batch_Job_ID__c = 'recentjob00' + i
            );
            testLogs.add(recentLog);
        }
        
        insert testLogs;
        
        // Manually set CreatedDate for old records using a test utility
        Test.setCreatedDate(testLogs[0].Id, DateTime.now().addDays(-15));
        Test.setCreatedDate(testLogs[1].Id, DateTime.now().addDays(-15));
        Test.setCreatedDate(testLogs[2].Id, DateTime.now().addDays(-15));
        Test.setCreatedDate(testLogs[3].Id, DateTime.now().addDays(-15));
        Test.setCreatedDate(testLogs[4].Id, DateTime.now().addDays(-15));
        
        // Verify initial state
        Integer initialCount = [SELECT COUNT() FROM Batch_Execution_Log__c];
        System.assertEquals(8, initialCount, 'Should have 8 test records initially');
        
        Test.startTest();
        
        // Execute the cleanup
        BatchExecutionLogCleanup.cleanupOldLogs();
        
        Test.stopTest();
        
        // Verify results - should have deleted 5 old records, kept 3 recent ones
        List<Batch_Execution_Log__c> remainingLogs = [SELECT Id, Contract_ID__c FROM Batch_Execution_Log__c];
        System.assertEquals(3, remainingLogs.size(), 'Should have 3 records remaining after cleanup');
        
        // Verify that only recent records remain
        Set<String> remainingContractIds = new Set<String>();
        for (Batch_Execution_Log__c log : remainingLogs) {
            remainingContractIds.add(log.Contract_ID__c);
        }
        
        // All remaining records should be the recent ones
        for (String contractId : remainingContractIds) {
            System.assert(contractId.startsWith('recentcontract'), 
                         'Only recent contract logs should remain: ' + contractId);
        }
    }
    
    /**
     * Test the schedulable interface
     */
    @IsTest
    static void testSchedulableExecution() {
        // Create one old record for testing
        Batch_Execution_Log__c oldLog = new Batch_Execution_Log__c(
            Contract_ID__c = 'scheduletest001',
            Processing_Stage__c = 'FAILED',
            Execution_Context__c = 'SCHEDULED'
        );
        insert oldLog;
        
        // Set it to be old
        Test.setCreatedDate(oldLog.Id, DateTime.now().addDays(-15));
        
        Test.startTest();
        
        // Test the schedulable interface
        BatchExecutionLogCleanup cleanup = new BatchExecutionLogCleanup();
        String jobId = System.schedule('Test Cleanup Job', 
                                     '0 0 2 * * ?', 
                                     cleanup);
        
        // Verify job was scheduled
        System.assert(jobId != null, 'Job should be scheduled successfully');
        
        // Execute the scheduled job manually for testing
        cleanup.execute(null);
        
        Test.stopTest();
        
        // Verify the old record was deleted
        List<Batch_Execution_Log__c> remainingLogs = [SELECT Id FROM Batch_Execution_Log__c];
        System.assertEquals(0, remainingLogs.size(), 'Old record should be deleted by scheduled job');
    }
    
    /**
     * Test utility methods
     */
    @IsTest
    static void testUtilityMethods() {
        // Create test data
        List<Batch_Execution_Log__c> testLogs = new List<Batch_Execution_Log__c>();
        
        // Create 2 old records and 2 recent records
        for (Integer i = 0; i < 4; i++) {
            Batch_Execution_Log__c log = new Batch_Execution_Log__c(
                Contract_ID__c = 'utiltest00' + i,
                Processing_Stage__c = 'PROCESSED'
            );
            testLogs.add(log);
        }
        
        insert testLogs;
        
        // Make 2 of them old
        Test.setCreatedDate(testLogs[0].Id, DateTime.now().addDays(-15));
        Test.setCreatedDate(testLogs[1].Id, DateTime.now().addDays(-15));
        
        Test.startTest();
        
        // Test getRecordCountForCleanup
        Integer countForCleanup = BatchExecutionLogCleanup.getRecordCountForCleanup();
        System.assertEquals(2, countForCleanup, 'Should find 2 records for cleanup');
        
        // Test getOldestRecordDate
        DateTime oldestDate = BatchExecutionLogCleanup.getOldestRecordDate();
        System.assert(oldestDate != null, 'Should find oldest record date');
        
        // Test executeNow method
        BatchExecutionLogCleanup.executeNow();
        
        Test.stopTest();
        
        // Verify cleanup worked
        List<Batch_Execution_Log__c> remainingLogs = [SELECT Id FROM Batch_Execution_Log__c];
        System.assertEquals(2, remainingLogs.size(), 'Should have 2 recent records remaining');
    }
    
    /**
     * Test empty database scenario
     */
    @IsTest
    static void testEmptyDatabase() {
        // No test data created
        
        Test.startTest();
        
        // Test cleanup with no records
        BatchExecutionLogCleanup.cleanupOldLogs();
        
        // Test utility methods with no records
        Integer countForCleanup = BatchExecutionLogCleanup.getRecordCountForCleanup();
        System.assertEquals(0, countForCleanup, 'Should find 0 records for cleanup in empty database');
        
        DateTime oldestDate = BatchExecutionLogCleanup.getOldestRecordDate();
        System.assertEquals(null, oldestDate, 'Should return null for oldest date in empty database');
        
        Test.stopTest();
        
        // Should complete without errors
        System.assertEquals(0, [SELECT COUNT() FROM Batch_Execution_Log__c], 'Database should remain empty');
    }
    
    /**
     * Test scheduleDaily method
     */
    @IsTest
    static void testScheduleDaily() {
        Test.startTest();
        
        // Test scheduling the daily job
        BatchExecutionLogCleanup.scheduleDaily();
        
        // Verify job was scheduled
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name, CronExpression, State
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Batch Execution Log Cleanup - Daily'
            AND State != 'DELETED'
        ];
        
        System.assertEquals(1, scheduledJobs.size(), 'Should have one scheduled job');
        System.assertEquals('0 0 2 * * ?', scheduledJobs[0].CronExpression, 'Should be scheduled for 2 AM UTC');
        
        // Test scheduling again (should replace existing job)
        BatchExecutionLogCleanup.scheduleDaily();
        
        Test.stopTest();
        
        // Should still have only one active job
        List<CronTrigger> finalJobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Batch Execution Log Cleanup - Daily'
            AND State != 'DELETED'
        ];
        
        System.assertEquals(1, finalJobs.size(), 'Should still have only one active scheduled job');
    }
    
    /**
     * Test large dataset handling (safety limit)
     */
    @IsTest
    static void testLargeDatasetSafetyLimit() {
        // Create the maximum number of test records we can (limited by DML limits in test context)
        List<Batch_Execution_Log__c> testLogs = new List<Batch_Execution_Log__c>();
        
        // Create 200 old records to test the safety limit
        for (Integer i = 0; i < 200; i++) {
            Batch_Execution_Log__c log = new Batch_Execution_Log__c(
                Contract_ID__c = 'largetest' + String.valueOf(i).leftPad(3, '0'),
                Processing_Stage__c = 'PROCESSED'
            );
            testLogs.add(log);
        }
        
        insert testLogs;
        
        // Make all of them old
        for (Batch_Execution_Log__c log : testLogs) {
            Test.setCreatedDate(log.Id, DateTime.now().addDays(-15));
        }
        
        Test.startTest();
        
        // Execute cleanup
        BatchExecutionLogCleanup.cleanupOldLogs();
        
        Test.stopTest();
        
        // All records should be deleted (within the 10000 safety limit)
        List<Batch_Execution_Log__c> remainingLogs = [SELECT Id FROM Batch_Execution_Log__c];
        System.assertEquals(0, remainingLogs.size(), 'All old records should be deleted');
    }
}
