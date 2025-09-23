// Run AccountRollupBatch for Atlas Data Storage account specifically
System.debug('=== RUNNING ACCOUNTROLLUPBATCH FOR ATLAS DATA STORAGE ===');

// Get the Atlas Data Storage account ID
Account atlasAccount = [SELECT Id, Name FROM Account WHERE Name = 'Atlas Data Storage' LIMIT 1];
System.debug('Atlas Account ID: ' + atlasAccount.Id);

// Create and execute AccountRollupBatch for this specific account
AccountRollupBatch batch = new AccountRollupBatch();
batch.accountIds = new Set<Id>{atlasAccount.Id}; // Process only this account
batch.query = 'SELECT Id, Name, Status__c, Has_Contracts__c, CurrencyIsoCode, ' +
              'ARR__c, ACV__c, TCV__c, MRR__c, ' +
              'ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, ' +
              'ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c ' +
              'FROM Account ' +
              'WHERE Id = \'' + atlasAccount.Id + '\' ' +
              'AND Has_Contracts__c = true';

// Execute the batch synchronously
Database.executeBatch(batch, 1);

System.debug('✅ AccountRollupBatch queued for Atlas Data Storage');
System.debug('=== ACCOUNT ROLLUP INITIATED ===');
