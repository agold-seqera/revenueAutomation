// Debug AccountRollupBatch by running the EXACT start() query and processing
// This will show if the issue is in the query scope vs. the individual account processing

System.debug(LoggingLevel.INFO, '=== ACCOUNTROLLUPBATCH FULL SCOPE DEBUG ===');

// Use the EXACT query from AccountRollupBatch.start() with EXACT WHERE clause
System.debug(LoggingLevel.INFO, 'Running EXACT AccountRollupBatch start() query...');

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
    WHERE Has_Contracts__c = true
    AND Id = '001fJ000021YCvsQAG'  // Filter to just AstraZeneca for debugging
];

System.debug(LoggingLevel.INFO, 'Accounts returned by start() query: ' + accounts.size());

if (accounts.isEmpty()) {
    System.debug(LoggingLevel.ERROR, 'AstraZeneca not returned by AccountRollupBatch start() query!');
    System.debug(LoggingLevel.ERROR, 'This means it does not meet the WHERE Has_Contracts__c = true criteria');
    return;
}

Account account = accounts[0];
Date today = Date.today();

System.debug(LoggingLevel.INFO, 'Processing account: ' + account.Id);
System.debug(LoggingLevel.INFO, 'Account has ' + account.Contracts.size() + ' contracts');

// Now process this account using EXACT AccountRollupBatch.processAccount() logic
// Initialize EXACT variables
Decimal varN_ActiveContracts = 0;
Decimal varN_FutureContracts = 0;
Decimal varN_NumExpiredContracts = 0;

System.debug(LoggingLevel.INFO, '=== STEP 3: CONTRACT COUNTING (EXACT LOGIC) ===');

// EXACT Step 3 logic from AccountRollupBatch
for (Contract contract : account.Contracts) {
    System.debug(LoggingLevel.INFO, 'Contract: ' + contract.Id + 
                                   ' | Status: ' + contract.Status + 
                                   ' | StartDate: ' + contract.StartDate + 
                                   ' | EndDate: ' + contract.EndDate + 
                                   ' | Exclude: ' + contract.Exclude_from_Status_Updates__c);
    
    // EXACT contract counting logic from lines 142-151
    if (contract.StartDate > today && contract.Exclude_from_Status_Updates__c == false) {
        varN_FutureContracts += 1;
        System.debug(LoggingLevel.INFO, '  ➡️ FUTURE (count: ' + varN_FutureContracts + ')');
    } else if (contract.StartDate <= today && 
              contract.EndDate >= today && 
              contract.Exclude_from_Status_Updates__c == false) {
        varN_ActiveContracts += 1;
        System.debug(LoggingLevel.INFO, '  ➡️ ACTIVE (count: ' + varN_ActiveContracts + ')');
    } else if (contract.EndDate < today) {
        varN_NumExpiredContracts += 1;
        System.debug(LoggingLevel.INFO, '  ➡️ EXPIRED (count: ' + varN_NumExpiredContracts + ')');
    } else {
        System.debug(LoggingLevel.WARN, '  ➡️ UNCATEGORIZED');
    }
}

System.debug(LoggingLevel.INFO, '=== FINAL COUNTS ===');
System.debug(LoggingLevel.INFO, 'varN_ActiveContracts: ' + varN_ActiveContracts);
System.debug(LoggingLevel.INFO, 'varN_FutureContracts: ' + varN_FutureContracts);
System.debug(LoggingLevel.INFO, 'varN_NumExpiredContracts: ' + varN_NumExpiredContracts);

// Check preservation logic that affects the debug message
Boolean preserveAllExpired = (varN_ActiveContracts == 0 && 
                             varN_FutureContracts == 0 && 
                             varN_NumExpiredContracts > 0);

Boolean preserveExpiredWithOpenRenewal = false; // We'll skip renewal logic for now

Boolean shouldPreserveExpiredRevenue = preserveAllExpired || preserveExpiredWithOpenRenewal;

System.debug(LoggingLevel.INFO, '=== PRESERVATION LOGIC ===');
System.debug(LoggingLevel.INFO, 'preserveAllExpired: ' + preserveAllExpired);
System.debug(LoggingLevel.INFO, 'shouldPreserveExpiredRevenue: ' + shouldPreserveExpiredRevenue);

// This determines which debug message is shown
if (shouldPreserveExpiredRevenue) {
    System.debug(LoggingLevel.INFO, '=== WOULD SHOW PRESERVATION MESSAGE ===');
    System.debug(LoggingLevel.INFO, 'AccountRollupBatch: Preserving ALL revenue fields for account ' + account.Id + 
                ' (Active: ' + varN_ActiveContracts + ', Future: ' + varN_FutureContracts + 
                ', Expired: ' + varN_NumExpiredContracts + ')');
} else {
    System.debug(LoggingLevel.INFO, '=== WOULD SHOW RECALCULATION MESSAGE ===');
    System.debug(LoggingLevel.INFO, 'AccountRollupBatch: Recalculating all revenue fields from active contracts for account ' + account.Id + 
                ' (Active: ' + varN_ActiveContracts + ')');
}

System.debug(LoggingLevel.INFO, '=== ACCOUNTROLLUPBATCH FULL SCOPE DEBUG COMPLETE ===');
