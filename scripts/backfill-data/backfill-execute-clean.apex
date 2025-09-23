// Backfill Script for USD Field Alignment - 41 Expired Contracts
List<Id> contractIds = new List<Id>();
contractIds.add('800fJ000007eMmPQAU');
contractIds.add('800fJ000007eNCLQA2');
contractIds.add('800fJ000007eMm7QAE');
contractIds.add('800fJ000007eNCJQA2');
contractIds.add('800fJ000007eNCIQA2');
contractIds.add('800fJ000007eMlnQAE');
contractIds.add('800fJ000007eLC8QAM');
contractIds.add('800fJ000007eLC5QAM');
contractIds.add('800fJ000007eLC3QAM');
contractIds.add('800fJ000007eNLVQA2');
contractIds.add('800fJ000007eLqdQAE');
contractIds.add('800fJ000007eNCDQA2');
contractIds.add('800fJ000007eNC5QAM');
contractIds.add('800fJ000007eMGKQA2');
contractIds.add('800fJ000007eMG7QAM');
contractIds.add('800fJ000007eI34QAE');
contractIds.add('800fJ000007eI30QAE');
contractIds.add('800fJ000007eNLOQA2');
contractIds.add('800fJ000008Q7vxQAC');
contractIds.add('800fJ000007eMbdQAE');
contractIds.add('800fJ000007eMbSQAU');
contractIds.add('800fJ000007eMbFQAU');
contractIds.add('800fJ000007eNLLQA2');
contractIds.add('800fJ000007eNBmQAM');
contractIds.add('800fJ000007eI2wQAE');
contractIds.add('800fJ000007eNBdQAM');
contractIds.add('800fJ000007eNBaQAM');
contractIds.add('800fJ000007eMlwQAE');
contractIds.add('800fJ000007eMmSQAU');
contractIds.add('800fJ000007eLBfQAM');
contractIds.add('800fJ000007eLBVQA2');
contractIds.add('800fJ000007eNCCQA2');
contractIds.add('800fJ000007eLq8QAE');
contractIds.add('800fJ000007ei38QAA');
contractIds.add('800fJ000007eMFgQAM');
contractIds.add('800fJ000007eI3HQAU');
contractIds.add('800fJ000007eI2MQAU');
contractIds.add('800fJ000007eLq9QAE');
contractIds.add('800fJ000007eMbQQAU');
contractIds.add('800fJ000007eNBjQAM');
contractIds.add('800fJ000007eNBgQAM');

System.debug('Starting USD field alignment backfill for ' + contractIds.size() + ' expired contracts');

// Execute ContractRevenueBatch for the specific contracts
Id batchId = Database.executeBatch(new ContractRevenueBatch(contractIds), 200);

System.debug('Backfill batch submitted successfully with ID: ' + batchId);
