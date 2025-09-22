#!/usr/bin/env python3

import os
import xml.etree.ElementTree as ET
from pathlib import Path

# Define all reporting fields by object
REPORTING_FIELDS = {
    'Asset': [
        'MRR_USD_Reporting__c',
        'Price_USD_Reporting__c', 
        'Total_Price_USD_Reporting__c',
        'Total_Value_USD_Reporting__c',
        'Unit_ARR_USD_Reporting__c',
        'Unit_MRR_USD_Reporting__c',
        'Unit_Value_USD_Reporting__c'
    ],
    'Quote': [
        'Annual_Total_USD_Reporting__c',
        'First_Payment_Due_USD_Reporting__c',
        'One_Off_Charges_USD_Reporting__c',
        'TotalPrice_USD_Reporting__c',
        'Total_Payment_Due_USD_Reporting__c'
    ],
    'QuoteLineItem': [
        'Annual_Amount_USD_Reporting__c',
        'ListPrice_USD_Reporting__c',
        'List_Price_USD_Reporting__c',
        'TotalPrice_USD_Reporting__c',
        'Total_Price_USD_Reporting__c',
        'UnitPrice_USD_Reporting__c'
    ],
    'Contract': [
        'ACV_USD_Reporting__c',
        'ARR_USD_Reporting__c',
        'Active_ARR_USD_Reporting__c',
        'Incremental_ARR_USD_Reporting__c',
        'Initial_ACV_USD_Reporting__c',
        'Initial_ARR_USD_Reporting__c',
        'Initial_MRR_USD_Reporting__c',
        'Initial_TCV_USD_Reporting__c',
        'MRR_USD_Reporting__c',
        'Previous_ACV_USD_Reporting__c',
        'Previous_ARR_USD_Reporting__c',
        'Previous_MRR_USD_Reporting__c',
        'Previous_TCV_USD_Reporting__c',
        'TCV_USD_Reporting__c'
    ],
    'Account': [
        'ACV_USD_Reporting__c',
        'ARR_USD_Reporting__c',
        'AnnualRevenue_USD_Reporting__c',
        'Incremental_ARR_USD_Reporting__c',
        'MRR_USD_Reporting__c',
        'Previous_Year_ACV_USD_Reporting__c',
        'Previous_Year_ARR_USD_Reporting__c',
        'Previous_Year_MRR_USD_Reporting__c',
        'Previous_Year_TCV_USD_Reporting__c',
        'TCV_USD_Reporting__c'
    ]
}

def update_profile(profile_path):
    """Update a single profile with all reporting fields"""
    print(f"Updating profile: {profile_path}")
    
    # Parse the XML
    tree = ET.parse(profile_path)
    root = tree.getroot()
    
    # Define namespace
    ns = {'sf': 'http://soap.sforce.com/2006/04/metadata'}
    
    # Track how many fields we add
    fields_added = 0
    
    # Process each object
    for object_name, field_list in REPORTING_FIELDS.items():
        for field_name in field_list:
            # Check if field permission already exists
            existing_field = root.find(f".//sf:fieldPermissions[sf:field='{object_name}.{field_name}']", ns)
            
            if existing_field is None:
                # Create new fieldPermissions element
                field_perm = ET.Element('{http://soap.sforce.com/2006/04/metadata}fieldPermissions')
                
                # Add editable
                editable = ET.SubElement(field_perm, '{http://soap.sforce.com/2006/04/metadata}editable')
                editable.text = 'true'
                
                # Add field
                field_elem = ET.SubElement(field_perm, '{http://soap.sforce.com/2006/04/metadata}field')
                field_elem.text = f'{object_name}.{field_name}'
                
                # Add readable
                readable = ET.SubElement(field_perm, '{http://soap.sforce.com/2006/04/metadata}readable')
                readable.text = 'true'
                
                # Insert in alphabetical order among fieldPermissions
                field_perms = root.findall('.//sf:fieldPermissions', ns)
                
                # Find insertion point
                insertion_index = 0
                for i, existing_perm in enumerate(field_perms):
                    existing_field_name = existing_perm.find('sf:field', ns).text
                    if existing_field_name > f'{object_name}.{field_name}':
                        insertion_index = i
                        break
                    insertion_index = i + 1
                
                # Insert the new field permission
                if field_perms:
                    # Find the position in the root element
                    for i, child in enumerate(root):
                        if child == field_perms[min(insertion_index, len(field_perms) - 1)]:
                            root.insert(i, field_perm)
                            break
                    else:
                        # Append at the end if not found
                        root.append(field_perm)
                else:
                    # No existing field permissions, just append
                    root.append(field_perm)
                
                fields_added += 1
    
    if fields_added > 0:
        # Write back to file
        tree.write(profile_path, encoding='UTF-8', xml_declaration=True)
        print(f"  Added {fields_added} reporting field permissions")
    else:
        print(f"  No new fields needed (all already present)")
    
    return fields_added

def main():
    """Update all profiles in the project"""
    profiles_dir = Path('force-app/main/default/profiles')
    
    if not profiles_dir.exists():
        print(f"Error: Profiles directory not found: {profiles_dir}")
        return
    
    total_fields_added = 0
    profiles_updated = 0
    
    print("=== UPDATING PROFILES WITH REPORTING FIELDS ===")
    print(f"Total reporting fields to add: {sum(len(fields) for fields in REPORTING_FIELDS.values())}")
    print()
    
    # Process each profile
    for profile_file in profiles_dir.glob('*.profile-meta.xml'):
        try:
            fields_added = update_profile(profile_file)
            if fields_added > 0:
                profiles_updated += 1
            total_fields_added += fields_added
        except Exception as e:
            print(f"Error updating {profile_file}: {e}")
    
    print()
    print("=== SUMMARY ===")
    print(f"Profiles processed: {len(list(profiles_dir.glob('*.profile-meta.xml')))}")
    print(f"Profiles updated: {profiles_updated}")
    print(f"Total field permissions added: {total_fields_added}")
    print()
    print("Profile update complete!")

if __name__ == '__main__':
    main()
