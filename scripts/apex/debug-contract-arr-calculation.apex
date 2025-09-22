// Debug the specific contract ARR calculation logic
System.debug('=== Debugging Contract ARR Calculation ===');

// Get the contract with its assets
List<Contract> contracts = [
    SELECT Id, Name, Status, StartDate, EndDate, ARR__c, ACV__c, TCV__c, Active_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c,
           (SELECT Id, Name, Status, Start_Date__c, End_Date__c, ARR__c, Total_Value__c, Total_Price__c,
                   Exchange_Rate__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Id = '800fJ000007eMFWQA2'
];

if (contracts.size() == 0) {
    System.debug('Contract not found!');
    return;
}

Contract contract = contracts[0];
Date today = Date.today();

System.debug('Contract: ' + contract.Id);
System.debug('Current ARR__c: ' + contract.ARR__c);
System.debug('Current ACV__c: ' + contract.ACV__c);
System.debug('Current TCV__c: ' + contract.TCV__c);
System.debug('Current Active_ARR__c: ' + contract.Active_ARR__c);
System.debug('Today: ' + today);
System.debug('Assets found: ' + contract.Assets__r.size());

// Simulate the ContractRevenueBatch logic
Decimal calculatedARR = 0;
Decimal calculatedACV = 0;
Decimal calculatedTCV = 0;
Decimal calculatedActiveARR = 0;

System.debug('\n--- Asset Analysis ---');
for (Asset asset : contract.Assets__r) {
    System.debug('Asset: ' + asset.Id + ' (' + asset.Name + ')');
    System.debug('  Status: ' + asset.Status);
    System.debug('  Start: ' + asset.Start_Date__c + ' | End: ' + asset.End_Date__c);
    System.debug('  ARR: ' + asset.ARR__c + ' | Total_Value: ' + asset.Total_Value__c + ' | Total_Price: ' + asset.Total_Price__c);
    System.debug('  ProductFamily: ' + asset.ProductFamily);
    System.debug('  Exchange_Rate: ' + asset.Exchange_Rate__c);
    
    // TCV calculation (ALL assets)
    calculatedTCV += asset.Total_Value__c != null ? asset.Total_Value__c : 0;
    System.debug('  Added to TCV: ' + (asset.Total_Value__c != null ? asset.Total_Value__c : 0) + ' | Running TCV: ' + calculatedTCV);
    
    // Check if asset should be active
    Boolean isStarted = (asset.Start_Date__c <= today);
    Boolean isNotEnded = (asset.End_Date__c >= today);
    Boolean isNotProfessionalService = (asset.ProductFamily != 'Professional Service');
    Boolean shouldBeActive = isStarted && isNotEnded && isNotProfessionalService;
    
    System.debug('  Date Check: Start ≤ Today? ' + isStarted + ' (' + asset.Start_Date__c + ' ≤ ' + today + ')');
    System.debug('  Date Check: End ≥ Today? ' + isNotEnded + ' (' + asset.End_Date__c + ' ≥ ' + today + ')');
    System.debug('  Family Check: Not Professional Service? ' + isNotProfessionalService + ' (' + asset.ProductFamily + ')');
    System.debug('  SHOULD BE ACTIVE: ' + shouldBeActive);
    
    if (shouldBeActive) {
        // ARR/ACV calculation (ACTIVE assets only)
        calculatedARR += asset.ARR__c != null ? asset.ARR__c : 0;
        calculatedACV += asset.Total_Price__c != null ? asset.Total_Price__c : 0;
        calculatedActiveARR += asset.ARR__c != null ? asset.ARR__c : 0;
        
        System.debug('  ✅ ACTIVE ASSET - Added to ARR: ' + (asset.ARR__c != null ? asset.ARR__c : 0));
        System.debug('    Running ARR: ' + calculatedARR);
        System.debug('    Running ACV: ' + calculatedACV);
        System.debug('    Running Active_ARR: ' + calculatedActiveARR);
    } else {
        System.debug('  ❌ NOT ACTIVE - Excluded from ARR/ACV');
    }
    System.debug('');
}

System.debug('\n--- Final Calculations ---');
System.debug('Expected ARR: ' + calculatedARR + ' | Actual ARR: ' + contract.ARR__c);
System.debug('Expected ACV: ' + calculatedACV + ' | Actual ACV: ' + contract.ACV__c);
System.debug('Expected TCV: ' + calculatedTCV + ' | Actual TCV: ' + contract.TCV__c);
System.debug('Expected Active_ARR: ' + calculatedActiveARR + ' | Actual Active_ARR: ' + contract.Active_ARR__c);

// Check for discrepancies
Boolean arrMatch = Math.abs((calculatedARR != null ? calculatedARR : 0) - (contract.ARR__c != null ? contract.ARR__c : 0)) < 0.01;
Boolean acvMatch = Math.abs((calculatedACV != null ? calculatedACV : 0) - (contract.ACV__c != null ? contract.ACV__c : 0)) < 0.01;
Boolean tcvMatch = Math.abs((calculatedTCV != null ? calculatedTCV : 0) - (contract.TCV__c != null ? contract.TCV__c : 0)) < 0.01;

System.debug('\n--- Validation Results ---');
System.debug('ARR Match: ' + arrMatch + (arrMatch ? ' ✅' : ' ❌'));
System.debug('ACV Match: ' + acvMatch + (acvMatch ? ' ✅' : ' ❌'));
System.debug('TCV Match: ' + tcvMatch + (tcvMatch ? ' ✅' : ' ❌'));

if (!arrMatch) {
    System.debug('🚨 ARR MISMATCH DETECTED!');
    System.debug('Expected: ' + calculatedARR + ' | Actual: ' + contract.ARR__c);
    System.debug('Difference: ' + (contract.ARR__c - calculatedARR));
}

System.debug('=== Debug Complete ===');
