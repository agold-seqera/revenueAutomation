// Test script to verify reporting fields are populated correctly by batch classes
System.debug('=== Testing Reporting Fields Population ===');

// Test 1: Run ContractRevenueBatch and check if reporting fields are populated
System.debug('--- Test 1: ContractRevenueBatch Reporting Fields ---');

// Get a sample contract with assets
List<Contract> testContracts = [
    SELECT Id, Name, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
           ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, 
           MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c,
           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                   Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false LIMIT 5)
    FROM Contract 
    WHERE Status = 'Activated' 
    AND Id IN (SELECT Contract__c FROM Asset WHERE Exchange_Rate__c != null AND ARR__c > 0)
    LIMIT 3
];

System.debug('Found ' + testContracts.size() + ' test contracts with assets');

if (testContracts.size() > 0) {
    Contract sampleContract = testContracts[0];
    System.debug('Sample Contract BEFORE batch: ' + sampleContract.Name);
    System.debug('  ARR__c: ' + sampleContract.ARR__c + ', ARR_USD__c: ' + sampleContract.ARR_USD__c + ', ARR_USD_Reporting__c: ' + sampleContract.ARR_USD_Reporting__c);
    System.debug('  ACV__c: ' + sampleContract.ACV__c + ', ACV_USD__c: ' + sampleContract.ACV_USD__c + ', ACV_USD_Reporting__c: ' + sampleContract.ACV_USD_Reporting__c);
    System.debug('  Assets: ' + sampleContract.Assets__r.size());
    
    // Run ContractRevenueBatch
    ContractRevenueBatch batch = new ContractRevenueBatch();
    batch.execute(null, testContracts);
    
    // Check results
    Contract updatedContract = [
        SELECT Id, Name, ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c,
               ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
               ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, 
               MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c
        FROM Contract 
        WHERE Id = :sampleContract.Id
    ];
    
    System.debug('Sample Contract AFTER batch: ' + updatedContract.Name);
    System.debug('  ARR__c: ' + updatedContract.ARR__c + ', ARR_USD__c: ' + updatedContract.ARR_USD__c + ', ARR_USD_Reporting__c: ' + updatedContract.ARR_USD_Reporting__c);
    System.debug('  ACV__c: ' + updatedContract.ACV__c + ', ACV_USD__c: ' + updatedContract.ACV_USD__c + ', ACV_USD_Reporting__c: ' + updatedContract.ACV_USD_Reporting__c);
    System.debug('  TCV__c: ' + updatedContract.TCV__c + ', TCV_USD__c: ' + updatedContract.TCV_USD__c + ', TCV_USD_Reporting__c: ' + updatedContract.TCV_USD_Reporting__c);
    System.debug('  MRR__c: ' + updatedContract.MRR__c + ', MRR_USD__c: ' + updatedContract.MRR_USD__c + ', MRR_USD_Reporting__c: ' + updatedContract.MRR_USD_Reporting__c);
    
    // Validate reporting fields are populated
    Boolean contractReportingFieldsPopulated = 
        updatedContract.ARR_USD_Reporting__c != null ||
        updatedContract.ACV_USD_Reporting__c != null ||
        updatedContract.TCV_USD_Reporting__c != null ||
        updatedContract.MRR_USD_Reporting__c != null;
    
    System.debug('✅ Contract Reporting Fields Populated: ' + contractReportingFieldsPopulated);
}

System.debug('');

// Test 2: Run AccountRollupBatch and check if reporting fields are populated
System.debug('--- Test 2: AccountRollupBatch Reporting Fields ---');

// Get a sample account with contracts
List<Account> testAccounts = [
    SELECT Id, Name, Has_Contracts__c, ARR__c, ACV__c, TCV__c, MRR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
           (SELECT Id, ARR__c, ACV__c, TCV__c, MRR__c, Status, 
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c
            FROM Contracts WHERE Status = 'Activated' LIMIT 3)
    FROM Account 
    WHERE Has_Contracts__c = true 
    AND Id IN (SELECT AccountId FROM Contract WHERE Status = 'Activated' AND ARR_USD_Reporting__c != null)
    LIMIT 2
];

