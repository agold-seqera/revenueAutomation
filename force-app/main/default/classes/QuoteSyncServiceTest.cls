// Test class for QuoteSyncService
@IsTest
private class QuoteSyncServiceTest {
    
    @TestSetup
    static void makeData() {
        // Create test account using TestDataFactory
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
        
        // Create test contact for Contract Signer
        Contact testContact = TestDataFactory.createContact(testAccount.Id, 'Test', 'Signer');
        insert testContact;
        
        // Create test opportunity
        Opportunity testOpp = TestDataFactory.createOpportunity(testAccount.Id);
        insert testOpp;
        
        // Create test products
        Product2 product1 = TestDataFactory.createProduct('Software Product', 'Software Subscriptions');
        Product2 product2 = TestDataFactory.createProduct('Service Product', 'Professional Service');
        insert new List<Product2>{product1, product2};
        
        // Create pricebook entries
        PricebookEntry standardPrice1 = TestDataFactory.createPricebookEntry(product1.Id, 100);
        PricebookEntry standardPrice2 = TestDataFactory.createPricebookEntry(product2.Id, 200);
        insert new List<PricebookEntry>{standardPrice1, standardPrice2};
        
        // Create test quote with all required fields
        Quote testQuote = TestDataFactory.createQuote(testOpp.Id, 'Test Quote');
        testQuote.Status = 'Draft';
        testQuote.Billing_Frequency__c = 'Monthly';
        testQuote.Contract_Start_Date__c = Date.today();
        testQuote.Payment_Terms__c = 'Net 30';
        testQuote.Term_Length_Months__c = 12;
        testQuote.PO_Status__c = 'Not Required';
        testQuote.Contract_Signer__c = testContact.Id;
        insert testQuote;
        
        // Create test quote line items with different product families
        QuoteLineItem qli1 = TestDataFactory.createQuoteLineItem(
            testQuote.Id, product1.Id, standardPrice1.Id, 1, 100
        );
        qli1.Description = 'Software License';
        qli1.Discount = 10;
        
        QuoteLineItem qli2 = TestDataFactory.createQuoteLineItem(
            testQuote.Id, product2.Id, standardPrice2.Id, 2, 200
        );
        qli2.Description = 'Implementation Service';
        qli2.Discount = 5;
        qli2.ServiceDate = Date.today().addDays(7);
        
        insert new List<QuoteLineItem>{qli1, qli2};
    }
    
