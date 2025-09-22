// Trace exactly what happens when processing contract 800fJ000007eNJeQAM
System.debug('=== Tracing Contract 800fJ000007eNJeQAM Processing ===');

// Get the contract with all related data
List<Contract> testContract = [
    SELECT Id, Status, StartDate, EndDate, Exclude_from_Status_Updates__c,
           ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Previous_ARR__c, Incremental_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, 
           MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c,
           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                   Start_Date__c, End_Date__c, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Id = '800fJ000007eNJeQAM'
];

if (testContract.size() == 0) {
    System.debug('❌ Contract not found');
    return;
}

Contract contract = testContract[0];
System.debug('BEFORE Processing:');
System.debug('  Status: ' + contract.Status);
System.debug('  ARR__c: ' + contract.ARR__c);
System.debug('  ACV__c: ' + contract.ACV__c);
System.debug('  Active_ARR__c: ' + contract.Active_ARR__c);
System.debug('  Assets: ' + contract.Assets__r.size());

// Manually call the ContractRevenueBatch execute method with this single contract
ContractRevenueBatch batch = new ContractRevenueBatch();
List<Contract> contractList = new List<Contract>{contract};

System.debug('\n--- Starting ContractRevenueBatch.execute() ---');
batch.execute(null, contractList);

System.debug('\n--- ContractRevenueBatch.execute() completed ---');

// Check if the contract was actually updated in the database
Contract updatedContract = [
    SELECT Id, ARR__c, ACV__c, Active_ARR__c, TCV__c, MRR__c, LastModifiedDate, LastModifiedBy.Name
    FROM Contract 
    WHERE Id = :contract.Id
];

System.debug('\nAFTER Processing:');
System.debug('  ARR__c: ' + updatedContract.ARR__c);
System.debug('  ACV__c: ' + updatedContract.ACV__c);
System.debug('  Active_ARR__c: ' + updatedContract.Active_ARR__c);
System.debug('  TCV__c: ' + updatedContract.TCV__c);
System.debug('  MRR__c: ' + updatedContract.MRR__c);
System.debug('  LastModified: ' + updatedContract.LastModifiedDate);

// Check if values changed
Boolean arrChanged = contract.ARR__c != updatedContract.ARR__c;
Boolean acvChanged = contract.ACV__c != updatedContract.ACV__c;

System.debug('\n--- ANALYSIS ---');
System.debug('ARR Changed: ' + arrChanged + ' (' + contract.ARR__c + ' → ' + updatedContract.ARR__c + ')');
System.debug('ACV Changed: ' + acvChanged + ' (' + contract.ACV__c + ' → ' + updatedContract.ACV__c + ')');

if (arrChanged || acvChanged) {
    System.debug('✅ Contract WAS updated by the batch');
} else {
    System.debug('❌ Contract was NOT updated by the batch');
    System.debug('🔍 This confirms the contract is being skipped in processContract()');
}

System.debug('\n=== Trace Complete ===');
