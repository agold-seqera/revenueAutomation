// Debug opportunity revenue fields - FIXED
System.debug('=== DEBUGGING OPPORTUNITY REVENUE FIELDS ===');

// Get the opportunity with ALL revenue fields
Opportunity opp = [
    SELECT Id, Name, StageName, Contract_Start_Date__c, 
           Amount, ARR_RUS__c, Software_Subscription_Amount_RUS__c,
           TotalOpportunityQuantity, CurrencyIsoCode
    FROM Opportunity 
    WHERE Id = '006Pn00000bGVydIAG'
];

System.debug('Opportunity: ' + opp.Name);
System.debug('Stage: ' + opp.StageName);
System.debug('Amount: ' + opp.Amount);
System.debug('ARR_RUS__c: ' + opp.ARR_RUS__c);
System.debug('Software_Subscription_Amount_RUS__c: ' + opp.Software_Subscription_Amount_RUS__c);
System.debug('TotalOpportunityQuantity: ' + opp.TotalOpportunityQuantity);
System.debug('Currency: ' + opp.CurrencyIsoCode);

// Get OpportunityLineItems with ALL fields
List<OpportunityLineItem> olis = [
    SELECT Id, Product2.Name, Product2.Family, UnitPrice, Quantity, TotalPrice,
           Term_Start_Date__c, Include_in_ARR__c, Include_in_ARR_Sum__c,
           Exchange_Rate__c, CurrencyIsoCode
    FROM OpportunityLineItem
    WHERE OpportunityId = '006Pn00000bGVydIAG'
];

System.debug('Found ' + olis.size() + ' OpportunityLineItems:');
Decimal totalARRSum = 0;

for (OpportunityLineItem oli : olis) {
    System.debug('  Product: ' + oli.Product2.Name);
    System.debug('  Family: ' + oli.Product2.Family);
    System.debug('  Price: ' + oli.UnitPrice + ' x ' + oli.Quantity + ' = ' + oli.TotalPrice);
    System.debug('  Include_in_ARR__c: ' + oli.Include_in_ARR__c);
    System.debug('  Include_in_ARR_Sum__c: ' + oli.Include_in_ARR_Sum__c);
    System.debug('  Currency: ' + oli.CurrencyIsoCode);
    System.debug('  Exchange Rate: ' + oli.Exchange_Rate__c);
    
    if (oli.Include_in_ARR_Sum__c != null) {
        totalARRSum += oli.Include_in_ARR_Sum__c;
    }
    System.debug('  ---');
}

System.debug('CALCULATED Total ARR Sum from OLIs: ' + totalARRSum);
System.debug('OPPORTUNITY ARR_RUS__c: ' + opp.ARR_RUS__c);
System.debug('OPPORTUNITY Software_Subscription_Amount_RUS__c: ' + opp.Software_Subscription_Amount_RUS__c);

// Check if there are rollup summary issues
System.debug('=== ROLLUP ANALYSIS ===');
if (totalARRSum > 0 && (opp.ARR_RUS__c == null || opp.ARR_RUS__c == 0)) {
    System.debug('ISSUE: OLI Include_in_ARR_Sum__c has values but Opportunity ARR_RUS__c is 0/null');
    System.debug('This suggests a rollup summary field issue or field mapping problem');
}

if (totalARRSum == 0) {
    System.debug('ISSUE: Include_in_ARR_Sum__c is 0 on all OLIs - the flow is not populating this field');
}

System.debug('=== END DEBUG ===');
