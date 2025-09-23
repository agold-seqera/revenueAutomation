// Debug script to test ContractRevenueBatch on the test contract
Contract testContract = [SELECT Id, StartDate, EndDate, Status, Exclude_from_Status_Updates__c 
                        FROM Contract 
                        WHERE ContractNumber LIKE '00%' 
                        ORDER BY CreatedDate DESC 
                        LIMIT 1];

System.debug('Test Contract: ' + testContract.Id);
System.debug('StartDate: ' + testContract.StartDate);
System.debug('EndDate: ' + testContract.EndDate);
System.debug('Status: ' + testContract.Status);
System.debug('Exclude_from_Status_Updates__c: ' + testContract.Exclude_from_Status_Updates__c);
System.debug('Today: ' + Date.today());

// Check if it meets activation criteria
Boolean shouldActivate = (testContract.Status == 'Draft' || testContract.Status == null) &&
                        testContract.StartDate <= Date.today() && 
                        testContract.EndDate >= Date.today() &&
                        testContract.Exclude_from_Status_Updates__c != true;

System.debug('Should activate: ' + shouldActivate);

// Run the batch on this specific contract
ContractRevenueBatch batch = new ContractRevenueBatch();
List<Contract> contracts = [SELECT Id, AccountId, Status, StartDate, EndDate, ContractTerm, 
                           Exclude_from_Status_Updates__c, CurrencyIsoCode,
                           ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c, Incremental_ARR__c,
                           Previous_ARR__c, Previous_ACV__c, Previous_MRR__c, Previous_TCV__c,
                           Initial_ARR__c, Initial_ACV__c, Initial_MRR__c, Initial_TCV__c,
                           ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c, Active_ARR_USD__c,
                           Incremental_ARR_USD__c, Previous_ARR_USD__c, Previous_ACV_USD__c,
                           Previous_MRR_USD__c, Previous_TCV_USD__c, Initial_ARR_USD__c,
                           Initial_ACV_USD__c, Initial_MRR_USD__c, Initial_TCV_USD__c,
                           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c,
                           MRR_USD_Reporting__c, Active_ARR_USD_Reporting__c,
                           Incremental_ARR_USD_Reporting__c, Previous_ARR_USD_Reporting__c,
                           Previous_ACV_USD_Reporting__c, Previous_MRR_USD_Reporting__c,
                           Previous_TCV_USD_Reporting__c, Initial_ARR_USD_Reporting__c,
                           Initial_ACV_USD_Reporting__c, Initial_MRR_USD_Reporting__c,
                           Initial_TCV_USD_Reporting__c,
                           (SELECT Id, Name, Status, Start_Date__c, End_Date__c, ARR__c,
                            Price, Quantity, Total_Price__c, Total_Value__c,
                            Unit_ARR__c, Unit_MRR__c, Unit_Value__c, Exchange_Rate__c,
                            Product2.Family FROM Assets__r)
                           FROM Contract 
                           WHERE Id = :testContract.Id];

System.debug('Processing contract in batch...');
batch.execute(null, contracts);

// Check the result
Contract updatedContract = [SELECT Id, Status, ARR__c, ACV__c, TCV__c, MRR__c, Active_ARR__c
                           FROM Contract 
                           WHERE Id = :testContract.Id];

System.debug('After batch - Status: ' + updatedContract.Status);
System.debug('After batch - ARR: ' + updatedContract.ARR__c);
System.debug('After batch - ACV: ' + updatedContract.ACV__c);
