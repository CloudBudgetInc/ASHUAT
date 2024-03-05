@isTest(SeeAllData=true)
public class PersonnelBudgetStageBatchInvokableTest {

    static testMethod void testPersBudgetBatchInvoker() {   
		Test.startTest();
		Personnel_Budget_Batch__c someBatch = new Personnel_Budget_Batch__c(Year__c = '2025');
        insert someBatch;  
        
	    List<String> params = new List<String>();
        params.add(someBatch.Id);
        List<List<String>>  outerParams = new List<List<String>>();
        outerParams.add(params);
     	PersonnelBudgetStageBatchInvokable.invokeStagePersonnelBatch(outerParams);
     	Test.stopTest();  
     
     	List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob 
                                     WHERE ApexClass.Name = 'PersonnelBudgetStageBatch' 
                                     AND JobType = 'BatchApex'
                                     AND CreatedDate = TODAY];        
     	System.assert(batchJobs.size() > 0, 'Unexpected number of batch jobs ran: ' + batchJobs);
    }
}