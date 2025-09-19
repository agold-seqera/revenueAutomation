// Test Data Factory for creating test records consistently across test classes
// Follows Salesforce best practices for test data creation and management
// 
// Usage:
// - Create individual objects: TestDataFactory.createAccount()
// - Create complete relationships: TestDataFactory.createQuoteWithLineItems()
// - All methods return objects without DML - caller handles insert operations
@IsTest
public class TestDataFactory {
    
    // Get the standard pricebook ID - uses existing helper method
    public static Id getStandardPricebookId() {
        return Test.getStandardPricebookId();
    }
    
    // Create test Account
    public static Account createAccount() {
        return createAccount('Test Account');
    }
    
    public static Account createAccount(String name) {
        Account testAccount = new Account(
            Name = name,
            Type = 'Customer - Direct'
        );
        return testAccount;
    }
    
    // Create test Contact
    public static Contact createContact(Id accountId, String firstName, String lastName) {
        Contact testContact = new Contact(
            FirstName = firstName,
            LastName = lastName,
            AccountId = accountId,
            Email = firstName.toLowerCase().replace(' ', '.') + '.' + lastName.toLowerCase().replace(' ', '.') + '@test.com'
        );
        return testContact;
    }
    
    public static Contact createContact(Id accountId, String firstName, String lastName, String email) {
        Contact testContact = new Contact(
            FirstName = firstName,
            LastName = lastName,
            AccountId = accountId,
            Email = email
        );
        return testContact;
    }
    
    // Overload for simple contact creation
    public static Contact createContact(Id accountId, String lastName) {
        return createContact(accountId, 'Test', lastName);
    }
    
    // Create test Opportunity
    public static Opportunity createOpportunity(Id accountId) {
        return createOpportunity(accountId, 'Test Opportunity');
    }
    
