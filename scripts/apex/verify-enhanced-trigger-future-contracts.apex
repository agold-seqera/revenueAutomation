// Verify enhanced ContractTriggerHandler is populating USD Reporting fields for future contracts
System.debug('=== VERIFYING ENHANCED CONTRACTTRIGGERHANDLER FOR FUTURE CONTRACTS ===');

// Check Atlas Data Storage account and its future contract
Account atlasAccount = [
    SELECT Id, Name, Status__c, ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
           (SELECT Id, Status, StartDate, EndDate, Description, ARR__c, ARR_USD__c, ARR_USD_Reporting__c,
                   ACV__c, ACV_USD__c, ACV_USD_Reporting__c,
                   TCV__c, TCV_USD__c, TCV_USD_Reporting__c,
                   MRR__c, MRR_USD__c, MRR_USD_Reporting__c
            FROM Contracts
            WHERE StartDate > :Date.today()
            AND Status = 'Draft'
            ORDER BY StartDate)
    FROM Account
    WHERE Name = 'Atlas Data Storage'
    LIMIT 1
];

System.debug('--- ATLAS DATA STORAGE ACCOUNT ---');
System.debug('  Status: ' + atlasAccount.Status__c);
System.debug('  ARR: ' + atlasAccount.ARR__c + ' | USD: ' + atlasAccount.ARR_USD__c + ' | Reporting: ' + atlasAccount.ARR_USD_Reporting__c);

if (atlasAccount.Contracts.isEmpty()) {
    System.debug('❌ ERROR: No future contracts found for Atlas Data Storage');
} else {
    for (Contract contract : atlasAccount.Contracts) {
        System.debug('--- FUTURE CONTRACT: ' + contract.Id + ' ---');
        System.debug('  Status: ' + contract.Status + ' | Start: ' + contract.StartDate + ' | End: ' + contract.EndDate);
        System.debug('  ARR: ' + contract.ARR__c + ' | USD: ' + contract.ARR_USD__c + ' | Reporting: ' + contract.ARR_USD_Reporting__c);
        System.debug('  ACV: ' + contract.ACV__c + ' | USD: ' + contract.ACV_USD__c + ' | Reporting: ' + contract.ACV_USD_Reporting__c);
        System.debug('  TCV: ' + contract.TCV__c + ' | USD: ' + contract.TCV_USD__c + ' | Reporting: ' + contract.TCV_USD_Reporting__c);
        System.debug('  MRR: ' + contract.MRR__c + ' | USD: ' + contract.MRR_USD__c + ' | Reporting: ' + contract.MRR_USD_Reporting__c);
        
        // Check if USD Reporting fields are properly populated
        Boolean reportingFieldsPopulated = true;
        if (contract.ARR__c != null && contract.ARR__c > 0 && (contract.ARR_USD_Reporting__c == null || contract.ARR_USD_Reporting__c == 0)) {
            System.debug('⚠️  WARNING: ARR_USD_Reporting__c is not populated despite ARR__c = ' + contract.ARR__c);
            reportingFieldsPopulated = false;
        }
        if (contract.ACV__c != null && contract.ACV__c > 0 && (contract.ACV_USD_Reporting__c == null || contract.ACV_USD_Reporting__c == 0)) {
            System.debug('⚠️  WARNING: ACV_USD_Reporting__c is not populated despite ACV__c = ' + contract.ACV__c);
            reportingFieldsPopulated = false;
        }
        if (contract.TCV__c != null && contract.TCV__c > 0 && (contract.TCV_USD_Reporting__c == null || contract.TCV_USD_Reporting__c == 0)) {
            System.debug('⚠️  WARNING: TCV_USD_Reporting__c is not populated despite TCV__c = ' + contract.TCV__c);
            reportingFieldsPopulated = false;
        }
        if (contract.MRR__c != null && contract.MRR__c > 0 && (contract.MRR_USD_Reporting__c == null || contract.MRR_USD_Reporting__c == 0)) {
            System.debug('⚠️  WARNING: MRR_USD_Reporting__c is not populated despite MRR__c = ' + contract.MRR__c);
            reportingFieldsPopulated = false;
        }
        
        if (reportingFieldsPopulated) {
            System.debug('✅ SUCCESS: All USD Reporting fields properly populated');
        } else {
            System.debug('🔧 ACTION NEEDED: Contract needs to be updated to populate USD Reporting fields');
            
            // Trigger ContractTriggerHandler by making a trivial update
            System.debug('Triggering ContractTriggerHandler by updating contract description...');
            contract.Description = (contract.Description != null ? contract.Description : '') + ' [USD Reporting fields trigger]';
            try {
                update contract;
                System.debug('✅ Contract updated successfully - ContractTriggerHandler should have fired');
            } catch (Exception e) {
                System.debug('❌ Error updating contract: ' + e.getMessage());
            }
        }
    }
}

System.debug('=== VERIFICATION COMPLETE ===');
