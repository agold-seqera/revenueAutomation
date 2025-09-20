// Process ALL opportunities with Contract Start Date in batches
System.debug('=== PROCESSING ALL OPPORTUNITIES WITH CONTRACT START DATE (BATCH APPROACH) ===');

// First, count how many we have
Integer totalCount = [
    SELECT COUNT() 
    FROM Opportunity 
    WHERE Contract_Start_Date__c != null
];

System.debug('Total Opportunities with Contract Start Date: ' + totalCount);

// Process in batches of 200
Integer batchSize = 200;
Integer offset = 0;
Integer totalProcessed = 0;

while (offset < totalCount) {
    System.debug('Processing batch starting at offset: ' + offset);
    
    List<Opportunity> oppsToUpdate = [
        SELECT Id, Name, Contract_Start_Date__c, Description, StageName
        FROM Opportunity 
        WHERE Contract_Start_Date__c != null
        ORDER BY Id
        LIMIT :batchSize
        OFFSET :offset
    ];
    
    System.debug('Found ' + oppsToUpdate.size() + ' Opportunities in this batch');
    
    if (!oppsToUpdate.isEmpty()) {
        for (Opportunity opp : oppsToUpdate) {
            // Only update if not already processed (check description)
            if (opp.Description == null || !opp.Description.contains('[First Year Logic Triggered]')) {
                opp.Description = (opp.Description != null ? opp.Description : '') + ' [First Year Logic Triggered]';
            }
        }
        
        update oppsToUpdate;
        totalProcessed += oppsToUpdate.size();
        System.debug('Updated ' + oppsToUpdate.size() + ' Opportunities in this batch');
    }
    
    offset += batchSize;
    
    // Safety break to avoid infinite loops
    if (offset > 10000) {
        System.debug('Safety break: processed 10,000+ records');
        break;
    }
}

System.debug('=== COMPLETED: Processed ' + totalProcessed + ' total Opportunities ===');
