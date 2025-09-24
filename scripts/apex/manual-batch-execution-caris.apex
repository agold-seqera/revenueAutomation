// Manual batch execution for Caris Life Sciences account to see if status update actually happens
// This will simulate the exact AccountRollupBatch.execute() method for this one account

System.debug('=== MANUAL BATCH EXECUTION FOR CARIS LIFE SCIENCES ===');

// Query account exactly as the batch does
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
    WHERE Id = '001fJ000021YBjKQAW'
];

System.debug('Queried ' + accounts.size() + ' account(s)');

if (accounts.isEmpty()) {
    System.debug('ERROR: No account found');
    return;
}

Account account = accounts[0];
System.debug('BEFORE Processing:');
System.debug('  Account: ' + account.Name);
System.debug('  Status: ' + account.Status__c);
System.debug('  Type: ' + account.Type);

// Replicate AccountRollupBatch.execute() logic
List<Account> accountsToUpdate = new List<Account>();
Date today = Date.today();

// This is the exact logic from lines 46-52 in AccountRollupBatch.execute()
for (Account acc : accounts) {
    // We need to call processAccount method logic inline since we can't call private method
    // For this test, we'll just set the status manually based on our debug results
    
    System.debug('Processing account: ' + acc.Id);
    
    // We know from our previous debug that the logic should return "Active (Churning)"
    // Let's manually apply what processAccount should do
    String originalStatus = acc.Status__c;
    acc.Status__c = 'Active (Churning)';
    acc.Type = 'Customer'; // determineAccountType would return 'Customer' for this status
    
    System.debug('Status change applied: ' + originalStatus + ' → ' + acc.Status__c);
    System.debug('Type updated to: ' + acc.Type);
    
    accountsToUpdate.add(acc);
}

System.debug('');
System.debug('Accounts to update: ' + accountsToUpdate.size());

// This is the exact update logic from lines 55-70 in AccountRollupBatch.execute()
if (!accountsToUpdate.isEmpty()) {
    System.debug('Performing Database.update...');
    
    try {
        Database.SaveResult[] results = Database.update(accountsToUpdate, false);
        
        System.debug('Update completed. Processing results...');
        
        // Log results
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                System.debug('✅ SUCCESS: Account ' + accountsToUpdate[i].Id + ' updated successfully');
                System.debug('   Status: ' + accountsToUpdate[i].Status__c);
                System.debug('   Type: ' + accountsToUpdate[i].Type);
            } else {
                System.debug('❌ FAILURE: Account ' + accountsToUpdate[i].Id + ' update failed');
                for (Database.Error err : results[i].getErrors()) {
                    System.debug('   Error: ' + err.getMessage());
                    System.debug('   Fields: ' + err.getFields());
                }
            }
        }
    } catch (Exception e) {
        System.debug('❌ EXCEPTION during update: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
    }
} else {
    System.debug('No accounts to update');
}

// Verify the result by querying the account again
System.debug('');
System.debug('=== VERIFICATION ===');
Account verifyAccount = [SELECT Id, Name, Status__c, Type, LastModifiedDate, LastModifiedBy.Name 
                        FROM Account WHERE Id = '001fJ000021YBjKQAW'];

System.debug('AFTER Processing:');
System.debug('  Account: ' + verifyAccount.Name);
System.debug('  Status: ' + verifyAccount.Status__c);
System.debug('  Type: ' + verifyAccount.Type);
System.debug('  LastModified: ' + verifyAccount.LastModifiedDate);
System.debug('  LastModifiedBy: ' + verifyAccount.LastModifiedBy.Name);

System.debug('=== END MANUAL BATCH EXECUTION ===');
