// Test class for Quote Line Item pricing calculations and business logic
// Tests the Quote_After_Save_Create_Line_Items_from_Opportunity flow 
// and QuoteLineItemTriggerHandler pricing calculations
// 
// Validates core Quote System pricing functionality:
// - Annual amount calculations with discounts
// - Total price calculations and proration
// - Service date hierarchy and term calculations
// - Opportunity Line Item to Quote Line Item conversion
// - Bulk pricing operations and edge cases
@isTest
public class QuoteLineItemPricingTest {
    
    @testSetup
    static void setupTestData() {
        // Use TestDataFactory for consistent test data creation
        Account testAccount = TestDataFactory.createAccount('Test Account');
        insert testAccount;
        
        Opportunity testOpp = TestDataFactory.createOpportunity(testAccount.Id, 'Quote Pricing Test Opportunity');
        testOpp.StageName = 'Proposal';
        testOpp.Contract_Start_Date__c = Date.today();
        insert testOpp;
        
        // Get standard pricebook
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create Products using TestDataFactory
        Product2 softwareProduct = TestDataFactory.createProduct('Software Subscription Product', 'Software Subscriptions');
        Product2 serviceProduct = TestDataFactory.createProduct('Professional Service Product', 'Professional Service');
        insert new List<Product2>{ softwareProduct, serviceProduct };
        
        // Create PricebookEntries using TestDataFactory
        PricebookEntry softwarePBE = TestDataFactory.createPricebookEntry(softwareProduct.Id, 100000); // $100k list price
        PricebookEntry servicePBE = TestDataFactory.createPricebookEntry(serviceProduct.Id, 10000); // $10k list price
        insert new List<PricebookEntry>{ softwarePBE, servicePBE };
        
        // Create OpportunityLineItems using TestDataFactory
        OpportunityLineItem softwareOLI = TestDataFactory.createOpportunityLineItem(testOpp.Id, softwareProduct.Id, softwarePBE.Id, 1, 100000);
        softwareOLI.Discount = 50; // 50% discount
        
        OpportunityLineItem serviceOLI = TestDataFactory.createOpportunityLineItem(testOpp.Id, serviceProduct.Id, servicePBE.Id, 1, 10000);
        // No discount for service
        
        insert new List<OpportunityLineItem>{ softwareOLI, serviceOLI };
        
        // Create Quote using TestDataFactory
        Quote testQuote = TestDataFactory.createQuote(testOpp.Id, standardPricebookId, 'Quote Pricing Test Quote');
        testQuote.Order_Start_Date__c = Date.today();
        testQuote.Order_End_Date__c = Date.today().addDays(365);
        testQuote.Auto_Create_Line_Items__c = false; // We'll trigger this in tests
        insert testQuote;
    }
    
    @isTest
    static void testQuoteLineItemCreation_SoftwareSubscriptionWithDiscount() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        
        // Trigger the flow by setting Auto_Create_Line_Items__c = true
        testQuote.Auto_Create_Line_Items__c = true;
        update testQuote;
        
        Test.stopTest();
        
        // Validate the generated Software Subscription QLI
        List<QuoteLineItem> softwareQLIs = [
            SELECT Id, UnitPrice, Quantity, Discount, TotalPrice, Annual_Amount__c, 
                   Total_Price__c, List_Price__c, Term_Length_Months__c, Product_Family__c,
                   Service_Start_Date__c, Service_End_Date__c
            FROM QuoteLineItem 
            WHERE QuoteId = :testQuote.Id 
            AND Product_Family__c = 'Software Subscriptions'
        ];
        
        System.assertEquals(1, softwareQLIs.size(), 'Should have exactly 1 Software Subscriptions QLI');
        QuoteLineItem softwareQLI = softwareQLIs[0];
        
        // Validate field mappings from flow
        System.assertEquals(100000, softwareQLI.UnitPrice, 'UnitPrice should be annual amount (what reps work with)');
        System.assertEquals(100000, softwareQLI.List_Price__c, 'List_Price__c should be prorated unit price (NO discount): $100k * 12/12 months = $100k');
        System.assertEquals(50, softwareQLI.Discount, 'Discount should be copied from OLI');
        System.assertEquals(1, softwareQLI.Quantity, 'Quantity should be copied from OLI');
        
        // Service dates should be null (user override fields only)
        System.assertEquals(null, softwareQLI.Service_Start_Date__c, 'Service_Start_Date__c should be null (user override only)');
        System.assertEquals(null, softwareQLI.Service_End_Date__c, 'Service_End_Date__c should be null (user override only)');
        
