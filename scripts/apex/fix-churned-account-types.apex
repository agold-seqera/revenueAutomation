// One-time fix for Churned accounts that still have Type = 'Prospect'
// These should have Type = 'Churned' based on our new business logic

List<Account> accountsToFix = [
    SELECT Id, Name, Status__c, Type
    FROM Account 
    WHERE Status__c = 'Churned' 
    AND Type = 'Prospect'
];

System.debug('Found ' + accountsToFix.size() + ' Churned accounts with Type = Prospect to fix');

for (Account acc : accountsToFix) {
    System.debug('Fixing account: ' + acc.Name + ' (' + acc.Id + ') - Setting Type from Prospect to Churned');
    acc.Type = 'Churned';
}

if (!accountsToFix.isEmpty()) {
    update accountsToFix;
    System.debug('Successfully updated ' + accountsToFix.size() + ' accounts to Type = Churned');
} else {
    System.debug('No accounts found to fix');
}
