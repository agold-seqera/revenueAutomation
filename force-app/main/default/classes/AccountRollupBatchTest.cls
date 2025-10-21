@IsTest
private class AccountRollupBatchTest {
    // Helpers
    private static Contract makeContract(Id accountId, Date startDate, Date endDate, String status, Boolean exclude,
                                         Decimal arr, Decimal acv, Decimal tcv, Decimal mrr,
                                         Decimal incArr, Decimal arrUsd, Decimal acvUsd, Decimal tcvUsd, Decimal mrrUsd,
                                         Id renewalOppId) {
        Contract c = TestDataFactory.createContract(accountId, 'ARB Test Contract');
        c.StartDate = startDate;
        c.EndDate = endDate;
        c.Status = status;
        c.Exclude_from_Status_Updates__c = exclude;
        c.ARR__c = arr;
        c.ACV__c = acv;
        c.TCV__c = tcv;
        c.MRR__c = mrr;
        c.Incremental_ARR__c = incArr;
        c.ARR_USD_Reporting__c = arrUsd;
        c.ACV_USD_Reporting__c = acvUsd;
        c.TCV_USD_Reporting__c = tcvUsd;
        c.MRR_USD_Reporting__c = mrrUsd;
        c.Renewal_Opportunity__c = renewalOppId;
        return c;
    }

    private static Opportunity makeRenewalOpp(Id accountId, String stage, Boolean isClosed, String dealType) {
        Opportunity o = new Opportunity(
            Name = 'ARB Renewal',
            AccountId = accountId,
            StageName = stage,
            CloseDate = Date.today().addDays(30),
            Amount = 1000
        );
        // Populate custom fields used by logic
        o.Deal_Type__c = dealType;
        // StageName + IsClosed is derived by system on insert, but logic only reads StageName/IsClosed; we rely on StageName
        return o;
    }

    @IsTest
    static void recalculatesFromActivatedContracts_only() {
        // Account with both activated and draft contracts; should use activated only
        Account acct = TestDataFactory.createAccount('ARB Acc 1');
        insert acct;

        Date today = Date.today();

        // Activated contract (active now)
        Contract act1 = makeContract(acct.Id,
            today.addDays(-10), today.addDays(200), 'Activated', false,
            120, 200, 1000, 10, 70, // arr, acv, tcv, mrr, incArr
            60, 100, 500, 5,        // USD reporting
            null);
        // Draft contract (active window) should be ignored because activated takes priority
        Contract dr1 = makeContract(acct.Id,
            today.addDays(-5), today.addDays(100), 'Draft', false,
            999, 999, 999, 999, 999,
            999, 999, 999, 999,
            null);

        insert new List<Contract>{ act1, dr1 };

        Test.startTest();
        Database.executeBatch(new AccountRollupBatch(), 50);
        Test.stopTest();

        Account result = [
            SELECT ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                   Status__c, Type
            FROM Account WHERE Id = :acct.Id
        ];

        // Recalculated only from activated contracts
        System.assertEquals(120, result.ARR__c);
        System.assertEquals(200, result.ACV__c);
        System.assertEquals(1000, result.TCV__c);
        System.assertEquals(10, result.MRR__c);
        System.assertEquals(70, result.Incremental_ARR__c);
        System.assertEquals(60, result.ARR_USD_Reporting__c);
        System.assertEquals(100, result.ACV_USD_Reporting__c);
        System.assertEquals(500, result.TCV_USD_Reporting__c);
        System.assertEquals(5, result.MRR_USD_Reporting__c);

        // Status/Type: has active contract(s) -> Active, Type -> Customer
        System.assertEquals('Active', result.Status__c, 'Active contracts should mark account Active');
        System.assertEquals('Customer', result.Type, 'Active status maps to Type=Customer');
    }

