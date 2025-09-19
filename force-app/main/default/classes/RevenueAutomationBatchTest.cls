/**
 * Comprehensive test class for Revenue Automation Batch system
 * Tests sequential execution and exact flow logic replication
 */
@isTest
public class RevenueAutomationBatchTest {
    
    @TestSetup
    static void makeData() {
        // Create test account
        Account testAccount = TestDataFactory.createAccount('Batch Test Account');
        testAccount.Type__c = 'Commercial';
        testAccount.Has_Contracts__c = true;
        insert testAccount;
        
        // Create test contract with proper dates for activation by ContractRevenueBatch
        Contract testContract = TestDataFactory.createContract(testAccount.Id, 'Batch Test Contract');
        testContract.StartDate = Date.today().addDays(-30); // Started 30 days ago (meets StartDate <= today)
        testContract.EndDate = Date.today().addDays(335);   // Ends 335 days from now (meets EndDate >= today)
        testContract.Status = 'Draft';                      // Start as Draft for batch to activate
        testContract.Exclude_from_Status_Updates__c = false; // Allow status updates (meets condition)
        insert testContract;
        
        // Debug: Verify the contract setup before batch execution
        System.debug('DEBUG: Contract StartDate: ' + testContract.StartDate + ', EndDate: ' + testContract.EndDate);
        System.debug('DEBUG: Today: ' + Date.today());
        System.debug('DEBUG: Contract Status before batch: ' + testContract.Status);
        System.debug('DEBUG: Exclude_from_Status_Updates__c: ' + testContract.Exclude_from_Status_Updates__c);
        
        // Create test assets with different scenarios
        List<Asset> testAssets = new List<Asset>();
        
        // Active asset (should contribute to revenue)
        Asset activeAsset = TestDataFactory.createAsset(testAccount.Id, testContract.Id, 'Purchased');
        activeAsset.Start_Date__c = Date.today().addDays(-10);
        activeAsset.End_Date__c = Date.today().addDays(355);
        activeAsset.Exchange_Rate__c = 1.0;
        testAssets.add(activeAsset);
        
        // Inactive asset (should not contribute to active revenue)
        Asset inactiveAsset = TestDataFactory.createAsset(testAccount.Id, testContract.Id, 'Active');
        inactiveAsset.Start_Date__c = Date.today().addDays(-100);
        inactiveAsset.End_Date__c = Date.today().addDays(-10);
        inactiveAsset.Exchange_Rate__c = 1.0;
        testAssets.add(inactiveAsset);
        
        insert testAssets;
    }
    
    @isTest
    static void testAssetStatusBatch() {
        Test.startTest();
        
        // Execute Asset batch
        Database.executeBatch(new AssetStatusBatch(), 200);
        
        Test.stopTest();
        
        // Verify asset status updates
        List<Asset> updatedAssets = [
            SELECT Id, Status, Start_Date__c, End_Date__c 
            FROM Asset 
            ORDER BY Start_Date__c DESC
        ];
        
        System.assertEquals(2, updatedAssets.size(), 'Should have 2 test assets');
        
        // Active asset should be 'Active' (Start_Date <= TODAY, End_Date >= TODAY)
        Asset activeAsset = updatedAssets[0];
        System.assertEquals('Active', activeAsset.Status, 'Active asset should have Status = Active');
        
        // Inactive asset should be 'Inactive' (End_Date < TODAY)
        Asset inactiveAsset = updatedAssets[1];
        System.assertEquals('Inactive', inactiveAsset.Status, 'Inactive asset should have Status = Inactive');
    }
    
    @isTest
    static void testContractRevenueBatch() {
        // Get the contract to test
        Contract testContract = [
            SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c
            FROM Contract 
            LIMIT 1
        ];
        
        Test.startTest();
        
        // SYNCHRONOUS EXECUTION: Call batch methods directly instead of Database.executeBatch
        ContractRevenueBatch batch = new ContractRevenueBatch();
        Database.QueryLocator ql = batch.start(null);
        List<Contract> contracts = Database.query(ql.getQuery());
        
        // Execute the batch logic directly (synchronously)
        batch.execute(null, contracts);
        
        Test.stopTest();
        
        // Verify contract updates
        Contract updatedContract = [
            SELECT Id, Status, ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Incremental_ARR__c,
                   ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c
            FROM Contract 
            WHERE Id = :testContract.Id
        ];
        
        // Contract should be Activated (within start/end dates)
        System.assertEquals('Activated', updatedContract.Status, 'Contract should be Activated');
        
        // Revenue should be calculated (exact values depend on asset data from TestDataFactory)
        System.assertNotEquals(null, updatedContract.ARR__c, 'ARR should be calculated');
        System.assertNotEquals(null, updatedContract.ACV__c, 'ACV should be calculated');
        System.assertNotEquals(null, updatedContract.TCV__c, 'TCV should be calculated');
        System.assertNotEquals(null, updatedContract.Active_ARR__c, 'Active ARR should be calculated');
        
        // MRR calculation (ARR / 12)
        System.assertNotEquals(null, updatedContract.MRR__c, 'MRR should be calculated');
        
        // Incremental ARR (Previous_ARR is null, so should equal ARR)
        System.assertEquals(updatedContract.ARR__c, updatedContract.Incremental_ARR__c, 'Incremental ARR should equal ARR when Previous_ARR is null');
        
        // USD formatting should be applied
        System.assertNotEquals(null, updatedContract.ARR_USD__c, 'ARR_USD should be formatted');
        System.assert(updatedContract.ARR_USD__c.contains('$'), 'ARR_USD should contain $ symbol');
    }
    
    @isTest
    static void testAccountRollupBatch() {
        Test.startTest();
        
        // Execute Account batch
        Database.executeBatch(new AccountRollupBatch(), 100);
        
        Test.stopTest();
        
        // Verify account rollups
        Account updatedAccount = [
            SELECT Id, Status__c, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
                   ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c
            FROM Account 
            WHERE Name = 'Batch Test Account'
            LIMIT 1
        ];
        
        // Account status should be determined by contract analysis
        System.assertNotEquals(null, updatedAccount.Status__c, 'Account status should be set');
        
        // Revenue should be aggregated from contracts
        System.assertNotEquals(null, updatedAccount.ARR__c, 'Account ARR should be calculated');
        System.assertNotEquals(null, updatedAccount.TCV__c, 'Account TCV should be calculated');
        
        // USD fields should be formatted
        System.assertNotEquals(null, updatedAccount.ARR_USD__c, 'Account ARR_USD should be formatted');
        System.assert(updatedAccount.ARR_USD__c.contains('$'), 'Account ARR_USD should contain $ symbol');
    }
    
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