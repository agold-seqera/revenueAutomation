// Debug script to test the EXACT query used by AccountRollupBatch
// This will reveal if there's a difference in how relationship data is loaded

System.debug('=== DEBUGGING ACCOUNTROLLUPBATCH EXACT QUERY ===');

// Use the EXACT query from AccountRollupBatch.start() method
List<Account> accounts = [
    SELECT Id, Name, Status__c, Type, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
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
    AND Id = '001fJ000021YBjKQAW'
];

if (accounts.isEmpty()) {
    System.debug('❌ ERROR: Caris account not found in AccountRollupBatch query');
    return;
}

Account account = accounts[0];
System.debug('✅ Account found: ' + account.Name + ' (ID: ' + account.Id + ')');
System.debug('Account Status: ' + account.Status__c);
System.debug('Contracts found: ' + account.Contracts.size());

for (Contract contract : account.Contracts) {
    System.debug('');
    System.debug('Contract: ' + contract.Id);
    System.debug('  Status: ' + contract.Status);
    System.debug('  StartDate: ' + contract.StartDate);
    System.debug('  EndDate: ' + contract.EndDate);
    System.debug('  Exclude_from_Status_Updates__c: ' + contract.Exclude_from_Status_Updates__c);
    
    // CRITICAL: Check if renewal opportunity data is loaded
    System.debug('  Renewal_Opportunity__c: ' + contract.Renewal_Opportunity__c);
    
    if (contract.Renewal_Opportunity__c != null) {
        // Check if the relationship query loaded the data
        if (contract.Renewal_Opportunity__r != null) {
            System.debug('  ✅ Renewal_Opportunity__r IS LOADED:');
            System.debug('    Id: ' + contract.Renewal_Opportunity__r.Id);
            System.debug('    StageName: ' + contract.Renewal_Opportunity__r.StageName);
            System.debug('    IsClosed: ' + contract.Renewal_Opportunity__r.IsClosed);
            System.debug('    Deal_Type__c: ' + contract.Renewal_Opportunity__r.Deal_Type__c);
            
            // Test the exact logic from AccountRollupBatch
            if (contract.Renewal_Opportunity__r.IsClosed == false) {
                System.debug('    → Would set varB_HasOpenRenewal = true');
            } else if (contract.Renewal_Opportunity__r.StageName == 'Closed Lost' && 
                      contract.Renewal_Opportunity__r.Deal_Type__c == 'Churn') {
                System.debug('    → Would set varB_HasLostRenewal = true');
            } else {
                System.debug('    → No renewal flags would be set');
                System.debug('      (IsClosed=' + contract.Renewal_Opportunity__r.IsClosed + 
                           ', StageName=' + contract.Renewal_Opportunity__r.StageName + 
                           ', Deal_Type=' + contract.Renewal_Opportunity__r.Deal_Type__c + ')');
            }
        } else {
            System.debug('  ❌ ERROR: Renewal_Opportunity__r IS NULL despite Renewal_Opportunity__c having value!');
            System.debug('    This would cause the batch to NOT detect the lost renewal!');
            System.debug('    Renewal_Opportunity__c field value: ' + contract.Renewal_Opportunity__c);
        }
    } else {
        System.debug('  No renewal opportunity linked');
    }
}

System.debug('');
System.debug('=== COMPARISON TEST ===');

// Compare with direct opportunity query (what our manual tests used)
System.debug('Direct opportunity query:');
Opportunity directOpp = [
    SELECT Id, Name, StageName, IsClosed, Deal_Type__c 
    FROM Opportunity 
    WHERE Id = '006fJ000006Oi4zQAC'
];

System.debug('Direct query result:');
System.debug('  Id: ' + directOpp.Id);
System.debug('  StageName: ' + directOpp.StageName);
System.debug('  IsClosed: ' + directOpp.IsClosed);
System.debug('  Deal_Type__c: ' + directOpp.Deal_Type__c);

System.debug('');
System.debug('=== CONCLUSION ===');
System.debug('If the relationship query loads data correctly, the issue is elsewhere.');
System.debug('If the relationship query fails to load data, that\'s the root cause!');

System.debug('=== END DEBUG ===');
