# Account Flow Optimization Implementation Plan

**Document Purpose:** Step-by-step implementation guide for Account flow scalability optimization  
**Created:** September 18, 2025  
**Target:** GL-Live deployment readiness  
**Impact:** 95% reduction in daily flow interviews (11,548 → ~500-1,000)

---

## 🎯 **Implementation Overview**

**Goal:** Optimize Account flow to process only accounts with contracts  
**Method:** Add filtering field + Contract trigger for population  
**Timeline:** 1-2 days implementation  
**Risk Level:** ✅ LOW (additive changes only)

---

## 📋 **Step-by-Step Implementation Actions**

### **STEP 1: Database Schema Changes**

#### **1.1 Create Custom Fields on Account Object**

**Field 1: Has_Contracts__c (Primary Filter Field)**
```yaml
Field Label: Has Contracts
API Name: Has_Contracts__c
Data Type: Checkbox
Default Value: false
Required: No
Unique: No
External ID: No
Description: "Indicates if this account has one or more contracts (any status). Used by Account flow for performance optimization."
Help Text: "Automatically populated by Contract trigger. Do not manually edit."
```

**Field 2: Contract_Count__c (Monitoring/Insights Field)**
```yaml
Field Label: Contract Count
API Name: Contract_Count__c
Data Type: Number (16, 0)
Default Value: 0
Required: No
Unique: No
External ID: No
Description: "Total number of contracts on this account (any status). Used for monitoring and business insights."
Help Text: "Automatically populated by Contract trigger. Do not manually edit."
```

#### **1.2 Field Security and Permissions**
```yaml
Profile Access:
  - System Administrator: Read/Write
  - Revenue Operations: Read Only
  - Sales Team: Read Only
  - Standard User: Hidden

Page Layout Placement:
  - Account Detail Layout: "Contract Information" section
  - Display as Read-Only fields
  - Position after existing contract-related fields
```

### **STEP 2: Contract Trigger Implementation**

#### **2.1 Create Record-Triggered Flow: Contract_Account_Field_Update**

**Flow Configuration:**
```yaml
Flow Type: Record-Triggered Flow
Object: Contract
Trigger Events: 
  - Create: After Save
  - Update: After Save  
  - Delete: After Delete
  - Undelete: After Save
Run: Asynchronously (for bulk operations)
Entry Conditions: None (process all Contract changes)
```

#### **2.2 Flow Logic Design**

**Flow Elements:**

**Element 1: Get Related Account**
```xml
<recordLookups>
    <name>Get_Account</name>
    <label>Get Related Account</label>
    <locationX>176</locationX>
    <locationY>158</locationY>
    <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
    <connector>
        <targetReference>Get_Contract_Count</targetReference>
    </connector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>Id</field>
        <operator>EqualTo</operator>
        <value>
            <elementReference>$Record.AccountId</elementReference>
        </value>
    </filters>
    <getFirstRecordOnly>true</getFirstRecordOnly>
    <object>Account</object>
    <storeOutputAutomatically>true</storeOutputAutomatically>
    <queriedFields>Id</queriedFields>
    <queriedFields>Has_Contracts__c</queriedFields>
    <queriedFields>Contract_Count__c</queriedFields>
</recordLookups>
```

**Element 2: Count All Contracts on Account**
```xml
<recordLookups>
    <name>Get_Contract_Count</name>
    <label>Get Contract Count for Account</label>
    <locationX>176</locationX>
    <locationY>278</locationY>
    <assignNullValuesIfNoRecordsFound>true</assignNullValuesIfNoRecordsFound>
    <connector>
        <targetReference>Calculate_New_Values</targetReference>
    </connector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>AccountId</field>
        <operator>EqualTo</operator>
        <value>
            <elementReference>$Record.AccountId</elementReference>
        </value>
    </filters>
    <getFirstRecordOnly>false</getFirstRecordOnly>
    <object>Contract</object>
    <storeOutputAutomatically>true</storeOutputAutomatically>
    <queriedFields>Id</queriedFields>
</recordLookups>
```

