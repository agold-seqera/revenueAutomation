// DIAGNOSTIC SCRIPT: Analyze USD field calculation issue for account 001fJ000021YCbNQAW

System.debug('=== DIAGNOSING USD CALCULATION FOR ACCOUNT 001fJ000021YCbNQAW ===');

String accountId = '001fJ000021YCbNQAW';

// Step 1: Get the account with all relevant fields
Account account = [
    SELECT Id, Name, Status__c, CurrencyIsoCode,
           ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           ACV__c, ACV_USD__c, TCV__c, TCV_USD__c, MRR__c, MRR_USD__c
    FROM Account 
    WHERE Id = :accountId
];

System.debug('=== ACCOUNT CURRENT STATE ===');
System.debug('Account: ' + account.Name + ' (' + account.Status__c + ', ' + account.CurrencyIsoCode + ')');
System.debug('ARR__c: ' + account.ARR__c + ' | ARR_USD__c: ' + account.ARR_USD__c + ' | ARR_USD_Reporting__c: ' + account.ARR_USD_Reporting__c);

// Step 2: Get all contracts for this account
List<Contract> contracts = [
    SELECT Id, Status, CurrencyIsoCode, ARR__c, ARR_USD__c, TCV__c, TCV_USD__c,
           (SELECT Id, Exchange_Rate__c, Price, Start_Date__c, End_Date__c, Product2.Family 
            FROM Assets__r WHERE Product2.Family IN ('Software Subscriptions', 'Sample-based', 'Recurring Services', 'CPUh - Prepaid'))
    FROM Contract 
    WHERE AccountId = :accountId
    ORDER BY Status, LastModifiedDate DESC
];

System.debug('=== CONTRACTS ANALYSIS ===');
Decimal totalContractARR_Base = 0;
Decimal totalContractARR_USD = 0;

for (Contract contract : contracts) {
    System.debug('Contract ' + contract.Id + ' (' + contract.Status + ', ' + contract.CurrencyIsoCode + '):');
    System.debug('  ARR__c: ' + contract.ARR__c + ' | ARR_USD__c: ' + contract.ARR_USD__c);
    
    if (contract.Status == 'Activated') {
        totalContractARR_Base += (contract.ARR__c != null ? contract.ARR__c : 0);
        
        // Parse USD value
        if (contract.ARR_USD__c != null) {
            String usdString = contract.ARR_USD__c.replace('$', '').replace(',', '');
            try {
                totalContractARR_USD += Decimal.valueOf(usdString);
            } catch (Exception e) {
                System.debug('  ERROR parsing USD: ' + contract.ARR_USD__c);
            }
        }
    }
    
    // Check assets for exchange rates
    for (Asset asset : contract.Assets__r) {
        System.debug('  Asset: Price=' + asset.Price + ', Exchange_Rate=' + asset.Exchange_Rate__c + 
                    ', Dates=' + asset.Start_Date__c + ' to ' + asset.End_Date__c + 
                    ', Family=' + asset.Product2.Family);
        
        // Check for date issues
        if (asset.Start_Date__c != null && asset.End_Date__c != null && asset.Start_Date__c > asset.End_Date__c) {
            System.debug('  ⚠️  INVALID DATES: Start date after end date!');
        }
    }
}

System.debug('=== EXPECTED VALUES ===');
System.debug('Total Active Contract ARR (Base): ' + totalContractARR_Base);
System.debug('Total Active Contract ARR (USD): ' + totalContractARR_USD);
System.debug('Account ARR (Base): ' + account.ARR__c + ' | Expected: ' + totalContractARR_Base);
System.debug('Account ARR (USD): ' + account.ARR_USD__c + ' | Expected: ~$' + totalContractARR_USD.format());

// Step 3: Manual USD calculation using AccountRollupBatch logic
System.debug('=== MANUAL USD CALCULATION ===');
if (account.CurrencyIsoCode == 'USD') {
    System.debug('USD Account - should be direct copy');
} else {
    System.debug('Non-USD Account (' + account.CurrencyIsoCode + ') - should use exchange rate conversion');
    
    // Get exchange rate from first active asset
    Decimal exchangeRate = 1.0;
    for (Contract contract : contracts) {
        if (contract.Status == 'Activated' && !contract.Assets__r.isEmpty()) {
            exchangeRate = contract.Assets__r[0].Exchange_Rate__c;
            System.debug('Using exchange rate: ' + exchangeRate + ' from contract ' + contract.Id);
            break;
        }
    }
    
    if (account.ARR__c != null) {
        Decimal expectedUSD = account.ARR__c / exchangeRate;
        System.debug('Expected USD calculation: ' + account.ARR__c + ' / ' + exchangeRate + ' = ' + expectedUSD);
        System.debug('Formatted: $' + expectedUSD.setScale(2).format());
    }
}

System.debug('=== DIAGNOSIS COMPLETE ===');