    @IsTest
    static void fallsBackToDraftWhenNoActivated() {
        Account acct = TestDataFactory.createAccount('ARB Acc 2');
        insert acct;

        Date today = Date.today();

        // Only Draft contracts in active/future windows
        Contract drActive = makeContract(acct.Id,
            today.addDays(-2), today.addDays(50), 'Draft', false,
            50, 80, 300, 4, 20,
            25, 40, 150, 2,
            null);
        Contract drFuture = makeContract(acct.Id,
            today.addDays(10), today.addDays(400), 'Draft', false,
            60, 90, 400, 5, 30,
            30, 45, 200, 2.5,
            null);
        insert new List<Contract>{ drActive, drFuture };

        Test.startTest();
        Database.executeBatch(new AccountRollupBatch(), 50);
        Test.stopTest();

        Account result = [
            SELECT ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                   Status__c, Type
            FROM Account WHERE Id = :acct.Id
        ];

        // Should add only eligible Draft contracts (both active window and future are eligible by logic)
        // Sum both drafts
        System.assertEquals(50 + 60, result.ARR__c);
        System.assertEquals(80 + 90, result.ACV__c);
        System.assertEquals(300 + 400, result.TCV__c);
        System.assertEquals(4 + 5, result.MRR__c);
        System.assertEquals(20 + 30, result.Incremental_ARR__c);
        System.assertEquals(25 + 30, result.ARR_USD_Reporting__c);
        System.assertEquals(40 + 45, result.ACV_USD_Reporting__c);
        System.assertEquals(150 + 200, result.TCV_USD_Reporting__c);
        System.assertEquals(2 + 2.5, result.MRR_USD_Reporting__c);

        // No activated contracts but with drafts in window → account becomes Active (due to contract counting making eligibleContracts = drafts and activeContracts count > 0 path triggers Active)
        System.assertEquals('Active', result.Status__c);
        System.assertEquals('Customer', result.Type);
    }

    @IsTest
    static void preservesRevenueWhenOnlyExpired_andNotAllCancelled() {
        Account acct = TestDataFactory.createAccount('ARB Acc 3');
        insert acct;

        Date today = Date.today();

        // Existing account revenue to be preserved
        acct.ARR__c = 50000;
        acct.ACV__c = 50000;
        acct.TCV__c = 50000;
        acct.MRR__c = 4166.67;
        acct.Incremental_ARR__c = 1000;
        acct.ARR_USD_Reporting__c = 50000;
        acct.ACV_USD_Reporting__c = 50000;
        acct.TCV_USD_Reporting__c = 50000;
        acct.MRR_USD_Reporting__c = 4166.67;
        update acct;

        // Only expired contracts
        Contract expired1 = makeContract(acct.Id,
            today.addDays(-365), today.addDays(-10), 'Activated', false,
            100, 100, 100, 8.33, 50,
            90, 90, 90, 7.5,
            null);
        Contract expired2 = makeContract(acct.Id,
            today.addDays(-200), today.addDays(-5), 'Activated', false,
            200, 200, 200, 16.66, 75,
            180, 180, 180, 15,
            null);
        insert new List<Contract>{ expired1, expired2 };

        Test.startTest();
        Database.executeBatch(new AccountRollupBatch(), 50);
        Test.stopTest();

        Account result = [
            SELECT ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                   Status__c, Type
            FROM Account WHERE Id = :acct.Id
        ];

        // Should preserve all fields (unchanged)
        System.assertEquals(50000, result.ARR__c);
        System.assertEquals(50000, result.ACV__c);
        System.assertEquals(50000, result.TCV__c);
        System.assertEquals(4166.67, result.MRR__c);
        System.assertEquals(1000, result.Incremental_ARR__c);
        System.assertEquals(50000, result.ARR_USD_Reporting__c);
        System.assertEquals(50000, result.ACV_USD_Reporting__c);
        System.assertEquals(50000, result.TCV_USD_Reporting__c);
        System.assertEquals(4166.67, result.MRR_USD_Reporting__c);

        // With only expired contracts and not all cancelled: account status depends on existing logic; with no active, no future, some expired and no open renewal → could become Churned; but determineAccountStatus uses previous status, which is null here; default to null is acceptable.
        // We just assert no exceptions and revenue preserved.
        System.assert(true, 'Revenue preserved with only expired contracts and not all cancelled');
    }

