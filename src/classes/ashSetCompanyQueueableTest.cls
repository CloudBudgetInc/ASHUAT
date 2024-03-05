@isTest(SeeAllData=true)
private class ashSetCompanyQueueableTest {

    static void setup() {
        Account acc = new Account(Name='TestAccount');
  		insert acc;
        c2g__codaInvoice__c testInvoice = new c2g__codaInvoice__c(
        c2g__Account__c = acc.Id,
		c2g__DueDate__c = Date.today().addDays(30),
		c2g__FirstDueDate__c = Date.today().addDays(30),
		c2g__InvoiceDate__c = Date.today().addDays(10)
        );
		insert testInvoice;
        c2g__codaCompany__c testCompany = new c2g__codaCompany__c(
    	Name = 'Test Company'
    	);
    	insert testCompany;
    }


    static testMethod void testQueueableExecution() {
        // Retrieve test data
        c2g__codaInvoice__c testInvoice = [SELECT Id FROM c2g__codaInvoice__c LIMIT 1];
        
        // Instantiate the queueable class with test data
        ashSetCompanyQueueable queueableJob = new ashSetCompanyQueueable('American Society of Hematology', testInvoice.Id);

        // Execute the queueable job
        Test.startTest();
        System.enqueueJob(queueableJob);
        Test.stopTest();

    }
}