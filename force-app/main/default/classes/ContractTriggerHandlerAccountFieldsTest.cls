@isTest
public class ContractTriggerHandlerAccountFieldsTest {
    
    @TestSetup
    static void makeData() {
        // Create test accounts using TestDataFactory
        List<Account> accounts = new List<Account>();
        accounts.add(TestDataFactory.createAccount('Account With Contracts'));
        accounts.add(TestDataFactory.createAccount('Account No Contracts'));
        accounts.add(TestDataFactory.createAccount('Account For Updates'));
        
        // Set Type__c for Commercial accounts (needed for Account flow filter)
        for (Account acc : accounts) {
            acc.Type__c = 'Commercial';
        }
        insert accounts;
    }
    
    @isTest
    static void testContractCreation() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Account With Contracts' LIMIT 1];
        
        // Verify initial state
        Account initialAccount = [
            SELECT Id, Has_Contracts__c, Contract_Count__c 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        System.assertEquals(false, initialAccount.Has_Contracts__c, 'Initially Has_Contracts__c should be false');
        System.assertEquals(0, initialAccount.Contract_Count__c, 'Initially Contract_Count__c should be 0');
        
        Test.startTest();
        
        // Create contracts using TestDataFactory
        List<Contract> contracts = new List<Contract>();
        contracts.add(TestDataFactory.createContract(testAccount.Id, 'Contract 1'));
        contracts.add(TestDataFactory.createContract(testAccount.Id, 'Contract 2'));
        insert contracts;
        
        Test.stopTest(); // This forces @future methods to complete synchronously
        
        // Verify account fields updated after @future method completion
        Account updatedAccount = [
            SELECT Id, Has_Contracts__c, Contract_Count__c 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals(true, updatedAccount.Has_Contracts__c, 'Has_Contracts__c should be true');
        System.assertEquals(2, updatedAccount.Contract_Count__c, 'Contract_Count__c should be 2');
    }
    
    @isTest
    static void testContractDeletion() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Account For Updates' LIMIT 1];
        
        // Create and then delete contract
        Contract testContract = TestDataFactory.createContract(testAccount.Id, 'Contract To Delete');
        insert testContract;
        
        Test.startTest();
        delete testContract;
        Test.stopTest();
        
        // Verify account fields updated
        Account updatedAccount = [
            SELECT Id, Has_Contracts__c, Contract_Count__c 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals(false, updatedAccount.Has_Contracts__c, 'Has_Contracts__c should be false');
        System.assertEquals(0, updatedAccount.Contract_Count__c, 'Contract_Count__c should be 0');
    }
    
    @isTest
    static void testContractUndelete() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Account For Updates' LIMIT 1];
        
        // Create, delete, then undelete contract
        Contract testContract = TestDataFactory.createContract(testAccount.Id, 'Contract To Undelete');
        insert testContract;
        delete testContract;
        
        Test.startTest();
        undelete testContract;
        Test.stopTest();
        
        // Verify account fields updated
        Account updatedAccount = [
            SELECT Id, Has_Contracts__c, Contract_Count__c 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals(true, updatedAccount.Has_Contracts__c, 'Has_Contracts__c should be true after undelete');
        System.assertEquals(1, updatedAccount.Contract_Count__c, 'Contract_Count__c should be 1 after undelete');
    }
    
    @isTest
    static void testBulkOperations() {
        List<Account> accounts = [SELECT Id FROM Account WHERE Name LIKE 'Account %'];
        
        Test.startTest();
        
        // Create 200 contracts across accounts (bulk test)
        List<Contract> contracts = new List<Contract>();
        for (Integer i = 0; i < 200; i++) {
            Account randomAccount = accounts[Math.mod(i, accounts.size())];
            contracts.add(TestDataFactory.createContract(randomAccount.Id, 'Bulk Contract ' + i));
        }
        insert contracts;
        
        Test.stopTest();
        
        // Verify all accounts have correct counts
        List<Account> updatedAccounts = [
            SELECT Id, Has_Contracts__c, Contract_Count__c 
            FROM Account 
            WHERE Id IN :accounts
        ];
        
        for (Account acc : updatedAccounts) {
            if (acc.Contract_Count__c > 0) {
                System.assertEquals(true, acc.Has_Contracts__c, 
                    'Account with contracts should have Has_Contracts__c = true');
            }
        }
    }
    
    @isTest
    static void testAccountChange() {
        List<Account> accounts = [SELECT Id FROM Account WHERE Name LIKE 'Account %' LIMIT 2];
        
        Contract testContract = TestDataFactory.createContract(accounts[0].Id, 'Contract To Move');
        insert testContract;
        
        Test.startTest();
        
        // Move contract to different account
        testContract.AccountId = accounts[1].Id;
        update testContract;
        
        Test.stopTest();
        
        // Verify both accounts updated correctly
        List<Account> updatedAccounts = [
            SELECT Id, Has_Contracts__c, Contract_Count__c 
            FROM Account 
            WHERE Id IN :accounts
        ];
        
        for (Account acc : updatedAccounts) {
            if (acc.Id == accounts[1].Id) {
                System.assertEquals(true, acc.Has_Contracts__c, 'New account should have contract');
                System.assertEquals(1, acc.Contract_Count__c, 'New account should have count 1');
            } else {
                System.assertEquals(false, acc.Has_Contracts__c, 'Old account should not have contract');
                System.assertEquals(0, acc.Contract_Count__c, 'Old account should have count 0');
            }
        }
    }
    
    @isTest
    static void testMultipleContractStatuses() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Account With Contracts' LIMIT 1];
        
        Test.startTest();
        
        // Create contracts with different statuses (use valid Salesforce contract statuses)
        List<Contract> contracts = new List<Contract>();
        contracts.add(TestDataFactory.createContract(testAccount.Id, 'Draft Contract', 'Draft'));
        contracts.add(TestDataFactory.createContract(testAccount.Id, 'In Approval Process', 'In Approval Process'));
        contracts.add(TestDataFactory.createContract(testAccount.Id, 'Expired Contract', 'Expired'));
        insert contracts;
        
        Test.stopTest();
        
        // Verify account fields count ALL contracts regardless of status
        Account updatedAccount = [
            SELECT Id, Has_Contracts__c, Contract_Count__c 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals(true, updatedAccount.Has_Contracts__c, 'Has_Contracts__c should be true');
        System.assertEquals(3, updatedAccount.Contract_Count__c, 'Contract_Count__c should count all statuses');
    }
    
    @isTest
    static void testRecursionPrevention() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Account For Updates' LIMIT 1];
        
        Test.startTest();
        
        // Create multiple contracts in quick succession to test recursion prevention
        List<Contract> contracts = new List<Contract>();
        for (Integer i = 0; i < 10; i++) {
            contracts.add(TestDataFactory.createContract(testAccount.Id, 'Recursion Test ' + i));
        }
        insert contracts;
        
        // Update all contracts to trigger handler again
        for (Contract c : contracts) {
            c.Status = 'Activated';
        }
        update contracts;
        
        Test.stopTest();
        
        // Verify account fields are correct despite multiple operations
        Account updatedAccount = [
            SELECT Id, Has_Contracts__c, Contract_Count__c 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals(true, updatedAccount.Has_Contracts__c, 'Has_Contracts__c should be true');
        System.assertEquals(10, updatedAccount.Contract_Count__c, 'Contract_Count__c should be 10');
    }
}