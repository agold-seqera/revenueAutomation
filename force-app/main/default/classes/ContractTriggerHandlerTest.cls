@isTest
public class ContractTriggerHandlerTest {

    // Note: Standardize on TestDataFactory for all test data creation.
    // ContractTriggerHandler behavior:
    // - On after insert/update/delete/undelete of Contract, update related Accounts:
    //   * Contract_Count__c = number of Contracts with Status != 'Expired'
    //   * Has_Contracts__c = (Contract_Count__c > 0)
    // - For after update, also re-roll the old Account when AccountId changes.

    // Helper: Requery Account and return a simplified tuple for assertions
    private class AccountRollup {
        public Id accountId;
        public Integer countVal;
        public Boolean hasContracts;
        public AccountRollup(Account a) {
            this.accountId = a.Id;
            this.countVal = (Integer) a.get('Contract_Count__c');
            this.hasContracts = (Boolean) a.get('Has_Contracts__c');
        }
    }

    private static AccountRollup fetchRollup(Id accountId) {
        Account a = [
            SELECT Id, Contract_Count__c, Has_Contracts__c
            FROM Account WHERE Id = :accountId
        ];
        return new AccountRollup(a);
    }

    // Insert: mix of non-expired and expired per account; verify counts and flags.
    @isTest
    static void testAfterInsertCountsAndFlags() {
        // Accounts
        Account a1 = TestDataFactory.createAccount('A1');
        Account a2 = TestDataFactory.createAccount('A2');
        insert new List<Account>{ a1, a2 };

        // Contracts for A1: 2 non-expired, 1 expired
        Contract a1c1 = TestDataFactory.createContract(a1.Id, 'A1 C1', 'Draft');
        Contract a1c2 = TestDataFactory.createContract(a1.Id, 'A1 C2', 'Activated');
        Contract a1c3 = TestDataFactory.createContract(a1.Id, 'A1 C3', 'Expired');

        // Contracts for A2: 0 non-expired (only expired)
        Contract a2c1 = TestDataFactory.createContract(a2.Id, 'A2 C1', 'Expired');

        // Include a contract without AccountId to exercise guard path
        Contract noAcct = new Contract(
            ContractTerm = 12,
            StartDate = Date.today(),
            EndDate = Date.today().addMonths(12),
            Status = 'Draft'
        );

        insert new List<Contract>{ a1c1, a1c2, a1c3, a2c1, noAcct };

        // Assert A1 count = 2 (Draft + Activated), Has_Contracts__c = true
        AccountRollup r1 = fetchRollup(a1.Id);
        System.assertEquals(2, r1.countVal, 'A1 should count only non-expired contracts');
        System.assertEquals(true, r1.hasContracts, 'A1 Has_Contracts__c should be true');

        // Assert A2 count = 0 (only expired), Has_Contracts__c = false
        AccountRollup r2 = fetchRollup(a2.Id);
        System.assertEquals(0, r2.countVal, 'A2 should exclude expired contracts');
        System.assertEquals(false, r2.hasContracts, 'A2 Has_Contracts__c should be false');
    }

    // Update: status transitions between non-expired <-> expired adjust counts and flags.
    @isTest
    static void testAfterUpdateStatusChangeAffectsCounts() {
        Account a1 = TestDataFactory.createAccount('A1');
        insert a1;

        // Start non-expired
        Contract c = TestDataFactory.createContract(a1.Id, 'Status Test', 'Activated');
        insert c;

        // Verify initial rollup
        AccountRollup r0 = fetchRollup(a1.Id);
        System.assertEquals(1, r0.countVal, 'Initial count should be 1');
        System.assertEquals(true, r0.hasContracts, 'Has_Contracts__c should be true');

        Test.startTest();
        // Transition to Expired
        update new Contract(Id = c.Id, Status = 'Expired');
        Test.stopTest();

        AccountRollup r1 = fetchRollup(a1.Id);
        System.assertEquals(0, r1.countVal, 'Count should drop to 0 after expiring the only contract');
        System.assertEquals(false, r1.hasContracts, 'Has_Contracts__c should be false when count is 0');

        Test.startTest();
        // Transition back to non-expired
        update new Contract(Id = c.Id, Status = 'Draft');
        Test.stopTest();

        AccountRollup r2 = fetchRollup(a1.Id);
        System.assertEquals(1, r2.countVal, 'Count should return to 1 after reverting to non-expired');
        System.assertEquals(true, r2.hasContracts, 'Has_Contracts__c should be true again');
    }

