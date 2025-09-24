// Debug what AccountRollupBatch actually sees vs what it should see
// Replicate the EXACT start() query and processAccount() logic

System.debug(LoggingLevel.INFO, '=== ACCOUNTROLLUPBATCH ACTUAL DEBUG ===');

String targetAccountId = '001fJ000021YCvsQAG';

// Use the EXACT query from AccountRollupBatch.start()
System.debug(LoggingLevel.INFO, 'Using EXACT AccountRollupBatch query...');

List<Account> accounts = [
    SELECT Id, Status__c, Type, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
           (SELECT Id, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
                   ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                   StartDate, EndDate, Status, Exclude_from_Status_Updates__c,
                   Renewal_Opportunity__c,
                   Renewal_Opportunity__r.Id, Renewal_Opportunity__r.StageName, 
                   Renewal_Opportunity__r.IsClosed, Renewal_Opportunity__r.Deal_Type__c
            FROM Contracts)
    FROM Account 
    WHERE Id = :targetAccountId
];

if (accounts.isEmpty()) {
    System.debug(LoggingLevel.ERROR, 'No account found with ID: ' + targetAccountId);
    return;
}

Account account = accounts[0];
Date today = Date.today();

System.debug(LoggingLevel.INFO, 'Account found: ' + account.Id);
System.debug(LoggingLevel.INFO, 'Account Status: ' + account.Status__c);
System.debug(LoggingLevel.INFO, 'Contracts found: ' + account.Contracts.size());
System.debug(LoggingLevel.INFO, 'Today: ' + today);

// EXACT contract counting logic from AccountRollupBatch processAccount()
Decimal varN_ActiveContracts = 0;
Decimal varN_FutureContracts = 0;
Decimal varN_NumExpiredContracts = 0;

System.debug(LoggingLevel.INFO, '=== EXACT CONTRACT COUNTING LOGIC ===');

// Step 3: Contract counting (exact flow replication)
for (Contract contract : account.Contracts) {
    System.debug(LoggingLevel.INFO, 'Processing Contract: ' + contract.Id);
    System.debug(LoggingLevel.INFO, '  Status: ' + contract.Status);
    System.debug(LoggingLevel.INFO, '  StartDate: ' + contract.StartDate);
    System.debug(LoggingLevel.INFO, '  EndDate: ' + contract.EndDate);
    System.debug(LoggingLevel.INFO, '  Exclude_from_Status_Updates__c: ' + contract.Exclude_from_Status_Updates__c);
    System.debug(LoggingLevel.INFO, '  ARR__c: ' + contract.ARR__c);
    
    // EXACT logic from AccountRollupBatch lines 142-151
    if (contract.StartDate > today && contract.Exclude_from_Status_Updates__c == false) {
        varN_FutureContracts += 1;
        System.debug(LoggingLevel.INFO, '  ➡️ FUTURE CONTRACT (count now: ' + varN_FutureContracts + ')');
    } else if (contract.StartDate <= today && 
              contract.EndDate >= today && 
              contract.Exclude_from_Status_Updates__c == false) {
        varN_ActiveContracts += 1;
        System.debug(LoggingLevel.INFO, '  ➡️ ACTIVE CONTRACT (count now: ' + varN_ActiveContracts + ')');
    } else if (contract.EndDate < today) {
        varN_NumExpiredContracts += 1;
        System.debug(LoggingLevel.INFO, '  ➡️ EXPIRED CONTRACT (count now: ' + varN_NumExpiredContracts + ')');
    } else {
        System.debug(LoggingLevel.WARN, '  ➡️ UNCATEGORIZED CONTRACT');
        System.debug(LoggingLevel.WARN, '    StartDate > today: ' + (contract.StartDate > today));
        System.debug(LoggingLevel.WARN, '    StartDate <= today: ' + (contract.StartDate <= today));
        System.debug(LoggingLevel.WARN, '    EndDate >= today: ' + (contract.EndDate >= today));
        System.debug(LoggingLevel.WARN, '    EndDate < today: ' + (contract.EndDate < today));
        System.debug(LoggingLevel.WARN, '    Exclude_from_Status_Updates__c: ' + contract.Exclude_from_Status_Updates__c);
    }
}

System.debug(LoggingLevel.INFO, '=== FINAL CONTRACT COUNTS ===');
System.debug(LoggingLevel.INFO, 'varN_ActiveContracts: ' + varN_ActiveContracts);
System.debug(LoggingLevel.INFO, 'varN_FutureContracts: ' + varN_FutureContracts);
System.debug(LoggingLevel.INFO, 'varN_NumExpiredContracts: ' + varN_NumExpiredContracts);

// This is the EXACT debug message from AccountRollupBatch line 181-182
System.debug(LoggingLevel.INFO, '=== EXACT DEBUG MESSAGE ===');
System.debug(LoggingLevel.INFO, 'AccountRollupBatch: Recalculating all revenue fields from active contracts for account ' + account.Id + 
             ' (Active: ' + varN_ActiveContracts + ')');

if (varN_ActiveContracts == 0) {
    System.debug(LoggingLevel.ERROR, '🚨 CONFIRMED ISSUE: varN_ActiveContracts is 0');
    System.debug(LoggingLevel.ERROR, 'This means NONE of the contracts are being counted as active');
    System.debug(LoggingLevel.ERROR, 'Check each contract against the counting criteria above');
} else {
    System.debug(LoggingLevel.INFO, '✅ Expected behavior: ' + varN_ActiveContracts + ' active contracts found');
}

System.debug(LoggingLevel.INFO, '=== ACCOUNTROLLUPBATCH ACTUAL DEBUG COMPLETE ===');
