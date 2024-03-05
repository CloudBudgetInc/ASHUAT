@isTest(SeeAllData=true)
private class ashSCRpostMatchQueueableTest {

    static testMethod void testQueueableExecution() {
        // Inset new Account
        Account acc = new Account(Name='TestAccount');
  		insert acc;
        // Insert New Invoice
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
		
		ashSCRpostMatchQueueable.bypassRetriesForTesting = true; // this is for bypassing the queueable script in the Apex Class. 
        Test.startTest();        
        System.enqueueJob(new ashSCRpostMatchQueueable(testSCR.Id));               
        Test.stopTest();
    }

    // Additional test methods to cover various scenarios and edge cases
}