System.debug('Found ' + testAccounts.size() + ' test accounts with contracts');

if (testAccounts.size() > 0) {
    Account sampleAccount = testAccounts[0];
    System.debug('Sample Account BEFORE batch: ' + sampleAccount.Name);
    System.debug('  ARR__c: ' + sampleAccount.ARR__c + ', ARR_USD__c: ' + sampleAccount.ARR_USD__c + ', ARR_USD_Reporting__c: ' + sampleAccount.ARR_USD_Reporting__c);
    System.debug('  ACV__c: ' + sampleAccount.ACV__c + ', ACV_USD__c: ' + sampleAccount.ACV_USD__c + ', ACV_USD_Reporting__c: ' + sampleAccount.ACV_USD_Reporting__c);
    System.debug('  Active Contracts: ' + sampleAccount.Contracts.size());
    
    // Run AccountRollupBatch
    AccountRollupBatch batch = new AccountRollupBatch();
    batch.execute(null, testAccounts);
    
    // Check results
    Account updatedAccount = [
        SELECT Id, Name, ARR__c, ACV__c, TCV__c, MRR__c,
               ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
               ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c
        FROM Account 
        WHERE Id = :sampleAccount.Id
    ];
    
    System.debug('Sample Account AFTER batch: ' + updatedAccount.Name);
    System.debug('  ARR__c: ' + updatedAccount.ARR__c + ', ARR_USD__c: ' + updatedAccount.ARR_USD__c + ', ARR_USD_Reporting__c: ' + updatedAccount.ARR_USD_Reporting__c);
    System.debug('  ACV__c: ' + updatedAccount.ACV__c + ', ACV_USD__c: ' + updatedAccount.ACV_USD__c + ', ACV_USD_Reporting__c: ' + updatedAccount.ACV_USD_Reporting__c);
    System.debug('  TCV__c: ' + updatedAccount.TCV__c + ', TCV_USD__c: ' + updatedAccount.TCV_USD__c + ', TCV_USD_Reporting__c: ' + updatedAccount.TCV_USD_Reporting__c);
    System.debug('  MRR__c: ' + updatedAccount.MRR__c + ', MRR_USD__c: ' + updatedAccount.MRR_USD__c + ', MRR_USD_Reporting__c: ' + updatedAccount.MRR_USD_Reporting__c);
    
    // Validate reporting fields are populated
    Boolean accountReportingFieldsPopulated = 
        updatedAccount.ARR_USD_Reporting__c != null ||
        updatedAccount.ACV_USD_Reporting__c != null ||
        updatedAccount.TCV_USD_Reporting__c != null ||
        updatedAccount.MRR_USD_Reporting__c != null;
    
    System.debug('✅ Account Reporting Fields Populated: ' + accountReportingFieldsPopulated);
}

System.debug('');

// Test 3: Verify Asset formula reporting fields are calculating correctly
System.debug('--- Test 3: Asset Formula Reporting Fields ---');

List<Asset> testAssets = [
    SELECT Id, Name, ARR__c, Total_Value__c, Price, Exchange_Rate__c,
           ARR_USD__c, Total_Value_USD__c, Price_USD__c
    FROM Asset 
    WHERE Exchange_Rate__c != null AND ARR__c > 0
    LIMIT 3
];

System.debug('Found ' + testAssets.size() + ' test assets with exchange rates');

for (Asset testAsset : testAssets) {
    System.debug('Asset: ' + testAsset.Name);
    System.debug('  ARR__c: ' + testAsset.ARR__c + ', Exchange_Rate__c: ' + testAsset.Exchange_Rate__c);
    System.debug('  ARR_USD__c (Text): ' + testAsset.ARR_USD__c);
    System.debug('  Price_USD__c (Text): ' + testAsset.Price_USD__c);
    
    // Note: Asset reporting fields will be tested once deployed in future tests
    System.debug('');
}

System.debug('=== Test Complete ===');
