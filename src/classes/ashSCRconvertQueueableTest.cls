@isTest(SeeAllData=true)
private class ashSCRconvertQueueableTest {

    static testMethod void testQueueableExecution() {
        Account acc = new Account(Name='TestAccount');
  		insert acc;
        c2g__codaInvoice__c testInvoice = new c2g__codaInvoice__c(
        c2g__Account__c = acc.Id,
		c2g__DueDate__c = Date.today().addDays(30),
		c2g__FirstDueDate__c = Date.today().addDays(30),
		c2g__InvoiceDate__c = Date.today().addDays(10)
        );
		insert testInvoice;
        
        // insert Credit note.
        c2g__codaCreditNote__c testSCR = new c2g__codaCreditNote__c(
        c2g__Invoice__c = testInvoice.Id,
        c2g__Account__c = acc.Id
        );
        insert testSCR;
        // Instantiates the queueable class 
        ashSCRconvertQueueable queueableJob = new ashSCRconvertQueueable(testInvoice.Id);

        // Test - Execute the queueable job
        Test.startTest();
        System.enqueueJob(queueableJob);               
        Test.stopTest();
    }

    // Additional test methods if needed. 
}