# Salesforce Apex batch processing silent failures: Why scheduled jobs complete but don't update records

When the ContractRevenueBatch.processContract() method works perfectly in manual execution but silently fails to update Contract 800fJ000007eNJeQAM's ARR/ACV values from 550,000/650,000 to 300,000 in scheduled runs, you're experiencing one of Salesforce's most challenging debugging scenarios. This comprehensive analysis reveals the root causes and provides actionable solutions based on extensive research into Salesforce's batch processing architecture.

## The Automated Process user creates a fundamentally different execution context

The core issue lies in how Salesforce handles scheduled vs manual batch execution contexts. When you manually execute Database.executeBatch(), the job runs with your user credentials and permissions. However, scheduled batch jobs run under the **Automated Process user** (username: autoproc), a special system user with minimal default permissions that cannot be managed through the standard UI.

This context switch creates three critical differences. First, the Automated Process user may lack field-level security permissions on custom fields like ARR_USD__c and ACV_USD__c, causing DML operations to fail silently. Second, this user exists outside the role hierarchy and sharing rules, potentially blocking access to related records needed for revenue calculations. Third, debug logs for this user require specific trace flag configuration and have different retention policies, making troubleshooting significantly harder.

**Immediate solution:** Configure a Default Workflow User in Setup → Process Automation Settings (available in API v53.0+) to assign a real user account with appropriate permissions for scheduled operations. This eliminates the Automated Process user limitations while maintaining automation capabilities.

## Governor limits behave differently across execution contexts

Scheduled batch execution operates with **asynchronous governor limits** while manual execution in Developer Console uses **synchronous limits**, creating substantial operational differences that can mask critical issues during testing.

The heap size limit doubles from 6MB (synchronous) to 12MB (asynchronous) in scheduled execution. CPU time extends from 10 seconds to 60 seconds. SOQL query limits increase from 100 to 200. These differences mean code that appears to work in scheduled execution might fail when tested manually, or more critically, code that barely works in manual testing might hit different limits when scheduled with larger data volumes.

For the ContractRevenueBatch issue, complex revenue calculations involving multiple related objects (Assets, Opportunities, Subscriptions) likely consume different amounts of heap memory and CPU time depending on the execution context. The scheduled batch may be hitting memory pressure that doesn't manifest in manual testing, causing partial processing failures.

## Silent exception handling patterns mask critical failures

The research reveals a common anti-pattern where try-catch blocks in batch apex swallow exceptions without proper logging, creating "ghost errors" that leave no trace in AsyncApexJob monitoring.

```apex
// This pattern causes silent failures
public void execute(Database.BatchableContext BC, List<sObject> scope){
    try {
        database.update(records, false); // allOrNone=false allows partial success
    } catch(Exception e) {
        System.debug('Error: ' + e.getMessage()); // Debug won't persist in scheduled context
        // No re-throw means AsyncApexJob shows "Completed" with no errors
    }
}
```

When Database.update uses allOrNone=false, partial failures don't throw exceptions. Combined with insufficient error handling, this creates scenarios where the batch "completes successfully" while silently failing to update specific records. The scheduled context's limited debug log retention makes these failures invisible.

**Critical implementation:** Add the Database.RaisesPlatformEvents interface to your batch class. This automatically publishes BatchApexErrorEvent records for uncaught exceptions, capturing even uncatchable limit exceptions that standard try-catch blocks miss.

## Data state timing and race conditions cause inconsistent updates

The most likely root cause for Contract 800fJ000007eNJeQAM's update failure involves **race conditions between concurrent batch processes**. Multiple scheduled batches processing related records simultaneously create complex timing scenarios unique to the automated execution environment.

When the RevenueAutomationBatchManager triggers multiple batch processes, they compete for record locks on the same Contract. The Asset-to-Contract relationship creates a bottleneck where updating child Assets locks the parent Contract. If one batch reads the Contract's original ARR value (550,000) while another batch is mid-calculation, the "last writer wins" pattern causes the intended update to 300,000 to be overwritten with stale data.

Manual execution avoids these race conditions because you control the execution timing and typically process smaller data sets without concurrent operations. The scheduled environment's parallel processing capabilities, while powerful, introduce timing complexities absent in manual testing.

## Advanced debugging reveals the hidden execution differences

Implementing comprehensive monitoring uncovers the specific failure patterns affecting your ContractRevenueBatch. Deploy this diagnostic framework to capture the execution context differences:

