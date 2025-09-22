#!/bin/bash

# Create remaining Contract reporting fields

# Active_ARR_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/Active_ARR_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Active_ARR_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Active ARR USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Active ARR (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Incremental_ARR_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/Incremental_ARR_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Incremental_ARR_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Incremental ARR USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Incremental ARR (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Initial_ACV_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/Initial_ACV_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Initial_ACV_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Initial ACV USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Initial ACV (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Initial_ARR_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/Initial_ARR_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Initial_ARR_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Initial ARR USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Initial ARR (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Initial_MRR_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/Initial_MRR_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Initial_MRR_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Initial MRR USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Initial MRR (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Initial_TCV_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/Initial_TCV_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Initial_TCV_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Initial TCV USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Initial TCV (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# MRR_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/MRR_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>MRR_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as MRR USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>MRR (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Previous_ACV_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/Previous_ACV_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Previous_ACV_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Previous ACV USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Previous ACV (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Previous_ARR_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/Previous_ARR_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Previous_ARR_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Previous ARR USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Previous ARR (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Previous_MRR_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/Previous_MRR_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Previous_MRR_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Previous MRR USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Previous MRR (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Previous_TCV_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/Previous_TCV_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Previous_TCV_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Previous TCV USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Previous TCV (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# TCV_USD_Reporting__c
cat > force-app/main/default/objects/Contract/fields/TCV_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>TCV_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as TCV USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>TCV (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

echo "Created all remaining Contract reporting fields!"
