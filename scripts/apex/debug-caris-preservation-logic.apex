// Debug script to check preservation logic for Caris Life Sciences
// Focus on shouldPreserveExpiredRevenue logic that might prevent status updates

System.debug('=== DEBUGGING PRESERVATION LOGIC FOR CARIS ===');

// Query the account
Account account = [
    SELECT Id, Name, Status__c, Type,
           (SELECT Id, StartDate, EndDate, Status, Exclude_from_Status_Updates__c,
                   Renewal_Opportunity__c,
                   Renewal_Opportunity__r.Id, Renewal_Opportunity__r.StageName, 
                   Renewal_Opportunity__r.IsClosed, Renewal_Opportunity__r.Deal_Type__c
            FROM Contracts)
    FROM Account 
    WHERE Id = '001fJ000021YBjKQAW'
];

Date today = Date.today();
System.debug('Today: ' + today);
System.debug('Account: ' + account.Name + ' (Status: ' + account.Status__c + ')');

// Replicate exact preservation logic from AccountRollupBatch
Boolean varB_HasOpenRenewal = false;
Boolean varB_HasLostRenewal = false;
Boolean varB_AllContractsCancelled = false;

Decimal varN_ActiveContracts = 0;
Decimal varN_FutureContracts = 0;
Decimal varN_NumExpiredContracts = 0;

// Step 1: Process renewals
for (Contract contract : account.Contracts) {
    if (contract.Renewal_Opportunity__c != null) {
        if (contract.Renewal_Opportunity__r.IsClosed == false) {
            varB_HasOpenRenewal = true;
        } else if (contract.Renewal_Opportunity__r.StageName == 'Closed Lost' && 
                  contract.Renewal_Opportunity__r.Deal_Type__c == 'Churn') {
            varB_HasLostRenewal = true;
        }
    }
}

// Step 2: Check cancelled contracts
Integer totalContracts = account.Contracts.size();
Integer cancelledContracts = 0;
for (Contract contract : account.Contracts) {
    if (contract.Status == 'Cancelled') {
        cancelledContracts++;
    }
}
varB_AllContractsCancelled = (cancelledContracts == totalContracts && totalContracts > 0);

// Step 3: Count contract types
for (Contract contract : account.Contracts) {
    if (contract.Exclude_from_Status_Updates__c == true) {
        System.debug('Contract ' + contract.Id + ' excluded from status updates');
        continue;
    }
    
    if (contract.StartDate <= today && contract.EndDate >= today) {
        varN_ActiveContracts++;
    } else if (contract.StartDate > today) {
        varN_FutureContracts++;
    } else if (contract.EndDate < today) {
        varN_NumExpiredContracts++;
    }
}

System.debug('Contract Counts:');
System.debug('  Active: ' + varN_ActiveContracts);
System.debug('  Future: ' + varN_FutureContracts);
System.debug('  Expired: ' + varN_NumExpiredContracts);
System.debug('  HasOpenRenewal: ' + varB_HasOpenRenewal);
System.debug('  HasLostRenewal: ' + varB_HasLostRenewal);
System.debug('  AllCancelled: ' + varB_AllContractsCancelled);

// Step 4: Check preservation logic (CRITICAL!)
Boolean preserveAllExpired = (varN_ActiveContracts == 0 && 
                             varN_FutureContracts == 0 && 
                             varN_NumExpiredContracts > 0 &&
                             !varB_AllContractsCancelled);

Boolean preserveExpiredWithOpenRenewal = (varN_ActiveContracts == 0 && 
                                         varN_NumExpiredContracts > 0 && 
                                         varB_HasOpenRenewal);

Boolean shouldPreserveExpiredRevenue = preserveAllExpired || preserveExpiredWithOpenRenewal;

System.debug('');
System.debug('=== PRESERVATION LOGIC EVALUATION ===');
System.debug('preserveAllExpired conditions:');
System.debug('  varN_ActiveContracts == 0: ' + (varN_ActiveContracts == 0));
System.debug('  varN_FutureContracts == 0: ' + (varN_FutureContracts == 0));
System.debug('  varN_NumExpiredContracts > 0: ' + (varN_NumExpiredContracts > 0));
System.debug('  !varB_AllContractsCancelled: ' + (!varB_AllContractsCancelled));
System.debug('  → preserveAllExpired: ' + preserveAllExpired);

System.debug('');
System.debug('preserveExpiredWithOpenRenewal conditions:');
System.debug('  varN_ActiveContracts == 0: ' + (varN_ActiveContracts == 0));
System.debug('  varN_NumExpiredContracts > 0: ' + (varN_NumExpiredContracts > 0));
System.debug('  varB_HasOpenRenewal: ' + varB_HasOpenRenewal);
System.debug('  → preserveExpiredWithOpenRenewal: ' + preserveExpiredWithOpenRenewal);

System.debug('');
System.debug('FINAL RESULT: shouldPreserveExpiredRevenue = ' + shouldPreserveExpiredRevenue);

// Step 5: Status determination (same as before)
String newStatus = null;
String currentStatus = account.Status__c;

// Rule 6: Active_With_Lost_Renewal_Enhanced (the one we expect to match)
if (currentStatus == 'Active' && varN_ActiveContracts > 0 && varB_HasLostRenewal && !varB_HasOpenRenewal) {
    newStatus = 'Active (Churning)';
    System.debug('Rule 6 MATCH: newStatus = ' + newStatus);
}

System.debug('');
System.debug('=== ACCOUNT UPDATE LOGIC ===');
System.debug('Current Status: ' + currentStatus);
System.debug('Calculated Status: ' + newStatus);
System.debug('shouldPreserveExpiredRevenue: ' + shouldPreserveExpiredRevenue);

if (newStatus != null) {
    System.debug('✅ STATUS UPDATE WOULD BE APPLIED: ' + currentStatus + ' → ' + newStatus);
    System.debug('This means preservation logic is NOT blocking status updates');
} else {
    System.debug('❌ NO STATUS UPDATE CALCULATED');
}

// The key question: does preservation logic affect status updates?
// Looking at the AccountRollupBatch code, status updates happen OUTSIDE preservation blocks
System.debug('');
System.debug('=== CONCLUSION ===');
System.debug('Status updates in AccountRollupBatch happen at lines 221-229, which are OUTSIDE the preservation logic blocks');
System.debug('Preservation logic only affects revenue field calculations, NOT status updates');
System.debug('Therefore, preservation logic should NOT prevent this status change');

System.debug('=== END DEBUG ===');