    public static Opportunity createOpportunity(Id accountId, String name) {
        Opportunity testOpp = new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 150000,
            Contract_Start_Date__c = Date.today(),
            Term_Length_Months__c = 12, // Formula field Contract_End_Date__c will calculate from this
            Type = 'Commercial',
            LeadSource = 'AE Outreach',
            NextStep = 'Initial Discovery Call'
        );
        return testOpp;
    }
    
    // Create test Product2
    public static Product2 createProduct() {
        return createProduct('Test Product', 'Software Subscriptions');
    }
    
    public static Product2 createProduct(String name, String family) {
        Product2 testProduct = new Product2(
            Name = name,
            IsActive = true,
            Family = family
        );
        return testProduct;
    }
    
    // Create PricebookEntry for standard pricebook
    public static PricebookEntry createPricebookEntry(Id productId, Decimal unitPrice) {
        Id standardPricebookId = getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );
        return pbe;
    }
    
    // Create test Quote
    public static Quote createQuote(Id opportunityId) {
        return createQuote(opportunityId, 'Test Quote');
    }
    
    public static Quote createQuote(Id opportunityId, String name) {
        Id standardPricebookId = getStandardPricebookId();
        return createQuote(opportunityId, standardPricebookId, name);
    }
    
    public static Quote createQuote(Id opportunityId, Id pricebookId, String name) {
        Quote testQuote = new Quote(
            Name = name,
            OpportunityId = opportunityId,
            Pricebook2Id = pricebookId,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30),
            Order_Start_Date__c = Date.today(),
            Order_End_Date__c = Date.today().addDays(365),
            // Required fields for VR_Draft_to_Needs_Review_Required_Fields
            Customer_Legal_Name__c = 'Test Customer Legal Name',
            BillingName = 'Test Billing Name',
            Master_Terms__c = 'Website Terms effective as of the Start Date below',
            Seqera_Contact_Email__c = 'test@seqera.io',
            DPA_Required__c = 'No',
            Payment_Terms__c = 'Net 30',
            Term_Length_Months__c = 12,
            Annual_Total__c = 100000,
            One_Off_Charges__c = 0,
            Total_Payment_Due__c = 100000,
            Billing_Frequency__c = 'Monthly',
            Tax_Exempt__c = 'No',
            PO_Required_by_Customer__c = 'No',
            Exchange_Rate_at_Creation__c = 1.0 // Bypass DatedConversionRate lookup in flow
        );
        return testQuote;
    }
    
    // Create Quote without Opportunity (for validation testing)
    public static Quote createQuoteWithoutOpportunity(String name) {
        Id standardPricebookId = getStandardPricebookId();
        Quote testQuote = new Quote(
            Name = name,
            Pricebook2Id = standardPricebookId,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30),
            Exchange_Rate_at_Creation__c = 1.0 // Bypass DatedConversionRate lookup in flow
        );
        return testQuote;
    }
    
    // Create OpportunityLineItem
    public static OpportunityLineItem createOpportunityLineItem(Id opportunityId, Id productId, Id pricebookEntryId, Decimal quantity, Decimal unitPrice) {
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opportunityId,
            Product2Id = productId,
            PricebookEntryId = pricebookEntryId,
            Quantity = quantity,
            UnitPrice = unitPrice,
            ServiceDate = Date.today()
        );
        return oli;
    }
    
    // Create QuoteLineItem
    public static QuoteLineItem createQuoteLineItem(Id quoteId, Id productId, Id pricebookEntryId, Decimal quantity, Decimal unitPrice) {
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quoteId,
            Product2Id = productId,
            PricebookEntryId = pricebookEntryId,
            Quantity = quantity,
            UnitPrice = unitPrice,
            ServiceDate = Date.today(),
            Service_End_Date__c = Date.today().addDays(365)
        );
        return qli;
    }
    
    // Create Asset
    public static Asset createAsset(Id accountId, String name) {
        Asset testAsset = new Asset(
            Name = name,
            AccountId = accountId,
            Status = 'Purchased',
            Price = 1000
        );
        return testAsset;
    }
    
    // Create Asset with OLI relationship for exchange rate testing
    public static Asset createAssetWithOLI(Id accountId, String name, Id originatingOLIId) {
        Asset testAsset = new Asset(
            Name = name,
            AccountId = accountId,
            Originating_OLI__c = originatingOLIId,
            Status = 'Purchased',
            Price = 1000
        );
        return testAsset;
    }
    
    // Create test Contract
    public static Contract createContract(Id accountId) {
        return createContract(accountId, 'Test Contract');
    }
    
    public static Contract createContract(Id accountId, String contractName) {
        Contract testContract = new Contract(
            AccountId = accountId,
            ContractTerm = 12,
            StartDate = Date.today(),
            EndDate = Date.today().addMonths(12),
            Status = 'Draft'
        );
        return testContract;
    }
    
    // Create Contract with specific status
    public static Contract createContract(Id accountId, String contractName, String status) {
        Contract testContract = createContract(accountId, contractName);
        testContract.Status = status;
        
        // Contracts can be Activated without signed dates based on org data
        
        return testContract;
    }
    
    // Create Asset with Contract relationship
    public static Asset createAsset(Id accountId, Id contractId, String status) {
        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = accountId,
            Contract__c = contractId,
            Status = status,
            Price = 1000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(365)
        );
        return testAsset;
    }
    
    // Create complete Quote with line items for different approval levels
    public class QuoteWithLineItemsResult {
        public Account account;
        public Opportunity opportunity;
        public Product2 product;
        public PricebookEntry pricebookEntry;
        public Quote quote;
        public List<QuoteLineItem> lineItems;
    }
    
    // Approval scenario configuration
    public class ApprovalScenarioResult {
        public QuoteWithLineItemsResult firstOverrideQuote;   // First_Approval_Override__c = true
        public QuoteWithLineItemsResult secondOverrideQuote;  // Second_Approval_Override__c = true  
        public QuoteWithLineItemsResult bothOverridesQuote;   // Both overrides = true (Auto-Approval)
        public QuoteWithLineItemsResult standardQuote;       // Both overrides = false (Dual Approval)
    }
    
    // Create all approval scenario quotes for comprehensive testing
    public static ApprovalScenarioResult createApprovalScenarioQuotes() {
        ApprovalScenarioResult result = new ApprovalScenarioResult();
        
        // First Override Quote (Operations/Legal Approval Only)
        result.firstOverrideQuote = createQuoteWithLineItems(125000, 'First Override Quote');
        result.firstOverrideQuote.quote.First_Approval_Override__c = true;
        result.firstOverrideQuote.quote.Second_Approval_Override__c = false;
        
        // Second Override Quote (Sales Approval Only)
        result.secondOverrideQuote = createQuoteWithLineItems(150000, 'Second Override Quote');
        result.secondOverrideQuote.quote.First_Approval_Override__c = false;
        result.secondOverrideQuote.quote.Second_Approval_Override__c = true;
        
        // Both Overrides Quote (Auto-Approval)
        result.bothOverridesQuote = createQuoteWithLineItems(200000, 'Both Overrides Quote');
        result.bothOverridesQuote.quote.First_Approval_Override__c = true;
        result.bothOverridesQuote.quote.Second_Approval_Override__c = true;
        
        // Standard Process Quote (Dual Approval)
        result.standardQuote = createQuoteWithLineItems(75000, 'Standard Process Quote');
        result.standardQuote.quote.First_Approval_Override__c = false;
        result.standardQuote.quote.Second_Approval_Override__c = false;
        
        // Update all quotes with override field values
        List<Quote> quotesToUpdate = new List<Quote>{
            result.firstOverrideQuote.quote,
            result.secondOverrideQuote.quote,
            result.bothOverridesQuote.quote,
            result.standardQuote.quote
        };
        update quotesToUpdate;
        
        return result;
    }
    
    // Create quote with specific override configuration
    public static Quote createQuoteWithOverrides(Id opportunityId, String quoteName, Boolean firstOverride, Boolean secondOverride) {
        Quote quote = createQuote(opportunityId, quoteName);
        quote.First_Approval_Override__c = firstOverride;
        quote.Second_Approval_Override__c = secondOverride;
        return quote;
    }
    
    // Create validation-compliant quote (passes VR_Draft_to_Needs_Review_Required_Fields)
    public static Quote createValidationCompliantQuote(Id opportunityId, String quoteName) {
        Quote quote = createQuote(opportunityId, quoteName);
        
        // Ensure all required fields are populated for validation rule
        quote.Customer_Legal_Name__c = 'Test Customer Legal Name';
        quote.BillingName = 'Test Billing Name';
        quote.Master_Terms__c = 'Website Terms effective as of the Start Date below';
        quote.Seqera_Contact_Email__c = 'test@seqera.io';
        quote.DPA_Required__c = 'No';
        quote.Payment_Terms__c = 'Net 30';
        quote.Term_Length_Months__c = 12;
        quote.Annual_Total__c = 100000;
        quote.One_Off_Charges__c = 0;
        quote.Total_Payment_Due__c = 100000;
        quote.Billing_Frequency__c = 'Monthly';
        quote.Tax_Exempt__c = 'No';
        quote.PO_Required_by_Customer__c = 'No';
        
        return quote;
    }
    
    // Create incomplete quote that will fail VR_Draft_to_Needs_Review_Required_Fields validation
    public static Quote createIncompleteQuote(Id opportunityId, String quoteName) {
        Id standardPricebookId = getStandardPricebookId();
        Quote testQuote = new Quote(
            Name = quoteName,
            OpportunityId = opportunityId,
            Pricebook2Id = standardPricebookId,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30),
            Exchange_Rate_at_Creation__c = 1.0 // Bypass DatedConversionRate lookup in flow
            // Deliberately missing required fields:
            // Customer_Legal_Name__c, BillingName, Master_Terms__c, Seqera_Contact_Email__c,
            // DPA_Required__c, Payment_Terms__c, Order_Start_Date__c, Order_End_Date__c,
            // Term_Length_Months__c, Annual_Total__c, Total_Payment_Due__c, Billing_Frequency__c,
            // Contract_Signer__c, Tax_Exempt__c, Primary_Customer_Contact__c,
            // Customer_Legal_Notice_Contact__c, Billing_Contact__c, PO_Required_by_Customer__c
        );
        return testQuote;
    }
    
    // Create complete quote with required contacts for validation testing
    public static QuoteWithLineItemsResult createValidationTestQuote(Decimal totalAmount, String quoteName, Boolean shouldPassValidation) {
        QuoteWithLineItemsResult result = new QuoteWithLineItemsResult();
        
        // Create Account
        result.account = createAccount();
        insert result.account;
        
        // Create required Contacts for Quote
        Contact primaryContact = createContact(result.account.Id, 'Primary Contact');
        Contact legalContact = createContact(result.account.Id, 'Legal Contact');
        Contact billingContact = createContact(result.account.Id, 'Billing Contact');
        insert new List<Contact>{primaryContact, legalContact, billingContact};
        
        // Create Opportunity
        result.opportunity = createOpportunity(result.account.Id);
        insert result.opportunity;
        
        // Create OpportunityContactRole records for the flow to find
        // The "Quote Before Save | Stamp Fields" flow expects these specific roles
        List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>();
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = result.opportunity.Id,
            ContactId = primaryContact.Id,
            Role = 'Primary Contact', // This role automatically sets IsPrimary = true
            IsPrimary = true // Explicit for complete test data
        ));
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = result.opportunity.Id,
            ContactId = legalContact.Id,
            Role = 'Legal Contact' // Exact role name the flow expects
        ));
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = result.opportunity.Id,
            ContactId = billingContact.Id,
            Role = 'Invoice Contact' // Exact role name the flow expects
        ));
        insert contactRoles;
        
        // Create Product
        result.product = createProduct();
        insert result.product;
        
        // Create PricebookEntry
        result.pricebookEntry = createPricebookEntry(result.product.Id, 1000);
        insert result.pricebookEntry;
        
        // Create Quote - complete or incomplete based on parameter
        if (shouldPassValidation) {
            result.quote = createValidationCompliantQuote(result.opportunity.Id, quoteName);
            // Add required contact references
            result.quote.Primary_Customer_Contact__c = primaryContact.Id;
            result.quote.Customer_Legal_Notice_Contact__c = legalContact.Id;
            result.quote.Billing_Contact__c = billingContact.Id;
            result.quote.Contract_Signer__c = primaryContact.Id;
        } else {
            result.quote = createIncompleteQuote(result.opportunity.Id, quoteName);
            // Deliberately leave contact fields empty to trigger validation
        }
        insert result.quote;
        
        // Create QuoteLineItem if quote should pass validation (needs LineItemCount > 0)
        if (shouldPassValidation) {
            Decimal quantity = totalAmount / 1000; // UnitPrice is 1000
            QuoteLineItem qli = createQuoteLineItem(
                result.quote.Id, 
                result.product.Id, 
                result.pricebookEntry.Id, 
                quantity, 
                1000
            );
            result.lineItems = new List<QuoteLineItem>{ qli };
            insert result.lineItems;
        } else {
            result.lineItems = new List<QuoteLineItem>(); // Empty list for validation failure
        }
        
        // Re-query the quote to get the calculated TotalPrice
        result.quote = [SELECT Id, Name, TotalPrice, OpportunityId, Status FROM Quote WHERE Id = :result.quote.Id];
        
        return result;
    }
    
    public static QuoteWithLineItemsResult createQuoteWithLineItems(Decimal totalAmount, String quoteName) {
        QuoteWithLineItemsResult result = new QuoteWithLineItemsResult();
        
        // Create Account
        result.account = createAccount();
        insert result.account;
        
        // Create required Contacts for Quote
        Contact primaryContact = createContact(result.account.Id, 'Primary Contact');
        Contact legalContact = createContact(result.account.Id, 'Legal Contact');
        Contact billingContact = createContact(result.account.Id, 'Billing Contact');
        insert new List<Contact>{primaryContact, legalContact, billingContact};
        
        // Create Opportunity
        result.opportunity = createOpportunity(result.account.Id);
        insert result.opportunity;
        
        // Create OpportunityContactRole records for the flow to find
        // The "Quote Before Save | Stamp Fields" flow expects these specific roles
        List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>();
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = result.opportunity.Id,
            ContactId = primaryContact.Id,
            Role = 'Primary Contact', // This role automatically sets IsPrimary = true
            IsPrimary = true // Explicit for complete test data
        ));
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = result.opportunity.Id,
            ContactId = legalContact.Id,
            Role = 'Legal Contact' // Exact role name the flow expects
        ));
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = result.opportunity.Id,
            ContactId = billingContact.Id,
            Role = 'Invoice Contact' // Exact role name the flow expects
        ));
        insert contactRoles;
        
        // Create Product
        result.product = createProduct();
        insert result.product;
        
        // Create PricebookEntry
        result.pricebookEntry = createPricebookEntry(result.product.Id, 1000);
        insert result.pricebookEntry;
        
        // Create Quote with Contact references
        result.quote = createQuote(result.opportunity.Id, quoteName);
        result.quote.Primary_Customer_Contact__c = primaryContact.Id;
        result.quote.Customer_Legal_Notice_Contact__c = legalContact.Id;
        result.quote.Billing_Contact__c = billingContact.Id;
        result.quote.Contract_Signer__c = primaryContact.Id; // Use primary contact as contract signer
        insert result.quote;
        
        // Create QuoteLineItem to achieve the total amount
        Decimal quantity = totalAmount / 1000; // UnitPrice is 1000
        QuoteLineItem qli = createQuoteLineItem(
            result.quote.Id, 
            result.product.Id, 
            result.pricebookEntry.Id, 
            quantity, 
            1000
        );
        result.lineItems = new List<QuoteLineItem>{ qli };
        insert result.lineItems;
        
        // Re-query the quote to get the calculated TotalPrice
        result.quote = [SELECT Id, Name, TotalPrice, OpportunityId, Status FROM Quote WHERE Id = :result.quote.Id];
        
        return result;
    }
    
    // Create multiple quotes efficiently for bulk testing (reuses account/opportunity data)
    public static List<QuoteWithLineItemsResult> createBulkQuotesWithLineItems(Integer count, Decimal baseAmount, String baseQuoteName) {
        List<QuoteWithLineItemsResult> results = new List<QuoteWithLineItemsResult>();
        
        // Create shared test data once for efficiency
        Account sharedAccount = createAccount('Bulk Test Account');
        insert sharedAccount;
        
        // Create shared contacts
        Contact primaryContact = createContact(sharedAccount.Id, 'Bulk Primary Contact');
        Contact legalContact = createContact(sharedAccount.Id, 'Bulk Legal Contact');
        Contact billingContact = createContact(sharedAccount.Id, 'Bulk Billing Contact');
        insert new List<Contact>{primaryContact, legalContact, billingContact};
        
        // Create shared opportunity
        Opportunity sharedOpportunity = createOpportunity(sharedAccount.Id, 'Bulk Test Opportunity');
        insert sharedOpportunity;
        
        // Create shared OpportunityContactRole records
        List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>();
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = sharedOpportunity.Id,
            ContactId = primaryContact.Id,
            Role = 'Primary Contact',
            IsPrimary = true
        ));
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = sharedOpportunity.Id,
            ContactId = legalContact.Id,
            Role = 'Legal Contact'
        ));
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = sharedOpportunity.Id,
            ContactId = billingContact.Id,
            Role = 'Invoice Contact'
        ));
        insert contactRoles;
        
        // Create shared product and pricebook entry
        Product2 sharedProduct = createProduct('Bulk Test Product', 'Software Subscriptions');
        insert sharedProduct;
        
        PricebookEntry sharedPricebookEntry = createPricebookEntry(sharedProduct.Id, 1000);
        insert sharedPricebookEntry;
        
        // Now create quotes in bulk
        List<Quote> quotesToInsert = new List<Quote>();
        for (Integer i = 0; i < count; i++) {
            Quote quote = createQuote(sharedOpportunity.Id, baseQuoteName + ' ' + i);
            quote.Primary_Customer_Contact__c = primaryContact.Id;
            quote.Customer_Legal_Notice_Contact__c = legalContact.Id;
            quote.Billing_Contact__c = billingContact.Id;
            quote.Contract_Signer__c = primaryContact.Id;
            quotesToInsert.add(quote);
        }
        
        // Bulk insert quotes (this will trigger the flow once per quote, but more efficiently)
        insert quotesToInsert;
        
        // Create quote line items in bulk
        List<QuoteLineItem> qliToInsert = new List<QuoteLineItem>();
        for (Integer i = 0; i < count; i++) {
            Decimal amount = baseAmount + (i * 10000);
            Decimal quantity = amount / 1000; // UnitPrice is 1000
            QuoteLineItem qli = createQuoteLineItem(
                quotesToInsert[i].Id,
                sharedProduct.Id,
                sharedPricebookEntry.Id,
                quantity,
                1000
            );
            qliToInsert.add(qli);
        }
        insert qliToInsert;
        
        // Build results
        for (Integer i = 0; i < count; i++) {
            QuoteWithLineItemsResult result = new QuoteWithLineItemsResult();
            result.account = sharedAccount;
            result.opportunity = sharedOpportunity;
            result.product = sharedProduct;
            result.pricebookEntry = sharedPricebookEntry;
            result.quote = quotesToInsert[i];
            result.lineItems = new List<QuoteLineItem>{ qliToInsert[i] };
            results.add(result);
        }
        
        return results;
    }
    
    // Create User for testing
    public static User createUser(String profileName, String username) {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User testUser = new User(
            Alias = 'test',
            Email = 'test@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = username
        );
        return testUser;
    }

}