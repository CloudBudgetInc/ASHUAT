@isTest(SeeAllData=true)
public class MonthlyCloseChecklistBatchTest {

	static testMethod void testMonthlyCloseBatch() { 
                    
		User u = new User( ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id, LastName = 'last',
     		Email = 'puser000@amamama.com', Username = 'puser000@amamama.com' + System.currentTimeMillis(),
     		CompanyName = 'TEST', TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
     		LocaleSidKey = 'en_US', Title = 'title', Alias = 'alias' );
        insert u;
        Monthly_Close_Task_Template__c someTemplate = new Monthly_Close_Task_Template__c(Assignee__c = u.Id, Item__c = 'TEST123');
        insert someTemplate;
        
        Test.startTest();
        MonthlyCloseChecklistBatch mccb = new MonthlyCloseChecklistBatch('ASH','202303');
        Id jobId = Database.executeBatch(mccb, 50);
        Test.stopTest();
        
        Monthly_Close_Task__c someTask = [SELECT Id FROM Monthly_Close_Task__c WHERE Item__c = 'TEST123'];
        System.assertNotEquals(someTask, null);        
    }
}