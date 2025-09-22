// ONE-TIME BULK UPDATE: Populate USD fields for existing contracts with null USD values
System.debug('=== ONE-TIME CONTRACT USD BULK UPDATE ===');

// Query all contracts that have null USD fields but have revenue data and assets with exchange rates
List<Contract> contractsToUpdate = [SELECT Id, Status, ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c,
                                           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
                                           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                                                   Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
                                            FROM Assets__r 
                                            WHERE Exclude_from_Status_Updates__c = false AND Exchange_Rate__c != null)
                                   FROM Contract 
                                   WHERE (ARR_USD__c = null OR TCV_USD__c = null OR ACV_USD__c = null OR 
                                          MRR_USD__c = null OR Active_ARR_USD__c = null)
                                   AND Id IN (SELECT Contract__c FROM Asset WHERE Exchange_Rate__c != null)];

System.debug('Found contracts needing USD population: ' + contractsToUpdate.size());

Date today = Date.today();
List<Contract> contractsForUpdate = new List<Contract>();

for (Contract contract : contractsToUpdate) {
    Boolean needsUpdate = false;
    
    System.debug('Processing Contract: ' + contract.Id + ' | Status: ' + contract.Status);
    System.debug('  Assets with exchange rates: ' + contract.Assets__r.size());
    
    if (contract.Assets__r.size() > 0) {
        // Calculate USD totals from assets using corrected division formulas
        Decimal varARR_Total = 0;
        Decimal varACV_Total = 0;
        Decimal varTCV_Total = 0;
        Decimal varActiveARR_Total = 0;
        Decimal varMRR_Total = 0;
        
        for (Asset asset : contract.Assets__r) {
            // TCV calculation for all assets
            Decimal forTCV_USD = (asset.Total_Value__c != null ? asset.Total_Value__c : 0) / 
                                 (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
            varTCV_Total += forTCV_USD;
            
            // Active asset calculations
            if (asset.Start_Date__c <= today && 
                asset.End_Date__c >= today && 
                asset.ProductFamily != 'Professional Service') {
                
                Decimal forARR_USD = (asset.ARR__c != null ? asset.ARR__c : 0) / 
                                     (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                Decimal forACV_USD = (asset.Total_Price__c != null ? asset.Total_Price__c : 0) / 
                                     (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                Decimal assetMRR = (asset.ARR__c != null ? asset.ARR__c / 12 : 0);
                Decimal forMRR_USD = assetMRR / (asset.Exchange_Rate__c != null ? asset.Exchange_Rate__c : 1);
                
                varARR_Total += forARR_USD;
                varACV_Total += forACV_USD;
                varActiveARR_Total += forARR_USD;
                varMRR_Total += forMRR_USD;
            }
        }
        
        System.debug('  Calculated USD totals: ARR=' + varARR_Total + ', TCV=' + varTCV_Total + ', ACV=' + varACV_Total);
        
        // Format and populate USD fields using CurrencyFormatterHelper
        try {
            if (String.isBlank(contract.ARR_USD__c) && varARR_Total > 0) {
                CurrencyFormatterHelper.FormatInput request = new CurrencyFormatterHelper.FormatInput();
                request.amount = varARR_Total;
                List<CurrencyFormatterHelper.FormatInput> requests = new List<CurrencyFormatterHelper.FormatInput>{request};
                List<CurrencyFormatterHelper.FormatOutput> responses = CurrencyFormatterHelper.formatCurrency(requests);
                contract.ARR_USD__c = responses[0].formattedAmount;
                needsUpdate = true;
                System.debug('  Set ARR_USD: ' + contract.ARR_USD__c);
            }
            
            if (String.isBlank(contract.TCV_USD__c) && varTCV_Total > 0) {
                CurrencyFormatterHelper.FormatInput request = new CurrencyFormatterHelper.FormatInput();
                request.amount = varTCV_Total;
                List<CurrencyFormatterHelper.FormatInput> requests = new List<CurrencyFormatterHelper.FormatInput>{request};
                List<CurrencyFormatterHelper.FormatOutput> responses = CurrencyFormatterHelper.formatCurrency(requests);
                contract.TCV_USD__c = responses[0].formattedAmount;
                needsUpdate = true;
                System.debug('  Set TCV_USD: ' + contract.TCV_USD__c);
            }
            
            if (String.isBlank(contract.ACV_USD__c) && varACV_Total > 0) {
                CurrencyFormatterHelper.FormatInput request = new CurrencyFormatterHelper.FormatInput();
                request.amount = varACV_Total;
                List<CurrencyFormatterHelper.FormatInput> requests = new List<CurrencyFormatterHelper.FormatInput>{request};
                List<CurrencyFormatterHelper.FormatOutput> responses = CurrencyFormatterHelper.formatCurrency(requests);
                contract.ACV_USD__c = responses[0].formattedAmount;
                needsUpdate = true;
                System.debug('  Set ACV_USD: ' + contract.ACV_USD__c);
            }
            
            if (String.isBlank(contract.Active_ARR_USD__c) && varActiveARR_Total > 0) {
                CurrencyFormatterHelper.FormatInput request = new CurrencyFormatterHelper.FormatInput();
                request.amount = varActiveARR_Total;
                List<CurrencyFormatterHelper.FormatInput> requests = new List<CurrencyFormatterHelper.FormatInput>{request};
                List<CurrencyFormatterHelper.FormatOutput> responses = CurrencyFormatterHelper.formatCurrency(requests);
                contract.Active_ARR_USD__c = responses[0].formattedAmount;
                needsUpdate = true;
                System.debug('  Set Active_ARR_USD: ' + contract.Active_ARR_USD__c);
            }
            
            if (String.isBlank(contract.MRR_USD__c) && varMRR_Total > 0) {
                CurrencyFormatterHelper.FormatInput request = new CurrencyFormatterHelper.FormatInput();
                request.amount = varMRR_Total;
                List<CurrencyFormatterHelper.FormatInput> requests = new List<CurrencyFormatterHelper.FormatInput>{request};
                List<CurrencyFormatterHelper.FormatOutput> responses = CurrencyFormatterHelper.formatCurrency(requests);
                contract.MRR_USD__c = responses[0].formattedAmount;
                needsUpdate = true;
                System.debug('  Set MRR_USD: ' + contract.MRR_USD__c);
            }
            
        } catch (Exception e) {
            System.debug('Currency formatting error for Contract ' + contract.Id + ': ' + e.getMessage());
        }
    }
    
    if (needsUpdate) {
        contractsForUpdate.add(contract);
    }
}

System.debug('Contracts marked for USD field updates: ' + contractsForUpdate.size());

if (contractsForUpdate.size() > 0) {
    try {
        update contractsForUpdate;
        System.debug('SUCCESS: Updated ' + contractsForUpdate.size() + ' contracts with USD values');
        
        // Sample verification
        if (contractsForUpdate.size() > 0) {
            Contract sampleContract = [SELECT Id, ARR_USD__c, TCV_USD__c, ACV_USD__c 
                                      FROM Contract WHERE Id = :contractsForUpdate[0].Id LIMIT 1];
            System.debug('Sample verification - Contract ' + sampleContract.Id + ':');
            System.debug('  ARR_USD: ' + sampleContract.ARR_USD__c);
            System.debug('  TCV_USD: ' + sampleContract.TCV_USD__c);
            System.debug('  ACV_USD: ' + sampleContract.ACV_USD__c);
        }
        
    } catch (Exception e) {
        System.debug('ERROR updating contracts: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
    }
} else {
    System.debug('No contracts need USD field updates');
}

System.debug('=== END ONE-TIME BULK UPDATE ===');
