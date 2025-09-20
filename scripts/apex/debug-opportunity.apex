// Debug specific opportunity 006Pn00000bGVydIAG
String oppId = '006Pn00000bGVydIAG';

System.debug('=== DEBUGGING OPPORTUNITY: ' + oppId + ' ===');

// Query the opportunity with all relevant fields
Opportunity opp = [
    SELECT Id, Name, StageName, Contract_Start_Date__c, Description,
           CloseDate, CreatedDate, LastModifiedDate
    FROM Opportunity 
    WHERE Id = :oppId
];

System.debug('Opportunity Details:');
System.debug('- Name: ' + opp.Name);
System.debug('- Stage: ' + opp.StageName);
System.debug('- Contract Start Date: ' + opp.Contract_Start_Date__c);
System.debug('- Close Date: ' + opp.CloseDate);
System.debug('- Description: ' + opp.Description);

// Query the OpportunityLineItems
List<OpportunityLineItem> olis = [
    SELECT Id, Product2.Name, Term_Start_Date__c, Include_in_ARR__c, 
           Quantity, UnitPrice, TotalPrice
    FROM OpportunityLineItem 
    WHERE OpportunityId = :oppId
];

System.debug('OpportunityLineItems (' + olis.size() + ' found):');
for (OpportunityLineItem oli : olis) {
    System.debug('- Product: ' + oli.Product2.Name);
    System.debug('  Term Start Date: ' + oli.Term_Start_Date__c);
    System.debug('  Include in ARR: ' + oli.Include_in_ARR__c);
    System.debug('  Price: ' + oli.UnitPrice + ' x ' + oli.Quantity + ' = ' + oli.TotalPrice);
    
    // Calculate the first year cutoff
    if (opp.Contract_Start_Date__c != null) {
        Date firstYearCutoff = opp.Contract_Start_Date__c.addDays(365);
        System.debug('  First Year Cutoff: ' + firstYearCutoff);
        System.debug('  Should Include in ARR: ' + (oli.Term_Start_Date__c != null && oli.Term_Start_Date__c <= firstYearCutoff));
    }
    System.debug('---');
}

// Check if this opportunity was in our update list
System.debug('Opportunity qualifies for first year logic: ' + 
    (opp.Contract_Start_Date__c != null && opp.StageName == 'Closed Won'));
