global class MonthlyCloseChecklistBatch implements Database.Batchable<sObject> {

    String company = 'ASH';
    String period = '';    
    
    public MonthlyCloseChecklistBatch(String company, String period) {
        this.period = period;
        this.company = company;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        
        String query = 'SELECT Id, Assignee__c, Item__c FROM Monthly_Close_Task_Template__c ORDER BY Order__c';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Monthly_Close_Task_Template__c> templates) { 
		
       	FfaDataProvider provider = FfaDataProvider.getInstance();        
		c2g__codaPeriod__c somePeriod = provider.getPeriod(company, period);
        
        List<Monthly_Close_Task__c> forInsert = new List<Monthly_Close_Task__c>();
        for(Monthly_Close_Task_Template__c template : templates) {
            Monthly_Close_Task__c someTask = new Monthly_Close_Task__c();
			someTask.Assignee__c = template.Assignee__c;
			someTask.Item__c = template.Item__c;
			someTask.Period__c = somePeriod.Id;
			forInsert.add(someTask);
        }
        insert forInsert;
    }

    global void finish(Database.BatchableContext bc) {} 
}