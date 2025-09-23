// Fix USD Reporting fields for expired contracts
List<Contract> contractsToFix = [
    SELECT Id, ContractNumber, CurrencyIsoCode, 
           ARR__c, ARR_USD_Reporting__c,
           ACV__c, ACV_USD_Reporting__c, 
           TCV__c, TCV_USD_Reporting__c,
           MRR__c, MRR_USD_Reporting__c,
           Incremental_ARR__c, Incremental_ARR_USD_Reporting__c,
           Active_ARR__c, Active_ARR_USD_Reporting__c,
           (SELECT Exchange_Rate__c FROM Assets__r LIMIT 1)
    FROM Contract 
    WHERE Status = 'Expired' 
    AND (ARR__c > 0 OR ACV__c > 0 OR TCV__c > 0 OR MRR__c > 0)
];

System.debug('Found ' + contractsToFix.size() + ' expired contracts for USD Reporting field fix');

List<Contract> contractsToUpdate = new List<Contract>();

for (Contract contract : contractsToFix) {
    Boolean needsUpdate = false;
    
    if (contract.CurrencyIsoCode == 'USD') {
        // USD contracts: reporting fields = base currency values
        if (contract.ARR__c != null) {
            contract.ARR_USD_Reporting__c = contract.ARR__c;
            needsUpdate = true;
        }
        if (contract.ACV__c != null) {
            contract.ACV_USD_Reporting__c = contract.ACV__c;
            needsUpdate = true;
        }
        if (contract.TCV__c != null) {
            contract.TCV_USD_Reporting__c = contract.TCV__c;
            needsUpdate = true;
        }
        if (contract.MRR__c != null) {
            contract.MRR_USD_Reporting__c = contract.MRR__c;
            needsUpdate = true;
        }
        if (contract.Incremental_ARR__c != null) {
            contract.Incremental_ARR_USD_Reporting__c = contract.Incremental_ARR__c;
            needsUpdate = true;
        }
        if (contract.Active_ARR__c != null) {
            contract.Active_ARR_USD_Reporting__c = contract.Active_ARR__c;
            needsUpdate = true;
        }
    } else {
        // Non-USD contracts: use Exchange_Rate__c from assets
        Decimal exchangeRate = null;
        if (!contract.Assets__r.isEmpty() && contract.Assets__r[0].Exchange_Rate__c != null) {
            exchangeRate = contract.Assets__r[0].Exchange_Rate__c;
        }
        
        if (exchangeRate != null && exchangeRate > 0) {
            if (contract.ARR__c != null) {
                contract.ARR_USD_Reporting__c = contract.ARR__c / exchangeRate;
                needsUpdate = true;
            }
            if (contract.ACV__c != null) {
                contract.ACV_USD_Reporting__c = contract.ACV__c / exchangeRate;
                needsUpdate = true;
            }
            if (contract.TCV__c != null) {
                contract.TCV_USD_Reporting__c = contract.TCV__c / exchangeRate;
                needsUpdate = true;
            }
            if (contract.MRR__c != null) {
                contract.MRR_USD_Reporting__c = contract.MRR__c / exchangeRate;
                needsUpdate = true;
            }
            if (contract.Incremental_ARR__c != null) {
                contract.Incremental_ARR_USD_Reporting__c = contract.Incremental_ARR__c / exchangeRate;
                needsUpdate = true;
            }
            if (contract.Active_ARR__c != null) {
                contract.Active_ARR_USD_Reporting__c = contract.Active_ARR__c / exchangeRate;
                needsUpdate = true;
            }
        }
    }
    
    if (needsUpdate) {
        contractsToUpdate.add(contract);
        System.debug('Contract ' + contract.ContractNumber + ' (' + contract.CurrencyIsoCode + ') - updated USD reporting fields');
    }
}

System.debug('Updating ' + contractsToUpdate.size() + ' contracts with USD reporting field alignment');

if (!contractsToUpdate.isEmpty()) {
    update contractsToUpdate;
    System.debug('SUCCESS: Updated USD reporting fields for ' + contractsToUpdate.size() + ' expired contracts');
} else {
    System.debug('No contracts needed USD reporting field updates');
}
