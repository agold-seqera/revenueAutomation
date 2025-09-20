// Execute Contract Revenue Batch to populate all revenue fields
ContractRevenueBatch batch = new ContractRevenueBatch();
Database.executeBatch(batch, 200);
System.debug('ContractRevenueBatch started - this will populate ARR, ACV, TCV, MRR fields on all Contracts');
