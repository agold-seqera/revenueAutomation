// Debug script for Caris Life Sciences account status logic
// Account ID: 001fJ000021YBjKQAW
// Contract ID: 800fJ000007eLBiQAM
// Purpose: Identify why Rule 6 (Active_With_Lost_Renewal_Enhanced) is not executing

System.debug('=== DEBUGGING CARIS LIFE SCIENCES ACCOUNT STATUS LOGIC ===');

// Query the specific account with all related data
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

System.debug('Account Data:');
System.debug('  ID: ' + account.Id);
System.debug('  Name: ' + account.Name);
System.debug('  Current Status: ' + account.Status__c);
System.debug('  Current Type: ' + account.Type);
System.debug('  Number of Contracts: ' + account.Contracts.size());

// Initialize tracking variables (replicate exact AccountRollupBatch logic)
Date today = Date.today();
System.debug('Today\'s Date: ' + today);

// v42 Enhancement variables for status determination
Boolean varB_HasOpenRenewal = false;
Boolean varB_HasLostRenewal = false;
Boolean varB_AllContractsCancelled = false;

// Contract counting variables
Decimal varN_ActiveContracts = 0;
Decimal varN_FutureContracts = 0;
Decimal varN_NumExpiredContracts = 0;

System.debug('');
System.debug('=== STEP 1: PROCESS CONTRACTS WITH RENEWALS ===');

// Step 1: Process contracts with renewals (v42 enhancement)
for (Contract contract : account.Contracts) {
    System.debug('Contract: ' + contract.Id);
    System.debug('  Status: ' + contract.Status);
    System.debug('  StartDate: ' + contract.StartDate);
    System.debug('  EndDate: ' + contract.EndDate);
    System.debug('  Renewal_Opportunity__c: ' + contract.Renewal_Opportunity__c);
    
    if (contract.Renewal_Opportunity__c != null) {
        System.debug('  Renewal Opportunity Found:');
        System.debug('    ID: ' + contract.Renewal_Opportunity__r.Id);
        System.debug('    StageName: ' + contract.Renewal_Opportunity__r.StageName);
        System.debug('    IsClosed: ' + contract.Renewal_Opportunity__r.IsClosed);
        System.debug('    Deal_Type__c: ' + contract.Renewal_Opportunity__r.Deal_Type__c);
        
        // Check_Renewal_Status logic
        if (contract.Renewal_Opportunity__r.IsClosed == false) {
            varB_HasOpenRenewal = true;
            System.debug('    → Setting varB_HasOpenRenewal = true (renewal is open)');
        } else if (contract.Renewal_Opportunity__r.StageName == 'Closed Lost' && 
                  contract.Renewal_Opportunity__r.Deal_Type__c == 'Churn') {
            varB_HasLostRenewal = true;
            System.debug('    → Setting varB_HasLostRenewal = true (closed lost + churn)');
        } else {
            System.debug('    → No renewal status flags set');
            System.debug('      (StageName: ' + contract.Renewal_Opportunity__r.StageName + 
                        ', Deal_Type: ' + contract.Renewal_Opportunity__r.Deal_Type__c + ')');
        }
    } else {
        System.debug('  No Renewal Opportunity linked');
    }
    System.debug('');
}

System.debug('=== STEP 2: CHECK CANCELLED CONTRACTS ===');

// Step 2: Check if all contracts are cancelled
Integer totalContracts = account.Contracts.size();
Integer cancelledContracts = 0;
for (Contract contract : account.Contracts) {
    System.debug('Contract ' + contract.Id + ' Status: ' + contract.Status);
    if (contract.Status == 'Cancelled') {
        cancelledContracts++;
        System.debug('  → Cancelled contract found');
    }
}
varB_AllContractsCancelled = (cancelledContracts == totalContracts && totalContracts > 0);
System.debug('Total Contracts: ' + totalContracts);
System.debug('Cancelled Contracts: ' + cancelledContracts);
System.debug('varB_AllContractsCancelled: ' + varB_AllContractsCancelled);
System.debug('');

System.debug('=== STEP 3: COUNT CONTRACT TYPES ===');

