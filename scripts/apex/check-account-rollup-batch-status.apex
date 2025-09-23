// Check the status of the AccountRollupBatch job we started
System.debug('=== CHECKING ACCOUNTROLLUPBATCH JOB STATUS ===');

// Check the job we started: 707Pn0000212HGLIA2
Id jobId = '707Pn0000212HGLIA2';

AsyncApexJob job = [
    SELECT Id, Status, JobType, MethodName, JobItemsProcessed, TotalJobItems, 
           NumberOfErrors, CompletedDate, CreatedDate
    FROM AsyncApexJob 
    WHERE Id = :jobId
];

System.debug('Job ID: ' + job.Id);
System.debug('Status: ' + job.Status);
System.debug('Job Type: ' + job.JobType);
System.debug('Method: ' + job.MethodName);
System.debug('Items Processed: ' + job.JobItemsProcessed + ' / ' + job.TotalJobItems);
System.debug('Errors: ' + job.NumberOfErrors);
System.debug('Created: ' + job.CreatedDate);
System.debug('Completed: ' + job.CompletedDate);

System.debug('=== JOB STATUS CHECK COMPLETE ===');