```apex
public class ContractRevenueBatch implements Database.Batchable<sObject>, 
                                            Database.Stateful, 
                                            Database.RaisesPlatformEvents {
    
    private String executionContext;
    private List<String> processingErrors = new List<String>();
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Identify execution context
        User currentUser = [SELECT Id, Name, Alias FROM User WHERE Id = :UserInfo.getUserId()];
        executionContext = (currentUser.Alias == 'autoproc') ? 'SCHEDULED' : 'MANUAL';
        
        // Use FOR UPDATE to prevent concurrent access
        return Database.getQueryLocator([
            SELECT Id, ARR_USD__c, ACV_USD__c 
            FROM Contract 
            WHERE Status = 'Active' 
            FOR UPDATE
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<Contract> scope) {
        // Monitor resource consumption
        System.debug('Heap before: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());
        
        Savepoint sp = Database.setSavepoint();
        try {
            processContracts(scope);
            
            Database.SaveResult[] results = Database.update(scope, false);
            captureUpdateFailures(results, scope);
            
        } catch(Exception e) {
            Database.rollback(sp);
            processingErrors.add('Batch failed: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
            // Don't swallow - let platform events capture it
            throw e;
        }
    }
    
    private void captureUpdateFailures(Database.SaveResult[] results, List<Contract> contracts) {
        for(Integer i = 0; i < results.size(); i++) {
            if(!results[i].isSuccess()) {
                String errorMsg = 'Contract ' + contracts[i].Id + ' update failed: ';
                for(Database.Error err : results[i].getErrors()) {
                    errorMsg += err.getStatusCode() + ': ' + err.getMessage();
                    // Critical: Log field-level errors
                    if(!err.getFields().isEmpty()) {
                        errorMsg += ' Fields: ' + String.join(err.getFields(), ',');
                    }
                }
                processingErrors.add(errorMsg);
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        if(!processingErrors.isEmpty()) {
            // Send detailed error report
            sendErrorNotification(BC.getJobId(), processingErrors);
        }
    }
}
```

## Immediate actions to resolve the ContractRevenueBatch issue

1. **Implement record locking with FOR UPDATE** in your start() method query to ensure exclusive access during revenue calculations and prevent concurrent modifications.

2. **Add comprehensive SaveResult analysis** after Database.update operations. The allOrNone=false parameter masks individual record failures that only surface through careful result inspection.

3. **Configure Default Workflow User** or assign appropriate permission sets to the Automated Process user to ensure field-level access to ARR_USD__c and ACV_USD__c fields.

4. **Deploy BatchApexErrorEvent monitoring** by implementing Database.RaisesPlatformEvents and creating a trigger to capture and alert on batch failures that don't surface in AsyncApexJob.

5. **Sequence batch processing** to prevent concurrent execution conflicts. Check AsyncApexJob before starting new batches to ensure the previous ContractRevenueBatch has completed.

## Long-term architectural improvements

The research reveals that Salesforce batch processing requires a fundamentally different architecture for scheduled vs manual execution. Building robust batch jobs demands designing for the scheduled context from the outset, not retrofitting manually-tested code.

Implement a **batch coordination framework** using Platform Events to orchestrate multiple batch processes, preventing race conditions through controlled execution sequencing. Create **custom logging objects** that persist regardless of transaction rollbacks, providing audit trails independent of debug logs. Develop **adaptive batch sizing** that adjusts based on execution context, leveraging the higher limits in scheduled execution while avoiding timeouts.

Most critically, establish **dual-context testing protocols** that validate batch behavior in both manual and scheduled contexts with production-scale data volumes. The subtle differences in permissions, governor limits, exception handling, and timing between these contexts make this comprehensive testing essential for preventing silent failures.

## Conclusion

The ContractRevenueBatch silent failure represents a perfect storm of Salesforce platform complexities: user context switches, governor limit variations, inadequate exception handling, and race conditions between concurrent processes. While manual execution's immediate feedback and generous debugging capabilities mask these issues, the scheduled execution environment's constraints expose them dramatically.

By implementing the diagnostic techniques and architectural patterns identified in this research, you can transform unreliable batch processes into robust, observable systems that perform consistently across all execution contexts. The key insight is that scheduled batch processing isn't simply automated manual processing—it's a fundamentally different execution paradigm requiring purpose-built solutions.