**Element 3: Calculate New Field Values**
```xml
<assignments>
    <name>Calculate_New_Values</name>
    <label>Calculate New Field Values</label>
    <locationX>176</locationX>
    <locationY>398</locationY>
    <assignmentItems>
        <assignToReference>varNewContractCount</assignToReference>
        <operator>AssignCount</operator>
        <value>
            <elementReference>Get_Contract_Count</elementReference>
        </value>
    </assignmentItems>
    <assignmentItems>
        <assignToReference>varNewHasContracts</assignToReference>
        <operator>Assign</operator>
        <value>
            <elementReference>forB_HasContracts</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Check_If_Update_Needed</targetReference>
    </connector>
</assignments>
```

**Element 4: Formula for Has_Contracts Logic**
```xml
<formulas>
    <name>forB_HasContracts</name>
    <label>Has Contracts Boolean</label>
    <dataType>Boolean</dataType>
    <expression>{!varNewContractCount} > 0</expression>
</formulas>
```

**Element 5: Decision - Check if Update Needed**
```xml
<decisions>
    <name>Check_If_Update_Needed</name>
    <label>Check If Update Needed</label>
    <locationX>176</locationX>
    <locationY>518</locationY>
    <defaultConnectorLabel>No Update Needed</defaultConnectorLabel>
    <rules>
        <name>Values_Changed</name>
        <conditionLogic>or</conditionLogic>
        <conditions>
            <leftValueReference>Get_Account.Has_Contracts__c</leftValueReference>
            <operator>NotEqualTo</operator>
            <rightValue>
                <elementReference>varNewHasContracts</elementReference>
            </rightValue>
        </conditions>
        <conditions>
            <leftValueReference>Get_Account.Contract_Count__c</leftValueReference>
            <operator>NotEqualTo</operator>
            <rightValue>
                <elementReference>varNewContractCount</elementReference>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Update_Account_Fields</targetReference>
        </connector>
        <label>Values Changed</label>
    </rules>
</decisions>
```

**Element 6: Update Account Record**
```xml
<recordUpdates>
    <name>Update_Account_Fields</name>
    <label>Update Account Contract Fields</label>
    <locationX>50</locationX>
    <locationY>638</locationY>
    <inputAssignments>
        <field>Has_Contracts__c</field>
        <value>
            <elementReference>varNewHasContracts</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Contract_Count__c</field>
        <value>
            <elementReference>varNewContractCount</elementReference>
        </value>
    </inputAssignments>
    <inputReference>Get_Account</inputReference>
</recordUpdates>
```

**Flow Variables:**
```xml
<variables>
    <name>varNewContractCount</name>
    <dataType>Number</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <scale>0</scale>
    <value>
        <numberValue>0.0</numberValue>
    </value>
</variables>
<variables>
    <name>varNewHasContracts</name>
    <dataType>Boolean</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <value>
        <booleanValue>false</booleanValue>
    </value>
</variables>
```

### **STEP 3: Update Account Flow Filter**

#### **3.1 Modify Scheduled_Flow_Daily_Update_Accounts**

**Add New Filter Element:**
```xml
<!-- Add after existing Type__c filter -->
<filters>
    <field>Has_Contracts__c</field>
    <operator>EqualTo</operator>
    <value>
        <booleanValue>true</booleanValue>
    </value>
</filters>
```

**Complete Filter Section:**
```xml
<start>
    <locationX>0</locationX>
    <locationY>0</locationY>
    <connector>
        <targetReference>Get_Contracts</targetReference>
    </connector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>Type__c</field>
        <operator>EqualTo</operator>
        <value>
            <stringValue>Commercial</stringValue>
        </value>
    </filters>
    <filters>
        <field>Has_Contracts__c</field>
        <operator>EqualTo</operator>
        <value>
            <booleanValue>true</booleanValue>
        </value>
    </filters>
    <object>Account</object>
    <schedule>
        <frequency>Daily</frequency>
        <startDate>2025-07-18</startDate>
        <startTime>00:45:00.000Z</startTime>
    </schedule>
    <triggerType>Scheduled</triggerType>
</start>
```

