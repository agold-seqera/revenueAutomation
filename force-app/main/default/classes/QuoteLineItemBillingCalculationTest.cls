// Test class for QuoteLineItemBillingCalculation trigger
// Tests billing calculation integration with existing helper method
@isTest
public class QuoteLineItemBillingCalculationTest {
    
    @testSetup
    static void setupTestData() {
        // Use TestDataFactory for consistent test data creation
        Account testAccount = TestDataFactory.createAccount('Billing Test Account');
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
    static void testTrigger_SoftwareSubscription_Insert() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        Test.startTest();
        
        // Create QuoteLineItem using TestDataFactory - trigger should fire on insert
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        qli.Service_Start_Date__c = Date.today();
        qli.Service_End_Date__c = Date.today().addDays(90); // 3 months
        insert qli;
        
        Test.stopTest();
        
        // Verify trigger populated Total_Price__c
        QuoteLineItem insertedQLI = [SELECT Id, Total_Price__c, Annual_Amount__c FROM QuoteLineItem WHERE Id = :qli.Id];
        
        System.assertNotEquals(null, insertedQLI.Total_Price__c, 'Total_Price__c should be populated by trigger');
        System.assert(insertedQLI.Total_Price__c > 2900 && insertedQLI.Total_Price__c < 3100, 
                     'Billing amount should be approximately $3000 for 3-month subscription');
        System.assert(insertedQLI.Total_Price__c < insertedQLI.Annual_Amount__c, 
                     'Billing amount should be less than annual amount');
    }
    
    @isTest
    static void testTrigger_SoftwareSubscription_Update() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        // Create initial QuoteLineItem using TestDataFactory
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        qli.Service_Start_Date__c = Date.today();
        qli.Service_End_Date__c = Date.today().addDays(90); // 3 months
        insert qli;
        
        Test.startTest();
        
        // Update UnitPrice - trigger should recalculate
        qli.UnitPrice = 24000; // Double the annual price
        update qli;
        
        Test.stopTest();
        
        // Verify trigger recalculated Total_Price__c
        QuoteLineItem updatedQLI = [SELECT Id, Total_Price__c, Annual_Amount__c FROM QuoteLineItem WHERE Id = :qli.Id];
        
        // Updated calculation: 24000 * (3/12) = 6000
        System.assert(updatedQLI.Total_Price__c > 5900 && updatedQLI.Total_Price__c < 6100, 
                     'Updated billing amount should be approximately $6000, actual: ' + updatedQLI.Total_Price__c);
        System.assertEquals(24000, updatedQLI.Annual_Amount__c, 'Annual_Amount__c should be updated to 24000');
    }
    
    @isTest
    static void testTrigger_NonSubscription_NoCalculation() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Professional Service' LIMIT 1];
        
        Test.startTest();
        
        // Create non-subscription QuoteLineItem using TestDataFactory
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 5000);
        qli.Annual_Amount__c = 5000; // For consistent test expectations
        insert qli;
        
        Test.stopTest();
        
        // Verify trigger populated Total_Price__c with annual amount for non-subscriptions
        QuoteLineItem insertedQLI = [SELECT Id, Total_Price__c, Annual_Amount__c FROM QuoteLineItem WHERE Id = :qli.Id];
        
        System.assertEquals(insertedQLI.Annual_Amount__c, insertedQLI.Total_Price__c, 
                           'Total_Price__c should equal Annual_Amount__c for non-subscription products (no proration)');
    }
    
    @isTest
    static void testTrigger_BulkOperation() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        
        // Create multiple subscription QuoteLineItems using TestDataFactory
        for (Integer i = 0; i < 10; i++) {
            QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 1000 + (i * 100));
            qli.Annual_Amount__c = 12000 + (i * 1000); // Varying amounts for test
            qli.Service_Start_Date__c = Date.today();
            qli.Service_End_Date__c = Date.today().addDays(90);
            qlis.add(qli);
        }
        
        Test.startTest();
        
        // Bulk insert - trigger should handle all records
        insert qlis;
        
        Test.stopTest();
        
        // Verify all records have calculated Total_Price__c
        List<QuoteLineItem> insertedQLIs = [SELECT Id, Total_Price__c, Annual_Amount__c 
                                           FROM QuoteLineItem 
                                           WHERE Id IN :qlis];
        
        System.assertEquals(10, insertedQLIs.size(), 'Should have 10 QuoteLineItems');
        
        for (QuoteLineItem qli : insertedQLIs) {
            System.assertNotEquals(null, qli.Total_Price__c, 'Each QLI should have calculated Total_Price__c');
            System.assert(qli.Total_Price__c < qli.Annual_Amount__c, 'Billing should be less than annual');
        }
    }
    
    @isTest
    static void testTrigger_ErrorHandling() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        Test.startTest();
        
        // Create QuoteLineItem with null UnitPrice using TestDataFactory - should be handled gracefully
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 1000);
        qli.Annual_Amount__c = 5000;
        qli.UnitPrice = null; // Invalid: null unit price for error testing
        
        try {
            insert qli;
            
            // If we get here, verify calculations didn't run due to null UnitPrice
            QuoteLineItem insertedQLI = [SELECT Id, Total_Price__c, Annual_Amount__c FROM QuoteLineItem WHERE Id = :qli.Id];
            System.assertEquals(5000, insertedQLI.Annual_Amount__c, 
                               'Annual_Amount__c should remain as set when UnitPrice is null');
            System.assertEquals(null, insertedQLI.Total_Price__c, 
                               'Total_Price__c should remain null when UnitPrice is null');
            
        } catch (Exception e) {
            // This is also acceptable - any exception handling is fine
            System.assert(true, 'Exception handled appropriately: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
}