    // Update: moving a contract between accounts adjusts both accounts; moving expired has no effect.
    @isTest
    static void testAfterUpdateAccountMoveAdjustsBothAccounts() {
        Account a1 = TestDataFactory.createAccount('A1');
        Account a2 = TestDataFactory.createAccount('A2');
        insert new List<Account>{ a1, a2 };

        // Non-expired contract on A1
        Contract activeOnA1 = TestDataFactory.createContract(a1.Id, 'Active C', 'Activated');
        insert activeOnA1;

        // Baseline checks
        System.assertEquals(1, fetchRollup(a1.Id).countVal, 'A1 baseline count should be 1');
        System.assertEquals(0, fetchRollup(a2.Id).countVal, 'A2 baseline count should be 0');

        Test.startTest();
        // Move non-expired contract from A1 -> A2
        update new Contract(Id = activeOnA1.Id, AccountId = a2.Id);
        Test.stopTest();

        AccountRollup a1AfterMove = fetchRollup(a1.Id);
        AccountRollup a2AfterMove = fetchRollup(a2.Id);
        System.assertEquals(0, a1AfterMove.countVal, 'A1 should decrement after move');
        System.assertEquals(false, a1AfterMove.hasContracts, 'A1 flag false after losing last active contract');
        System.assertEquals(1, a2AfterMove.countVal, 'A2 should increment after receiving active contract');
        System.assertEquals(true, a2AfterMove.hasContracts, 'A2 flag true after receiving contract');

        // Now verify moving an expired contract has no impact on counts
        Contract expiredOnA2 = TestDataFactory.createContract(a2.Id, 'Expired C', 'Expired');
        insert expiredOnA2;

        // Move expired contract A2 -> A1
        Test.startTest();
        update new Contract(Id = expiredOnA2.Id, AccountId = a1.Id);
        Test.stopTest();

        // Counts should be unchanged (expired contracts excluded)
        AccountRollup a1AfterExpiredMove = fetchRollup(a1.Id);
        AccountRollup a2AfterExpiredMove = fetchRollup(a2.Id);
        System.assertEquals(0, a1AfterExpiredMove.countVal, 'A1 count unchanged by moving expired contract in');
        System.assertEquals(1, a2AfterExpiredMove.countVal, 'A2 active count remains based on active contract');
    }

    // Delete: deletion decrements counts and toggles flags.
    @isTest
    static void testAfterDeleteDecrementsCounts() {
        Account a1 = TestDataFactory.createAccount('A1');
        insert a1;

        Contract c1 = TestDataFactory.createContract(a1.Id, 'C1', 'Draft');
        Contract c2 = TestDataFactory.createContract(a1.Id, 'C2', 'Activated');
        Contract c3 = TestDataFactory.createContract(a1.Id, 'C3', 'Expired'); // ignored
        insert new List<Contract>{ c1, c2, c3 };

        System.assertEquals(2, fetchRollup(a1.Id).countVal, 'Baseline count should be 2');

        Test.startTest();
        delete c1;
        Test.stopTest();

        System.assertEquals(1, fetchRollup(a1.Id).countVal, 'Count should decrement to 1 after deleting one active');

        Test.startTest();
        delete c2;
        Test.stopTest();

        AccountRollup r = fetchRollup(a1.Id);
        System.assertEquals(0, r.countVal, 'Count should be 0 after deleting last active');
        System.assertEquals(false, r.hasContracts, 'Flag should be false at zero');
    }

