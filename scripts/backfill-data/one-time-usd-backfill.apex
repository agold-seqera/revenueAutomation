// One-time USD field backfill for expired contracts
// Direct field updates using base currency values and Exchange_Rate__c from assets

List<Contract> contractsToFix = [
    SELECT Id, ContractNumber, CurrencyIsoCode, ARR__c, ARR_USD__c, ACV__c, ACV_USD__c, 
           TCV__c, TCV_USD__c, MRR__c, MRR_USD__c, Incremental_ARR__c, Incremental_ARR_USD__c,
           (SELECT Exchange_Rate__c FROM Assets__r LIMIT 1)
    FROM Contract 
    WHERE Status = 'Expired' 
    AND (ARR__c > 0 OR ACV__c > 0 OR TCV__c > 0 OR MRR__c > 0)
];

System.debug('Found ' + contractsToFix.size() + ' expired contracts for USD backfill');

List<Contract> contractsToUpdate = new List<Contract>();

for (Contract contract : contractsToFix) {
    Boolean needsUpdate = false;
    
    if (contract.CurrencyIsoCode == 'USD') {
        // USD contracts: direct copy
        if (contract.ARR__c != null && contract.ARR__c > 0) {
            contract.ARR_USD__c = '$' + String.valueOf(contract.ARR__c.setScale(2));
            needsUpdate = true;
        }
        if (contract.ACV__c != null && contract.ACV__c > 0) {
            contract.ACV_USD__c = '$' + String.valueOf(contract.ACV__c.setScale(2));
            needsUpdate = true;
        }
        if (contract.MRR__c != null && contract.MRR__c > 0) {
            contract.MRR_USD__c = '$' + String.valueOf(contract.MRR__c.setScale(2));
            needsUpdate = true;
        }
        if (contract.Incremental_ARR__c != null) {
            contract.Incremental_ARR_USD__c = '$' + String.valueOf(contract.Incremental_ARR__c.setScale(2));
            needsUpdate = true;
        }
    } else {
        // Non-USD contracts: use Exchange_Rate__c from assets
        Decimal exchangeRate = null;
        if (!contract.Assets__r.isEmpty() && contract.Assets__r[0].Exchange_Rate__c != null) {
            exchangeRate = contract.Assets__r[0].Exchange_Rate__c;
        }
        
        if (exchangeRate != null && exchangeRate > 0) {
            if (contract.ARR__c != null && contract.ARR__c > 0) {
                Decimal usdValue = contract.ARR__c / exchangeRate;
                contract.ARR_USD__c = '$' + String.valueOf(usdValue.setScale(2));
                needsUpdate = true;
            }
            if (contract.ACV__c != null && contract.ACV__c > 0) {
                Decimal usdValue = contract.ACV__c / exchangeRate;
                contract.ACV_USD__c = '$' + String.valueOf(usdValue.setScale(2));
                needsUpdate = true;
            }
            if (contract.MRR__c != null && contract.MRR__c > 0) {
                Decimal usdValue = contract.MRR__c / exchangeRate;
                contract.MRR_USD__c = '$' + String.valueOf(usdValue.setScale(2));
                needsUpdate = true;
            }
            if (contract.Incremental_ARR__c != null) {
                Decimal usdValue = contract.Incremental_ARR__c / exchangeRate;
                contract.Incremental_ARR_USD__c = '$' + String.valueOf(usdValue.setScale(2));
                needsUpdate = true;
            }
        }
    }
    
    if (needsUpdate) {
        contractsToUpdate.add(contract);
        System.debug('Contract ' + contract.ContractNumber + ' (' + contract.CurrencyIsoCode + ') - updated USD fields');
    }
}

System.debug('Updating ' + contractsToUpdate.size() + ' contracts with USD field alignment');

if (!contractsToUpdate.isEmpty()) {
    update contractsToUpdate;
    System.debug('SUCCESS: Updated USD fields for ' + contractsToUpdate.size() + ' expired contracts');
} else {
    System.debug('No contracts needed USD field updates');
}
