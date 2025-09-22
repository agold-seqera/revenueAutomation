// AUTOMATIC CURRENCY MISMATCH FIXES
// Fix 23 clear mismatches: 4 contracts + 19 accounts
System.debug('=== AUTOMATIC CURRENCY MISMATCH FIXES ===');

// ========================================
// PART 1: FIX CONTRACT CURRENCY MISMATCHES (4 contracts)
// ========================================
System.debug('');
System.debug('=== PART 1: FIXING CONTRACT CURRENCY MISMATCHES ===');

// List of contract IDs that need fixing (from analysis)
List<String> contractIdsToFix = new List<String>{
    '800fJ000007eI2nQAE', // USD → EUR
    '800fJ000007eI34QAE', // EUR → USD  
    '800Pn00000lIOLnIAO', // USD → EUR
    '800Pn00000m35yvIAA'  // USD → EUR
};

// Query contracts with their assets to determine correct currency
List<Contract> contractsToUpdate = [SELECT Id, CurrencyIsoCode,
                                           (SELECT Id, CurrencyIsoCode 
                                            FROM Assets__r 
                                            WHERE Exclude_from_Status_Updates__c = false)
                                   FROM Contract 
                                   WHERE Id IN :contractIdsToFix];

List<Contract> contractsForUpdate = new List<Contract>();

for (Contract contract : contractsToUpdate) {
    if (contract.Assets__r.size() > 0) {
        // Get asset currencies
        Set<String> assetCurrencies = new Set<String>();
        for (Asset asset : contract.Assets__r) {
            if (String.isNotBlank(asset.CurrencyIsoCode)) {
                assetCurrencies.add(asset.CurrencyIsoCode);
            }
        }
        
        // Should have single currency (verified in analysis)
        if (assetCurrencies.size() == 1) {
            String correctCurrency = new List<String>(assetCurrencies)[0];
            
            if (contract.CurrencyIsoCode != correctCurrency) {
                System.debug('Contract ' + contract.Id + ': ' + contract.CurrencyIsoCode + ' → ' + correctCurrency);
                contract.CurrencyIsoCode = correctCurrency;
                contractsForUpdate.add(contract);
            }
        } else {
            System.debug('ERROR: Contract ' + contract.Id + ' has multiple asset currencies: ' + assetCurrencies);
        }
    }
}

System.debug('Contracts to update: ' + contractsForUpdate.size());

