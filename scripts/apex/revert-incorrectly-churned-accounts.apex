// Fix incorrectly churned accounts that have open renewals
// These should be "Active (Churning)" not "Churned"

List<Account> accountsToRevert = [
    SELECT Id, Name, Status__c 
    FROM Account 
    WHERE Id IN ('001fJ000021Y30LQAS', '001fJ000021YDsNQAW', '001fJ000021YDYZQA4')
];

System.debug('Found ' + accountsToRevert.size() + ' accounts to revert from Churned to Active (Churning)');

for (Account acc : accountsToRevert) {
    System.debug('Reverting account: ' + acc.Name + ' (' + acc.Id + ') from ' + acc.Status__c + ' to Active (Churning)');
    acc.Status__c = 'Active (Churning)';
}

if (!accountsToRevert.isEmpty()) {
    update accountsToRevert;
    System.debug('Successfully reverted ' + accountsToRevert.size() + ' accounts to Active (Churning)');
} else {
    System.debug('No accounts found to revert');
}
