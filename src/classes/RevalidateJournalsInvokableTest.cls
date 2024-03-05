@isTest(SeeAllData=true)
public class RevalidateJournalsInvokableTest {
    
	public static testmethod void testInvokable() {    
        
		Test.startTest();
	    List<String> params = new List<String>();
        List<c2g__CombinationRuleLineItem__c> result = [SELECT Id FROM c2g__CombinationRuleLineItem__c LIMIT 1];
        c2g__CombinationRuleLineItem__c item = result.get(0);
     	params.add(item.Id);
        List<List<String>>  outerParams = new List<List<String>>();
        outerParams.add(params);
     	RevalidateJournalsInvokable.invokeRevalidateJournals(outerParams);
     	Test.stopTest();          
    }
}