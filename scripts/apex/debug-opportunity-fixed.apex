// Debug opportunity ARR issue - fixed
System.debug('=== DEBUGGING OPPORTUNITY ARR ISSUE ===');

// Get the opportunity details
Opportunity opp = [
    SELECT Id, Name, StageName, Contract_Start_Date__c, Description, AccountId
    FROM Opportunity 
    WHERE Id = '006Pn00000bGVydIAG'
];

System.debug('Opportunity: ' + opp.Name);
System.debug('Stage: ' + opp.StageName);
System.debug('Contract Start Date: ' + opp.Contract_Start_Date__c);
System.debug('Description: ' + opp.Description);
System.debug('Account ID: ' + opp.AccountId);

// Get the OpportunityLineItems
List<OpportunityLineItem> olis = [
    SELECT Id, Product2.Name, UnitPrice, Quantity, TotalPrice,
           Term_Start_Date__c, Include_in_ARR__c, Exchange_Rate__c,
           Product2.Family
    FROM OpportunityLineItem
    WHERE OpportunityId = '006Pn00000bGVydIAG'
];

System.debug('Found ' + olis.size() + ' OpportunityLineItems:');
Integer totalIncluded = 0;
Decimal totalARRAmount = 0;

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
        
        if (oli.Include_in_ARR__c == true) {
            totalIncluded++;
            totalARRAmount += oli.TotalPrice != null ? oli.TotalPrice : 0;
        }
    }
    System.debug('  ---');
}

System.debug('SUMMARY: ' + totalIncluded + ' OLIs included in ARR, Total Amount: ' + totalARRAmount);

// Check Contracts for this Account
List<Contract> contracts = [
    SELECT Id, Status, StartDate, EndDate, ARR__c, ARR_USD__c,
           Initial_ARR__c, Initial_ARR_USD__c, AccountId
    FROM Contract
    WHERE AccountId = :opp.AccountId
    ORDER BY CreatedDate DESC
    LIMIT 5
];

System.debug('Found ' + contracts.size() + ' Contracts for this Account:');
for (Contract contract : contracts) {
    System.debug('  Contract ID: ' + contract.Id);
    System.debug('  Status: ' + contract.Status);
    System.debug('  Start/End: ' + contract.StartDate + ' to ' + contract.EndDate);
    System.debug('  ARR: ' + contract.ARR__c);
    System.debug('  ARR USD: ' + contract.ARR_USD__c);
    System.debug('  Initial ARR: ' + contract.Initial_ARR__c);
    System.debug('  Initial ARR USD: ' + contract.Initial_ARR_USD__c);
    System.debug('  ---');
}

System.debug('=== END DEBUG ===');
