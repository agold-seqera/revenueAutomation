// Full batch execution for AstraZeneca (001fJ000021YCvsQAG)
// Execute complete RevenueAutomationBatchManager chain

System.debug(LoggingLevel.INFO, '=== FULL BATCH EXECUTION FOR ASTRAZENECA ===');

String targetAccountId = '001fJ000021YCvsQAG';

// Get baseline account data
Account account = [
    SELECT Id, Name, Status__c, LastModifiedDate
    FROM Account 
    WHERE Id = :targetAccountId
    LIMIT 1
];

System.debug(LoggingLevel.INFO, 'Target Account: ' + account.Name + ' (' + account.Id + ')');
System.debug(LoggingLevel.INFO, 'Current Status: ' + account.Status__c);
System.debug(LoggingLevel.INFO, 'Last Modified: ' + account.LastModifiedDate);

// Get contracts before batch
List<Contract> contractsBefore = [
    SELECT Id, Status, ARR__c, ACV__c, TCV__c, Active_ARR__c, StartDate, EndDate
    FROM Contract 
    WHERE AccountId = :targetAccountId
];

System.debug(LoggingLevel.INFO, '=== PRE-BATCH CONTRACT STATUS ===');
for (Contract contract : contractsBefore) {
    System.debug(LoggingLevel.INFO, 'Contract: ' + contract.Id + 
                                   ' | Status: ' + contract.Status + 
                                   ' | ARR: ' + contract.ARR__c + 
                                   ' | Active_ARR: ' + contract.Active_ARR__c +
                                   ' | ACV: ' + contract.ACV__c +
                                   ' | TCV: ' + contract.TCV__c);
}

System.debug(LoggingLevel.INFO, '=== EXECUTING FULL BATCH CHAIN ===');

// Execute the full RevenueAutomationBatchManager
RevenueAutomationBatchManager batchManager = new RevenueAutomationBatchManager();

try {
    // Schedule the batch manager to run immediately
    DateTime now = DateTime.now();
    DateTime executionTime = now.addMinutes(1);
    
    String cronExpression = String.format(
        '{0} {1} {2} {3} {4} ? {5}',
        new List<String>{
            String.valueOf(executionTime.second()),
            String.valueOf(executionTime.minute()),
            String.valueOf(executionTime.hour()),
            String.valueOf(executionTime.day()),
            String.valueOf(executionTime.month()),
            String.valueOf(executionTime.year())
        }
    );
    
    System.debug(LoggingLevel.INFO, 'Scheduling batch for: ' + executionTime);
    System.debug(LoggingLevel.INFO, 'Cron Expression: ' + cronExpression);
    
    String jobId = System.schedule(
        'AstraZeneca_Full_Batch_' + String.valueOf(now.getTime()), 
        cronExpression, 
        batchManager
    );
    
    System.debug(LoggingLevel.INFO, '✅ BATCH SCHEDULED SUCCESSFULLY');
    System.debug(LoggingLevel.INFO, 'Job ID: ' + jobId);
    System.debug(LoggingLevel.INFO, 'Expected execution: ' + executionTime.format());
    
    System.debug(LoggingLevel.INFO, '📋 MONITORING INSTRUCTIONS:');
    System.debug(LoggingLevel.INFO, '1. Wait ~1-2 minutes for batch to execute');
    System.debug(LoggingLevel.INFO, '2. Check AsyncApexJob records for completion');
    System.debug(LoggingLevel.INFO, '3. Query account and contracts after completion');
    
    System.debug(LoggingLevel.INFO, 'Monitor with:');
    System.debug(LoggingLevel.INFO, 'SELECT Id, Status, ApexClass.Name, CreatedDate FROM AsyncApexJob WHERE CreatedDate >= ' + now.format('yyyy-MM-dd\'T\'HH:mm:ss\'.000+0000\''));
    
} catch (Exception e) {
    System.debug(LoggingLevel.ERROR, '❌ Batch scheduling failed: ' + e.getMessage());
    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
}

System.debug(LoggingLevel.INFO, '=== FULL BATCH EXECUTION INITIATED ===');