// Step 3: Count active, future, and expired contracts
for (Contract contract : account.Contracts) {
    // Skip contracts excluded from status updates
    if (contract.Exclude_from_Status_Updates__c == true) {
        System.debug('Contract ' + contract.Id + ' excluded from status updates');
        continue;
    }
    
    System.debug('Processing Contract: ' + contract.Id);
    System.debug('  StartDate: ' + contract.StartDate + ', EndDate: ' + contract.EndDate + ', Today: ' + today);
    
    // Determine contract status relative to today
    if (contract.StartDate <= today && contract.EndDate >= today) {
        varN_ActiveContracts++;
        System.debug('  → ACTIVE contract (count: ' + varN_ActiveContracts + ')');
    } else if (contract.StartDate > today) {
        varN_FutureContracts++;
        System.debug('  → FUTURE contract (count: ' + varN_FutureContracts + ')');
    } else if (contract.EndDate < today) {
        varN_NumExpiredContracts++;
        System.debug('  → EXPIRED contract (count: ' + varN_NumExpiredContracts + ')');
    }
}

System.debug('');
System.debug('=== FINAL TRACKING VARIABLES ===');
System.debug('varN_ActiveContracts: ' + varN_ActiveContracts);
System.debug('varN_FutureContracts: ' + varN_FutureContracts);
System.debug('varN_NumExpiredContracts: ' + varN_NumExpiredContracts);
System.debug('varB_HasOpenRenewal: ' + varB_HasOpenRenewal);
System.debug('varB_HasLostRenewal: ' + varB_HasLostRenewal);
System.debug('varB_AllContractsCancelled: ' + varB_AllContractsCancelled);

System.debug('');
System.debug('=== STEP 4: EVALUATE BUSINESS RULES ===');

String newStatus = null;
String currentStatus = account.Status__c;

System.debug('Current Account Status: ' + currentStatus);
System.debug('Evaluating business rules in priority order:');

// Rule 1: All_Contracts_Cancelled (highest priority)
System.debug('Rule 1: All_Contracts_Cancelled');
System.debug('  Condition: allContractsCancelled && activeContracts == 0');
System.debug('  Values: ' + varB_AllContractsCancelled + ' && ' + varN_ActiveContracts + ' == 0');
if (varB_AllContractsCancelled && varN_ActiveContracts == 0) {
    newStatus = 'Churned';
    System.debug('  → MATCH: Setting status to Churned');
} else {
    System.debug('  → No match, continuing to Rule 2');
}

// Rule 2: Null_To_Prospect
if (newStatus == null) {
    System.debug('Rule 2: Null_To_Prospect');
    System.debug('  Condition: Status = null && futureContracts == 0 && activeContracts == 0');
    System.debug('  Values: ' + currentStatus + ' == null && ' + varN_FutureContracts + ' == 0 && ' + varN_ActiveContracts + ' == 0');
    if (currentStatus == null && varN_FutureContracts == 0 && varN_ActiveContracts == 0) {
        newStatus = 'Prospect';
        System.debug('  → MATCH: Setting status to Prospect');
    } else {
        System.debug('  → No match, continuing to Rule 3');
    }
}

// Rule 3: Only_Future_Contracts
if (newStatus == null) {
    System.debug('Rule 3: Only_Future_Contracts');
    System.debug('  Condition: futureContracts > 0 && activeContracts == 0');
    System.debug('  Values: ' + varN_FutureContracts + ' > 0 && ' + varN_ActiveContracts + ' == 0');
    if (varN_FutureContracts > 0 && varN_ActiveContracts == 0) {
        newStatus = 'Contracted';
        System.debug('  → MATCH: Setting status to Contracted');
    } else {
        System.debug('  → No match, continuing to Rule 4');
    }
}

// Rule 4: Churning_To_Churned
if (newStatus == null) {
    System.debug('Rule 4: Churning_To_Churned');
    System.debug('  Condition: Status = \'Active (Churning)\' && activeContracts == 0 && expiredContracts > 0 && !hasOpenRenewal');
    System.debug('  Values: ' + currentStatus + ' == \'Active (Churning)\' && ' + varN_ActiveContracts + ' == 0 && ' + varN_NumExpiredContracts + ' > 0 && !' + varB_HasOpenRenewal);
    if (currentStatus == 'Active (Churning)' && varN_ActiveContracts == 0 && varN_NumExpiredContracts > 0 && !varB_HasOpenRenewal) {
        newStatus = 'Churned';
        System.debug('  → MATCH: Setting status to Churned');
    } else {
        System.debug('  → No match, continuing to Rule 5');
    }
}

