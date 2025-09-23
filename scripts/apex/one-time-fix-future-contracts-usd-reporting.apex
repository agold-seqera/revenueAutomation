// ONE-TIME FIX: Populate missing USD Reporting fields for all future/draft contracts
System.debug('=== ONE-TIME FIX: FUTURE CONTRACT USD REPORTING FIELDS ===');

// Find all Draft contracts that have base revenue but missing USD Reporting fields
List<Contract> contractsToFix = [
    SELECT Id, Status, CurrencyIsoCode, StartDate, EndDate,
           ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
           TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
           MRR__c, MRR_USD__c, MRR_USD_Reporting__c,
           Initial_ARR__c, Initial_ACV__c, Initial_TCV__c, Initial_MRR__c,
           (SELECT Id, Exchange_Rate__c FROM Assets__r LIMIT 1)
    FROM Contract
    WHERE Status = 'Draft'
    AND StartDate > :Date.today()
    AND (
        (ARR__c > 0 AND (ARR_USD_Reporting__c = null OR ARR_USD_Reporting__c = 0)) OR
        (ACV__c > 0 AND (ACV_USD_Reporting__c = null OR ACV_USD_Reporting__c = 0)) OR
        (TCV__c > 0 AND (TCV_USD_Reporting__c = null OR TCV_USD_Reporting__c = 0)) OR
        (MRR__c > 0 AND (MRR_USD_Reporting__c = null OR MRR_USD_Reporting__c = 0))
    )
];

System.debug('Found ' + contractsToFix.size() + ' future contracts needing USD Reporting field fixes');

List<Contract> updatedContracts = new List<Contract>();

for (Contract contract : contractsToFix) {
    Boolean needsUpdate = false;
    Contract contractToUpdate = new Contract(Id = contract.Id);
    
    System.debug('Processing contract: ' + contract.Id + ' (' + contract.Status + ', starts: ' + contract.StartDate + ')');
    
    // Get exchange rate from first asset (following ContractTriggerHandler pattern)
    Decimal exchangeRate = 1.0; // Default for USD
    if (!contract.Assets__r.isEmpty() && contract.Assets__r[0].Exchange_Rate__c != null) {
        exchangeRate = contract.Assets__r[0].Exchange_Rate__c;
        System.debug('  Using asset exchange rate: ' + exchangeRate);
    } else if (contract.CurrencyIsoCode != 'USD') {
        System.debug('  WARNING: Non-USD contract without asset exchange rate - using 1.0');
    }
    
    // Fix ARR USD Reporting field
    if (contract.ARR__c != null && contract.ARR__c > 0 && 
        (contract.ARR_USD_Reporting__c == null || contract.ARR_USD_Reporting__c == 0)) {
        Decimal arrUSD = contract.ARR__c * exchangeRate;
        contractToUpdate.ARR_USD_Reporting__c = arrUSD;
        needsUpdate = true;
        System.debug('  ✓ ARR_USD_Reporting: ' + contract.ARR__c + ' * ' + exchangeRate + ' = ' + arrUSD);
    }
    
    // Fix ACV USD Reporting field
    if (contract.ACV__c != null && contract.ACV__c > 0 && 
        (contract.ACV_USD_Reporting__c == null || contract.ACV_USD_Reporting__c == 0)) {
        Decimal acvUSD = contract.ACV__c * exchangeRate;
        contractToUpdate.ACV_USD_Reporting__c = acvUSD;
        needsUpdate = true;
        System.debug('  ✓ ACV_USD_Reporting: ' + contract.ACV__c + ' * ' + exchangeRate + ' = ' + acvUSD);
    }
    
    // Fix TCV USD Reporting field
    if (contract.TCV__c != null && contract.TCV__c > 0 && 
        (contract.TCV_USD_Reporting__c == null || contract.TCV_USD_Reporting__c == 0)) {
        Decimal tcvUSD = contract.TCV__c * exchangeRate;
        contractToUpdate.TCV_USD_Reporting__c = tcvUSD;
        needsUpdate = true;
        System.debug('  ✓ TCV_USD_Reporting: ' + contract.TCV__c + ' * ' + exchangeRate + ' = ' + tcvUSD);
    }
    
    // Fix MRR USD Reporting field
    if (contract.MRR__c != null && contract.MRR__c > 0 && 
        (contract.MRR_USD_Reporting__c == null || contract.MRR_USD_Reporting__c == 0)) {
        Decimal mrrUSD = contract.MRR__c * exchangeRate;
        contractToUpdate.MRR_USD_Reporting__c = mrrUSD;
        needsUpdate = true;
        System.debug('  ✓ MRR_USD_Reporting: ' + contract.MRR__c + ' * ' + exchangeRate + ' = ' + mrrUSD);
    }
    
    if (needsUpdate) {
        updatedContracts.add(contractToUpdate);
    } else {
        System.debug('  ✗ No updates needed');
    }
}

// Execute the update
if (!updatedContracts.isEmpty()) {
    try {
        update updatedContracts;
        System.debug('✅ SUCCESS: Updated ' + updatedContracts.size() + ' future contracts with USD Reporting fields');
        
        for (Contract contract : updatedContracts) {
            System.debug('  ✓ Contract: ' + contract.Id);
        }
    } catch (DmlException e) {
        System.debug('❌ ERROR updating contracts: ' + e.getMessage());
    }
} else {
    System.debug('ℹ️ No future contracts found needing USD Reporting field updates');
}

System.debug('=== ONE-TIME FUTURE CONTRACT FIX COMPLETE ===');
