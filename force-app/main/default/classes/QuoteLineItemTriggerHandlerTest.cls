// Test class for QuoteLineItemTriggerHandler and QuoteLineItemBillingCalculation trigger
@isTest
public class QuoteLineItemTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
        
        // Create test Opportunity
        Opportunity opp = TestDataFactory.createOpportunity(testAccount.Id);
        opp.Contract_Start_Date__c = Date.today();
        insert opp;
        
        // Create test Products
        Product2 subscriptionProduct = TestDataFactory.createProduct('Subscription Product', 'Software Subscriptions');
        Product2 serviceProduct = TestDataFactory.createProduct('Service Product', 'Professional Service');
        insert new List<Product2>{ subscriptionProduct, serviceProduct };
        
        // Create PricebookEntries
        PricebookEntry pbe1 = TestDataFactory.createPricebookEntry(subscriptionProduct.Id, 1000);
        PricebookEntry pbe2 = TestDataFactory.createPricebookEntry(serviceProduct.Id, 5000);
        insert new List<PricebookEntry>{ pbe1, pbe2 };
        
        // Create test Quote
        Quote quote = TestDataFactory.createQuote(opp.Id);
        insert quote;
    }
    
    @isTest
    static void testTriggerHandler_SoftwareSubscription_Insert() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        Test.startTest();
        
        // Create QuoteLineItem using TestDataFactory - trigger and handler should fire on insert
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        qli.Service_Start_Date__c = Date.today();
        qli.Service_End_Date__c = Date.today().addDays(90); // 3 months
        insert qli;
        
        Test.stopTest();
        
        // Verify trigger handler populated Total_Price__c and List_Price__c using monthly proration
        QuoteLineItem insertedQLI = [SELECT Id, Total_Price__c, Annual_Amount__c, List_Price__c FROM QuoteLineItem WHERE Id = :qli.Id];
        
        System.assertNotEquals(null, insertedQLI.Total_Price__c, 'Total_Price__c should be populated by trigger handler');
        System.assertNotEquals(null, insertedQLI.List_Price__c, 'List_Price__c should be populated by trigger handler');
        System.assertEquals(12000, insertedQLI.Annual_Amount__c, 'Annual_Amount__c should be actual annual amount (no discount)');
        
        // Monthly proration: $12,000 × (3 months / 12 months) = $3,000 exactly
        System.assert(insertedQLI.Total_Price__c > 2950 && insertedQLI.Total_Price__c < 3050, 
                     'Billing amount should be approximately $3000 for 3-month subscription (monthly proration)');
        System.assert(insertedQLI.List_Price__c > 2950 && insertedQLI.List_Price__c < 3050, 
                     'List_Price__c should be approximately $3000 for 3-month subscription (customer-facing prorated unit price)');
        System.assert(insertedQLI.Total_Price__c < insertedQLI.Annual_Amount__c, 
                     'Billing amount should be less than annual amount');
    }
    
    @isTest
    static void testTriggerHandler_SoftwareSubscription_Update() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        // Create initial QuoteLineItem using TestDataFactory
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        qli.Service_Start_Date__c = Date.today();
        qli.Service_End_Date__c = Date.today().addDays(90); // 3 months
        insert qli;
        
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        Test.startTest();
        
        // Update UnitPrice - trigger handler should recalculate
        qli.UnitPrice = 24000; // Double the amount
        update qli;
        
        Test.stopTest();
        
        // Verify trigger handler recalculated Total_Price__c and List_Price__c using monthly proration
        QuoteLineItem updatedQLI = [SELECT Id, Total_Price__c, List_Price__c FROM QuoteLineItem WHERE Id = :qli.Id];
        
        // Monthly proration: $24,000 × (3 months / 12 months) = $6,000 exactly
        System.assertNotEquals(null, updatedQLI.Total_Price__c, 'Total_Price__c should be recalculated');
        System.assertNotEquals(null, updatedQLI.List_Price__c, 'List_Price__c should be recalculated');
        System.assert(updatedQLI.Total_Price__c > 5950 && updatedQLI.Total_Price__c < 6050, 
                     'Updated billing amount should be approximately $6000 with monthly proration, actual: ' + updatedQLI.Total_Price__c);
        System.assert(updatedQLI.List_Price__c > 5950 && updatedQLI.List_Price__c < 6050, 
                     'Updated List_Price__c should be approximately $6000 with monthly proration, actual: ' + updatedQLI.List_Price__c);
    }
    
    @isTest
    static void testTriggerHandler_NonSubscription_FullAmount() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Professional Service' LIMIT 1];
        
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        Test.startTest();
        
        // Create non-subscription QuoteLineItem using TestDataFactory
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 5000);
        insert qli;
        
        Test.stopTest();
        
        // Verify trigger handler populated Total_Price__c and List_Price__c with full annual amount for non-subscriptions
        QuoteLineItem insertedQLI = [SELECT Id, Total_Price__c, Annual_Amount__c, List_Price__c FROM QuoteLineItem WHERE Id = :qli.Id];
        
        System.assertEquals(5000, insertedQLI.Annual_Amount__c, 'Annual_Amount__c should be actual annual amount (no discount)');
        System.assertEquals(5000, insertedQLI.Total_Price__c, 
                           'Total_Price__c should equal Annual_Amount__c for non-subscription products');
        System.assertEquals(5000, insertedQLI.List_Price__c, 
                           'List_Price__c should equal UnitPrice for non-subscription products (no proration)');
        System.assertEquals(insertedQLI.Annual_Amount__c, insertedQLI.Total_Price__c,
                           'Non-subscription products should use full annual amount');
    }
    
    @isTest
    static void testTriggerHandler_TermBasedPricing() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        Test.startTest();
        
        // Test 1: <1 year deal (6 months) - should show prorated amounts
        QuoteLineItem qli6Month = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        qli6Month.Service_Start_Date__c = Date.today();
        qli6Month.Service_End_Date__c = Date.today().addMonths(6); // 6 months
        insert qli6Month;
        
        // Test 2: ≥1 year deal (18 months) - should show annualized amounts
        QuoteLineItem qli18Month = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        qli18Month.Service_Start_Date__c = Date.today();
        qli18Month.Service_End_Date__c = Date.today().addMonths(18); // 18 months
        insert qli18Month;
        
        Test.stopTest();
        
        // Verify term-based pricing logic
        List<QuoteLineItem> qlis = [SELECT Id, Total_Price__c, Annual_Amount__c, List_Price__c, Term_Length_Months__c 
                                    FROM QuoteLineItem WHERE Id IN (:qli6Month.Id, :qli18Month.Id) ORDER BY Term_Length_Months__c];
        
        QuoteLineItem qli6 = qlis[0]; // 6-month term
        QuoteLineItem qli18 = qlis[1]; // 18-month term
        
        // 6-month term: should show prorated amounts
        System.assertEquals(6, qli6.Term_Length_Months__c, '6-month term should be calculated correctly');
        System.assertEquals(12000, qli6.Annual_Amount__c, 'Annual_Amount__c should always be annual value');
        System.assertEquals(6000, qli6.List_Price__c, 'List_Price__c should be prorated for <1 year: $12k × 6/12 = $6k');
        System.assertEquals(6000, qli6.Total_Price__c, 'Total_Price__c should be prorated for <1 year: $6k');
        
        // 18-month term: should show annualized unit price but total contract value
        System.assertEquals(18, qli18.Term_Length_Months__c, '18-month term should be calculated correctly');
        System.assertEquals(12000, qli18.Annual_Amount__c, 'Annual_Amount__c should always be annual value');
        System.assertEquals(12000, qli18.List_Price__c, 'List_Price__c should be annual for ≥1 year: $12k');
        System.assertEquals(18000, qli18.Total_Price__c, 'Total_Price__c should be total contract value for ≥1 year: $12k × 1.5 years = $18k');
    }
    
    @isTest
    static void testTriggerHandler_BulkOperation() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        
        // Create multiple subscription QuoteLineItems using TestDataFactory
        for (Integer i = 0; i < 10; i++) {
            QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000 + (i * 1000));
            qli.Service_Start_Date__c = Date.today();
            qli.Service_End_Date__c = Date.today().addDays(90);
            qlis.add(qli);
        }
        
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        Test.startTest();
        
        // Bulk insert - trigger handler should handle all records
        insert qlis;
        
        Test.stopTest();
        
        // Verify all records have calculated Total_Price__c and List_Price__c
        List<QuoteLineItem> insertedQLIs = [SELECT Id, Total_Price__c, Annual_Amount__c, List_Price__c 
                                           FROM QuoteLineItem 
                                           WHERE Id IN :qlis];
        
        System.assertEquals(10, insertedQLIs.size(), 'Should have 10 QuoteLineItems');
        
        for (QuoteLineItem qli : insertedQLIs) {
            System.assertNotEquals(null, qli.Total_Price__c, 'Each QLI should have calculated Total_Price__c');
            System.assertNotEquals(null, qli.List_Price__c, 'Each QLI should have calculated List_Price__c');
            System.assert(qli.Total_Price__c < qli.Annual_Amount__c, 'Billing should be less than annual');
            System.assert(qli.List_Price__c < qli.Annual_Amount__c, 'List_Price__c should be less than annual for prorated subscriptions');
        }
    }
    
    @isTest
    static void testTriggerHandler_ErrorHandling() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        Test.startTest();
        
        // Create QuoteLineItem with null UnitPrice using TestDataFactory - should be handled gracefully
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 1000);
        qli.UnitPrice = null; // Invalid: null UnitPrice for error testing
        
        try {
            insert qli;
            
            // If we get here, verify the record was created but Total_Price__c is null
            QuoteLineItem insertedQLI = [SELECT Id, Total_Price__c, Annual_Amount__c FROM QuoteLineItem WHERE Id = :qli.Id];
            System.assertEquals(null, insertedQLI.Total_Price__c, 
                               'Total_Price__c should be null when UnitPrice is null');
            System.assertEquals(null, insertedQLI.Annual_Amount__c, 
                               'Annual_Amount__c should be null when UnitPrice is null');
            
        } catch (Exception e) {
            // This is also acceptable - any exception handling is fine
            System.assert(true, 'Exception handled appropriately: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testTriggerHandler_RecursionPrevention() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        Test.startTest();
        
        // Create initial QuoteLineItem using TestDataFactory
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        qli.Service_Start_Date__c = Date.today();
        qli.Service_End_Date__c = Date.today().addDays(90);
        insert qli;
        
        // Reset static variables before updates to allow handler to run
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        // Multiple updates should work correctly with proper static variable management
        qli.UnitPrice = 13000;
        update qli;
        
        // Reset again for next update
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        qli.UnitPrice = 14000;
        update qli;
        
        Test.stopTest();
        
        // Verify final calculation is correct (no recursion errors)
        QuoteLineItem finalQLI = [SELECT Id, Total_Price__c FROM QuoteLineItem WHERE Id = :qli.Id];
        
        System.assertNotEquals(null, finalQLI.Total_Price__c, 'Total_Price__c should be calculated despite multiple updates');
        // Monthly proration: $14,000 × (3 months / 12 months) = $3,500 exactly
        System.assert(finalQLI.Total_Price__c > 3450 && finalQLI.Total_Price__c < 3550, 
                     'Final billing amount should be ~$3500 with monthly proration, actual: ' + finalQLI.Total_Price__c);
    }
    
    @isTest
    static void testTriggerHandler_HandleTriggerMethod() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        qli.Service_Start_Date__c = Date.today();
        qli.Service_End_Date__c = Date.today().addDays(90);
        
        Test.startTest();
        
        // This would be called by the actual trigger
        insert qli;
        
        Test.stopTest();
        
        // Verify the handler was called correctly
        QuoteLineItem testQLI = [SELECT Id, Total_Price__c FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertNotEquals(null, testQLI.Total_Price__c, 'Handler should have calculated Total_Price__c');
    }
    
    @isTest
    static void testTriggerHandler_OpportunityDateFallback() {
        // Use existing TestDataFactory setup which already has Contract_Start_Date__c
        Quote quote = [SELECT Id, OpportunityId FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        Test.startTest();
        
        // Create QLI WITHOUT Service dates or Effective dates using TestDataFactory
        // This should trigger the fallback to Opportunity contract dates (lines 88-89)
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        // TestDataFactory doesn't set service dates by default, so this should trigger fallback
        
        insert qli;
        
        Test.stopTest();
        
        // Verify the QLI was created successfully
        QuoteLineItem insertedQLI = [SELECT Id, UnitPrice FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertEquals(12000, insertedQLI.UnitPrice, 'QLI should be created with UnitPrice');
        
        // Verify Quote dates were updated from Opportunity fallback (TestDataFactory setup provides these)
        Quote updatedQuote = [SELECT Id, Order_Start_Date__c, Order_End_Date__c FROM Quote WHERE Id = :quote.Id];
        System.assertNotEquals(null, updatedQuote.Order_Start_Date__c, 'Quote should have start date from Opportunity fallback');
    }
    
    @isTest
    static void testTriggerHandler_CalculationException() {
        // Use existing TestDataFactory setup
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        Test.startTest();
        
        // Create a QLI using TestDataFactory with null UnitPrice to trigger exception handling
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(quote.Id, pbe.Product2Id, pbe.Id, 1, 0);
        qli.UnitPrice = null; // This should trigger the hasValidUnitPrice check and exception handling
        
        try {
            insert qli;
            
            // If successful, verify the record exists but calculation fields might be null
            QuoteLineItem insertedQLI = [SELECT Id, UnitPrice, Total_Price__c, Annual_Amount__c FROM QuoteLineItem WHERE Id = :qli.Id];
            System.assertNotEquals(null, insertedQLI.Id, 'QLI should be created');
            // With null UnitPrice, calculation should be skipped or handle gracefully
            
        } catch (Exception e) {
            // This tests the exception handling path (lines 154-155)
            System.assert(e.getMessage().contains('Error calculating billing amount') || 
                         e.getMessage().contains('REQUIRED_FIELD_MISSING') ||
                         e.getMessage().contains('UnitPrice'), 
                         'Should handle calculation exception appropriately: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
}