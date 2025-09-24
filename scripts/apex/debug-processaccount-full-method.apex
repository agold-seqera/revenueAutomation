// Complete debugging of AccountRollupBatch.processAccount() method for Caris Life Sciences
// This will simulate the EXACT method execution to find where it differs from our manual logic

System.debug('=== FULL PROCESSACCOUNT METHOD DEBUG FOR CARIS ===');

// Query account exactly as batch does
Account account = [
    SELECT Id, Name, Status__c, Type, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
           (SELECT Id, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c,
                   ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
                   ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c,
                   StartDate, EndDate, Status, Exclude_from_Status_Updates__c,
                   Renewal_Opportunity__c,
                   Renewal_Opportunity__r.Id, Renewal_Opportunity__r.StageName, 
                   Renewal_Opportunity__r.IsClosed, Renewal_Opportunity__r.Deal_Type__c
            FROM Contracts)
    FROM Account 
    WHERE Id = '001fJ000021YBjKQAW'
];

Date today = Date.today();
System.debug('Processing Account: ' + account.Name + ' (ID: ' + account.Id + ')');
System.debug('Current Status: ' + account.Status__c);
System.debug('Today: ' + today);
System.debug('');

// ===== STEP-BY-STEP REPLICATION OF processAccount() METHOD =====

// Initialize tracking variables (lines 95-114)
Decimal varARR_USD_Total = 0;
Decimal varACV_USD_Total = 0;
Decimal varTCV_USD_Total = 0;
Decimal varMRR_USD_Total = 0;

Decimal varARR_Reporting_Total = 0;
Decimal varACV_Reporting_Total = 0;
Decimal varTCV_Reporting_Total = 0;
Decimal varMRR_Reporting_Total = 0;

// v42 Enhancement variables for status determination
Boolean varB_HasOpenRenewal = false;
Boolean varB_HasLostRenewal = false;
Boolean varB_AllContractsCancelled = false;

// Contract counting variables
Decimal varN_ActiveContracts = 0;
Decimal varN_FutureContracts = 0;
Decimal varN_NumExpiredContracts = 0;

System.debug('=== STEP 1: PROCESS CONTRACTS WITH RENEWALS (lines 116-127) ===');
for (Contract contract : account.Contracts) {
    System.debug('Processing renewal for contract: ' + contract.Id);
    if (contract.Renewal_Opportunity__c != null) {
        System.debug('  Has renewal opportunity: ' + contract.Renewal_Opportunity__c);
        System.debug('  IsClosed: ' + contract.Renewal_Opportunity__r.IsClosed);
        System.debug('  StageName: ' + contract.Renewal_Opportunity__r.StageName);
        System.debug('  Deal_Type__c: ' + contract.Renewal_Opportunity__r.Deal_Type__c);
        
        if (contract.Renewal_Opportunity__r.IsClosed == false) {
            varB_HasOpenRenewal = true;
            System.debug('  → Set varB_HasOpenRenewal = true');
        } else if (contract.Renewal_Opportunity__r.StageName == 'Closed Lost' && 
                  contract.Renewal_Opportunity__r.Deal_Type__c == 'Churn') {
            varB_HasLostRenewal = true;
            System.debug('  → Set varB_HasLostRenewal = true');
        }
    } else {
        System.debug('  No renewal opportunity');
    }
}

System.debug('');
System.debug('=== STEP 2: CHECK CANCELLED CONTRACTS (lines 129-137) ===');
Integer totalContracts = account.Contracts.size();
Integer cancelledContracts = 0;
for (Contract contract : account.Contracts) {
    System.debug('Contract ' + contract.Id + ' Status: ' + contract.Status);
    if (contract.Status == 'Cancelled') {
        cancelledContracts++;
    }
}
varB_AllContractsCancelled = (cancelledContracts == totalContracts && totalContracts > 0);
System.debug('Total: ' + totalContracts + ', Cancelled: ' + cancelledContracts + ', AllCancelled: ' + varB_AllContractsCancelled);

System.debug('');
System.debug('=== STEP 3: CONTRACT COUNTING (lines 139-151) ===');
// ***** CRITICAL DIFFERENCE! *****
// Look at lines 142 and 145-146: Exclude_from_Status_Updates__c checking!
for (Contract contract : account.Contracts) {
    System.debug('Contract ' + contract.Id + ':');
    System.debug('  StartDate: ' + contract.StartDate);
    System.debug('  EndDate: ' + contract.EndDate);
    System.debug('  Exclude_from_Status_Updates__c: ' + contract.Exclude_from_Status_Updates__c);
    
    // Contract counting logic (exact flow replication)
    if (contract.StartDate > today && contract.Exclude_from_Status_Updates__c == false) {
        varN_FutureContracts += 1;
        System.debug('  → FUTURE contract (Exclude check: ' + contract.Exclude_from_Status_Updates__c + ')');
    } else if (contract.StartDate <= today && 
              contract.EndDate >= today && 
              contract.Exclude_from_Status_Updates__c == false) {
        varN_ActiveContracts += 1;
        System.debug('  → ACTIVE contract (Exclude check: ' + contract.Exclude_from_Status_Updates__c + ')');
    } else if (contract.EndDate < today) {
        varN_NumExpiredContracts += 1;
        System.debug('  → EXPIRED contract (no exclude check)');
    } else {
        System.debug('  → NO CATEGORY (failed all conditions)');
        if (contract.Exclude_from_Status_Updates__c == true) {
            System.debug('      Reason: EXCLUDED from status updates');
        }
    }
}