// Rule 5: Active_With_Lost_Renewal_No_Active
if (newStatus == null) {
    System.debug('Rule 5: Active_With_Lost_Renewal_No_Active');
    System.debug('  Condition: Status = \'Active\' && activeContracts == 0 && hasLostRenewal');
    System.debug('  Values: ' + currentStatus + ' == \'Active\' && ' + varN_ActiveContracts + ' == 0 && ' + varB_HasLostRenewal);
    if (currentStatus == 'Active' && varN_ActiveContracts == 0 && varB_HasLostRenewal) {
        newStatus = 'Churned';
        System.debug('  → MATCH: Setting status to Churned');
    } else {
        System.debug('  → No match, continuing to Rule 6');
    }
}

// Rule 6: Active_With_Lost_Renewal_Enhanced (THE KEY RULE)
if (newStatus == null) {
    System.debug('Rule 6: Active_With_Lost_Renewal_Enhanced (KEY RULE FOR THIS CASE)');
    System.debug('  Condition: Status = \'Active\' && activeContracts > 0 && hasLostRenewal && !hasOpenRenewal');
    System.debug('  Values: ' + currentStatus + ' == \'Active\' && ' + varN_ActiveContracts + ' > 0 && ' + varB_HasLostRenewal + ' && !' + varB_HasOpenRenewal);
    System.debug('  Evaluation:');
    System.debug('    Status = \'Active\': ' + (currentStatus == 'Active'));
    System.debug('    activeContracts > 0: ' + (varN_ActiveContracts > 0));
    System.debug('    hasLostRenewal: ' + varB_HasLostRenewal);
    System.debug('    !hasOpenRenewal: ' + (!varB_HasOpenRenewal));
    
    if (currentStatus == 'Active' && varN_ActiveContracts > 0 && varB_HasLostRenewal && !varB_HasOpenRenewal) {
        newStatus = 'Active (Churning)';
        System.debug('  → ✅ MATCH: Setting status to Active (Churning)');
    } else {
        System.debug('  → ❌ NO MATCH: Continuing to Rule 7');
    }
}

// Rule 7: Expired_Contracts_With_Open_Renewal
if (newStatus == null) {
    System.debug('Rule 7: Expired_Contracts_With_Open_Renewal');
    System.debug('  Condition: activeContracts == 0 && expiredContracts > 0 && hasOpenRenewal');
    System.debug('  Values: ' + varN_ActiveContracts + ' == 0 && ' + varN_NumExpiredContracts + ' > 0 && ' + varB_HasOpenRenewal);
    if (varN_ActiveContracts == 0 && varN_NumExpiredContracts > 0 && varB_HasOpenRenewal) {
        newStatus = 'Active (Churning)';
        System.debug('  → MATCH: Setting status to Active (Churning)');
    } else {
        System.debug('  → No match, continuing to Rule 8');
    }
}

// Rule 8: Has_Active_Contracts
if (newStatus == null) {
    System.debug('Rule 8: Has_Active_Contracts');
    System.debug('  Condition: activeContracts > 0');
    System.debug('  Values: ' + varN_ActiveContracts + ' > 0');
    if (varN_ActiveContracts > 0) {
        newStatus = 'Active';
        System.debug('  → MATCH: Setting status to Active');
    } else {
        System.debug('  → No match, continuing to Rule 9');
    }
}

// Rule 9: Default - no change
if (newStatus == null) {
    System.debug('Rule 9: Default - no change');
    System.debug('  → No status change');
}

System.debug('');
System.debug('=== FINAL RESULT ===');
System.debug('Current Status: ' + currentStatus);
System.debug('Determined Status: ' + newStatus);

if (newStatus != null && newStatus != currentStatus) {
    System.debug('✅ STATUS CHANGE REQUIRED: ' + currentStatus + ' → ' + newStatus);
} else if (newStatus == null) {
    System.debug('ℹ️  NO STATUS CHANGE (returned null)');
} else {
    System.debug('ℹ️  NO STATUS CHANGE (same status)');
}

System.debug('=== END DEBUG ===');
