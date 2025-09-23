// SIMPLIFIED ACCOUNT ROLLUP LOGIC - What it should actually be

/*
BUSINESS RULES:
1. Active accounts: Calculate ALL fields (base + USD) from ACTIVE contracts only
2. Churning/Churned accounts: PRESERVE ALL existing field values (don't touch anything)
3. USD fields should ALWAYS align with base fields (same contract scope)
*/

// CURRENT OVERLY COMPLEX LOGIC:
if (shouldPreserveExpiredRevenue) {
    // Preserve base currency, but recalculate USD from ALL contracts ← WHY?!
    // This makes no sense - if we're preserving, we should preserve EVERYTHING
} else {
    // Recalculate base from ACTIVE, but USD from ALL ← INCONSISTENT!
    // This breaks the alignment between base and USD fields
}

// SIMPLIFIED CORRECT LOGIC:
if (shouldPreserveExpiredRevenue) {
    // PRESERVE EVERYTHING - don't touch any fields
    // The values were already correct when the account was Active
    System.debug('Preserving all revenue fields for ' + account.Name);
    // DO NOTHING - leave all fields as-is
    
} else {
    // ACTIVE ACCOUNT - recalculate ALL fields from ACTIVE contracts
    System.debug('Recalculating all revenue fields from active contracts for ' + account.Name);
    
    // Reset all fields
    account.ARR__c = 0;
    account.ACV__c = 0; 
    account.TCV__c = 0;
    account.MRR__c = 0;
    
    Decimal arrUsdTotal = 0;
    Decimal acvUsdTotal = 0;
    Decimal tcvUsdTotal = 0;
    Decimal mrrUsdTotal = 0;
    
    Decimal arrReportingTotal = 0;
    Decimal acvReportingTotal = 0;
    Decimal tcvReportingTotal = 0;
    Decimal mrrReportingTotal = 0;
    
    // Single loop, single condition, all fields calculated together
    for (Contract contract : account.Contracts) {
        if (contract.Exclude_from_Status_Updates__c == false && 
            contract.StartDate <= today && 
            contract.EndDate >= today) {
            
            // Base currency fields
            account.ARR__c += (contract.ARR__c != null ? contract.ARR__c : 0);
            account.ACV__c += (contract.ACV__c != null ? contract.ACV__c : 0);
            account.TCV__c += (contract.TCV__c != null ? contract.TCV__c : 0);
            account.MRR__c += (contract.MRR__c != null ? contract.MRR__c : 0);
            
            // USD fields (from same ACTIVE contracts)
            arrUsdTotal += parseUSDValue(contract.ARR_USD__c);
            acvUsdTotal += parseUSDValue(contract.ACV_USD__c);
            tcvUsdTotal += parseUSDValue(contract.TCV_USD__c);
            mrrUsdTotal += parseUSDValue(contract.MRR_USD__c);
            
            // Reporting fields (from same ACTIVE contracts)
            arrReportingTotal += (contract.ARR_USD_Reporting__c != null ? contract.ARR_USD_Reporting__c : 0);
            acvReportingTotal += (contract.ACV_USD_Reporting__c != null ? contract.ACV_USD_Reporting__c : 0);
            tcvReportingTotal += (contract.TCV_USD_Reporting__c != null ? contract.TCV_USD_Reporting__c : 0);
            mrrReportingTotal += (contract.MRR_USD_Reporting__c != null ? contract.MRR_USD_Reporting__c : 0);
        }
    }
    
    // Set USD fields (formatted)
    account.ARR_USD__c = formatCurrency(arrUsdTotal);
    account.ACV_USD__c = formatCurrency(acvUsdTotal);
    account.TCV_USD__c = formatCurrency(tcvUsdTotal);
    account.MRR_USD__c = formatCurrency(mrrUsdTotal);
    
    // Set reporting fields
    account.ARR_USD_Reporting__c = arrReportingTotal;
    account.ACV_USD_Reporting__c = acvReportingTotal;
    account.TCV_USD_Reporting__c = tcvReportingTotal;
    account.MRR_USD_Reporting__c = mrrReportingTotal;
}

/*
BENEFITS OF SIMPLIFIED LOGIC:
1. Clear business rule alignment
2. Base and USD fields always calculated from same contract scope
3. No confusing "preserve some but recalculate others" logic  
4. Single condition, single loop
5. Much easier to understand and debug
6. Eliminates the current bugs
*/