System.debug('');
System.debug('=== CONTRACT COUNT RESULTS ===');
System.debug('varN_ActiveContracts: ' + varN_ActiveContracts);
System.debug('varN_FutureContracts: ' + varN_FutureContracts);
System.debug('varN_NumExpiredContracts: ' + varN_NumExpiredContracts);
System.debug('varB_HasOpenRenewal: ' + varB_HasOpenRenewal);
System.debug('varB_HasLostRenewal: ' + varB_HasLostRenewal);
System.debug('varB_AllContractsCancelled: ' + varB_AllContractsCancelled);

System.debug('');
System.debug('=== STEP 4: PRESERVATION LOGIC (lines 153-166) ===');
Boolean preserveAllExpired = (varN_ActiveContracts == 0 && 
                             varN_FutureContracts == 0 && 
                             varN_NumExpiredContracts > 0 &&
                             !varB_AllContractsCancelled);

Boolean preserveExpiredWithOpenRenewal = (varN_ActiveContracts == 0 && 
                                         varN_FutureContracts == 0 && 
                                         varN_NumExpiredContracts > 0 &&
                                         varB_HasOpenRenewal);

Boolean shouldPreserveExpiredRevenue = preserveAllExpired || preserveExpiredWithOpenRenewal;

System.debug('preserveAllExpired: ' + preserveAllExpired);
System.debug('preserveExpiredWithOpenRenewal: ' + preserveExpiredWithOpenRenewal);
System.debug('shouldPreserveExpiredRevenue: ' + shouldPreserveExpiredRevenue);

System.debug('');
System.debug('=== STEP 6: ACCOUNT STATUS DETERMINATION (lines 217-229) ===');
// This calls determineAccountStatus method with the calculated values

// Rule 6 check specifically
System.debug('Checking Rule 6 conditions:');
System.debug('  account.Status__c == \'Active\': ' + (account.Status__c == 'Active'));
System.debug('  varN_ActiveContracts > 0: ' + (varN_ActiveContracts > 0));
System.debug('  varB_HasLostRenewal: ' + varB_HasLostRenewal);
System.debug('  !varB_HasOpenRenewal: ' + (!varB_HasOpenRenewal));

String newStatus = null;
if (account.Status__c == 'Active' && 
    varN_ActiveContracts > 0 && 
    varB_HasLostRenewal && 
    !varB_HasOpenRenewal) {
    newStatus = 'Active (Churning)';
    System.debug('  → ✅ RULE 6 MATCH: newStatus = ' + newStatus);
} else {
    System.debug('  → ❌ RULE 6 NO MATCH');
    
    // Check other rules that might match
    if (varN_ActiveContracts > 0) {
        newStatus = 'Active';
        System.debug('  → Rule 8 MATCH: newStatus = ' + newStatus + ' (Has Active Contracts)');
    }
}

System.debug('');
System.debug('=== FINAL RESULTS ===');
System.debug('Original Status: ' + account.Status__c);
System.debug('Calculated newStatus: ' + newStatus);

if (newStatus != null) {
    System.debug('✅ STATUS CHANGE WOULD BE APPLIED');
} else {
    System.debug('❌ NO STATUS CHANGE (newStatus is null)');
}

// Check if processAccount would return account or null
if (newStatus != null && newStatus != account.Status__c) {
    System.debug('🔄 Account object WOULD BE RETURNED for update');
} else if (shouldPreserveExpiredRevenue) {
    System.debug('🔄 Account object WOULD BE RETURNED (preservation scenario)');
} else {
    System.debug('❓ NEED TO CHECK: Would account object be returned?');
}

System.debug('');
System.debug('=== CRITICAL FINDING ===');
if (varN_ActiveContracts == 0) {
    System.debug('🚨 BUG FOUND: varN_ActiveContracts = 0 when it should be 1!');
    System.debug('This means the contract counting logic has a bug with Exclude_from_Status_Updates__c');
} else {
    System.debug('✅ Contract counting appears correct');
}

System.debug('=== END FULL METHOD DEBUG ===');
