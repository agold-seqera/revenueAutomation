// Investigate which accounts were actually processed by AccountRollupBatch
System.debug('=== INVESTIGATING ACCOUNTROLLUPBATCH SCOPE ===');

// The AccountRollupBatch job processed 3 items. Let's see which accounts have Has_Contracts__c = true
// and what the current state looks like for all potential accounts

List<Account> allAccountsWithContracts = [
    SELECT Id, Name, Status__c, Has_Contracts__c, 
           ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           LastModifiedDate,
           (SELECT Id, Status, StartDate, EndDate FROM Contracts)
    FROM Account
    WHERE Has_Contracts__c = true
    ORDER BY LastModifiedDate DESC
];

System.debug('Total accounts with Has_Contracts__c = true: ' + allAccountsWithContracts.size());

// Group by status
Map<String, Integer> statusCounts = new Map<String, Integer>();
Integer contractedAccountsTotal = 0;

for (Account account : allAccountsWithContracts) {
    String status = account.Status__c;
    statusCounts.put(status, statusCounts.containsKey(status) ? statusCounts.get(status) + 1 : 1);
    
    if (status == 'Contracted') {
        contractedAccountsTotal++;
    }
    
    System.debug('Account: ' + account.Name + ' | Status: ' + account.Status__c + 
                 ' | LastModified: ' + account.LastModifiedDate + 
                 ' | ARR_USD_Reporting: ' + account.ARR_USD_Reporting__c);
}

System.debug('--- STATUS BREAKDOWN ---');
for (String status : statusCounts.keySet()) {
    System.debug('  ' + status + ': ' + statusCounts.get(status) + ' accounts');
}

System.debug('--- ANALYSIS ---');
System.debug('Total "Contracted" accounts: ' + contractedAccountsTotal);
System.debug('Job processed: 3 accounts');

if (contractedAccountsTotal > 3) {
    System.debug('⚠️  POTENTIAL ISSUE: More Contracted accounts (' + contractedAccountsTotal + ') than job processed (3)');
    System.debug('    This suggests the AccountRollupBatch may need to run for ALL accounts, not just a subset');
} else {
    System.debug('✅ All Contracted accounts were processed by the AccountRollupBatch');
}

System.debug('=== INVESTIGATION COMPLETE ===');