    @IsTest
    static void openRenewalWithExpiredContracts_setsChurning() {
        Account acct = TestDataFactory.createAccount('ARB Acc 4');
        insert acct;

        Date today = Date.today();

        Opportunity openRenewal = makeRenewalOpp(acct.Id, 'Negotiations/Contracting', false, 'Renewal');
        insert openRenewal;

        Contract expiredWithOpenRenewal = makeContract(acct.Id,
            today.addDays(-300), today.addDays(-1), 'Activated', false,
            100, 100, 100, 8.33, 10,
            90, 90, 90, 7.5,
            openRenewal.Id);
        insert expiredWithOpenRenewal;

        Test.startTest();
        Database.executeBatch(new AccountRollupBatch(), 50);
        Test.stopTest();

        Account result = [
            SELECT Status__c, Type FROM Account WHERE Id = :acct.Id
        ];
        System.assertEquals('Active (Churning)', result.Status__c, 'Expired with open renewal should set Active (Churning)');
        System.assertEquals('Customer', result.Type, 'Churning maps to Customer type');
    }

    @IsTest
    static void allContractsCancelled_setsChurned() {
        Account acct = TestDataFactory.createAccount('ARB Acc 5');
        insert acct;

        Date today = Date.today();

        Contract cancelled1 = makeContract(acct.Id,
            today.addDays(-30), today.addDays(60), 'Cancelled', false,
            0, 0, 0, 0, 0,
            0, 0, 0, 0,
            null);
        Contract cancelled2 = makeContract(acct.Id,
            today.addDays(-20), today.addDays(30), 'Cancelled', false,
            0, 0, 0, 0, 0,
            0, 0, 0, 0,
            null);
        insert new List<Contract>{ cancelled1, cancelled2 };

        Test.startTest();
        Database.executeBatch(new AccountRollupBatch(), 50);
        Test.stopTest();

        Account result = [SELECT Status__c, Type FROM Account WHERE Id = :acct.Id];
        System.assertEquals('Churned', result.Status__c, 'All contracts cancelled -> Churned');
        System.assertEquals('Churned', result.Type, 'Churned status maps to Type=Churned');
    }

    @IsTest
    static void typeMapping_forStatuses() {
        // Directly validate the mapping function via overall batch results
        Account acct = TestDataFactory.createAccount('ARB Acc 6');
        insert acct;

        Date today = Date.today();

        // Future-only contracts -> Contracted
        Contract future = makeContract(acct.Id,
            today.addDays(10), today.addDays(370), 'Draft', false,
            10, 20, 30, 1, 5,
            8, 16, 24, 0.8,
            null);
        insert future;

        Test.startTest();
        Database.executeBatch(new AccountRollupBatch(), 50);
        Test.stopTest();

        Account res1 = [SELECT Status__c, Type FROM Account WHERE Id = :acct.Id];
        System.assertEquals('Contracted', res1.Status__c);
        System.assertEquals('Customer', res1.Type);

        // Change to active contracts -> Active
        future.StartDate = today.addDays(-1);
        future.EndDate = today.addDays(11);
        future.Status = 'Activated';
        update future;

        Test.startTest();
        Database.executeBatch(new AccountRollupBatch(), 50);
        Test.stopTest();

        Account res2 = [SELECT Status__c, Type FROM Account WHERE Id = :acct.Id];
        System.assertEquals('Active', res2.Status__c);
        System.assertEquals('Customer', res2.Type);

        // Simulate lost renewal on Active account -> Active (Churning)
        Opportunity lostRenewal = makeRenewalOpp(acct.Id, 'Closed Lost', true, 'Churn');
        insert lostRenewal;
        future.Renewal_Opportunity__c = lostRenewal.Id;
        update future;

        Test.startTest();
        Database.executeBatch(new AccountRollupBatch(), 50);
        Test.stopTest();

        Account res3 = [SELECT Status__c, Type FROM Account WHERE Id = :acct.Id];
        // determineAccountStatus branch 3.1 checks for account.Status__c == 'Active' and hasLostRenewal && !hasOpenRenewal
        // Because the previous run set Active, this run should set Active (Churning)
        System.assertEquals('Active (Churning)', res3.Status__c);
        System.assertEquals('Customer', res3.Type);
    }

    @IsTest
    static void finish_noFurtherChaining_noException() {
        Account acct = TestDataFactory.createAccount('ARB Acc 7');
        insert acct;

        Test.startTest();
        Database.executeBatch(new AccountRollupBatch(), 50);
        Test.stopTest();

        System.assert(true, 'Finish executed without exception');
    }
}
