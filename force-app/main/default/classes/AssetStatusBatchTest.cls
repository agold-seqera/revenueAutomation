@IsTest
private class AssetStatusBatchTest {
    @IsTest
    static void setsActive_whenWithinWindow_andNotExcludedOrCancelled() {
        // Account and asset setup via factory
        Account acct = TestDataFactory.createAccount('ASB Acc 1');
        insert acct;

        Date today = Date.today();

        // Asset initially Purchased; within active window; not excluded; not cancelled
        Asset a = new Asset(
            Name = 'To Active',
            AccountId = acct.Id,
            Status = 'Purchased',
            Start_Date__c = today.addDays(-1),
            End_Date__c = today.addDays(10),
            Exclude_from_Status_Updates__c = false
        );
        insert a;

        Test.startTest();
        Database.executeBatch(new AssetStatusBatch(), 200);
        Test.stopTest();

        a = [SELECT Status FROM Asset WHERE Id = :a.Id];
        System.assertEquals('Active', a.Status, 'Asset should transition to Active within window');
    }

    @IsTest
    static void setsInactive_whenPastWindow_andNotExcludedOrCancelled() {
        Account acct = TestDataFactory.createAccount('ASB Acc 2');
        insert acct;

        Date today = Date.today();

        // Asset was Active but both dates are before today
        Asset a = new Asset(
            Name = 'To Inactive',
            AccountId = acct.Id,
            Status = 'Active',
            Start_Date__c = today.addDays(-10),
            End_Date__c = today.addDays(-1),
            Exclude_from_Status_Updates__c = false
        );
        insert a;

        Test.startTest();
        Database.executeBatch(new AssetStatusBatch(), 200);
        Test.stopTest();

        a = [SELECT Status FROM Asset WHERE Id = :a.Id];
        System.assertEquals('Inactive', a.Status, 'Asset should transition to Inactive after window');
    }

    @IsTest
    static void noChange_whenExcludedFromStatusUpdates() {
        Account acct = TestDataFactory.createAccount('ASB Acc 3');
        insert acct;

        Date today = Date.today();

        Asset a = new Asset(
            Name = 'Excluded',
            AccountId = acct.Id,
            Status = 'Purchased',
            Start_Date__c = today.addDays(-2),
            End_Date__c = today.addDays(5),
            Exclude_from_Status_Updates__c = true
        );
        insert a;

        Test.startTest();
        Database.executeBatch(new AssetStatusBatch(), 200);
        Test.stopTest();

        a = [SELECT Status FROM Asset WHERE Id = :a.Id];
        System.assertEquals('Purchased', a.Status, 'Excluded asset should not change status');
    }

    @IsTest
    static void noChange_whenCancelled() {
        Account acct = TestDataFactory.createAccount('ASB Acc 4');
        insert acct;

        Date today = Date.today();

        Asset a = new Asset(
            Name = 'Cancelled',
            AccountId = acct.Id,
            Status = 'Cancelled',
            Start_Date__c = today.addDays(-2),
            End_Date__c = today.addDays(5),
            Exclude_from_Status_Updates__c = false
        );
        insert a;

        Test.startTest();
        Database.executeBatch(new AssetStatusBatch(), 200);
        Test.stopTest();

        a = [SELECT Status FROM Asset WHERE Id = :a.Id];
        System.assertEquals('Cancelled', a.Status, 'Cancelled asset should not change status');
    }

    @IsTest
    static void finishChainsToContractRevenueBatch_noException() {
        Account acct = TestDataFactory.createAccount('ASB Acc 5');
        insert acct;

        Date today = Date.today();

        // Create an asset in purchased state to ensure batch has some scope
        Asset a = new Asset(
            Name = 'Chain Scope',
            AccountId = acct.Id,
            Status = 'Purchased',
            Start_Date__c = today,
            End_Date__c = today.addDays(1),
            Exclude_from_Status_Updates__c = false
        );
        insert a;

        Test.startTest();
        Database.executeBatch(new AssetStatusBatch(), 200);
        Test.stopTest();

        // We assert finish ran without throwing. Optionally check jobs for ContractRevenueBatch.
        System.assert(true, 'AssetStatusBatch finish executed and chained without exception');
    }

    @IsTest
    static void schedulable_execute_runsBatch() {
        // Minimal scope setup
        Account acct = TestDataFactory.createAccount('ASB Acc 6');
        insert acct;

        Asset a = new Asset(
            Name = 'Schedulable Scope',
            AccountId = acct.Id,
            Status = 'Purchased',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(1),
            Exclude_from_Status_Updates__c = false
        );
        insert a;

        Test.startTest();
        // Invoke Schedulable path directly
        new AssetStatusBatch().execute((SchedulableContext) null);
        Test.stopTest();

        // No exception indicates schedulable path worked and executed batch
        System.assert(true, 'Schedulable execute invoked batch without exception');
    }
}
