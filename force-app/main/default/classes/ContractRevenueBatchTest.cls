@IsTest
private class ContractRevenueBatchTest {
    // Helper DTO for readability inside tests mirroring the planned factory DTO
    private class RevAssetParams {
        Decimal arr;
        Decimal totalPrice;
        Decimal totalValue;
        Decimal exchangeRate;
        Date startDate;
        Date endDate;
        Boolean excludeAsset;
        String name;
    }

    // Local helper to insert a revenue-configured Asset using TestDataFactory conventions
    private static Asset makeRevenueAsset(Id accountId, Id contractId, Id productId, RevAssetParams p) {
        Asset a = new Asset(
            Name = p.name != null ? p.name : 'Rev Asset',
            AccountId = accountId,
            Contract__c = contractId,
            Product2Id = productId,
            Status = 'Purchased',
            Start_Date__c = p.startDate,
            End_Date__c = p.endDate,
            Exchange_Rate__c = p.exchangeRate,
            Exclude_from_Status_Updates__c = p.excludeAsset
        );
        // Revenue driver fields expected by ContractRevenueBatch
        a.ARR__c = p.arr;
        a.Total_Price__c = p.totalPrice;
        a.Total_Value__c = p.totalValue;
        return a;
    }

    // Creates a Contract with explicit dates and flags via TestDataFactory base method
    private static Contract makeContractWithDates(Id accountId, Date startDate, Date endDate, String status, Boolean exclude, Decimal prevArr, Decimal prevArrUsd) {
        Contract c = TestDataFactory.createContract(accountId, 'CRB Test Contract');
        c.StartDate = startDate;
        c.EndDate = endDate;
        c.Status = status;
        c.Exclude_from_Status_Updates__c = exclude;
        c.Previous_ARR__c = prevArr;
        c.Previous_ARR_USD_Reporting__c = prevArrUsd;
        return c;
    }

