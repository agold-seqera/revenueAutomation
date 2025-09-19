trigger ContractTrigger on Contract (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        ContractTriggerHandler.handleAfterInsertUpdate(Trigger.new, Trigger.oldMap);
    }
    
    // Handle delete and undelete for account field updates
    if (Trigger.isAfter && (Trigger.isDelete || Trigger.isUndelete)) {
        ContractTriggerHandler.handleAccountFieldUpdates(
            Trigger.isDelete ? Trigger.old : Trigger.new, 
            Trigger.operationType
        );
    }
}