    @IsTest
    static void testSyncQuotesToOpportunities() {
        Quote testQuote = [
            SELECT Id, Status, OpportunityId, Billing_Frequency__c, Contract_Signer__c,
                   Contract_Start_Date__c, Payment_Terms__c, Term_Length_Months__c
            FROM Quote LIMIT 1
        ];
        testQuote.Status = 'Accepted';
        update testQuote;
        
        Test.startTest();
        
        QuoteSyncService.syncQuotesToOpportunities(new List<Quote>{testQuote});
        
        Test.stopTest();
        
        // Verify OLIs were created with correct field mappings
        List<OpportunityLineItem> olis = [
            SELECT Id, OpportunityId, Product2Id, Quantity, UnitPrice, TotalPrice,
                   Billing_Amount__c, Prorated_Unit_Price__c, Product_Family__c, Description, Discount, ServiceDate,
                   Term_Start_Date__c, Term_End_Date__c, Quote__c, QuoteLineItem__c
            FROM OpportunityLineItem 
            WHERE OpportunityId = :testQuote.OpportunityId
            ORDER BY UnitPrice
        ];
        
        System.assertEquals(2, olis.size(), 'Should have created 2 OLIs');
        
        // Verify first OLI (Software Product - UnitPrice 100)
        OpportunityLineItem oli1 = olis[0];
        System.assertEquals(testQuote.OpportunityId, oli1.OpportunityId);
        System.assertEquals(1, oli1.Quantity);
        
        // Verify our corrected pricing logic:
        // UnitPrice should be annual (qli.UnitPrice) = 100
        System.assertEquals(100, oli1.UnitPrice, 'UnitPrice should be annual amount (qli.UnitPrice)');
        // TotalPrice should be auto-calculated by Salesforce: UnitPrice × Quantity × (1 - Discount/100) = 100 × 1 × 0.9 = 90
        System.assertEquals(90, oli1.TotalPrice, 'TotalPrice should be UnitPrice × Quantity × (1 - Discount/100) (auto-calculated by Salesforce)');
        // Prorated_Unit_Price__c should be qli.List_Price__c (customer-facing prorated)
        System.assertNotEquals(null, oli1.Prorated_Unit_Price__c, 'Prorated_Unit_Price__c should be populated from qli.List_Price__c');
        // Billing_Amount__c should be qli.Total_Price__c (prorated total for billing)
        System.assertNotEquals(null, oli1.Billing_Amount__c, 'Billing_Amount__c should be populated from qli.Total_Price__c');
        
        System.assertNotEquals(null, oli1.Product_Family__c, 'Product_Family__c should be populated');
        System.assertEquals('Software License', oli1.Description);
        System.assertEquals(10, oli1.Discount);
        System.assertEquals(testQuote.Id, oli1.Quote__c, 'Should reference source quote');
        System.assertNotEquals(null, oli1.QuoteLineItem__c, 'Should reference source QLI');
        
        // Verify second OLI (Service Product - UnitPrice 200)
        OpportunityLineItem oli2 = olis[1];
        System.assertEquals(2, oli2.Quantity);
        
        // Verify our corrected pricing logic:
        // UnitPrice should be annual (qli.UnitPrice) = 200
        System.assertEquals(200, oli2.UnitPrice, 'UnitPrice should be annual amount (qli.UnitPrice)');
        // TotalPrice should be auto-calculated by Salesforce: UnitPrice × Quantity × (1 - Discount/100) = 200 × 2 × 0.95 = 380
        System.assertEquals(380, oli2.TotalPrice, 'TotalPrice should be UnitPrice × Quantity × (1 - Discount/100) (auto-calculated by Salesforce)');
        // Prorated_Unit_Price__c should be qli.List_Price__c (customer-facing prorated)
        System.assertNotEquals(null, oli2.Prorated_Unit_Price__c, 'Prorated_Unit_Price__c should be populated from qli.List_Price__c');
        // Billing_Amount__c should be qli.Total_Price__c (prorated total for billing)
        System.assertNotEquals(null, oli2.Billing_Amount__c, 'Billing_Amount__c should be populated from qli.Total_Price__c');
        
        System.assertNotEquals(null, oli2.Product_Family__c, 'Product_Family__c should be populated');
        System.assertEquals('Implementation Service', oli2.Description);
        System.assertEquals(5, oli2.Discount);
    }
    
        @IsTest
    static void testSyncQuoteLevelFields() {
        Quote testQuote = [
            SELECT Id, OpportunityId, Billing_Frequency__c, Contract_Signer__c,
                   Contract_Start_Date__c, Payment_Terms__c, Term_Length_Months__c
            FROM Quote LIMIT 1
        ];
        testQuote.Status = 'Accepted';
        testQuote.Billing_Frequency__c = 'Monthly';
        testQuote.Payment_Terms__c = 'Net 30';
        testQuote.Term_Length_Months__c = 12;
        update testQuote;
        
        Test.startTest();
        
        QuoteSyncService.syncQuotesToOpportunities(new List<Quote>{testQuote});
        
        Test.stopTest();
        
        // Verify opportunity was updated with quote fields
        Opportunity updatedOpp = [
            SELECT Id, Synced_Quote__c, Contract_Billing_Frequency__c, Contract_Signer__c,
                   Contract_Start_Date__c, Contract_End_Date_Override__c, Payment_Terms__c, Term_Length_Months__c
            FROM Opportunity 
            WHERE Id = :testQuote.OpportunityId
        ];
        
        // Verify our custom Synced_Quote__c field is properly stamped
        System.assertEquals(testQuote.Id, updatedOpp.Synced_Quote__c, 'Synced_Quote__c should be stamped with the synced quote ID');
        System.assertEquals('Monthly', updatedOpp.Contract_Billing_Frequency__c);
        System.assertEquals([SELECT Id FROM Contact LIMIT 1].Id, updatedOpp.Contract_Signer__c);
        System.assertEquals(Date.today(), updatedOpp.Contract_Start_Date__c, 'Contract_Start_Date__c should be synced from Order_Start_Date__c');
        System.assertEquals(Date.today().addMonths(12), updatedOpp.Contract_End_Date_Override__c, 'Contract_End_Date_Override__c should be synced from Order_End_Date__c');
        System.assertEquals('Net 30', updatedOpp.Payment_Terms__c);
        System.assertEquals(12, updatedOpp.Term_Length_Months__c);
    }
    
