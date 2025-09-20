// Debug specific opportunity 006Pn00000bGVydIAG
System.debug('=== DEBUGGING OPPORTUNITY 006Pn00000bGVydIAG ===');

// Get the opportunity details
Opportunity opp = [
    SELECT Id, Name, StageName, Contract_Start_Date__c, Description,
           ARR_RUS__c, Software_Subscription_Amount_RUS__c
    FROM Opportunity 
    WHERE Id = '006Pn00000bGVydIAG'
];

System.debug('Opportunity: ' + opp.Name);
System.debug('Stage: ' + opp.StageName);
System.debug('Contract Start Date: ' + opp.Contract_Start_Date__c);
System.debug('Description: ' + opp.Description);
System.debug('ARR_RUS__c: ' + opp.ARR_RUS__c);
System.debug('Software_Subscription_Amount_RUS__c: ' + opp.Software_Subscription_Amount_RUS__c);

// Get the OpportunityLineItems
List<OpportunityLineItem> olis = [
    SELECT Id, Product2.Name, UnitPrice, Quantity, TotalPrice,
           Term_Start_Date__c, Include_in_ARR__c, Exchange_Rate__c,
           Product2.Family
    FROM OpportunityLineItem
    WHERE OpportunityId = '006Pn00000bGVydIAG'
];

System.debug('Found ' + olis.size() + ' OpportunityLineItems:');
for (OpportunityLineItem oli : olis) {
    System.debug('  Product: ' + oli.Product2.Name);
    System.debug('  Family: ' + oli.Product2.Family);
    System.debug('  Price: ' + oli.UnitPrice + ' x ' + oli.Quantity + ' = ' + oli.TotalPrice);
    System.debug('  Term Start Date: ' + oli.Term_Start_Date__c);
    System.debug('  Include in ARR: ' + oli.Include_in_ARR__c);
    System.debug('  Exchange Rate: ' + oli.Exchange_Rate__c);
    System.debug('  ---');
}

// Check if there are any Assets
List<Asset> assets = [
    SELECT Id, Name, Status, Price, Quantity, Total_Price__c, ARR__c,
           Start_Date__c, End_Date__c, Include_in_ARR__c, Exchange_Rate__c
    FROM Asset
    WHERE Opportunity__c = '006Pn00000bGVydIAG'
];

System.debug('Found ' + assets.size() + ' Assets:');
for (Asset asset : assets) {
    System.debug('  Asset: ' + asset.Name);
    System.debug('  Status: ' + asset.Status);
    System.debug('  Price: ' + asset.Price + ' x ' + asset.Quantity + ' = ' + asset.Total_Price__c);
    System.debug('  ARR: ' + asset.ARR__c);
    System.debug('  Start/End: ' + asset.Start_Date__c + ' to ' + asset.End_Date__c);
    System.debug('  Include in ARR: ' + asset.Include_in_ARR__c);
    System.debug('  Exchange Rate: ' + asset.Exchange_Rate__c);
    System.debug('  ---');
}

// Check Contract
List<Contract> contracts = [
    SELECT Id, Status, StartDate, EndDate, ARR__c, ARR_USD__c,
           Initial_ARR__c, Initial_ARR_USD__c
    FROM Contract
    WHERE Opportunity__c = '006Pn00000bGVydIAG'
];

System.debug('Found ' + contracts.size() + ' Contracts:');
for (Contract contract : contracts) {
    System.debug('  Contract Status: ' + contract.Status);
    System.debug('  Start/End: ' + contract.StartDate + ' to ' + contract.EndDate);
    System.debug('  ARR: ' + contract.ARR__c);
    System.debug('  ARR USD: ' + contract.ARR_USD__c);
    System.debug('  Initial ARR: ' + contract.Initial_ARR__c);
    System.debug('  Initial ARR USD: ' + contract.Initial_ARR_USD__c);
}

System.debug('=== END DEBUG ===');