        // Validate trigger handler calculations
        System.assertEquals(50000, softwareQLI.Annual_Amount__c, 'Annual_Amount__c should be actual annual amount (after discount)');
        System.assertEquals(50000, softwareQLI.Total_Price__c, 'Total_Price__c should equal Annual_Amount__c for 12-month term');
        System.assertEquals(50000, softwareQLI.TotalPrice, 'TotalPrice (standard) should match Total_Price__c (custom)');
        System.assertEquals(12, softwareQLI.Term_Length_Months__c, 'Term should default to 12 months');
    }
    
    @isTest
    static void testQuoteLineItemCreation_ProfessionalServiceNoDiscount() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        
        // Trigger the flow
        testQuote.Auto_Create_Line_Items__c = true;
        update testQuote;
        
        Test.stopTest();
        
        // Validate the generated Professional Service QLI
        List<QuoteLineItem> serviceQLIs = [
            SELECT Id, UnitPrice, Quantity, Discount, TotalPrice, Annual_Amount__c,
                   Total_Price__c, List_Price__c, Term_Length_Months__c, Product_Family__c
            FROM QuoteLineItem 
            WHERE QuoteId = :testQuote.Id 
            AND Product_Family__c = 'Professional Service'
        ];
        
        System.assertEquals(1, serviceQLIs.size(), 'Should have exactly 1 Professional Service QLI');
        QuoteLineItem serviceQLI = serviceQLIs[0];
        
        // Validate field mappings
        System.assertEquals(10000, serviceQLI.UnitPrice, 'UnitPrice should be sales price from OLI');
        System.assertEquals(10000, serviceQLI.List_Price__c, 'List_Price__c should be sales price');
        System.assertEquals(null, serviceQLI.Discount, 'Discount should be null (no discount on service)');
        
        // Validate trigger calculations for non-subscription
        System.assertEquals(10000, serviceQLI.Annual_Amount__c, 'Annual_Amount__c should be actual annual amount (no discount applied)');
        System.assertEquals(10000, serviceQLI.Total_Price__c, 'Total_Price__c should equal Annual_Amount__c (no proration for services)');
        System.assertEquals(10000, serviceQLI.TotalPrice, 'TotalPrice should match Total_Price__c');
        System.assertEquals(12, serviceQLI.Term_Length_Months__c, 'Term should default to 12 months');
    }
    
    @isTest
    static void testPricingCalculations_QuantityHandling() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        Test.startTest();
        
        // Create QLI with quantity > 1 using TestDataFactory
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(testQuote.Id, pbe.Product2Id, pbe.Id, 2, 50000);
        qli.Discount = 20; // 20% discount
        insert qli;
        
        Test.stopTest();
        
        // Reload to get calculated fields
        qli = [SELECT Annual_Amount__c, Total_Price__c FROM QuoteLineItem WHERE Id = :qli.Id];
        
        // Validate quantity handling  
        System.assertEquals(80000, qli.Annual_Amount__c, 'Annual_Amount__c should be actual annual amount after discount ($50k × 2 × 80% = $80k)');
        System.assertEquals(80000, qli.Total_Price__c, 'Total_Price__c should equal Annual_Amount__c for 12-month term');
    }
    
    @isTest
    static void testPricingCalculations_ServiceDateHierarchy() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        // Reset static variables to ensure trigger handler runs
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        Test.startTest();
        
        // Create test QLIs for service date hierarchy testing using TestDataFactory
        QuoteLineItem qliWithServiceDates = TestDataFactory.createQuoteLineItem(testQuote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        qliWithServiceDates.Service_Start_Date__c = Date.today();
        qliWithServiceDates.Service_End_Date__c = Date.today().addDays(90); // 3 months
        
        QuoteLineItem qliWithoutServiceDates = TestDataFactory.createQuoteLineItem(testQuote.Id, pbe.Product2Id, pbe.Id, 1, 12000);
        
        // Insert both together to trigger handler in single transaction
        insert new List<QuoteLineItem>{ qliWithServiceDates, qliWithoutServiceDates };
        
        Test.stopTest();
        
        // Reload to get calculated fields
        List<QuoteLineItem> qlis = [
            SELECT Id, Total_Price__c, Annual_Amount__c, Term_Length_Months__c, Service_Start_Date__c
            FROM QuoteLineItem 
            WHERE Id IN (:qliWithServiceDates.Id, :qliWithoutServiceDates.Id)
            ORDER BY Service_Start_Date__c NULLS LAST
        ];
        
        QuoteLineItem qliWithDates = qlis[0];
        QuoteLineItem qliWithoutDates = qlis[1];
        
        // Validate Service date hierarchy
        System.assertEquals(3, qliWithDates.Term_Length_Months__c, 'Should calculate 3 months from Service dates');
        System.assertEquals(12000, qliWithDates.Annual_Amount__c, 'Annual_Amount__c should be actual annual amount');
        System.assertEquals(3000, qliWithDates.Total_Price__c, 'Should prorate: $12k × 3/12 = $3k');
        
        System.assertEquals(12, qliWithoutDates.Term_Length_Months__c, 'Should default to 12 months when no dates');
        System.assertEquals(12000, qliWithoutDates.Annual_Amount__c, 'Annual_Amount__c should be actual annual amount');
        System.assertEquals(12000, qliWithoutDates.Total_Price__c, 'Should use full amount: $12k × 12/12 = $12k');
    }
    
    @isTest
    static void testPricingCalculations_EdgeCases() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        // Reset static variables to ensure trigger handler runs
        QuoteLineItemTriggerHandler.resetStaticVariables();
        
        Test.startTest();
        
        // Create both test QLIs using TestDataFactory
        QuoteLineItem qliFullDiscount = TestDataFactory.createQuoteLineItem(testQuote.Id, pbe.Product2Id, pbe.Id, 1, 10000);
        qliFullDiscount.Discount = 100;
        
        QuoteLineItem qliNoDiscount = TestDataFactory.createQuoteLineItem(testQuote.Id, pbe.Product2Id, pbe.Id, 1, 10000);
        qliNoDiscount.Discount = 0;
        
        // Insert both together to trigger handler in single transaction
        insert new List<QuoteLineItem>{ qliFullDiscount, qliNoDiscount };
        
        Test.stopTest();
        
        // Reload to get calculated fields
        Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>([
            SELECT Id, Annual_Amount__c, Total_Price__c, Discount
            FROM QuoteLineItem 
            WHERE Id IN (:qliFullDiscount.Id, :qliNoDiscount.Id)
        ]);
        
        QuoteLineItem fullDiscountQLI = qliMap.get(qliFullDiscount.Id);
        QuoteLineItem noDiscountQLI = qliMap.get(qliNoDiscount.Id);
        
        // Validate edge cases
        System.assertEquals(0, fullDiscountQLI.Annual_Amount__c, 'Annual_Amount__c should be 0 with 100% discount');
        System.assertEquals(0, fullDiscountQLI.Total_Price__c, 'Total_Price__c should be 0 with 100% discount');
        
        System.assertEquals(10000, noDiscountQLI.Annual_Amount__c, 'Annual_Amount__c should be full amount with 0% discount');
        System.assertEquals(10000, noDiscountQLI.Total_Price__c, 'Total_Price__c should equal Annual_Amount__c with 0% discount');
    }
    
    @isTest
    static void testPricingCalculations_BulkOperations() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        
        // Create 10 QLIs with different scenarios using TestDataFactory
        for (Integer i = 0; i < 10; i++) {
            QuoteLineItem qli = TestDataFactory.createQuoteLineItem(testQuote.Id, pbe.Product2Id, pbe.Id, 1 + i, 10000 + (i * 1000));
            qli.Discount = i * 10; // Varying discounts (0%, 10%, 20%, etc.)
            qlis.add(qli);
        }
        
        Test.startTest();
        
        // Bulk insert should trigger handler for all records
        insert qlis;
        
        Test.stopTest();
        
        // Validate all records were processed
        List<QuoteLineItem> insertedQLIs = [
            SELECT Id, UnitPrice, Quantity, Discount, Annual_Amount__c, Total_Price__c
            FROM QuoteLineItem 
            WHERE Id IN :qlis
            ORDER BY UnitPrice
        ];
        
        System.assertEquals(10, insertedQLIs.size(), 'Should have 10 QLIs');
        
        for (Integer i = 0; i < insertedQLIs.size(); i++) {
            QuoteLineItem qli = insertedQLIs[i];
            Decimal baseAmount = qli.UnitPrice * qli.Quantity;
            Decimal expectedAnnual = baseAmount * (1 - (qli.Discount / 100));
            
            System.assertEquals(expectedAnnual, qli.Annual_Amount__c, 
                'Annual_Amount__c should be actual annual amount (after discount) for record ' + i);
            System.assertEquals(expectedAnnual, qli.Total_Price__c, 
                'Total_Price__c should equal Annual_Amount__c for 12-month term for record ' + i);
        }
    }
    
    @isTest
    static void testPricingCalculations_AutoCalculation() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Family = 'Software Subscriptions' LIMIT 1];
        
        Test.startTest();
        
        // Create QLI without Annual_Amount__c using TestDataFactory - trigger should auto-calculate
        QuoteLineItem qli = TestDataFactory.createQuoteLineItem(testQuote.Id, pbe.Product2Id, pbe.Id, 1, 10000);
        // Note: Not setting Annual_Amount__c - trigger should calculate it automatically
        
        // This should succeed and trigger should populate pricing fields
        insert qli;
        
        Test.stopTest();
        
        // Verify the record was created and Annual_Amount__c was calculated
        QuoteLineItem insertedQLI = [
            SELECT Id, Annual_Amount__c, Total_Price__c 
            FROM QuoteLineItem 
            WHERE Id = :qli.Id
        ];
        
        System.assertEquals(10000, insertedQLI.Annual_Amount__c, 'Trigger should have calculated Annual_Amount__c (actual annual amount)');
        System.assertEquals(10000, insertedQLI.Total_Price__c, 'Trigger should have calculated Total_Price__c');
    }
}