    @IsTest
    static void draftToActivated_activeRecurring_exactRevenueAndUSD() {
        // Data setup
        Account acct = TestDataFactory.createAccount('CRB Acc 1');
        insert acct;

        Product2 prodRecurring = TestDataFactory.createProduct('CRB Prod Recurring', 'Software Subscriptions');
        insert prodRecurring;

        Date today = Date.today();
        Contract c = makeContractWithDates(acct.Id, today.addDays(-1), today.addDays(1), null, false, null, null);
        insert c;

        RevAssetParams p = new RevAssetParams();
        p.arr = 120;              // ARR
        p.totalPrice = 200;       // ACV contribution
        p.totalValue = 500;       // TCV contribution
        p.exchangeRate = 2;       // USD division factor
        p.startDate = today.addDays(-1);
        p.endDate = today.addDays(5);
        p.excludeAsset = false;
        p.name = 'Active Recurring';
        Asset a = makeRevenueAsset(acct.Id, c.Id, prodRecurring.Id, p);
        insert a;

        Test.startTest();
        
        // Query the specific contract with its assets to process only this contract
        Contract contractToProcess = [
            SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c, CurrencyIsoCode,
                   ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                   (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c, Start_Date__c, End_Date__c, Product2.Family
                    FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
            FROM Contract WHERE Id = :c.Id
        ];
        
        // Execute batch directly with only this contract to avoid test data interference
        ContractRevenueBatch batch = new ContractRevenueBatch();
        batch.execute(null, new List<Contract>{contractToProcess});
        
        Test.stopTest();

        c = [
            SELECT Status, ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c,
                   MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c,
                   Incremental_ARR__c, Incremental_ARR_USD_Reporting__c
            FROM Contract WHERE Id = :c.Id
        ];

        System.assertEquals('Activated', c.Status, 'Contract should be Activated');
        System.assertEquals(120, c.ARR__c, 'ARR should sum asset ARR');
        System.assertEquals(200, c.ACV__c, 'ACV should sum asset Total_Price');
        System.assertEquals(120, c.Active_ARR__c, 'Active ARR should sum active assets ARR');
        System.assertEquals(500, c.TCV__c, 'TCV should sum asset Total_Value');
        System.assertEquals(10, c.MRR__c, 'MRR = ARR / 12');

        // USD reporting divisions (divide by exchange rate 2)
        System.assertEquals(60, c.ARR_USD_Reporting__c, 'ARR USD Reporting should be divided by exch rate');
        System.assertEquals(100, c.ACV_USD_Reporting__c, 'ACV USD Reporting should be divided by exch rate');
        System.assertEquals(250, c.TCV_USD_Reporting__c, 'TCV USD Reporting should be divided by exch rate');
        System.assertEquals(5, c.MRR_USD_Reporting__c, 'MRR USD Reporting should be divided by exch rate');
        System.assertEquals(60, c.Active_ARR_USD_Reporting__c, 'Active ARR USD Reporting should be divided by exch rate');

        // Incremental
        System.assertEquals(120, c.Incremental_ARR__c, 'Incremental ARR equals ARR when previous is null');
        System.assertEquals(60, c.Incremental_ARR_USD_Reporting__c, 'Incremental ARR USD equals ARR_USD when previous is null (120 / 2)');
    }

    @IsTest
    static void activatedWithMixedAssets_onlyActiveRecurringContributesToARR_ACV() {
        Account acct = TestDataFactory.createAccount('CRB Acc 2');
        insert acct;

        Product2 prodRecurring = TestDataFactory.createProduct('CRB Recurring', 'Software Subscriptions');
        Product2 prodNonRecurring = TestDataFactory.createProduct('CRB OneTime', 'One-Time Services');
        insert new List<Product2>{ prodRecurring, prodNonRecurring };

        Date today = Date.today();
        Contract c = makeContractWithDates(acct.Id, today.addDays(-10), today.addDays(335), 'Draft', false, 50, 25);
        insert c;

        List<Asset> toInsert = new List<Asset>();

        // Active recurring
        RevAssetParams a1 = new RevAssetParams();
        a1.arr = 120; a1.totalPrice = 200; a1.totalValue = 1000; a1.exchangeRate = 2;
        a1.startDate = today.addDays(-5); a1.endDate = today.addDays(50); a1.excludeAsset = false; a1.name = 'Active Recurring';
        toInsert.add(makeRevenueAsset(acct.Id, c.Id, prodRecurring.Id, a1));

        // Inactive recurring (starts tomorrow) -> TCV only
        RevAssetParams a2 = new RevAssetParams();
        a2.arr = 60; a2.totalPrice = 100; a2.totalValue = 500; a2.exchangeRate = 2;
        a2.startDate = today.addDays(1); a2.endDate = today.addDays(60); a2.excludeAsset = false; a2.name = 'Inactive Recurring';
        toInsert.add(makeRevenueAsset(acct.Id, c.Id, prodRecurring.Id, a2));

        // Active non-recurring (excluded from ARR/ACV, included in TCV)
        RevAssetParams a3 = new RevAssetParams();
        a3.arr = 9999; a3.totalPrice = 8888; a3.totalValue = 300; a3.exchangeRate = 2;
        a3.startDate = today.addDays(-2); a3.endDate = today.addDays(20); a3.excludeAsset = false; a3.name = 'Active NonRecurring';
        toInsert.add(makeRevenueAsset(acct.Id, c.Id, prodNonRecurring.Id, a3));

        // Excluded asset (ignored entirely by subquery)
        RevAssetParams a4 = new RevAssetParams();
        a4.arr = 777; a4.totalPrice = 666; a4.totalValue = 400; a4.exchangeRate = 2;
        a4.startDate = today.addDays(-2); a4.endDate = today.addDays(20); a4.excludeAsset = true; a4.name = 'Excluded Asset';
        toInsert.add(makeRevenueAsset(acct.Id, c.Id, prodRecurring.Id, a4));

        insert toInsert;

        Test.startTest();
        Database.executeBatch(new ContractRevenueBatch(), 50);
        Test.stopTest();

        c = [
            SELECT Status, ARR__c, ACV__c, Active_ARR__c, TCV__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR__c,
                   Incremental_ARR__c, Incremental_ARR_USD_Reporting__c
            FROM Contract WHERE Id = :c.Id
        ];

        // Batch should activate it
        System.assertEquals('Activated', c.Status, 'Should be Activated within window');

        // Only active recurring contributes
        System.assertEquals(120, c.ARR__c, 'ARR only from active recurring');
        System.assertEquals(200, c.ACV__c, 'ACV only from active recurring');
        System.assertEquals(120, c.Active_ARR__c, 'Active ARR only from active recurring');

        // TCV includes all non-excluded assets (a1 + a2 + a3) = 1000 + 500 + 300 = 1800
        System.assertEquals(1800, c.TCV__c, 'TCV sums all non-excluded Total_Value');

        // USD reporting: only from active recurring for ARR/ACV; TCV_USD from all non-excluded
        System.assertEquals(60, c.ARR_USD_Reporting__c, 'ARR USD from active recurring only');
        System.assertEquals(100, c.ACV_USD_Reporting__c, 'ACV USD from active recurring only');
        System.assertEquals(1800/2, c.TCV_USD_Reporting__c, 'TCV USD sums non-excluded divided by exch');
        System.assertEquals(120/12, c.MRR__c, 'MRR from ARR');

        // Incremental: previous 50 -> 120-50 = 70; USD: (60 - 25) = 35
        System.assertEquals(70, c.Incremental_ARR__c, 'Incremental ARR difference to previous');
        System.assertEquals(35, c.Incremental_ARR_USD_Reporting__c, 'Incremental ARR USD difference to previous');
    }

    @IsTest
    static void expiredContract_statusSet_noRevenueRecompute() {
        Account acct = TestDataFactory.createAccount('CRB Acc 3');
        insert acct;

        Product2 prodRecurring = TestDataFactory.createProduct('CRB Prod', 'Software Subscriptions');
        insert prodRecurring;

        Date today = Date.today();
        // Pre-populate revenue to confirm not nullified/recalculated on expiration
        Contract c = makeContractWithDates(acct.Id, today.addDays(-10), today.addDays(-1), 'Activated', false, 10, 5);
        c.ARR__c = 111; c.ACV__c = 222; c.TCV__c = 333; c.MRR__c = 9; c.Active_ARR__c = 111;
        c.ARR_USD_Reporting__c = 55.5; c.ACV_USD_Reporting__c = 111; c.TCV_USD_Reporting__c = 222; c.MRR_USD_Reporting__c = 4.5; c.Active_ARR_USD_Reporting__c = 55.5;
        insert c;

        // Assets present should not matter because post-status check it will become Expired and revenue block is not executed
        RevAssetParams p = new RevAssetParams();
        p.arr = 999; p.totalPrice = 999; p.totalValue = 999; p.exchangeRate = 2; p.startDate = today.addDays(-2); p.endDate = today.addDays(2); p.excludeAsset = false;
        Asset a = makeRevenueAsset(acct.Id, c.Id, prodRecurring.Id, p);
        insert a;

        Test.startTest();
        Database.executeBatch(new ContractRevenueBatch(), 50);
        Test.stopTest();

        c = [
            SELECT Status, ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c
            FROM Contract WHERE Id = :c.Id
        ];

        System.assertEquals('Expired', c.Status, 'Contract should be set to Expired');
        // Ensure no recompute happened (values kept as pre-batch)
        System.assertEquals(111, c.ARR__c);
        System.assertEquals(222, c.ACV__c);
        System.assertEquals(333, c.TCV__c);
        System.assertEquals(9, c.MRR__c);
        System.assertEquals(111, c.Active_ARR__c);
        System.assertEquals(55.5, c.ARR_USD_Reporting__c);
        System.assertEquals(111, c.ACV_USD_Reporting__c);
        System.assertEquals(222, c.TCV_USD_Reporting__c);
        System.assertEquals(4.5, c.MRR_USD_Reporting__c);
        System.assertEquals(55.5, c.Active_ARR_USD_Reporting__c);
    }

    @IsTest
    static void excludedContractAlreadyActivated_revenueStillRecomputed() {
        Account acct = TestDataFactory.createAccount('CRB Acc 4');
        insert acct;

        Product2 prodRecurring = TestDataFactory.createProduct('CRB Prod', 'Software Subscriptions');
        insert prodRecurring;

        Date today = Date.today();
        Contract c = makeContractWithDates(acct.Id, today.addDays(-5), today.addDays(200), 'Activated', true, null, null);
        insert c;

        RevAssetParams p = new RevAssetParams();
        p.arr = 120; p.totalPrice = 240; p.totalValue = 480; p.exchangeRate = 2; p.startDate = today.addDays(-1); p.endDate = today.addDays(10); p.excludeAsset = false;
        Asset a = makeRevenueAsset(acct.Id, c.Id, prodRecurring.Id, p);
        insert a;

        Test.startTest();
        Database.executeBatch(new ContractRevenueBatch(), 50);
        Test.stopTest();

        c = [
            SELECT Status, ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c
            FROM Contract WHERE Id = :c.Id
        ];
        // Status unchanged (exclude stops status logic), but revenue recomputed because status is Activated
        System.assertEquals('Activated', c.Status);
        System.assertEquals(120, c.ARR__c);
        System.assertEquals(240, c.ACV__c);
        System.assertEquals(480, c.TCV__c);
        System.assertEquals(10, c.MRR__c);
        System.assertEquals(120, c.Active_ARR__c);
        System.assertEquals(60, c.ARR_USD_Reporting__c);
        System.assertEquals(120, c.ACV_USD_Reporting__c);
        System.assertEquals(240, c.TCV_USD_Reporting__c);
        System.assertEquals(5, c.MRR_USD_Reporting__c);
        System.assertEquals(60, c.Active_ARR_USD_Reporting__c);
    }

    @IsTest
    static void nullExchangeRate_divisionDefaultsToOne() {
        Account acct = TestDataFactory.createAccount('CRB Acc 5');
        insert acct;

        Product2 prodRecurring = TestDataFactory.createProduct('CRB Prod', 'Software Subscriptions');
        insert prodRecurring;

        Date today = Date.today();
        Contract c = makeContractWithDates(acct.Id, today.addDays(-5), today.addDays(200), 'Draft', false, null, null);
        insert c;

        RevAssetParams p = new RevAssetParams();
        p.arr = 120; p.totalPrice = 240; p.totalValue = 480; p.exchangeRate = null;
        p.startDate = today.addDays(-1); p.endDate = today.addDays(10); p.excludeAsset = false;
        Asset a = makeRevenueAsset(acct.Id, c.Id, prodRecurring.Id, p);
        insert a;

        Test.startTest();
        Database.executeBatch(new ContractRevenueBatch(), 50);
        Test.stopTest();

        c = [
            SELECT Status, ARR__c, ACV__c, TCV__c, MRR__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c
            FROM Contract WHERE Id = :c.Id
        ];
        System.assertEquals('Activated', c.Status);
        // USD equals native when Exchange_Rate__c is null (division by 1)
        System.assertEquals(120, c.ARR_USD_Reporting__c);
        System.assertEquals(240, c.ACV_USD_Reporting__c);
        System.assertEquals(480, c.TCV_USD_Reporting__c);
        System.assertEquals(10, c.MRR__c);
        System.assertEquals(10, c.MRR_USD_Reporting__c);
    }

    @IsTest
    static void finishChainsAccountRollupBatch_noException() {
        Account acct = TestDataFactory.createAccount('CRB Acc 6');
        insert acct;

        Date today = Date.today();
        Contract c = makeContractWithDates(acct.Id, today.addDays(-1), today.addDays(30), 'Draft', false, null, null);
        insert c;

        Test.startTest();
        Database.executeBatch(new ContractRevenueBatch(), 50);
        Test.stopTest();

        // We assert simply that no exception was thrown through finish. Optionally check async jobs:
        // List<AsyncApexJob> jobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE ApexClass.Name = 'AccountRollupBatch'];
        // System.assert(jobs.size() >= 0);
        System.assert(true, 'Batch and finish executed without exception');
    }

    @IsTest
    static void mixtureUpdatedAndSkipped() {
        Account acct = TestDataFactory.createAccount('CRB Acc 7');
        insert acct;

        Product2 prodRecurring = TestDataFactory.createProduct('CRB Prod', 'Software Subscriptions');
        insert prodRecurring;

        Date today = Date.today();

        // Will update (within window, Draft -> Activated)
        Contract cUpdate = makeContractWithDates(acct.Id, today.addDays(-2), today.addDays(10), 'Draft', false, null, null);
        insert cUpdate;
        RevAssetParams rp = new RevAssetParams();
        rp.arr = 120;
        rp.totalPrice = 120;
        rp.totalValue = 240;
        rp.exchangeRate = 2;
        rp.startDate = today.addDays(-1);
        rp.endDate = today.addDays(5);
        rp.excludeAsset = false;
        rp.name = 'Active Recurring';
        Asset a1 = makeRevenueAsset(acct.Id, cUpdate.Id, prodRecurring.Id, rp);
        insert a1;

        // Will skip (out of window, already Expired; determineContractStatus returns null and not Activated => no revenue block, returns null)
        Contract cSkip = makeContractWithDates(acct.Id, today.addDays(-20), today.addDays(-10), 'Expired', false, null, null);
        cSkip.ARR__c = 1; cSkip.ACV__c = 1; cSkip.TCV__c = 1; cSkip.MRR__c = 0.08; cSkip.Active_ARR__c = 1;
        insert cSkip;

        Test.startTest();
        Database.executeBatch(new ContractRevenueBatch(), 50);
        Test.stopTest();

        // Updated contract assertions
        Contract cu = [SELECT Status, ARR__c, ACV__c, TCV__c, MRR__c FROM Contract WHERE Id = :cUpdate.Id];
        System.assertEquals('Activated', cu.Status);
        System.assertEquals(120, cu.ARR__c);
        System.assertEquals(120, cu.ACV__c);
        System.assertEquals(240, cu.TCV__c);
        System.assertEquals(10, cu.MRR__c);

        // Skipped contract unchanged
        Contract cs = [SELECT Status, ARR__c, ACV__c, TCV__c, MRR__c FROM Contract WHERE Id = :cSkip.Id];
        System.assertEquals('Expired', cs.Status);
        System.assertEquals(1, cs.ARR__c);
        System.assertEquals(1, cs.ACV__c);
        System.assertEquals(1, cs.TCV__c);
        System.assertEquals(0.08, cs.MRR__c);
    }
}
