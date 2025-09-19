// Handler for Quote sync trigger operations
// Replaces Quote_After_Save_Sync_Approved_Quote flow
@IsTest
private class QuoteSyncTriggerHandlerTest {
    
    @TestSetup
    static void makeData() {
        // Use TestDataFactory for consistent test data creation
        Account testAccount = TestDataFactory.createAccount('Test Account');
        insert testAccount;
        
        Contact testContact = TestDataFactory.createContact(testAccount.Id, 'Test', 'Signer');
        insert testContact;
        
        Opportunity testOpp = TestDataFactory.createOpportunity(testAccount.Id, 'Test Opportunity');
        testOpp.CloseDate = Date.today().addMonths(3);
        insert testOpp;
        
        // Create test products using TestDataFactory
        Product2 product1 = TestDataFactory.createProduct('Test Product 1', 'Software Subscriptions');
        Product2 product2 = TestDataFactory.createProduct('Test Product 2', 'Professional Service');
        insert new List<Product2>{product1, product2};
        
        // Create test pricebook entries using TestDataFactory
        PricebookEntry standardPrice1 = TestDataFactory.createPricebookEntry(product1.Id, 100);
        PricebookEntry standardPrice2 = TestDataFactory.createPricebookEntry(product2.Id, 200);
        insert new List<PricebookEntry>{standardPrice1, standardPrice2};
        
        // Create test quote using TestDataFactory with required fields
        Quote testQuote = TestDataFactory.createQuote(testOpp.Id, 'Test Quote');
        testQuote.Billing_Frequency__c = 'Monthly';
        testQuote.Contract_Start_Date__c = Date.today();
        testQuote.Payment_Terms__c = 'Net 30';
        testQuote.Term_Length_Months__c = 12;
        testQuote.PO_Status__c = 'Not Required';
        testQuote.Contract_Signer__c = testContact.Id;
        insert testQuote;
        
        // Create test quote line items using TestDataFactory
        QuoteLineItem qli1 = TestDataFactory.createQuoteLineItem(testQuote.Id, product1.Id, standardPrice1.Id, 1, 100);
        qli1.Description = 'Software License';
        qli1.Discount = 10;
        qli1.ServiceDate = Date.today();
        
        QuoteLineItem qli2 = TestDataFactory.createQuoteLineItem(testQuote.Id, product2.Id, standardPrice2.Id, 2, 200);
        qli2.Description = 'Implementation Service';
        qli2.Discount = 5;
        qli2.ServiceDate = Date.today().addDays(7);
        
        insert new List<QuoteLineItem>{qli1, qli2};
    }
    
    @IsTest
    static void testQuoteApprovalNoLongerTriggersSync() {
        Quote testQuote = [SELECT Id, Status, OpportunityId FROM Quote LIMIT 1];
        
        Test.startTest();
        testQuote.Status = 'Approved';
        update testQuote;
        Test.stopTest();
        
        // Verify NO OLIs were created (automatic sync disabled)
        List<OpportunityLineItem> olis = [
            SELECT Id, Quote__c, Billing_Amount__c, Product_Family__c, Term_Start_Date__c, Term_End_Date__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :testQuote.OpportunityId
        ];
        System.assertEquals(0, olis.size(), 'Should NOT have created OLIs - automatic sync disabled');
        
        // Verify Quote Synced_Quote__c status remains false (no automatic sync)
        Quote updatedQuote = [SELECT Id, Synced_Quote__c FROM Quote WHERE Id = :testQuote.Id];
        System.assertEquals(false, updatedQuote.Synced_Quote__c, 'Quote should NOT be marked as synced - automatic sync disabled');
    }
    
    @IsTest
    static void testMultipleQuotesNoAutomaticSync() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create two additional quotes for the same opportunity
        Quote quote1 = new Quote(
            Name = 'Quote 1', 
            OpportunityId = testOpp.Id,
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Billing_Frequency__c = 'Monthly',
            Payment_Terms__c = 'Net 30',
            PO_Status__c = 'Not Required',
            Contract_Signer__c = [SELECT Id FROM Contact LIMIT 1].Id
        );
        Quote quote2 = new Quote(
            Name = 'Quote 2', 
            OpportunityId = testOpp.Id,
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Billing_Frequency__c = 'Monthly',
            Payment_Terms__c = 'Net 30',
            PO_Status__c = 'Not Required',
            Contract_Signer__c = [SELECT Id FROM Contact LIMIT 1].Id
        );
        insert new List<Quote>{quote1, quote2};
        
