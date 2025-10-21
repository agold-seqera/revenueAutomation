trigger ContractTrigger on Contract (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ContractTriggerHandler.handleAfterInsert(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        ContractTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isAfter && Trigger.isDelete) {
        ContractTriggerHandler.handleAfterDelete(Trigger.old);
    }
    
    if (Trigger.isAfter && Trigger.isUndelete) {
        ContractTriggerHandler.handleAfterUndelete(Trigger.new);
    }
}