    @IsTest
    static void testSyncedQuoteStatusManagement() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create additional quotes using TestDataFactory
        Quote quote1 = TestDataFactory.createQuote(testOpp.Id, 'Quote 1');
        quote1.Status = 'Accepted';
        quote1.Synced_Quote__c = true;  // Previously synced
        quote1.Billing_Frequency__c = 'Monthly';
        quote1.Payment_Terms__c = 'Net 30';
        quote1.PO_Status__c = 'Not Required';
        quote1.Contract_Signer__c = [SELECT Id FROM Contact LIMIT 1].Id;
        
        Quote quote2 = TestDataFactory.createQuote(testOpp.Id, 'Quote 2');
        quote2.Status = 'Accepted';
        quote2.Billing_Frequency__c = 'Monthly';
        quote2.Payment_Terms__c = 'Net 30';
        quote2.PO_Status__c = 'Not Required';
        quote2.Contract_Signer__c = [SELECT Id FROM Contact LIMIT 1].Id;
        
        insert new List<Quote>{quote1, quote2};
        
        Test.startTest();
        
        // Sync the new quote
        QuoteSyncService.syncQuotesToOpportunities(new List<Quote>{quote2});
        
        Test.stopTest();
        
        // Verify sync status management
        List<Quote> quotes = [SELECT Id, Synced_Quote__c FROM Quote WHERE OpportunityId = :testOpp.Id];
        
