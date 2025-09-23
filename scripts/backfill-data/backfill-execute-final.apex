// Backfill Script for USD Field Alignment - All Contracts
// The updated ContractRevenueBatch logic will automatically process expired contracts with USD field alignment

System.debug('Starting USD field alignment backfill for expired contracts');

// Execute ContractRevenueBatch on all contracts - the new logic will handle USD field alignment for expired contracts
Id batchId = Database.executeBatch(new ContractRevenueBatch(), 200);

System.debug('Backfill batch submitted successfully with ID: ' + batchId);
System.debug('The batch will process all contracts, updating USD fields for expired contracts where needed');
