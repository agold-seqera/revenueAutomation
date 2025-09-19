// Test class for QuoteLineItemCalculationHelper
@isTest
public class QuoteLineItemCalculationHelperTest {
    
    @testSetup
    static void setupTestData() {
        // Use TestDataFactory for consistent test data creation
        Account testAccount = TestDataFactory.createAccount('Calculation Helper Test Account');
        insert testAccount;
        
        Opportunity opp = TestDataFactory.createOpportunity(testAccount.Id, 'Test Opportunity');
        opp.Contract_Start_Date__c = Date.today();
        insert opp;
        
        // Create test Products using TestDataFactory
        Product2 subscriptionProduct = TestDataFactory.createProduct('Subscription Product', 'Software Subscriptions');
        Product2 serviceProduct = TestDataFactory.createProduct('Service Product', 'Professional Service');
        insert new List<Product2>{ subscriptionProduct, serviceProduct };
        
        // Create PricebookEntries using TestDataFactory
        PricebookEntry pbe1 = TestDataFactory.createPricebookEntry(subscriptionProduct.Id, 1000);
        PricebookEntry pbe2 = TestDataFactory.createPricebookEntry(serviceProduct.Id, 5000);
        insert new List<PricebookEntry>{ pbe1, pbe2 };
        
        // Create test Quote using TestDataFactory
        Quote quote = TestDataFactory.createQuote(opp.Id, 'Test Quote');
        quote.Order_Start_Date__c = Date.today();
        quote.Order_End_Date__c = Date.today().addDays(365);
        insert quote;
    }
    
    @isTest
    static void testCalculateBillingAmount_SoftwareSubscription() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        // Create test QuoteLineItem using TestDataFactory
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        qli.Service_Start_Date__c = Date.today();
        qli.Service_End_Date__c = Date.today().addDays(90); // 3 months  
        qli.Annual_Amount__c = 12000; // For consistent test expectations
        insert qli;
        
        Test.startTest();
        
        // Call the Apex method
        List<Decimal> results = QuoteLineItemCalculationHelper.calculateBillingAmount(
            new List<Id>{ qli.Id }
        );
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(1, results.size(), 'Should return one result');
        
        // Should be approximately $3000 for 3-month subscription
        Decimal expected = 3000; // 12000 * (90/365) ≈ 2958, but formula fields handle exact calculation
        System.assert(results[0] > 2900 && results[0] < 3100, 'Billing amount should be approximately $3000');
    }
    
    @isTest
    static void testCalculateBillingAmount_NonSubscription() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Professional Service' LIMIT 1];
        
        // Create test QuoteLineItem using TestDataFactory
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 5000);
        qli.Annual_Amount__c = 5000; // For consistent test expectations
        insert qli;
        
        Test.startTest();
        
        List<Decimal> results = QuoteLineItemCalculationHelper.calculateBillingAmount(
            new List<Id>{ qli.Id }
        );
        
        Test.stopTest();
        
        // Should return 0 for non-subscription products
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(0, results[0], 'Non-subscription products should return 0');
    }
}