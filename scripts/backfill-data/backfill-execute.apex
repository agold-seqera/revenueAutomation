// Backfill Script for USD Field Alignment
// Extract Contract IDs from CSV and run ContractRevenueBatch

List<Id> contractIds = new List<Id>{

    '800fJ000007eMmPQAU',
    '800fJ000007eNCLQA2',
    '800fJ000007eMm7QAE',
    '800fJ000007eNCJQA2',
    '800fJ000007eNCIQA2',
    '800fJ000007eMlnQAE',
    '800fJ000007eLC8QAM',
    '800fJ000007eLC5QAM',
    '800fJ000007eLC3QAM',
    '800fJ000007eNLVQA2',
    '800fJ000007eLqdQAE',
    '800fJ000007eNCDQA2',
    '800fJ000007eNC5QAM',
    '800fJ000007eMGKQA2',
    '800fJ000007eMG7QAM',
    '800fJ000007eI34QAE',
    '800fJ000007eI30QAE',
    '800fJ000007eNLOQA2',
    '800fJ000008Q7vxQAC',
    '800fJ000007eMbdQAE',
    '800fJ000007eMbSQAU',
    '800fJ000007eMbFQAU',
    '800fJ000007eNLLQA2',
    '800fJ000007eNBmQAM',
    '800fJ000007eI2wQAE',
    '800fJ000007eNBdQAM',
    '800fJ000007eNBaQAM',
    '800fJ000007eMlwQAE',
    '800fJ000007eMmSQAU',
    '800fJ000007eLBfQAM',
    '800fJ000007eLBVQA2',
    '800fJ000007eNCCQA2',
    '800fJ000007eLq8QAE',
    '800fJ000007ei38QAA',
    '800fJ000007eMFgQAM',
    '800fJ000007eI3HQAU',
    '800fJ000007eI2MQAU',
    '800fJ000007eLq9QAE',
    '800fJ000007eMbQQAU',
    '800fJ000007eNBjQAM',
    '800fJ000007eNBgQAM',
};

System.debug('Starting backfill for ' + contractIds.size() + ' expired contracts');

// Execute ContractRevenueBatch for the specific contracts
Database.executeBatch(new ContractRevenueBatch(contractIds), 200);

System.debug('Backfill batch submitted successfully');
