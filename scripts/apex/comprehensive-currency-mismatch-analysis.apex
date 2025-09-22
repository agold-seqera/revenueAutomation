// COMPREHENSIVE CURRENCY MISMATCH ANALYSIS
// Analyze Asset → Contract → Account currency alignment issues
System.debug('=== COMPREHENSIVE CURRENCY MISMATCH ANALYSIS ===');

// ========================================
// PART 1: CONTRACT-LEVEL ANALYSIS
// ========================================
System.debug('');
System.debug('=== PART 1: CONTRACT CURRENCY ANALYSIS ===');

// Query all contracts with their assets
List<Contract> allContracts = [SELECT Id, CurrencyIsoCode, AccountId, Status, StartDate, EndDate,
                                      (SELECT Id, CurrencyIsoCode, Start_Date__c, End_Date__c 
                                       FROM Assets__r 
                                       WHERE Exclude_from_Status_Updates__c = false)
                               FROM Contract 
                               ORDER BY AccountId, Id];

Integer contractsWithAssets = 0;
Integer contractsWithSingleCurrency = 0;
Integer contractsWithMultipleCurrencies = 0;
Integer contractsWithCurrencyMismatch = 0;
List<String> contractsNeedingManualReview = new List<String>();
List<String> contractsNeedingCurrencyUpdate = new List<String>();

Date today = Date.today();

for (Contract contract : allContracts) {
    if (contract.Assets__r.size() > 0) {
        contractsWithAssets++;
        
        // Analyze asset currencies for this contract
        Set<String> assetCurrencies = new Set<String>();
        for (Asset asset : contract.Assets__r) {
            if (String.isNotBlank(asset.CurrencyIsoCode)) {
                assetCurrencies.add(asset.CurrencyIsoCode);
            }
        }
        
        System.debug('Contract ' + contract.Id + ' | Contract Currency: ' + contract.CurrencyIsoCode + 
                    ' | Asset Currencies: ' + assetCurrencies + ' | Assets: ' + contract.Assets__r.size());
        
        if (assetCurrencies.size() == 1) {
            contractsWithSingleCurrency++;
            String assetCurrency = new List<String>(assetCurrencies)[0];
            
            // Check if contract currency matches asset currency
            if (contract.CurrencyIsoCode != assetCurrency) {
                contractsWithCurrencyMismatch++;
                contractsNeedingCurrencyUpdate.add(contract.Id + ' (Contract: ' + contract.CurrencyIsoCode + 
                                                  ' → Should be: ' + assetCurrency + ')');
                System.debug('  ❌ MISMATCH: Contract should be ' + assetCurrency);
            } else {
                System.debug('  ✅ ALIGNED: Contract matches asset currency');
            }
        } else if (assetCurrencies.size() > 1) {
            contractsWithMultipleCurrencies++;
            contractsNeedingManualReview.add(contract.Id + ' (Asset currencies: ' + assetCurrencies + ')');
            System.debug('  ⚠️  MANUAL REVIEW: Multiple asset currencies - ' + assetCurrencies);
        }
    }
}

System.debug('');
System.debug('CONTRACT ANALYSIS SUMMARY:');
System.debug('- Total contracts with assets: ' + contractsWithAssets);
System.debug('- Contracts with single asset currency: ' + contractsWithSingleCurrency);
System.debug('- Contracts with multiple asset currencies (manual review): ' + contractsWithMultipleCurrencies);
System.debug('- Contracts with currency mismatch (auto-fix): ' + contractsWithCurrencyMismatch);

// ========================================
// PART 2: ACCOUNT-LEVEL ANALYSIS  
// ========================================
System.debug('');
System.debug('=== PART 2: ACCOUNT CURRENCY ANALYSIS ===');

// Query all accounts with their contracts
List<Account> allAccounts = [SELECT Id, CurrencyIsoCode, Name,
                                    (SELECT Id, CurrencyIsoCode, Status, StartDate, EndDate 
                                     FROM Contracts
                                     ORDER BY StartDate DESC)
                             FROM Account 
                             WHERE Id IN (SELECT AccountId FROM Contract)
                             ORDER BY Id];

Integer accountsWithContracts = 0;
Integer accountsWithSingleCurrency = 0;
Integer accountsWithMultipleCurrencies = 0;
Integer accountsWithCurrencyMismatch = 0;
List<String> accountsNeedingManualReview = new List<String>();
List<String> accountsNeedingCurrencyUpdate = new List<String>();