### **STEP 4: Contract Flow Optimization**

#### **4.1 Add Expired Contract Filter**

**Modify Contract Flow Filter:**
```xml
<!-- Add after existing Status filter -->
<filters>
    <field>Status</field>
    <operator>NotEqualTo</operator>
    <value>
        <stringValue>Expired</stringValue>
    </value>
</filters>
```

**Complete Filter Section:**
```xml
<start>
    <locationX>0</locationX>
    <locationY>0</locationY>
    <connector>
        <targetReference>Check_Contract_Start_End_Dates</targetReference>
    </connector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>Status</field>
        <operator>IsNull</operator>
        <value>
            <booleanValue>false</booleanValue>
        </value>
    </filters>
    <filters>
        <field>Status</field>
        <operator>NotEqualTo</operator>
        <value>
            <stringValue>Expired</stringValue>
        </value>
    </filters>
    <object>Contract</object>
    <schedule>
        <frequency>Daily</frequency>
        <startDate>2025-07-17</startDate>
        <startTime>00:30:00.000Z</startTime>
    </schedule>
    <triggerType>Scheduled</triggerType>
</start>
```

### **STEP 5: Initial Data Population**

#### **5.1 Create One-Time Data Population Script**

**Apex Script for Initial Population:**
```apex
/**
 * One-time script to populate Has_Contracts__c and Contract_Count__c
 * Run in Anonymous Apex after field creation
 */
public class PopulateAccountContractFields {
    
    public static void populateAllAccountFields() {
        List<Account> accountsToUpdate = new List<Account>();
        
        // Get all Commercial accounts with contract counts
        for (AggregateResult ar : [
            SELECT AccountId, COUNT(Id) contractCount 
            FROM Contract 
            WHERE Account.Type__c = 'Commercial'
            GROUP BY AccountId
        ]) {
            Id accountId = (Id)ar.get('AccountId');
            Integer contractCount = (Integer)ar.get('contractCount');
            
            accountsToUpdate.add(new Account(
                Id = accountId,
                Has_Contracts__c = contractCount > 0,
                Contract_Count__c = contractCount
            ));
        }
        
        // Also handle accounts with no contracts
        for (Account acc : [
            SELECT Id 
            FROM Account 
            WHERE Type__c = 'Commercial' 
            AND Id NOT IN (SELECT AccountId FROM Contract WHERE AccountId != null)
        ]) {
            accountsToUpdate.add(new Account(
                Id = acc.Id,
                Has_Contracts__c = false,
                Contract_Count__c = 0
            ));
        }
        
        // Bulk update in batches
        List<Database.SaveResult> results = Database.update(accountsToUpdate, false);
        
        // Log results
        Integer successCount = 0;
        Integer errorCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            } else {
                errorCount++;
                System.debug('Error updating account: ' + result.getErrors());
            }
        }
        
        System.debug('Population complete. Success: ' + successCount + ', Errors: ' + errorCount);
    }
}

// Execute the population
PopulateAccountContractFields.populateAllAccountFields();
```

### **STEP 6: Testing and Validation**

#### **6.1 Unit Testing Scenarios**

**Test Scenarios:**
1. **Contract Creation:** Verify Has_Contracts__c = true, Contract_Count__c increments
2. **Contract Deletion:** Verify fields update when last contract deleted  
3. **Account with No Contracts:** Verify Has_Contracts__c = false, Contract_Count__c = 0
4. **Bulk Operations:** Test trigger with 200 contract changes
5. **Account Flow Filter:** Verify only accounts with Has_Contracts__c = true process

**Test Data Setup:**
```apex
@TestSetup
static void makeData() {
    // Account with contracts
    Account accountWithContracts = TestDataFactory.createAccount('Test Account With Contracts');
    accountWithContracts.Type__c = 'Commercial';
    insert accountWithContracts;
    
    // Account without contracts  
    Account accountWithoutContracts = TestDataFactory.createAccount('Test Account No Contracts');
    accountWithoutContracts.Type__c = 'Commercial';
    insert accountWithoutContracts;
    
    // Create contracts for first account
    List<Contract> contracts = new List<Contract>();
    contracts.add(TestDataFactory.createContract(accountWithContracts.Id));
    contracts.add(TestDataFactory.createContract(accountWithContracts.Id));
    insert contracts;
}
```