if (contractsForUpdate.size() > 0) {
    try {
        update contractsForUpdate;
        System.debug('✅ SUCCESS: Updated ' + contractsForUpdate.size() + ' contracts');
        
        for (Contract contract : contractsForUpdate) {
            System.debug('  Updated Contract ' + contract.Id + ' to ' + contract.CurrencyIsoCode);
        }
    } catch (Exception e) {
        System.debug('❌ ERROR updating contracts: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
    }
} else {
    System.debug('No contracts to update');
}

// ========================================
// PART 2: FIX ACCOUNT CURRENCY MISMATCHES (19 accounts)
// ========================================
System.debug('');
System.debug('=== PART 2: FIXING ACCOUNT CURRENCY MISMATCHES ===');

// List of account IDs that need fixing (from analysis)
List<String> accountIdsToFix = new List<String>{
    '001fJ000021Y8qoQAC', // USD → EUR (Champalimaud Foundation)
    '001fJ000021Y9rwQAC', // USD → GBP (Shift Bioscience)
    '001fJ000021YBQ3QAO', // USD → EUR (Nucleome Therapeutics)
    '001fJ000021YCbNQAW', // USD → EUR (Almirall)
    '001fJ000021YCoZQAW', // USD → EUR (GenomeUp)
    '001fJ000021YCorQAG', // USD → EUR (Cosyne)
    '001fJ000021YD40QAG', // USD → EUR (Healx)
    '001fJ000021YD4VQAW', // USD → EUR (Lonza)
    '001fJ000021YDMoQAO', // USD → EUR (AB Enzymes)
    '001fJ000021YDNJQA4', // USD → EUR (Single Cell Discoveries)
    '001fJ000021YDZhQAO', // USD → GBP (Nonacus)
    '001fJ000021YDgvQAG', // USD → EUR (Rijk Zwaan Zaadteelt en Zaadhandel B.V)
    '001fJ000021YDrtQAG', // USD → EUR (IEO Istituto Europeo di Oncologia)
    '001fJ000021YDxRQAW', // USD → EUR (Genomics England)
    '001fJ000021YDxfQAG', // USD → EUR (EBI / EMBL)
    '001fJ000021YDxsQAG', // USD → EUR (SciLifeLab Clinical)
    '001fJ000021YDzNQAW', // USD → EUR (IARC)
    '001fJ000021YDzZQAW', // USD → EUR (Biomodal)
    '001fJ000021YEZ5QAO'  // USD → EUR (Eligo Bioscience)
};

// Query accounts with their contracts to determine correct currency
List<Account> accountsToUpdate = [SELECT Id, CurrencyIsoCode, Name,
                                         (SELECT Id, CurrencyIsoCode, Status, StartDate, EndDate 
                                          FROM Contracts
                                          ORDER BY StartDate DESC)
                                 FROM Account 
                                 WHERE Id IN :accountIdsToFix];

List<Account> accountsForUpdate = new List<Account>();
Date today = Date.today();

for (Account account : accountsToUpdate) {
    if (account.Contracts.size() > 0) {
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
        
        // Get contract currencies
        Set<String> contractCurrencies = new Set<String>();
        for (Contract contract : contractsToEvaluate) {
            if (String.isNotBlank(contract.CurrencyIsoCode)) {
                contractCurrencies.add(contract.CurrencyIsoCode);
            }
        }
        
        // Should have single currency (verified in analysis)
        if (contractCurrencies.size() == 1) {
            String correctCurrency = new List<String>(contractCurrencies)[0];
            
            if (account.CurrencyIsoCode != correctCurrency) {
                System.debug('Account ' + account.Id + ' (' + account.Name + '): ' + 
                           account.CurrencyIsoCode + ' → ' + correctCurrency + ' (based on ' + contractType + ' contracts)');
                account.CurrencyIsoCode = correctCurrency;
                accountsForUpdate.add(account);
            }
        } else {
            System.debug('ERROR: Account ' + account.Id + ' (' + account.Name + ') has multiple ' + 
                        contractType + ' contract currencies: ' + contractCurrencies);
        }
    }
}

System.debug('Accounts to update: ' + accountsForUpdate.size());

if (accountsForUpdate.size() > 0) {
    try {
        update accountsForUpdate;
        System.debug('✅ SUCCESS: Updated ' + accountsForUpdate.size() + ' accounts');
        
        for (Account account : accountsForUpdate) {
            System.debug('  Updated Account ' + account.Id + ' (' + account.Name + ') to ' + account.CurrencyIsoCode);
        }
    } catch (Exception e) {
        System.debug('❌ ERROR updating accounts: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
    }
} else {
    System.debug('No accounts to update');
}

// ========================================
// PART 3: VERIFICATION
// ========================================
System.debug('');
System.debug('=== PART 3: VERIFICATION ===');

Integer totalUpdated = contractsForUpdate.size() + accountsForUpdate.size();
System.debug('SUMMARY:');
System.debug('- Contracts updated: ' + contractsForUpdate.size() + '/4 expected');
System.debug('- Accounts updated: ' + accountsForUpdate.size() + '/19 expected');
System.debug('- Total updates: ' + totalUpdated + '/23 expected');

if (totalUpdated == 23) {
    System.debug('✅ ALL AUTOMATIC FIXES COMPLETED SUCCESSFULLY!');
} else {
    System.debug('⚠️  Some updates may have failed - check logs above');
}

// Sample verification
if (contractsForUpdate.size() > 0) {
    Contract sampleContract = [SELECT Id, CurrencyIsoCode FROM Contract WHERE Id = :contractsForUpdate[0].Id LIMIT 1];
    System.debug('Sample contract verification: ' + sampleContract.Id + ' now has currency ' + sampleContract.CurrencyIsoCode);
}

if (accountsForUpdate.size() > 0) {
    Account sampleAccount = [SELECT Id, Name, CurrencyIsoCode FROM Account WHERE Id = :accountsForUpdate[0].Id LIMIT 1];
    System.debug('Sample account verification: ' + sampleAccount.Id + ' (' + sampleAccount.Name + ') now has currency ' + sampleAccount.CurrencyIsoCode);
}

System.debug('');
System.debug('=== END AUTOMATIC CURRENCY FIXES ===');
