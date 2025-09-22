// Test if the current user (when running in scheduled context) can update Contract revenue fields
System.debug('=== Testing Automated Process User Permissions ===');

// Get current user info
User currentUser = [SELECT Id, Name, Alias, UserType, ProfileId FROM User WHERE Id = :UserInfo.getUserId()];
System.debug('Current User: ' + currentUser.Name + ' (' + currentUser.Alias + ')');
System.debug('User Type: ' + currentUser.UserType);
System.debug('Profile ID: ' + currentUser.ProfileId);

// Test field accessibility by attempting to query and update specific fields
System.debug('\n--- Testing Field Access ---');

try {
    // Test 1: Can we query the revenue fields?
    List<Contract> testQuery = [
        SELECT Id, ARR__c, ACV__c, TCV__c, ARR_USD__c, ACV_USD__c
        FROM Contract 
        WHERE Id = '800fJ000007eNJeQAM'
    ];
    
    System.debug('✅ Can query revenue fields: ' + testQuery.size() + ' records');
    
    Contract testContract = testQuery[0];
    System.debug('  Current ARR__c: ' + testContract.ARR__c);
    System.debug('  Current ACV__c: ' + testContract.ACV__c);
    System.debug('  Current ARR_USD__c: ' + testContract.ARR_USD__c);
    
} catch (Exception e) {
    System.debug('❌ Cannot query revenue fields: ' + e.getMessage());
    return;
}

try {
    // Test 2: Can we update the revenue fields?
    Contract updateTest = new Contract(
        Id = '800fJ000007eNJeQAM',
        ARR__c = 999999,  // Test value
        ACV__c = 888888   // Test value
    );
    
    update updateTest;
    System.debug('✅ Can update revenue fields successfully');
    
    // Immediately revert
    Contract revertTest = new Contract(
        Id = '800fJ000007eNJeQAM',
        ARR__c = 550000,  // Back to test value
        ACV__c = 650000   // Back to test value
    );
    
    update revertTest;
    System.debug('✅ Reverted values for continued testing');
    
} catch (Exception e) {
    System.debug('❌ Cannot update revenue fields: ' + e.getMessage());
    System.debug('❌ Error Type: ' + e.getTypeName());
    System.debug('❌ This could be the root cause of scheduled batch failures!');
    return;
}

try {
    // Test 3: Can we update USD text fields?
    Contract usdTest = new Contract(
        Id = '800fJ000007eNJeQAM',
        ARR_USD__c = '$999,999.00',
        ACV_USD__c = '$888,888.00'
    );
    
    update usdTest;
    System.debug('✅ Can update USD text fields successfully');
    
} catch (Exception e) {
    System.debug('❌ Cannot update USD text fields: ' + e.getMessage());
    System.debug('❌ Error Type: ' + e.getTypeName());
}

// Test 4: Check object-level permissions
try {
    Schema.DescribeSObjectResult contractDescribe = Contract.sObjectType.getDescribe();
    System.debug('Contract Object Permissions:');
    System.debug('  Accessible: ' + contractDescribe.isAccessible());
    System.debug('  Creatable: ' + contractDescribe.isCreateable());
    System.debug('  Updateable: ' + contractDescribe.isUpdateable());
    System.debug('  Deletable: ' + contractDescribe.isDeletable());
    
} catch (Exception e) {
    System.debug('❌ Cannot check Contract object permissions: ' + e.getMessage());
}

System.debug('\n=== Permission Test Complete ===');
System.debug('If all tests passed, permissions are NOT the issue');
System.debug('If any tests failed, we found the root cause!');
