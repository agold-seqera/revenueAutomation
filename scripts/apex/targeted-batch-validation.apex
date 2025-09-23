// Targeted batch validation for specific accounts after human error resolution
System.debug('=== TARGETED BATCH VALIDATION ===');
System.debug('Target Accounts: 001fJ000021YDvaQAG, 001fJ000022JGzmQAG');

// Get account details before batch processing
List<Account> targetAccounts = [
    SELECT Id, Name, Status__c, Type, Has_Contracts__c,
           ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
           TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
           MRR__c, MRR_USD__c, MRR_USD_Reporting__c,
           LastModifiedDate,
           (SELECT Id, Status, StartDate, EndDate, LastModifiedDate,
                   ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
                   ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
                   TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
                   MRR__c, MRR_USD__c, MRR_USD_Reporting__c,
                   CurrencyIsoCode, Exclude_from_Status_Updates__c
            FROM Contracts
            WHERE Exclude_from_Status_Updates__c = false)
    FROM Account
    WHERE Id IN ('001fJ000021YDvaQAG', '001fJ000022JGzmQAG')
    ORDER BY Name
];

System.debug('=== PRE-BATCH ACCOUNT STATE ===');
for (Account account : targetAccounts) {
    System.debug('--- ' + account.Name + ' (' + account.Id + ') ---');
    System.debug('  Status: ' + account.Status__c + ' | Type: ' + account.Type);
    System.debug('  Has_Contracts: ' + account.Has_Contracts__c);
    System.debug('  LastModified: ' + account.LastModifiedDate);
    System.debug('  ARR: ' + account.ARR__c + ' | USD: ' + account.ARR_USD__c + ' | Reporting: ' + account.ARR_USD_Reporting__c);
    System.debug('  ACV: ' + account.ACV__c + ' | USD: ' + account.ACV_USD__c + ' | Reporting: ' + account.ACV_USD_Reporting__c);
    System.debug('  TCV: ' + account.TCV__c + ' | USD: ' + account.TCV_USD__c + ' | Reporting: ' + account.TCV_USD_Reporting__c);
    System.debug('  MRR: ' + account.MRR__c + ' | USD: ' + account.MRR_USD__c + ' | Reporting: ' + account.MRR_USD_Reporting__c);
    
    System.debug('  Contracts (' + account.Contracts.size() + ' total):');
    for (Contract contract : account.Contracts) {
        System.debug('    ' + contract.Id + ' (' + contract.Status + ') Start: ' + contract.StartDate + ' End: ' + contract.EndDate);
        System.debug('      ARR: ' + contract.ARR__c + ' | USD: ' + contract.ARR_USD__c + ' | Reporting: ' + contract.ARR_USD_Reporting__c);
        System.debug('      LastModified: ' + contract.LastModifiedDate);
    }
    System.debug('');
}

// Now run targeted batches for these specific accounts
System.debug('=== EXECUTING TARGETED BATCHES ===');

// 1. First run AssetStatusBatch for any assets related to these accounts
System.debug('--- Running AssetStatusBatch ---');
AssetStatusBatch assetBatch = new AssetStatusBatch();
Id assetJobId = Database.executeBatch(assetBatch, 50);
System.debug('AssetStatusBatch Job ID: ' + assetJobId);

// 2. Then run ContractRevenueBatch for these specific accounts' contracts
System.debug('--- Running ContractRevenueBatch ---');
ContractRevenueBatch contractBatch = new ContractRevenueBatch();
Id contractJobId = Database.executeBatch(contractBatch, 50);
System.debug('ContractRevenueBatch Job ID: ' + contractJobId);

// 3. Finally run AccountRollupBatch for these specific accounts
System.debug('--- Running AccountRollupBatch ---');
AccountRollupBatch accountBatch = new AccountRollupBatch();
Id accountJobId = Database.executeBatch(accountBatch, 50);
System.debug('AccountRollupBatch Job ID: ' + accountJobId);

System.debug('=== BATCH JOBS INITIATED ===');
System.debug('Wait ~60 seconds then run targeted-batch-results.apex to see results');
System.debug('Asset Job: ' + assetJobId);
System.debug('Contract Job: ' + contractJobId);
System.debug('Account Job: ' + accountJobId);
