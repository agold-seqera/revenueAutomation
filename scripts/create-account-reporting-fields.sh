#!/bin/bash

# Create all Account reporting fields

# ACV_USD_Reporting__c
cat > force-app/main/default/objects/Account/fields/ACV_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>ACV_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as ACV USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>ACV (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# ARR_USD_Reporting__c
cat > force-app/main/default/objects/Account/fields/ARR_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>ARR_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as ARR USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>ARR (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# AnnualRevenue_USD_Reporting__c
cat > force-app/main/default/objects/Account/fields/AnnualRevenue_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>AnnualRevenue_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Annual Revenue USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Annual Revenue (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Incremental_ARR_USD_Reporting__c
cat > force-app/main/default/objects/Account/fields/Incremental_ARR_USD_Reporting__c.field-meta.xml << 'EOF'
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

# MRR_USD_Reporting__c
cat > force-app/main/default/objects/Account/fields/MRR_USD_Reporting__c.field-meta.xml << 'EOF'
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

# Previous_Year_ACV_USD_Reporting__c
cat > force-app/main/default/objects/Account/fields/Previous_Year_ACV_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Previous_Year_ACV_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Previous Year ACV USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Previous Year ACV (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Previous_Year_ARR_USD_Reporting__c
cat > force-app/main/default/objects/Account/fields/Previous_Year_ARR_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Previous_Year_ARR_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Previous Year ARR USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Previous Year ARR (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Previous_Year_MRR_USD_Reporting__c
cat > force-app/main/default/objects/Account/fields/Previous_Year_MRR_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Previous_Year_MRR_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Previous Year MRR USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Previous Year MRR (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# Previous_Year_TCV_USD_Reporting__c
cat > force-app/main/default/objects/Account/fields/Previous_Year_TCV_USD_Reporting__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Previous_Year_TCV_USD_Reporting__c</fullName>
    <description>USD value in Number format for SFDC reporting and aggregation</description>
    <externalId>false</externalId>
    <inlineHelpText>This field contains the same USD value as Previous Year TCV USD but in Number format to enable Salesforce reporting, rollups, and calculations.</inlineHelpText>
    <label>Previous Year TCV (Reporting)</label>
    <precision>16</precision>
    <required>false</required>
    <scale>2</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
EOF

# TCV_USD_Reporting__c
cat > force-app/main/default/objects/Account/fields/TCV_USD_Reporting__c.field-meta.xml << 'EOF'
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

echo "Created all Account reporting fields!"
