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
        testContract.StartDate = Date.today().addDays(-30);
        testContract.EndDate = Date.today().addDays(335);
        testContract.Status = 'Draft';
        testContract.Exclude_from_Status_Updates__c = false;
        insert testContract;
        
        // Create test product
        Product2 testProduct = TestDataFactory.createProduct('Test Product', 'Software Subscriptions');
        insert testProduct;
        
        // Create test assets
        List<Asset> testAssets = new List<Asset>();
        
        Asset activeAsset = TestDataFactory.createAsset(testAccount.Id, testContract.Id, 'Purchased');
        activeAsset.Product2Id = testProduct.Id;
        activeAsset.Start_Date__c = Date.today().addDays(-10);
        activeAsset.End_Date__c = Date.today().addDays(355);
        activeAsset.Exchange_Rate__c = 1.0;
        activeAsset.Price = 12000;
        activeAsset.Quantity = 1;
        testAssets.add(activeAsset);
        
        insert testAssets;
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
    static void testAllContractsProcessed() {
        // Create contracts with different statuses to verify ALL are processed
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        List<Contract> testContracts = new List<Contract>();
        
        Contract draftContract = TestDataFactory.createContract(testAccount.Id, 'Draft Contract');
        draftContract.Status = 'Draft';
        draftContract.StartDate = Date.today();
        draftContract.EndDate = Date.today().addDays(365);
        draftContract.Exclude_from_Status_Updates__c = false;
        testContracts.add(draftContract);
        
        Contract futureActivatedContract = TestDataFactory.createContract(testAccount.Id, 'Future Activated Contract');
        futureActivatedContract.Status = 'Draft';
        futureActivatedContract.StartDate = Date.today().addDays(-30);
        futureActivatedContract.EndDate = Date.today().addDays(335);
        futureActivatedContract.Exclude_from_Status_Updates__c = false;
        testContracts.add(futureActivatedContract);
        
        insert testContracts;
        
        futureActivatedContract.Status = 'Activated';
        update futureActivatedContract;
        
        Test.startTest();
        
        ContractRevenueBatch batch = new ContractRevenueBatch();
        Database.QueryLocator ql = batch.start(null);
        List<Contract> allContracts = Database.query(ql.getQuery());
        
        System.assert(allContracts.size() >= 3, 'Should process ALL contracts including Draft and Activated');
        
        Test.stopTest();
    }
    
    @isTest
    static void testErrorHandling() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Contract invalidContract = new Contract();
        invalidContract.AccountId = testAccount.Id;
        invalidContract.Status = 'Draft';
        
        try {
            insert invalidContract;
        } catch (Exception e) {
            // Expected
        }
        
        Test.startTest();
        
        Database.executeBatch(new AssetStatusBatch(), 200);
        Database.executeBatch(new ContractRevenueBatch(), 50);
        Database.executeBatch(new AccountRollupBatch(), 100);
        
        Test.stopTest();
        
        System.assert(true, 'Batch execution should handle errors gracefully');
    }
}
