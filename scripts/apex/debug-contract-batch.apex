// Debug why ContractRevenueBatch only processed 3 contracts
System.debug('=== DEBUGGING CONTRACT BATCH ===');

// Check the exact query the batch uses
List<Contract> contracts = [
    SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
           ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           (SELECT Id, ARR__c, MRR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                   Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r 
            WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Status != null AND Status != 'Expired'
    LIMIT 5
];

System.debug('Contracts matching batch criteria: ' + contracts.size());

for(Contract c : contracts) {
    System.debug('Contract: ' + c.Id + ' | Status: ' + c.Status + ' | ARR: ' + c.ARR__c + ' | ARR_USD: ' + c.ARR_USD__c);
    System.debug('  Assets: ' + c.Assets__r.size());
    for(Asset a : c.Assets__r) {
        System.debug('    Asset: ' + a.Id + ' | Exchange_Rate: ' + a.Exchange_Rate__c + ' | Total_Value: ' + a.Total_Value__c);
    }
}

// Check if CurrencyFormatterHelper is working
try {
    CurrencyFormatterHelper.FormatInput input = new CurrencyFormatterHelper.FormatInput();
    input.amount = 12345.67;
    List<CurrencyFormatterHelper.FormatOutput> outputs = CurrencyFormatterHelper.formatCurrency(new List<CurrencyFormatterHelper.FormatInput>{input});
    System.debug('CurrencyFormatterHelper test: ' + outputs[0].formattedAmount);
} catch(Exception e) {
    System.debug('CurrencyFormatterHelper ERROR: ' + e.getMessage());
}

System.debug('=== END DEBUG ===');
