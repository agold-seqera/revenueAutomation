// GTM-138: Test class for AssetTriggerHandler
// 
// Provides comprehensive test coverage for Asset trigger handler functionality
// including exchange rate inheritance from OpportunityLineItems during Asset creation
// 
// @author Alex Goldstein / Syl Architecture  
// @date September 2025
// @version 1.0
@isTest
public class AssetTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Account using TestDataFactory
        Account testAccount = TestDataFactory.createAccount('Asset Exchange Rate Test Account');
        insert testAccount;
        
        // Create test Opportunity using TestDataFactory (USD to match PricebookEntry)
        Opportunity testOpp = TestDataFactory.createOpportunity(testAccount.Id, 'Asset Test Opportunity');
        testOpp.CurrencyIsoCode = 'USD';
        insert testOpp;
        
        // Create test Product using TestDataFactory
        Product2 testProduct = TestDataFactory.createProduct('Test Product for Assets', 'Software Subscriptions');
        insert testProduct;
        
        // Create PricebookEntry using TestDataFactory
        PricebookEntry testPBE = TestDataFactory.createPricebookEntry(testProduct.Id, 1000);
        insert testPBE;
        
        // Create test OpportunityLineItems with different exchange rate scenarios using TestDataFactory
        List<OpportunityLineItem> testOLIs = new List<OpportunityLineItem>();
        
        // OLI 1: Has exchange rate (will be inherited by Asset)
        OpportunityLineItem oli1 = TestDataFactory.createOpportunityLineItem(
            testOpp.Id, testProduct.Id, testPBE.Id, 1, 1000
        );
        oli1.Exchange_Rate__c = 1.25;
        testOLIs.add(oli1);
        
        // OLI 2: No exchange rate (should not affect Asset)
        OpportunityLineItem oli2 = TestDataFactory.createOpportunityLineItem(
            testOpp.Id, testProduct.Id, testPBE.Id, 2, 2000
        );
        oli2.Exchange_Rate__c = null;
        testOLIs.add(oli2);
        
        // OLI 3: Different exchange rate for bulk testing
        OpportunityLineItem oli3 = TestDataFactory.createOpportunityLineItem(
            testOpp.Id, testProduct.Id, testPBE.Id, 1, 1500
        );
        oli3.Exchange_Rate__c = 1.35;
        testOLIs.add(oli3);
        
        insert testOLIs;
    }
    
    // Test main trigger handler entry point
    @isTest
    static void testHandleTrigger() {
        List<OpportunityLineItem> oliList = [SELECT Id, Exchange_Rate__c FROM OpportunityLineItem WHERE Exchange_Rate__c != null LIMIT 1];
        System.assert(!oliList.isEmpty(), 'Test setup should create OLI with exchange rate');
        
        OpportunityLineItem testOLI = oliList[0];
        
        Test.startTest();
        
        // Test trigger handler during Asset insert using TestDataFactory
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Asset testAsset = TestDataFactory.createAssetWithOLI(
            testAccount.Id, 'Test Asset for Trigger Handler', testOLI.Id
        );
        
        // Insert should trigger the handler
        insert testAsset;
        
        Test.stopTest();
        
        // Verify exchange rate was assigned during insert
        Asset insertedAsset = [SELECT Id, Exchange_Rate__c, Originating_OLI__c FROM Asset WHERE Id = :testAsset.Id];
        System.assertEquals(testOLI.Exchange_Rate__c, insertedAsset.Exchange_Rate__c, 
                           'Asset should inherit exchange rate from OLI during insert');
    }
    
    // Test exchange rate inheritance during Asset creation
    @isTest
    static void testExchangeRateInheritanceOnInsert() {
        List<OpportunityLineItem> oliList = [SELECT Id, Exchange_Rate__c FROM OpportunityLineItem WHERE Exchange_Rate__c != null];
        System.assert(oliList.size() >= 2, 'Test setup should create multiple OLIs with exchange rates');
        
        Test.startTest();
        
        // Create Assets linked to OLIs with exchange rates
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Asset> testAssets = new List<Asset>();
        
        Asset asset1 = new Asset(
            Name = 'Test Asset 1',
            AccountId = testAccount.Id,
            Originating_OLI__c = oliList[0].Id
        );
        testAssets.add(asset1);
        
        Asset asset2 = new Asset(
            Name = 'Test Asset 2',
            AccountId = testAccount.Id,
            Originating_OLI__c = oliList[1].Id
        );
        testAssets.add(asset2);
        
        insert testAssets;
        
        Test.stopTest();
        
        // Verify exchange rates were inherited
        Map<Id, Asset> insertedAssets = new Map<Id, Asset>([
            SELECT Id, Exchange_Rate__c, Originating_OLI__c 
            FROM Asset 
            WHERE Id IN :testAssets
        ]);
        
        for (Asset asset : insertedAssets.values()) {
            OpportunityLineItem relatedOLI = [SELECT Exchange_Rate__c FROM OpportunityLineItem WHERE Id = :asset.Originating_OLI__c];
            System.assertEquals(relatedOLI.Exchange_Rate__c, asset.Exchange_Rate__c,
                               'Asset should inherit exchange rate from related OLI');
        }
    }
    
    // Test that Assets without OLI relationships are not affected
    @isTest
    static void testAssetsWithoutOLIRelationship() {
        Test.startTest();
        
        // Create Asset without OLI relationship
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Asset assetWithoutOLI = new Asset(
            Name = 'Asset Without OLI',
            AccountId = testAccount.Id,
            Originating_OLI__c = null
        );
        
        insert assetWithoutOLI;
        
        Test.stopTest();
        
        // Verify no exchange rate was assigned
        Asset insertedAsset = [SELECT Id, Exchange_Rate__c FROM Asset WHERE Id = :assetWithoutOLI.Id];
        System.assertEquals(null, insertedAsset.Exchange_Rate__c, 
                           'Asset without OLI relationship should not have exchange rate assigned');
    }
    
    // Test that Assets with existing exchange rates are not overwritten
    @isTest
    static void testExistingExchangeRateNotOverwritten() {
        List<OpportunityLineItem> oliList = [SELECT Id, Exchange_Rate__c FROM OpportunityLineItem WHERE Exchange_Rate__c != null LIMIT 1];
        OpportunityLineItem testOLI = oliList[0];
        
        Test.startTest();
        
        // Create Asset with existing exchange rate
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Asset assetWithExistingRate = new Asset(
            Name = 'Asset With Existing Rate',
            AccountId = testAccount.Id,
            Originating_OLI__c = testOLI.Id,
            Exchange_Rate__c = 2.00 // Different from OLI rate
        );
        
        insert assetWithExistingRate;
        
        Test.stopTest();
        
        // Verify existing exchange rate was preserved
        Asset insertedAsset = [SELECT Id, Exchange_Rate__c FROM Asset WHERE Id = :assetWithExistingRate.Id];
        System.assertEquals(2.00, insertedAsset.Exchange_Rate__c,
                           'Asset with existing exchange rate should not be overwritten');
    }
    
    // Test Assets linked to OLIs without exchange rates
    @isTest
    static void testOLIWithoutExchangeRate() {
        List<OpportunityLineItem> oliList = [SELECT Id, Exchange_Rate__c FROM OpportunityLineItem WHERE Exchange_Rate__c = null LIMIT 1];
        System.assert(!oliList.isEmpty(), 'Test setup should create OLI without exchange rate');
        
        OpportunityLineItem oliWithoutRate = oliList[0];
        
        Test.startTest();
        
        // Create Asset linked to OLI without exchange rate
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Asset testAsset = new Asset(
            Name = 'Asset Linked to OLI Without Rate',
            AccountId = testAccount.Id,
            Originating_OLI__c = oliWithoutRate.Id
        );
        
        insert testAsset;
        
        Test.stopTest();
        
        // Verify no exchange rate was assigned
        Asset insertedAsset = [SELECT Id, Exchange_Rate__c FROM Asset WHERE Id = :testAsset.Id];
        System.assertEquals(null, insertedAsset.Exchange_Rate__c,
                           'Asset linked to OLI without exchange rate should not have rate assigned');
    }
    
    // Test bulk processing with multiple Assets
    @isTest
    static void testBulkProcessing() {
        List<OpportunityLineItem> oliList = [SELECT Id, Exchange_Rate__c FROM OpportunityLineItem WHERE Exchange_Rate__c != null];
        
        Test.startTest();
        
        // Create multiple Assets for bulk testing
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Asset> bulkAssets = new List<Asset>();
        
        for (Integer i = 0; i < 50; i++) {
            // Alternate between OLIs with exchange rates
            OpportunityLineItem selectedOLI = oliList[Math.mod(i, oliList.size())];
            
            Asset bulkAsset = new Asset(
                Name = 'Bulk Asset ' + i,
                AccountId = testAccount.Id,
                Originating_OLI__c = selectedOLI.Id
            );
            bulkAssets.add(bulkAsset);
        }
        
        insert bulkAssets;
        
        Test.stopTest();
        
        // Verify all Assets received exchange rates
        List<Asset> insertedAssets = [SELECT Id, Exchange_Rate__c, Originating_OLI__c FROM Asset WHERE Id IN :bulkAssets];
        
        for (Asset asset : insertedAssets) {
            System.assertNotEquals(null, asset.Exchange_Rate__c, 
                                  'Bulk processed Asset should have exchange rate assigned');
        }
        
        // Verify no governor limit exceptions occurred
        System.assertEquals(50, insertedAssets.size(), 'All bulk Assets should be processed successfully');
    }
    
    // Test update scenario (trigger should work on update too)
    @isTest
    static void testExchangeRateAssignmentOnUpdate() {
        List<OpportunityLineItem> oliList = [SELECT Id, Exchange_Rate__c FROM OpportunityLineItem WHERE Exchange_Rate__c != null LIMIT 1];
        OpportunityLineItem testOLI = oliList[0];
        
        // Create Asset without OLI relationship initially
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Asset testAsset = new Asset(
            Name = 'Asset for Update Test',
            AccountId = testAccount.Id,
            Originating_OLI__c = null
        );
        insert testAsset;
        
        Test.startTest();
        
        // Update Asset to link it to OLI (should trigger exchange rate assignment)
        testAsset.Originating_OLI__c = testOLI.Id;
        update testAsset;
        
        Test.stopTest();
        
        // Verify exchange rate was assigned during update
        Asset updatedAsset = [SELECT Id, Exchange_Rate__c FROM Asset WHERE Id = :testAsset.Id];
        System.assertEquals(testOLI.Exchange_Rate__c, updatedAsset.Exchange_Rate__c,
                           'Asset should inherit exchange rate from OLI during update');
    }
    
    // Test error handling scenarios
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        
        try {
            // Create Asset with invalid OLI ID (should handle gracefully)
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            Asset assetWithInvalidOLI = new Asset(
                Name = 'Asset With Invalid OLI',
                AccountId = testAccount.Id,
                Originating_OLI__c = '006000000000000' // Invalid ID format
            );
            
            insert assetWithInvalidOLI;
            
            // If we reach here, verify no exchange rate was assigned
            Asset insertedAsset = [SELECT Id, Exchange_Rate__c FROM Asset WHERE Id = :assetWithInvalidOLI.Id];
            System.assertEquals(null, insertedAsset.Exchange_Rate__c,
                               'Asset with invalid OLI should not have exchange rate assigned');
            
        } catch (Exception e) {
            // If exception occurred, it should be a DML or query exception
            System.assert(e instanceof DmlException || e instanceof QueryException,
                         'Exception should be DML or Query related');
        }
        
        Test.stopTest();
    }
    
    // Test trigger context verification
    @isTest
    static void testTriggerContextHandling() {
        List<OpportunityLineItem> oliList = [SELECT Id, Exchange_Rate__c FROM OpportunityLineItem WHERE Exchange_Rate__c != null LIMIT 1];
        OpportunityLineItem testOLI = oliList[0];
        
        Test.startTest();
        
        // Test both insert and update contexts
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Asset testAsset = new Asset(
            Name = 'Trigger Context Test Asset',
            AccountId = testAccount.Id,
            Originating_OLI__c = testOLI.Id
        );
        
        // Insert (before insert should trigger)
        insert testAsset;
        
        // Update (before update should trigger)  
        testAsset.Name = 'Updated Asset Name';
        update testAsset;
        
        Test.stopTest();
        
        // Verify exchange rate was set correctly
        Asset finalAsset = [SELECT Id, Exchange_Rate__c FROM Asset WHERE Id = :testAsset.Id];
        System.assertEquals(testOLI.Exchange_Rate__c, finalAsset.Exchange_Rate__c,
                           'Asset should maintain correct exchange rate through insert and update');
    }
    
    // Test mixed scenarios in single operation
    @isTest
    static void testMixedScenarios() {
        List<OpportunityLineItem> oliList = [SELECT Id, Exchange_Rate__c FROM OpportunityLineItem];
        OpportunityLineItem oliWithRate = null;
        OpportunityLineItem oliWithoutRate = null;
        
        for (OpportunityLineItem oli : oliList) {
            if (oli.Exchange_Rate__c != null && oliWithRate == null) {
                oliWithRate = oli;
            } else if (oli.Exchange_Rate__c == null && oliWithoutRate == null) {
                oliWithoutRate = oli;
            }
        }
        
        Test.startTest();
        
        // Create Assets with mixed scenarios in single operation
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Asset> mixedAssets = new List<Asset>();
        
        // Asset 1: Linked to OLI with exchange rate
        mixedAssets.add(new Asset(
            Name = 'Mixed Test Asset 1',
            AccountId = testAccount.Id,
            Originating_OLI__c = oliWithRate.Id
        ));
        
        // Asset 2: Linked to OLI without exchange rate
        mixedAssets.add(new Asset(
            Name = 'Mixed Test Asset 2',
            AccountId = testAccount.Id,
            Originating_OLI__c = oliWithoutRate.Id
        ));
        
        // Asset 3: No OLI relationship
        mixedAssets.add(new Asset(
            Name = 'Mixed Test Asset 3',
            AccountId = testAccount.Id,
            Originating_OLI__c = null
        ));
        
        // Asset 4: Has existing exchange rate
        mixedAssets.add(new Asset(
            Name = 'Mixed Test Asset 4',
            AccountId = testAccount.Id,
            Originating_OLI__c = oliWithRate.Id,
            Exchange_Rate__c = 3.00
        ));
        
        insert mixedAssets;
        
        Test.stopTest();
        
        // Verify each Asset handled correctly
        List<Asset> insertedAssets = [SELECT Id, Name, Exchange_Rate__c, Originating_OLI__c FROM Asset WHERE Id IN :mixedAssets ORDER BY Name];
        
        // Asset 1: Should have inherited exchange rate
        System.assertEquals(oliWithRate.Exchange_Rate__c, insertedAssets[0].Exchange_Rate__c,
                           'Asset 1 should inherit exchange rate from OLI');
        
        // Asset 2: Should not have exchange rate
        System.assertEquals(null, insertedAssets[1].Exchange_Rate__c,
                           'Asset 2 should not have exchange rate (OLI has no rate)');
        
        // Asset 3: Should not have exchange rate  
        System.assertEquals(null, insertedAssets[2].Exchange_Rate__c,
                           'Asset 3 should not have exchange rate (no OLI relationship)');
        
        // Asset 4: Should keep existing exchange rate
        System.assertEquals(3.00, insertedAssets[3].Exchange_Rate__c,
                           'Asset 4 should keep existing exchange rate');
    }
}