        for (Quote q : quotes) {
            if (q.Id == quote2.Id) {
                System.assertEquals(true, q.Synced_Quote__c, 'New synced quote should be marked true');
            } else {
                System.assertEquals(false, q.Synced_Quote__c, 'Other quotes should be marked false');
            }
        }
    }
    
    @IsTest
    static void testDeleteExistingOLIs() {
        Quote testQuote = [
            SELECT Id, OpportunityId, Billing_Frequency__c, Contract_Signer__c,
                   Contract_Start_Date__c, Payment_Terms__c, Term_Length_Months__c
            FROM Quote LIMIT 1
        ];
        
        OpportunityLineItem existingOLI = new OpportunityLineItem(
            OpportunityId = testQuote.OpportunityId,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'Software Product' LIMIT 1].Id,
            Quantity = 1,
            UnitPrice = 50
        );
        insert existingOLI;
        
        testQuote.Status = 'Accepted';
        update testQuote;
        
        Test.startTest();
        
        QuoteSyncService.syncQuotesToOpportunities(new List<Quote>{testQuote});
        
        Test.stopTest();
        
        // Verify existing OLIs were deleted and new ones created
        List<OpportunityLineItem> olis = [
            SELECT Id, Quote__c 
            FROM OpportunityLineItem 
            WHERE OpportunityId = :testQuote.OpportunityId
        ];
        
        // Should only have new OLIs from the quote (2 QLIs in test data)
        System.assertEquals(2, olis.size(), 'Should have only new OLIs from quote');
        
        for (OpportunityLineItem oli : olis) {
            System.assertEquals(testQuote.Id, oli.Quote__c, 'All OLIs should reference the synced quote');
        }
    }
    
    @IsTest
    static void testEmptyQuoteList() {
        Test.startTest();
        
        QuoteSyncService.syncQuotesToOpportunities(new List<Quote>());
        
        Test.stopTest();
        
        // Should complete without error
        System.assert(true, 'Empty list should be handled gracefully');
    }
    
    @IsTest
    static void testQuoteWithoutLineItemsHandling() {
        Quote testQuote = [
            SELECT Id, OpportunityId, Billing_Frequency__c, Contract_Signer__c,
                   Contract_Start_Date__c, Payment_Terms__c, Term_Length_Months__c
            FROM Quote LIMIT 1
        ];
        
        // Delete all line items
        delete [SELECT Id FROM QuoteLineItem WHERE QuoteId = :testQuote.Id];
        
        testQuote.Status = 'Accepted';
        update testQuote;
        
        Test.startTest();
        
        QuoteSyncService.syncQuotesToOpportunities(new List<Quote>{testQuote});
        
        Test.stopTest();
        
        // Should not create any OLIs
        List<OpportunityLineItem> olis = [
            SELECT Id FROM OpportunityLineItem 
            WHERE OpportunityId = :testQuote.OpportunityId
        ];
        
        System.assertEquals(0, olis.size(), 'No OLIs should be created when quote has no line items');
        
        // Quote should still be marked as synced
        Quote syncedQuote = [SELECT Id, Synced_Quote__c FROM Quote WHERE Id = :testQuote.Id];
        System.assertEquals(true, syncedQuote.Synced_Quote__c, 'Quote should still be marked as synced');
    }
    
    @IsTest
    static void testBulkSyncPerformance() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        List<Quote> bulkQuotes = new List<Quote>();
        
        // Reduce to 5 quotes to avoid governor limits in test
        for (Integer i = 0; i < 5; i++) {
            Quote quote = TestDataFactory.createQuote(testOpp.Id, 'Bulk Quote ' + i);
            quote.Status = 'Accepted';
            quote.Billing_Frequency__c = 'Monthly';
            quote.Term_Length_Months__c = 12;
            quote.Payment_Terms__c = 'Net 30';
            quote.PO_Status__c = 'Not Required';
            quote.Contract_Signer__c = testContact.Id;
            bulkQuotes.add(quote);
        }
        insert bulkQuotes;
        
        Test.startTest();
        
        QuoteSyncService.syncQuotesToOpportunities(bulkQuotes);
        
        Test.stopTest();
        
        // Only last quote should be synced
        List<Quote> syncedQuotes = [
            SELECT Id, Synced_Quote__c FROM Quote 
            WHERE OpportunityId = :testOpp.Id AND Synced_Quote__c = true
        ];
        
        System.assertEquals(1, syncedQuotes.size(), 'Only one quote should remain synced');
    }
    
    @IsTest
    static void testCustomSyncedQuoteFieldStamping() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Create two quotes using TestDataFactory
        Quote quote1 = TestDataFactory.createQuote(testOpp.Id, 'Quote 1');
        quote1.Status = 'Accepted';
        quote1.Billing_Frequency__c = 'Monthly';
        quote1.Payment_Terms__c = 'Net 30';
        quote1.PO_Status__c = 'Not Required';
        quote1.Contract_Signer__c = testContact.Id;
        
        Quote quote2 = TestDataFactory.createQuote(testOpp.Id, 'Quote 2');
        quote2.Status = 'Accepted';
        quote2.Billing_Frequency__c = 'Monthly';
        quote2.Payment_Terms__c = 'Net 30';
        quote2.PO_Status__c = 'Not Required';
        quote2.Contract_Signer__c = testContact.Id;
        
        insert new List<Quote>{quote1, quote2};
        
        Test.startTest();
        
        // Sync first quote
        QuoteSyncService.syncQuotesToOpportunities(new List<Quote>{quote1});
        
        // Verify opportunity has first quote stamped
        Opportunity opp1 = [SELECT Id, Synced_Quote__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(quote1.Id, opp1.Synced_Quote__c, 'Opportunity should reference first synced quote');
        
        // Sync second quote  
        QuoteSyncService.syncQuotesToOpportunities(new List<Quote>{quote2});
        
        // Verify opportunity now has second quote stamped
        Opportunity opp2 = [SELECT Id, Synced_Quote__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(quote2.Id, opp2.Synced_Quote__c, 'Opportunity should reference newly synced quote');
        
        // Verify quote sync status
        List<Quote> quotes = [SELECT Id, Synced_Quote__c FROM Quote WHERE OpportunityId = :testOpp.Id];
        for (Quote q : quotes) {
            if (q.Id == quote2.Id) {
                System.assertEquals(true, q.Synced_Quote__c, 'Second quote should be marked as synced');
            } else {
                System.assertEquals(false, q.Synced_Quote__c, 'First quote should no longer be marked as synced');
            }
        }
        
        Test.stopTest();
    }
}