// TEST: Verify ContractRevenueBatch now correctly populates USD fields for expired contracts with $0.00

System.debug('=== TESTING CONTRACT USD FIX ===');

// Test with CDC contract (Expired with $0.00 USD)
String contractId = '800fJ000007eLBfQAM';

Contract testContract = [
    SELECT Id, Status, ARR__c, ARR_USD__c, TCV__c, TCV_USD__c, CurrencyIsoCode
    FROM Contract 
    WHERE Id = :contractId
];

System.debug('BEFORE - Contract: ' + testContract.Id + ' (Status: ' + testContract.Status + ')');
System.debug('BEFORE - ARR__c: ' + testContract.ARR__c + ' | ARR_USD__c: ' + testContract.ARR_USD__c);
System.debug('BEFORE - TCV__c: ' + testContract.TCV__c + ' | TCV_USD__c: ' + testContract.TCV_USD__c);

// Execute ContractRevenueBatch for this contract
ContractRevenueBatch batch = new ContractRevenueBatch();
List<Contract> contracts = [
    SELECT Id, Status, ARR__c, ACV__c, TCV__c, MRR__c, Incremental_ARR__c, Previous_ARR__c, Active_ARR__c,
           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c,
           StartDate, EndDate, CurrencyIsoCode, Exclude_from_Status_Updates__c,
           (SELECT Id, ARR__c, Total_Value__c, Total_Price__c, Exchange_Rate__c,
                   Start_Date__c, End_Date__c, Product2.Family, ProductFamily, Exclude_from_Status_Updates__c
            FROM Assets__r
            WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE Id = :contractId
];

batch.execute(null, contracts);

// Check the result
Contract resultContract = [
    SELECT Id, Status, ARR__c, ARR_USD__c, TCV__c, TCV_USD__c
    FROM Contract 
    WHERE Id = :contractId
];

System.debug('AFTER - Contract: ' + resultContract.Id + ' (Status: ' + resultContract.Status + ')');
System.debug('AFTER - ARR__c: ' + resultContract.ARR__c + ' | ARR_USD__c: ' + resultContract.ARR_USD__c);
System.debug('AFTER - TCV__c: ' + resultContract.TCV__c + ' | TCV_USD__c: ' + resultContract.TCV_USD__c);

// Verification
if (resultContract.ARR_USD__c != null && resultContract.ARR_USD__c != '$0.00' && resultContract.ARR_USD__c.contains('924,687')) {
    System.debug('✅ SUCCESS: Contract USD fields correctly populated!');
} else {
    System.debug('❌ FAILED: Contract USD fields still not populated correctly');
}

System.debug('=== CONTRACT USD FIX TEST COMPLETE ===');
