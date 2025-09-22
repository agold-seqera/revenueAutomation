// INVENTORY ALL USD FIELDS ACROSS OBJECTS
// Pull USD fields from Opportunity, OLI, Quote, QLI, Asset, Contract, Account
System.debug('=== USD FIELDS INVENTORY ACROSS ALL OBJECTS ===');

// Helper method to describe fields for an object
Map<String, Object> describeObject(String objectName) {
    Map<String, Object> result = new Map<String, Object>();
    
    try {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType != null) {
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            
            List<String> usdFields = new List<String>();
            
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                String label = fieldDescribe.getLabel();
                String name = fieldDescribe.getName();
                
                // Look for USD in field name or label
                if (name.toLowerCase().contains('usd') || label.toLowerCase().contains('usd')) {
                    String fieldType = String.valueOf(fieldDescribe.getType());
                    Boolean isCustom = fieldDescribe.isCustom();
                    Boolean isFormula = fieldDescribe.isCalculated();
                    
                    String fieldInfo = name + ' (' + label + ') - Type: ' + fieldType;
                    if (isCustom) fieldInfo += ' [Custom]';
                    if (isFormula) fieldInfo += ' [Formula]';
                    
                    usdFields.add(fieldInfo);
                }
            }
            
            result.put('objectName', objectName);
            result.put('usdFields', usdFields);
            result.put('fieldCount', usdFields.size());
            
        } else {
            result.put('objectName', objectName);
            result.put('error', 'Object not found');
        }
    } catch (Exception e) {
        result.put('objectName', objectName);
        result.put('error', e.getMessage());
    }
    
    return result;
}

// Check each object
List<String> objectsToCheck = new List<String>{
    'Opportunity',
    'OpportunityLineItem', 
    'Quote',
    'QuoteLineItem',
    'Asset',
    'Contract',
    'Account'
};

List<Map<String, Object>> allResults = new List<Map<String, Object>>();
Integer totalUSDFields = 0;

for (String objectName : objectsToCheck) {
    Map<String, Object> result = describeObject(objectName);
    allResults.add(result);
    
    if (result.containsKey('fieldCount')) {
        totalUSDFields += (Integer)result.get('fieldCount');
    }
}

// Display results
System.debug('');
System.debug('=== USD FIELDS BY OBJECT ===');

for (Map<String, Object> result : allResults) {
    String objectName = (String)result.get('objectName');
    
    if (result.containsKey('error')) {
        System.debug('');
        System.debug('❌ ' + objectName + ': ' + result.get('error'));
        continue;
    }
    
    List<String> usdFields = (List<String>)result.get('usdFields');
    Integer fieldCount = (Integer)result.get('fieldCount');
    
    System.debug('');
    System.debug('=== ' + objectName.toUpperCase() + ' (' + fieldCount + ' USD fields) ===');
    
    if (fieldCount == 0) {
        System.debug('  No USD fields found');
    } else {
        for (String fieldInfo : usdFields) {
            System.debug('  • ' + fieldInfo);
        }
    }
}

System.debug('');
System.debug('=== SUMMARY ===');
System.debug('Total objects checked: ' + objectsToCheck.size());
System.debug('Total USD fields found: ' + totalUSDFields);

// Breakdown by object
System.debug('');
System.debug('BREAKDOWN BY OBJECT:');
for (Map<String, Object> result : allResults) {
    String objectName = (String)result.get('objectName');
    if (result.containsKey('fieldCount')) {
        Integer count = (Integer)result.get('fieldCount');
        System.debug('- ' + objectName + ': ' + count + ' USD fields');
    } else if (result.containsKey('error')) {
        System.debug('- ' + objectName + ': ERROR - ' + result.get('error'));
    }
}

System.debug('');
System.debug('=== NOTES FOR REPORTING FIELDS ===');
System.debug('Based on this inventory, we will need to create Number(16,2) reporting fields for:');
System.debug('- Each text USD field that needs aggregation capabilities');
System.debug('- Fields should be named like: Original_Field_Name_Reporting__c');
System.debug('- Label format: "FieldName (Reporting)"');
System.debug('- Description: "USD value in Number format for SFDC reporting and aggregation"');
System.debug('- Help text: "This field contains the same USD value as [Original Field] but in Number format to enable Salesforce reporting, rollups, and calculations."');

System.debug('');
System.debug('=== END USD FIELDS INVENTORY ===');