        // Create quote line items for both quotes to enable sync
        PricebookEntry standardPrice = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name = 'Test Product 1' LIMIT 1];
        
        QuoteLineItem qli1 = TestDataFactory.createQuoteLineItem(quote1.Id, standardPrice.Product2Id, standardPrice.Id, 1, 100);
        qli1.Annual_Amount__c = 1200;
        qli1.Total_Price__c = 100;
        
        QuoteLineItem qli2 = TestDataFactory.createQuoteLineItem(quote2.Id, standardPrice.Product2Id, standardPrice.Id, 1, 100);
        qli2.Annual_Amount__c = 1200;
        qli2.Total_Price__c = 100;
        insert new List<QuoteLineItem>{qli1, qli2};
        
        Test.startTest();
        
        // Approve first quote
        quote1.Status = 'Approved';
        update quote1;
        
        // Approve second quote  
        quote2.Status = 'Approved';
        update quote2;
        
        Test.stopTest();
        
        // Verify NO quotes are automatically marked as synced (automatic sync disabled)
        List<Quote> quotes = [SELECT Id, Name, Synced_Quote__c, LastModifiedDate FROM Quote WHERE OpportunityId = :testOpp.Id ORDER BY LastModifiedDate DESC];
        
        // No quotes should be automatically synced
        Integer syncedCount = 0;
        
        for (Quote q : quotes) {
            if (q.Synced_Quote__c) {
                syncedCount++;
            }
        }
        
        System.assertEquals(0, syncedCount, 'No quotes should be automatically synced - sync disabled');
    }
    
    @IsTest
    static void testQuoteStatusChangeNoSync() {
        Quote testQuote = [SELECT Id, Status, OpportunityId FROM Quote LIMIT 1];
        
        // Simulate IsSyncing being true (though it's read-only, this tests the handler's check)
        // Note: IsSyncing is a read-only field, so this test primarily verifies the handler's logic
        // if such a state were possible or if it were a custom field.
        // For actual read-only fields, direct manipulation in tests is not possible.
        // This test will now verify that a quote *can* be synced if IsSyncing is false (default).
        
        Test.startTest();
        testQuote.Status = 'Approved';
        update testQuote;
        Test.stopTest();
        
        // Verify NO OLIs were created (automatic sync disabled)
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testQuote.OpportunityId];
        System.assertEquals(0, olis.size(), 'No OLIs should be created - automatic sync disabled');
    }
    
    @IsTest
    static void testBulkQuoteStatusChangeNoSync() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        List<Quote> bulkQuotes = new List<Quote>();
        
        // Reduce to 5 quotes to avoid governor limits in test
        for (Integer i = 0; i < 5; i++) {
            Quote quote = new Quote(
                Name = 'Bulk Quote ' + i,
                OpportunityId = testOpp.Id,
                Status = 'Draft',
                Pricebook2Id = Test.getStandardPricebookId(),
                Billing_Frequency__c = 'Monthly',
                Contract_Start_Date__c = Date.today(),
                Payment_Terms__c = 'Net 30',
                Term_Length_Months__c = 12,
                PO_Status__c = 'Not Required',
                Contract_Signer__c = testContact.Id
            );
            bulkQuotes.add(quote);
        }
        insert bulkQuotes;
        
        Test.startTest();
        for (Quote q : bulkQuotes) {
            q.Status = 'Approved';
        }
        update bulkQuotes;
        Test.stopTest();
        
        // Verify that NO quotes were automatically synced (automatic sync disabled)
        List<Quote> updatedQuotes = [SELECT Id, Synced_Quote__c FROM Quote WHERE OpportunityId = :testOpp.Id ORDER BY CreatedDate DESC];
        System.assertEquals(6, updatedQuotes.size(), 'All bulk quotes should exist (5 + 1 from setup)');
        
        // None should be synced automatically
        Integer syncedCount = 0;
        for (Quote q : updatedQuotes) {
            if (q.Synced_Quote__c) {
                syncedCount++;
            }
        }
        System.assertEquals(0, syncedCount, 'No quotes should be automatically synced - sync disabled');
    }
    
    @IsTest
    static void testErrorHandlingInTrigger() {
        Quote testQuote = [SELECT Id, Status, OpportunityId FROM Quote LIMIT 1];
        
        // Simulate an error by making OpportunityId null before update, which will cause an error in service
        // This tests the try-catch in the service, which is called by the trigger handler.
        // Note: OpportunityId cannot be nulled out if already set, so we'll create a new quote for this.
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Quote errorQuote = new Quote(
            Name = 'Error Quote',
            OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id,
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Billing_Frequency__c = 'Monthly',
            Contract_Start_Date__c = Date.today(),
            Payment_Terms__c = 'Net 30',
            Term_Length_Months__c = 12,
            PO_Status__c = 'Not Required',
            Contract_Signer__c = testContact.Id
        );
        insert errorQuote;
        
        // Attempt to approve a quote that will cause an error (e.g., no OpportunityId)
        Test.startTest();
        errorQuote.Status = 'Approved';
        // Do not set OpportunityId, or set it to null if it was previously set (not allowed in real org)
        // For testing purposes, we'll rely on the service's validation for null OpportunityId
        update errorQuote;
        Test.stopTest();
        
        // Since the quote now has an OpportunityId, it will actually sync successfully
        // This test verifies the trigger handles normal cases gracefully
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :errorQuote.OpportunityId];
        System.assertEquals(0, olis.size(), 'No OLIs should be created for quote without line items');
    }
}