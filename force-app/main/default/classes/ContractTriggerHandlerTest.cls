@isTest
public class ContractTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Use TestDataFactory to create test data
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
    }
    
    @isTest
    static void testDraftContractFormatting() {
        // Use TestDataFactory to create proper test data following business flow
        Account testAccount = TestDataFactory.createAccount('Contract Format Test Account');
        insert testAccount;
        
        Test.startTest();
        
        // Create Opportunity (for reference, but focus on Asset → Contract flow)
        Opportunity testOpp = TestDataFactory.createOpportunity(testAccount.Id, 'Format Test Opp');
        testOpp.CurrencyIsoCode = 'EUR';
        insert testOpp;
        
        // Create Contract in Draft status with base revenue fields for ContractTriggerHandler
        Contract testContract = TestDataFactory.createContract(testAccount.Id, 'Format Test Contract');
        testContract.Status = 'Draft'; // ContractTriggerHandler only processes Draft contracts
        testContract.CurrencyIsoCode = 'EUR';
        testContract.StartDate = Date.today();
        testContract.EndDate = Date.today().addMonths(12);
        // Set base revenue fields that ContractTriggerHandler will convert to USD
        testContract.ARR__c = 100000; // €100K ARR
        testContract.ACV__c = 100000; // €100K ACV  
        testContract.TCV__c = 100000; // €100K TCV
        testContract.MRR__c = 8333.33; // €100K / 12 months
        testContract.Initial_ARR__c = 100000;
        testContract.Initial_ACV__c = 100000;
        testContract.Initial_TCV__c = 100000;
        testContract.Initial_MRR__c = 8333.33;
        insert testContract;
        
        // Create Assets with writeable fields that drive calculated revenue fields
        List<Asset> assets = new List<Asset>();
        Asset asset1 = TestDataFactory.createAsset(testAccount.Id, testContract.Id, 'Active');
        asset1.Price = 5000; // €5K monthly price
        asset1.Quantity = 12; // 12 months = €60K annual (ARR)
        asset1.Exchange_Rate__c = 1.10; // EUR to USD rate
        asset1.Start_Date__c = Date.today().addDays(-30); // Active asset (started)
        asset1.End_Date__c = Date.today().addDays(335); // Active asset (not ended)
        assets.add(asset1);
        
        Asset asset2 = TestDataFactory.createAsset(testAccount.Id, testContract.Id, 'Active');  
        asset2.Price = 3333; // €3.3K monthly price
        asset2.Quantity = 12; // 12 months = €40K annual (ARR)
        asset2.Exchange_Rate__c = 1.10; // EUR to USD rate
        asset2.Start_Date__c = Date.today().addDays(-60); // Active asset (started)
        asset2.End_Date__c = Date.today().addDays(305); // Active asset (not ended)
        assets.add(asset2);
        
        insert assets;
        
        // Trigger ContractTriggerHandler currency formatting by updating the Contract
        // The handler uses @future method, so we need Test.stopTest() AFTER the update
        testContract.Description = 'Trigger formatting'; // Dummy field change to trigger update
        update testContract;
        
        Test.stopTest(); // Execute @future method (processContractFieldsAsync) for USD formatting
        
        // Verify USD fields were formatted by ContractTriggerHandler
        Contract result = [
            SELECT ARR__c, ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                   Initial_ARR_USD__c, Initial_ACV_USD__c, Initial_TCV_USD__c, Initial_MRR_USD__c
            FROM Contract 
            WHERE Id = :testContract.Id
        ];
        
        // Verify base EUR values are still intact
        System.assertEquals(100000, result.ARR__c, 'Contract ARR should remain €100K');
        
        // ContractTriggerHandler should have formatted USD values from EUR base amounts
        // €100K * 1.10 exchange rate = $110,000.00
        System.assertNotEquals(null, result.ARR_USD__c, 'ARR USD should not be null after ContractTriggerHandler');
        System.assertNotEquals('$0.00', result.ARR_USD__c, 'ARR USD should not be $0.00 after formatting');
        
        // Verify formatted USD amounts
        System.assert(result.ARR_USD__c.startsWith('$'), 'ARR USD should start with $ symbol');
        System.assert(result.ARR_USD__c.contains('110'), 'ARR USD should reflect EUR to USD conversion (~$110K)');
        System.assert(result.ARR_USD__c.contains('.'), 'ARR USD should contain decimal places');
        
        // All USD fields should be formatted consistently
        System.assertNotEquals(null, result.ACV_USD__c, 'ACV USD should be formatted');
        System.assertNotEquals(null, result.TCV_USD__c, 'TCV USD should be formatted');
        System.assertNotEquals(null, result.MRR_USD__c, 'MRR USD should be formatted');
        
        // Initial and Current USD values should match
        System.assertEquals(result.Initial_ARR_USD__c, result.ARR_USD__c, 'Initial and Current ARR USD should match');
        System.assertEquals(result.Initial_ACV_USD__c, result.ACV_USD__c, 'Initial and Current ACV USD should match');
    }
    
    @isTest
    static void testActivatedContractNotProcessed() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Create contract as Draft first, then activate (proper Salesforce Contract lifecycle)
        Contract testContract = TestDataFactory.createContract(testAccount.Id, 'Activated Test Contract');
        testContract.Status = 'Draft';
        testContract.CurrencyIsoCode = 'USD';
        testContract.Initial_ARR__c = 100000;
        testContract.ARR_USD__c = '$0.00';
        insert testContract;
        
        // Activate contract following proper lifecycle (only update Status field)
        Contract contractToActivate = new Contract(Id = testContract.Id);
        contractToActivate.Status = 'Activated';
        update contractToActivate;
        
        Test.stopTest();
        
        // Verify USD fields were NOT formatted
        Contract result = [SELECT ARR_USD__c FROM Contract WHERE Id = :testContract.Id];
        System.assertEquals('$0.00', result.ARR_USD__c, 'Activated contract should not be formatted');
    }
    
    @isTest
    static void testContractAlreadyFormattedNotProcessed() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Create Draft contract with already formatted values
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'USD',
            Initial_ARR__c = 100000,
            ARR_USD__c = '$100,000.00',
            ACV_USD__c = '$100,000.00',
            TCV_USD__c = '$200,000.00',
            MRR_USD__c = '$8,333.33'
        );
        
        insert testContract;
        
        Test.stopTest();
        
        // Verify values remained the same (not processed again)
        Contract result = [SELECT ARR_USD__c FROM Contract WHERE Id = :testContract.Id];
        System.assertEquals('$100,000.00', result.ARR_USD__c, 'Already formatted contract should not be reprocessed');
    }
    
    @isTest
    static void testBulkContractFormatting() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Create contracts with base revenue fields for bulk formatting test
        List<Contract> contracts = new List<Contract>();
        for (Integer i = 0; i < 10; i++) {
            Decimal amount = 50000 + (i * 10000);
            contracts.add(new Contract(
                AccountId = testAccount.Id,
                Status = 'Draft',
                StartDate = Date.today(),
                ContractTerm = 24,
                CurrencyIsoCode = 'USD',
                ARR__c = amount,
                ACV__c = amount,
                TCV__c = amount,
                MRR__c = amount / 12,
                Initial_ARR__c = amount,
                Initial_ACV__c = amount,
                Initial_TCV__c = amount,
                Initial_MRR__c = amount / 12
            ));
        }
        
        insert contracts;
        
        // Trigger ContractTriggerHandler by updating contracts (@future method needs UPDATE)
        for (Integer i = 0; i < contracts.size(); i++) {
            contracts[i].Description = 'Trigger bulk formatting ' + i;
        }
        update contracts;
        
        Test.stopTest(); // Execute @future method for USD formatting
        
        // Verify all contracts were formatted
        List<Contract> results = [
            SELECT ARR_USD__c, Initial_ARR__c 
            FROM Contract 
            WHERE Id IN :contracts 
            ORDER BY Initial_ARR__c
        ];
        
        System.assertEquals(10, results.size(), 'Should have 10 contracts');
        
        for (Contract result : results) {
            System.assertNotEquals('$0.00', result.ARR_USD__c, 'All contracts should be formatted');
            System.assert(result.ARR_USD__c.startsWith('$'), 'All should start with $');
        }
    }
    
    @isTest
    static void testDifferentCurrencies() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Create contracts with base revenue fields (ContractTriggerHandler needs these)
        List<Contract> contracts = new List<Contract>();
        contracts.add(new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'USD',
            ARR__c = 100000,
            ACV__c = 100000,
            TCV__c = 100000,
            MRR__c = 8333.33,
            Initial_ARR__c = 100000,
            Initial_ACV__c = 100000,
            Initial_TCV__c = 100000,
            Initial_MRR__c = 8333.33
        ));
        
        contracts.add(new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'EUR',
            ARR__c = 100000,
            ACV__c = 100000,
            TCV__c = 100000,
            MRR__c = 8333.33,
            Initial_ARR__c = 100000,
            Initial_ACV__c = 100000,
            Initial_TCV__c = 100000,
            Initial_MRR__c = 8333.33
        ));
        
        insert contracts;
        
        // Trigger ContractTriggerHandler by updating contracts (@future method needs UPDATE)
        contracts[0].Description = 'Trigger USD formatting';
        contracts[1].Description = 'Trigger EUR formatting';
        update contracts;
        
        Test.stopTest(); // Execute @future method for USD formatting
        
        // Verify both contracts were formatted
        List<Contract> results = [
            SELECT ARR_USD__c, CurrencyIsoCode 
            FROM Contract 
            WHERE Id IN :contracts
            ORDER BY CurrencyIsoCode
        ];
        
        for (Contract result : results) {
            System.assertNotEquals('$0.00', result.ARR_USD__c, 
                'Contract with currency ' + result.CurrencyIsoCode + ' should be formatted');
        }
    }
    
    @isTest
    static void testNullAmountHandling() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Create contract with null amounts to test graceful handling
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'USD',
            ARR__c = null, // Null amounts
            ACV__c = null,
            TCV__c = null,
            MRR__c = null,
            Initial_ARR__c = null,
            Initial_ACV__c = null,
            Initial_TCV__c = null,
            Initial_MRR__c = null
        );
        
        insert testContract;
        
        // Trigger ContractTriggerHandler by updating contract (@future method needs UPDATE)
        testContract.Description = 'Trigger null amount formatting';
        update testContract;
        
        Test.stopTest(); // Execute @future method for USD formatting
        
        // Verify null amounts were handled gracefully
        Contract result = [SELECT ARR_USD__c FROM Contract WHERE Id = :testContract.Id];
        System.assertEquals('$0.00', result.ARR_USD__c, 'Null amount should format to $0.00');
    }
    
    @isTest
    static void testUpdateTrigger() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Create contract without USD formatting initially (no base revenue fields)
        Contract testContract = TestDataFactory.createContract(testAccount.Id, 'Update Test Contract');
        testContract.Status = 'Draft';
        testContract.CurrencyIsoCode = 'USD';
        // Don't set revenue fields initially - contract won't need formatting
        insert testContract;
        
        Test.startTest();
        
        // Update contract with revenue fields - should trigger formatting
        Contract contractToUpdate = new Contract(Id = testContract.Id);
        contractToUpdate.ARR__c = 100000;
        contractToUpdate.ACV__c = 100000;
        contractToUpdate.TCV__c = 100000;
        contractToUpdate.MRR__c = 8333.33;
        contractToUpdate.Initial_ARR__c = 100000;
        contractToUpdate.Initial_ACV__c = 100000;
        contractToUpdate.Initial_TCV__c = 100000;
        contractToUpdate.Initial_MRR__c = 8333.33;
        contractToUpdate.Description = 'Trigger update formatting';
        update contractToUpdate;
        
        Test.stopTest(); // Execute @future method for USD formatting
        
        // Verify USD field was formatted on update
        Contract result = [SELECT ARR_USD__c FROM Contract WHERE Id = :testContract.Id];
        System.assertNotEquals('$0.00', result.ARR_USD__c, 'Contract should be formatted on update to Draft');
    }
    
    @isTest
    static void testRecursionPrevention() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Create contract with base revenue fields for recursion prevention test
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'USD',
            ARR__c = 100000,
            ACV__c = 100000,
            TCV__c = 100000,
            MRR__c = 8333.33,
            Initial_ARR__c = 100000,
            Initial_ACV__c = 100000,
            Initial_TCV__c = 100000,
            Initial_MRR__c = 8333.33
        );
        
        insert testContract;
        
        // Trigger ContractTriggerHandler by updating contract (@future method needs UPDATE)
        // This should complete without hitting governor limits due to recursion
        testContract.Description = 'Trigger recursion prevention test';
        update testContract;
        
        Test.stopTest(); // Execute @future method for USD formatting
        
        // If we get here without exceptions, recursion prevention worked
        Contract result = [SELECT ARR_USD__c FROM Contract WHERE Id = :testContract.Id];
        System.assertNotEquals('$0.00', result.ARR_USD__c, 'Contract should be formatted once');
    }
}