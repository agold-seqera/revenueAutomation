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
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Create Draft contract with placeholder values
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'EUR',
            Initial_ARR__c = 100000,
            Initial_ACV__c = 100000,
            Initial_TCV__c = 200000,
            Initial_MRR__c = 8333.33,
            ARR_USD__c = '$0.00',
            ACV_USD__c = '$0.00',
            TCV_USD__c = '$0.00',
            MRR_USD__c = '$0.00'
        );
        
        insert testContract;
        
        Test.stopTest();
        
        // Verify USD fields were formatted
        Contract result = [
            SELECT ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                   Initial_ARR_USD__c, Initial_ACV_USD__c, Initial_TCV_USD__c, Initial_MRR_USD__c
            FROM Contract 
            WHERE Id = :testContract.Id
        ];
        
        // Should not be placeholder values anymore
        System.assertNotEquals('$0.00', result.ARR_USD__c, 'ARR USD should be formatted');
        System.assertNotEquals('$0.00', result.ACV_USD__c, 'ACV USD should be formatted');
        System.assertNotEquals('$0.00', result.TCV_USD__c, 'TCV USD should be formatted');
        System.assertNotEquals('$0.00', result.MRR_USD__c, 'MRR USD should be formatted');
        
        // Initial and Current should have same values
        System.assertEquals(result.Initial_ARR_USD__c, result.ARR_USD__c, 'Initial and Current ARR should match');
        System.assertEquals(result.Initial_ACV_USD__c, result.ACV_USD__c, 'Initial and Current ACV should match');
        System.assertEquals(result.Initial_TCV_USD__c, result.TCV_USD__c, 'Initial and Current TCV should match');
        System.assertEquals(result.Initial_MRR_USD__c, result.MRR_USD__c, 'Initial and Current MRR should match');
        
        // Should start with $ and contain decimal places
        System.assert(result.ARR_USD__c.startsWith('$'), 'ARR should start with $');
        System.assert(result.ARR_USD__c.contains('.'), 'ARR should contain decimal');
    }
    
    @isTest
    static void testActivatedContractNotProcessed() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Create Activated contract (should not be processed)
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Activated',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'USD',
            Initial_ARR__c = 100000,
            ARR_USD__c = '$0.00'
        );
        
        insert testContract;
        
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
        
        List<Contract> contracts = new List<Contract>();
        for (Integer i = 0; i < 10; i++) {
            contracts.add(new Contract(
                AccountId = testAccount.Id,
                Status = 'Draft',
                StartDate = Date.today(),
                ContractTerm = 24,
                CurrencyIsoCode = 'USD',
                Initial_ARR__c = 50000 + (i * 10000),
                ARR_USD__c = '$0.00'
            ));
        }
        
        insert contracts;
        
        Test.stopTest();
        
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
        
        List<Contract> contracts = new List<Contract>();
        contracts.add(new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'USD',
            Initial_ARR__c = 100000,
            ARR_USD__c = '$0.00'
        ));
        
        contracts.add(new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'EUR',
            Initial_ARR__c = 100000,
            ARR_USD__c = '$0.00'
        ));
        
        insert contracts;
        
        Test.stopTest();
        
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
        
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'USD',
            Initial_ARR__c = null, // Null amount
            ARR_USD__c = null
        );
        
        insert testContract;
        
        Test.stopTest();
        
        // Verify null amounts were handled gracefully
        Contract result = [SELECT ARR_USD__c FROM Contract WHERE Id = :testContract.Id];
        System.assertEquals('$0.00', result.ARR_USD__c, 'Null amount should format to $0.00');
    }
    
    @isTest
    static void testUpdateTrigger() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Create contract without formatting trigger first
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Activated', // Won't trigger formatting
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'USD',
            Initial_ARR__c = 100000,
            ARR_USD__c = '$0.00'
        );
        insert testContract;
        
        Test.startTest();
        
        // Update to Draft status - should trigger formatting
        testContract.Status = 'Draft';
        update testContract;
        
        Test.stopTest();
        
        // Verify USD field was formatted on update
        Contract result = [SELECT ARR_USD__c FROM Contract WHERE Id = :testContract.Id];
        System.assertNotEquals('$0.00', result.ARR_USD__c, 'Contract should be formatted on update to Draft');
    }
    
    @isTest
    static void testRecursionPrevention() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        
        // This test ensures the handler doesn't cause infinite recursion
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 24,
            CurrencyIsoCode = 'USD',
            Initial_ARR__c = 100000,
            ARR_USD__c = '$0.00'
        );
        
        // Should complete without hitting governor limits due to recursion
        insert testContract;
        
        Test.stopTest();
        
        // If we get here without exceptions, recursion prevention worked
        Contract result = [SELECT ARR_USD__c FROM Contract WHERE Id = :testContract.Id];
        System.assertNotEquals('$0.00', result.ARR_USD__c, 'Contract should be formatted once');
    }
}