#### **6.2 Performance Testing**

**Validation Queries:**
```sql
-- Verify field population accuracy
SELECT Type__c, Has_Contracts__c, Contract_Count__c, 
       (SELECT COUNT() FROM Contracts) ActualCount
FROM Account 
WHERE Type__c = 'Commercial'
ORDER BY Contract_Count__c DESC

-- Monitor Account flow scope reduction
SELECT COUNT() FROM Account 
WHERE Type__c = 'Commercial' AND Has_Contracts__c = true

-- Expected result: ~500-1,000 instead of 11,548
```

### **STEP 7: Deployment Process**

#### **7.1 Deployment Sequence**

**Partial Sandbox Deployment:**
1. Deploy custom fields to partial sandbox
2. Deploy Contract trigger flow
3. Run initial data population script
4. Deploy Account flow filter update
5. Deploy Contract flow filter update
6. Validate end-to-end functionality

**Production Deployment:**
1. Deploy custom fields (off-hours)
2. Deploy Contract trigger flow (test with sample contracts)
3. Run initial data population (monitor for errors)
4. Deploy flow filter updates (monitor flow execution)
5. Validate performance improvements

#### **7.2 Rollback Plan**

**If Issues Arise:**
1. **Remove flow filters** (immediate rollback to original scope)
2. **Deactivate Contract trigger flow** (stop field updates)
3. **Investigation and fixes** in sandbox
4. **Redeploy with corrections**

**Rollback Steps:**
```xml
<!-- Remove from Account flow -->
<filters>
    <field>Has_Contracts__c</field>
    <operator>EqualTo</operator>
    <value>
        <booleanValue>true</booleanValue>
    </value>
</filters>

<!-- Remove from Contract flow -->
<filters>
    <field>Status</field>
    <operator>NotEqualTo</operator>
    <value>
        <stringValue>Expired</stringValue>
    </value>
</filters>
```

---

## 📊 **Expected Results**

### **Performance Improvements**
- **Account Flow Interviews:** 11,548 → ~500-1,000 (95% reduction)
- **Contract Flow Interviews:** 175 → ~120-140 (exclude expired)
- **Total Daily Consumption:** 12,223 → ~1,600 interviews
- **Org Limit Usage:** 5% → 0.6% of daily limit

### **Business Value**
- ✅ **GL-Live Ready:** Production-safe deployment
- ✅ **Scalability Runway:** Handles significant account growth
- ✅ **Performance Monitoring:** Contract_Count__c provides insights
- ✅ **Maintenance Efficiency:** Automated field population

### **Risk Mitigation**
- ✅ **No Business Logic Changes:** Same calculations, better filtering
- ✅ **Additive Changes Only:** Can be rolled back safely
- ✅ **Incremental Deployment:** Test each component separately
- ✅ **Comprehensive Testing:** Multiple validation scenarios

---

## 🎯 **Action Items for Implementation**

### **Immediate Next Steps (This Week)**
1. ✅ **Create custom fields** on Account object
2. ✅ **Build Contract trigger flow** with logic above
3. ✅ **Deploy to partial sandbox** for testing
4. ✅ **Run initial data population** and validate
5. ✅ **Update flow filters** and test performance
6. ✅ **Deploy to production** for GL-Live readiness

### **Post-Deployment Monitoring**
1. ✅ **Monitor daily flow interviews** via FlowInterview queries
2. ✅ **Validate field accuracy** with spot checks
3. ✅ **Track performance improvements** in execution times
4. ✅ **Document lessons learned** for Phase 2 Batch Apex development

---

**Implementation Status:** Ready for Execution  
**Risk Assessment:** LOW - Additive optimizations only  
**Business Impact:** HIGH - 95% performance improvement for GL-Live