for (Account account : allAccounts) {
    if (account.Contracts.size() > 0) {
        accountsWithContracts++;
        
        // Determine which contracts to consider (active first, then expired if no active)
        List<Contract> activeContracts = new List<Contract>();
        List<Contract> expiredContracts = new List<Contract>();
        
        for (Contract contract : account.Contracts) {
            if (contract.StartDate <= today && contract.EndDate >= today) {
                activeContracts.add(contract);
            } else if (contract.EndDate < today) {
                expiredContracts.add(contract);
            }
        }
        
        List<Contract> contractsToEvaluate = activeContracts.size() > 0 ? activeContracts : expiredContracts;
        String contractType = activeContracts.size() > 0 ? 'ACTIVE' : 'EXPIRED';
        
        // Analyze contract currencies for this account
        Set<String> contractCurrencies = new Set<String>();
        for (Contract contract : contractsToEvaluate) {
            if (String.isNotBlank(contract.CurrencyIsoCode)) {
                contractCurrencies.add(contract.CurrencyIsoCode);
            }
        }
        
        System.debug('Account ' + account.Id + ' (' + account.Name + ') | Account Currency: ' + account.CurrencyIsoCode + 
                    ' | ' + contractType + ' Contract Currencies: ' + contractCurrencies + 
                    ' | Contracts: ' + contractsToEvaluate.size());
        
        if (contractCurrencies.size() == 1) {
            accountsWithSingleCurrency++;
            String contractCurrency = new List<String>(contractCurrencies)[0];
            
            // Check if account currency matches contract currency
            if (account.CurrencyIsoCode != contractCurrency) {
                accountsWithCurrencyMismatch++;
                accountsNeedingCurrencyUpdate.add(account.Id + ' (' + account.Name + ') (Account: ' + 
                                                 account.CurrencyIsoCode + ' → Should be: ' + contractCurrency + ')');
                System.debug('  ❌ MISMATCH: Account should be ' + contractCurrency);
            } else {
                System.debug('  ✅ ALIGNED: Account matches ' + contractType.toLowerCase() + ' contract currency');
            }
        } else if (contractCurrencies.size() > 1) {
            accountsWithMultipleCurrencies++;
            accountsNeedingManualReview.add(account.Id + ' (' + account.Name + ') (' + contractType + 
                                          ' contract currencies: ' + contractCurrencies + ')');
            System.debug('  ⚠️  MANUAL REVIEW: Multiple ' + contractType.toLowerCase() + ' contract currencies - ' + contractCurrencies);
        }
    }
}

System.debug('');
System.debug('ACCOUNT ANALYSIS SUMMARY:');
System.debug('- Total accounts with contracts: ' + accountsWithContracts);
System.debug('- Accounts with single contract currency: ' + accountsWithSingleCurrency);
System.debug('- Accounts with multiple contract currencies (manual review): ' + accountsWithMultipleCurrencies);
System.debug('- Accounts with currency mismatch (auto-fix): ' + accountsWithCurrencyMismatch);

// ========================================
// PART 3: DETAILED RECOMMENDATIONS
// ========================================
System.debug('');
System.debug('=== PART 3: DETAILED RECOMMENDATIONS ===');

System.debug('');
System.debug('CONTRACTS NEEDING AUTOMATIC CURRENCY UPDATE (' + contractsNeedingCurrencyUpdate.size() + '):');
for (String contractInfo : contractsNeedingCurrencyUpdate) {
    System.debug('  - ' + contractInfo);
}

System.debug('');
System.debug('CONTRACTS NEEDING MANUAL REVIEW (' + contractsNeedingManualReview.size() + '):');
for (String contractInfo : contractsNeedingManualReview) {
    System.debug('  - ' + contractInfo);
}

System.debug('');
System.debug('ACCOUNTS NEEDING AUTOMATIC CURRENCY UPDATE (' + accountsNeedingCurrencyUpdate.size() + '):');
for (String accountInfo : accountsNeedingCurrencyUpdate) {
    System.debug('  - ' + accountInfo);
}

System.debug('');
System.debug('ACCOUNTS NEEDING MANUAL REVIEW (' + accountsNeedingManualReview.size() + '):');
for (String accountInfo : accountsNeedingManualReview) {
    System.debug('  - ' + accountInfo);
}

// ========================================
// PART 4: IMPACT SUMMARY
// ========================================
System.debug('');
System.debug('=== PART 4: IMPACT SUMMARY ===');
System.debug('AUTOMATIC FIXES AVAILABLE:');
System.debug('- ' + contractsWithCurrencyMismatch + ' contracts can be auto-updated');
System.debug('- ' + accountsWithCurrencyMismatch + ' accounts can be auto-updated');
System.debug('- Total automatic updates: ' + (contractsWithCurrencyMismatch + accountsWithCurrencyMismatch));

System.debug('');
System.debug('MANUAL REVIEW REQUIRED:');
System.debug('- ' + contractsWithMultipleCurrencies + ' contracts with mixed asset currencies');
System.debug('- ' + accountsWithMultipleCurrencies + ' accounts with mixed contract currencies');
System.debug('- Total manual reviews: ' + (contractsWithMultipleCurrencies + accountsWithMultipleCurrencies));

System.debug('');
System.debug('=== END COMPREHENSIVE ANALYSIS ===');
