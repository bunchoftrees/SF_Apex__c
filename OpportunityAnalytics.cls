trigger OpportunityAnalytics on Opportunity (after insert, after update, after delete) {
    Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    Group salesOpsQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Sales_Ops' LIMIT 1];
    
    if (UserInfo.getProfileId() == sysAdminProfile.Id) {
        List<Analytics__c> analyticsToInsert = new List<Analytics__c>();
        
        
        String action = Trigger.isInsert ? 'Create' :
                        Trigger.isUpdate ? 'Modify' :
                        Trigger.isDelete ? 'Delete' : '';
        
        
        if (Trigger.isAfter) {
            for (Opportunity opp : Trigger.isDelete ? Trigger.old : Trigger.new) {
                Analytics__c analyticRecord = new Analytics__c();
                analyticRecord.Action__c = action;
                analyticRecord.OpportunityID__c = opp.Id;
                analyticRecord.UserID__c = UserInfo.getUserId();
                analyticRecord.OwnerId = salesOpsQueue.Id;
                
                
                if (Trigger.isUpdate) {
                    
                    List<String> changedFieldNames = new List<String>();

                    
                    Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
                    
                    
                    if (opp.Name != oldOpp.Name) {
                        changedFieldNames.add('Name');
                    }

                    
                    if (opp.Amount != oldOpp.Amount) {
                        analyticRecord.Amount_Changed__c = true;
                        analyticRecord.OldAmount__c = oldOpp.Amount;
                        analyticRecord.NewAmount__c = opp.Amount;
                        changedFieldNames.add('Amount');
                    }
                    
                    
                    analyticRecord.ChangedFields__c = String.join(changedFieldNames, ';');
                }
                
                
                analyticsToInsert.add(analyticRecord);
            }
            
            
            if (!analyticsToInsert.isEmpty()) {
                insert analyticsToInsert;
            }
        }
    }
}