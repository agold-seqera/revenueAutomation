// Debug and fix the specific account reporting fields issue
System.debug('=== Debugging Account Reporting Fields Issue ===');

// Check the specific account
Account targetAccount = [
    SELECT Id, Name, ARR_USD__c, ACV_USD__c, TCV_USD__c, MRR_USD__c,
           ARR_USD_Reporting__c, ACV_USD_Reporting__c, TCV_USD_Reporting__c, MRR_USD_Reporting__c
    FROM Account 
    WHERE Id = '001fJ000021YDzUQAW'
];

System.debug('BEFORE Fix - Account: ' + targetAccount.Name);
System.debug('  ARR_USD__c: "' + targetAccount.ARR_USD__c + '"');
System.debug('  ARR_USD_Reporting__c: ' + targetAccount.ARR_USD_Reporting__c);
System.debug('  ACV_USD__c: "' + targetAccount.ACV_USD__c + '"');
System.debug('  ACV_USD_Reporting__c: ' + targetAccount.ACV_USD_Reporting__c);

// Test the parsing logic step by step
System.debug('\n--- Testing Parsing Logic ---');

if (targetAccount.ARR_USD__c != null) {
    String original = targetAccount.ARR_USD__c;
    System.debug('Original ARR_USD__c: "' + original + '"');
    
    String step1 = original.replace('$', '');
    System.debug('After removing $: "' + step1 + '"');
    
    String step2 = step1.replace(',', '');
    System.debug('After removing commas: "' + step2 + '"');
    
    try {
        Decimal parsed = Decimal.valueOf(step2);
        System.debug('Successfully parsed to: ' + parsed);
        
        // Update the account
        targetAccount.ARR_USD_Reporting__c = parsed;
        System.debug('Set ARR_USD_Reporting__c to: ' + parsed);
        
    } catch (Exception e) {
        System.debug('ERROR parsing ARR_USD: ' + e.getMessage());
    }
}

if (targetAccount.ACV_USD__c != null) {
    String original = targetAccount.ACV_USD__c;
    String cleaned = original.replace('$', '').replace(',', '');
    try {
        Decimal parsed = Decimal.valueOf(cleaned);
        targetAccount.ACV_USD_Reporting__c = parsed;
        System.debug('Set ACV_USD_Reporting__c to: ' + parsed);
    } catch (Exception e) {
        System.debug('ERROR parsing ACV_USD: ' + e.getMessage());
    }
}

if (targetAccount.TCV_USD__c != null) {
    String original = targetAccount.TCV_USD__c;
    String cleaned = original.replace('$', '').replace(',', '');
    try {
        Decimal parsed = Decimal.valueOf(cleaned);
        targetAccount.TCV_USD_Reporting__c = parsed;
        System.debug('Set TCV_USD_Reporting__c to: ' + parsed);
    } catch (Exception e) {
        System.debug('ERROR parsing TCV_USD: ' + e.getMessage());
    }
}

if (targetAccount.MRR_USD__c != null) {
    String original = targetAccount.MRR_USD__c;
    String cleaned = original.replace('$', '').replace(',', '');
    try {
        Decimal parsed = Decimal.valueOf(cleaned);
        targetAccount.MRR_USD_Reporting__c = parsed;
        System.debug('Set MRR_USD_Reporting__c to: ' + parsed);
    } catch (Exception e) {
        System.debug('ERROR parsing MRR_USD: ' + e.getMessage());
    }
}

// Update the account
System.debug('\n--- Updating Account ---');
update targetAccount;

// Verify the fix
Account verifyAccount = [
    SELECT Id, Name, ARR_USD__c, ARR_USD_Reporting__c, ACV_USD__c, ACV_USD_Reporting__c,
           TCV_USD__c, TCV_USD_Reporting__c, MRR_USD__c, MRR_USD_Reporting__c
    FROM Account 
    WHERE Id = '001fJ000021YDzUQAW'
];

System.debug('\nAFTER Fix - Account: ' + verifyAccount.Name);
System.debug('  ARR_USD__c: "' + verifyAccount.ARR_USD__c + '" → ARR_USD_Reporting__c: ' + verifyAccount.ARR_USD_Reporting__c);
System.debug('  ACV_USD__c: "' + verifyAccount.ACV_USD__c + '" → ACV_USD_Reporting__c: ' + verifyAccount.ACV_USD_Reporting__c);
System.debug('  TCV_USD__c: "' + verifyAccount.TCV_USD__c + '" → TCV_USD_Reporting__c: ' + verifyAccount.TCV_USD_Reporting__c);
System.debug('  MRR_USD__c: "' + verifyAccount.MRR_USD__c + '" → MRR_USD_Reporting__c: ' + verifyAccount.MRR_USD_Reporting__c);

Boolean allPopulated = 
    verifyAccount.ARR_USD_Reporting__c != null && verifyAccount.ARR_USD_Reporting__c != 0 &&
    verifyAccount.ACV_USD_Reporting__c != null && verifyAccount.ACV_USD_Reporting__c != 0 &&
    verifyAccount.TCV_USD_Reporting__c != null && verifyAccount.TCV_USD_Reporting__c != 0 &&
    verifyAccount.MRR_USD_Reporting__c != null && verifyAccount.MRR_USD_Reporting__c != 0;

System.debug('\n✅ All reporting fields correctly populated: ' + allPopulated);

System.debug('=== Debug Complete ===');