    // Undelete: restores counts and flags.
    @isTest
    static void testAfterUndeleteReinstateCounts() {
        Account a1 = TestDataFactory.createAccount('A1');
        insert a1;

        Contract c = TestDataFactory.createContract(a1.Id, 'To Restore', 'Activated');
        insert c;

        System.assertEquals(1, fetchRollup(a1.Id).countVal, 'Baseline 1');

        Test.startTest();
        delete c;
        Test.stopTest();

        System.assertEquals(0, fetchRollup(a1.Id).countVal, 'After delete, count 0');

        Test.startTest();
        undelete c;
        Test.stopTest();

        AccountRollup r = fetchRollup(a1.Id);
        System.assertEquals(1, r.countVal, 'After undelete, count 1');
        System.assertEquals(true, r.hasContracts, 'Flag true after restoration');
    }

    // Bulk: mass status update across multiple accounts with mixed statuses.
    @isTest
    static void testBulkUpdateCountsMultipleAccounts() {
        Account a1 = TestDataFactory.createAccount('A1');
        Account a2 = TestDataFactory.createAccount('A2');
        Account a3 = TestDataFactory.createAccount('A3');
        insert new List<Account>{ a1, a2, a3 };

        List<Contract> toInsert = new List<Contract>();
        // A1: 5 contracts, 4 active, 1 expired
        for (Integer i = 0; i < 4; i++) {
            toInsert.add(TestDataFactory.createContract(a1.Id, 'A1 Active ' + i, 'Draft'));
        }
        toInsert.add(TestDataFactory.createContract(a1.Id, 'A1 Expired', 'Expired'));

        // A2: 4 contracts, all active
        for (Integer i = 0; i < 4; i++) {
            toInsert.add(TestDataFactory.createContract(a2.Id, 'A2 Active ' + i, 'Activated'));
        }

        // A3: 3 contracts, all expired
        for (Integer i = 0; i < 3; i++) {
            toInsert.add(TestDataFactory.createContract(a3.Id, 'A3 Expired ' + i, 'Expired'));
        }

        insert toInsert;

        // Baseline assertions
        System.assertEquals(4, fetchRollup(a1.Id).countVal, 'A1 baseline active = 4');
        System.assertEquals(4, fetchRollup(a2.Id).countVal, 'A2 baseline active = 4');
        System.assertEquals(0, fetchRollup(a3.Id).countVal, 'A3 baseline active = 0');

        // Bulk expire a subset: expire two from A1 and three from A2
        List<Contract> toExpire = new List<Contract>();
        Integer a1Expired = 0, a2Expired = 0;
        for (Contract c : [SELECT Id, AccountId, Name, Status FROM Contract WHERE AccountId IN :new Set<Id>{a1.Id, a2.Id} AND Status != 'Expired' ORDER BY AccountId, Name LIMIT 5]) {
            if (c.AccountId == a1.Id && a1Expired < 2) {
                c.Status = 'Expired';
                toExpire.add(c);
                a1Expired++;
            } else if (c.AccountId == a2.Id && a2Expired < 3) {
                c.Status = 'Expired';
                toExpire.add(c);
                a2Expired++;
            }
        }

        Test.startTest();
        update toExpire;
        Test.stopTest();

        AccountRollup a1After = fetchRollup(a1.Id);
        AccountRollup a2After = fetchRollup(a2.Id);
        AccountRollup a3After = fetchRollup(a3.Id);

        System.assertEquals(4 - a1Expired, a1After.countVal, 'A1 count reflects bulk expirations');
        System.assertEquals(4 - a2Expired, a2After.countVal, 'A2 count reflects bulk expirations');
        System.assertEquals(0, a3After.countVal, 'A3 remains 0 (all expired)');

        System.assertEquals(a1After.countVal > 0, a1After.hasContracts, 'A1 flag matches count');
        System.assertEquals(a2After.countVal > 0, a2After.hasContracts, 'A2 flag matches count');
        System.assertEquals(false, a3After.hasContracts, 'A3 flag false at zero');
    }
}
