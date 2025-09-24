// Target batch update for specific account: 001fJ000021YCvsQAG
// Execute AccountRollupBatch for this account only

System.debug(LoggingLevel.INFO, '=== TARGET BATCH UPDATE ===');

String targetAccountId = '001fJ000021YCvsQAG';

// First, get account details
Account targetAccount = [
    SELECT Id, Name, Status__c, LastModifiedDate, LastModifiedBy.Name
    FROM Account 
    WHERE Id = :targetAccountId
    LIMIT 1
];

System.debug(LoggingLevel.INFO, 'Target Account: ' + targetAccount.Name);
System.debug(LoggingLevel.INFO, 'Current Status: ' + targetAccount.Status__c);
System.debug(LoggingLevel.INFO, 'Last Modified: ' + targetAccount.LastModifiedDate);
System.debug(LoggingLevel.INFO, 'Modified By: ' + targetAccount.LastModifiedBy.Name);

// Get related contracts and assets for context
List<Contract> relatedContracts = [
    SELECT Id, Status, ARR__c, TCV__c, StartDate, EndDate,
           (SELECT Id, Product2.Family, ARR__c, Status, Start_Date__c, End_Date__c 
            FROM Assets__r 
            WHERE Exclude_from_Status_Updates__c = false)
    FROM Contract 
    WHERE AccountId = :targetAccountId
];

System.debug(LoggingLevel.INFO, 'Related Contracts: ' + relatedContracts.size());

for (Contract contract : relatedContracts) {
    System.debug(LoggingLevel.INFO, 'Contract: ' + contract.Id + 
                                   ' | Status: ' + contract.Status + 
                                   ' | ARR: ' + contract.ARR__c + 
                                   ' | Assets: ' + contract.Assets__r.size());
}

// Get related opportunities for context
List<Opportunity> relatedOpportunities = [
    SELECT Id, Name, StageName, Deal_Type__c, CloseDate
    FROM Opportunity 
    WHERE AccountId = :targetAccountId
    AND Deal_Type__c = 'Churn'
    ORDER BY CloseDate DESC
    LIMIT 5
];

System.debug(LoggingLevel.INFO, 'Related Churn Opportunities: ' + relatedOpportunities.size());

for (Opportunity opp : relatedOpportunities) {
    System.debug(LoggingLevel.INFO, 'Opportunity: ' + opp.Name + 
                                   ' | Stage: ' + opp.StageName + 
                                   ' | Type: ' + opp.Deal_Type__c + 
                                   ' | Close: ' + opp.CloseDate);
}

System.debug(LoggingLevel.INFO, '=== EXECUTING ACCOUNTROLLUPBATCH ===');

// Create a custom batch scope with just this account
AccountRollupBatch batch = new AccountRollupBatch();

// Execute the batch with the target account
List<Account> accountScope = new List<Account>{targetAccount};

try {
    // Execute the batch logic directly for debugging
    batch.execute(null, accountScope);
    
    System.debug(LoggingLevel.INFO, '✅ Batch execution completed successfully');
    
    // Get updated account status
    Account updatedAccount = [
        SELECT Id, Name, Status__c, LastModifiedDate, LastModifiedBy.Name
        FROM Account 
        WHERE Id = :targetAccountId
        LIMIT 1
    ];
    
    System.debug(LoggingLevel.INFO, '=== POST-BATCH STATUS ===');
    System.debug(LoggingLevel.INFO, 'Updated Status: ' + updatedAccount.Status__c);
    System.debug(LoggingLevel.INFO, 'Last Modified: ' + updatedAccount.LastModifiedDate);
    System.debug(LoggingLevel.INFO, 'Modified By: ' + updatedAccount.LastModifiedBy.Name);
    
    if (targetAccount.Status__c != updatedAccount.Status__c) {
        System.debug(LoggingLevel.INFO, '🔄 STATUS CHANGED: ' + 
                    targetAccount.Status__c + ' → ' + updatedAccount.Status__c);
    } else {
        System.debug(LoggingLevel.INFO, '📍 STATUS UNCHANGED: ' + updatedAccount.Status__c);
    }
    
} catch (Exception e) {
    System.debug(LoggingLevel.ERROR, '❌ Batch execution failed: ' + e.getMessage());
    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
}

System.debug(LoggingLevel.INFO, '=== TARGET BATCH UPDATE COMPLETE ===');
