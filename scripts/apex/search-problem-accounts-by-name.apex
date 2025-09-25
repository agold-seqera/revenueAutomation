// Search Problem Accounts by Name
// Date: September 25, 2025

System.debug('=== PROBLEM ACCOUNT SEARCH BY NAME ===');

// Search for the key accounts mentioned in September 23rd analysis
List<String> accountNames = new List<String>{
    'Natera',
    'ModernaTx', 
    'CDC',
    'Genomics England',
    'Biomodal'
};

System.debug('🔍 Searching for accounts by name:');

for (String accountName : accountNames) {
    List<Account> foundAccounts = [
        SELECT Id, Name, Status__c, Type,
               ARR__c, ACV__c, TCV__c, MRR__c, 
               ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
               CurrencyIsoCode, LastModifiedDate, LastModifiedBy.Name
        FROM Account 
        WHERE Name LIKE :('%' + accountName + '%')
        LIMIT 5
    ];
    
    System.debug('');
    System.debug('📊 Search for "' + accountName + '":');
    
    if (foundAccounts.isEmpty()) {
        System.debug('   No accounts found');
    } else {
        for (Account acc : foundAccounts) {
            System.debug('   ' + acc.Name + ' (' + acc.Id + ')');
            System.debug('      Status: ' + acc.Status__c + ' | Type: ' + acc.Type);
            System.debug('      ARR: ' + acc.ARR__c + ' → USD: $' + acc.ARR_USD__c);
            System.debug('      TCV: ' + acc.TCV__c + ' → USD: $' + acc.TCV_USD__c);
            
            // Check if modified today
            if (acc.LastModifiedDate != null && acc.LastModifiedDate.date() == Date.today()) {
                System.debug('      ✅ Modified today: ' + acc.LastModifiedDate);
            } else {
                System.debug('      ⚠️  Not modified today: ' + acc.LastModifiedDate);
            }
        }
    }
}

// Also check recent batch modifications
System.debug('');
System.debug('📊 ACCOUNTS MODIFIED TODAY (Sample):');

List<Account> todaysAccounts = [
    SELECT Id, Name, Status__c, ARR__c, ARR_USD__c, TCV__c, TCV_USD__c,
           CurrencyIsoCode, LastModifiedDate
    FROM Account 
    WHERE LastModifiedDate = TODAY 
    AND LastModifiedBy.Name = 'Sys Admin'
    ORDER BY LastModifiedDate DESC
    LIMIT 10
];

for (Account acc : todaysAccounts) {
    System.debug('   ' + acc.Name + ' - Status: ' + acc.Status__c);
    System.debug('      ARR: ' + acc.ARR__c + ' → USD: $' + acc.ARR_USD__c);
    System.debug('      Currency: ' + acc.CurrencyIsoCode);
    System.debug('   ---');
}

System.debug('');
System.debug('Analysis Complete: ' + System.now());
