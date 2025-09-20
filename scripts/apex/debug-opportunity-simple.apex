// Debug opportunity ARR issue - simplified
System.debug('=== DEBUGGING OPPORTUNITY ARR ISSUE ===');

// Get the opportunity details
Opportunity opp = [
    SELECT Id, Name, StageName, Contract_Start_Date__c, Description
    FROM Opportunity 
    WHERE Id = '006Pn00000bGVydIAG'
];

System.debug('Opportunity: ' + opp.Name);
System.debug('Stage: ' + opp.StageName);
System.debug('Contract Start Date: ' + opp.Contract_Start_Date__c);
System.debug('Description: ' + opp.Description);

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
    
    // Calculate what Include_in_ARR should be
    if (oli.Term_Start_Date__c != null && opp.Contract_Start_Date__c != null) {
        Date firstYearEnd = opp.Contract_Start_Date__c.addDays(365);
        Boolean shouldInclude = oli.Term_Start_Date__c <= firstYearEnd;
        System.debug('  SHOULD Include in ARR: ' + shouldInclude + ' (Term: ' + oli.Term_Start_Date__c + ' vs FirstYearEnd: ' + firstYearEnd + ')');
    }
    System.debug('  ---');
}

// Check if there are any Assets
List<Asset> assets = [
    SELECT Id, Name, Status, Price, Quantity, Total_Price__c, ARR__c,
           Start_Date__c, End_Date__c, Exchange_Rate__c
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
    System.debug('  Exchange Rate: ' + asset.Exchange_Rate__c);
    System.debug('  ---');
}

System.debug('=== END DEBUG ===');
