@isTest(SeeAllData=true)
private class ashEmailSenderQueueableTest {
    // Utility method to create test data
    private static List<c2g__codaInvoice__c> createTestInvoices(Integer count) {
        Account acc = new Account(
            Name='TestAccount',
        	c2g__CODAInvoiceEmail__c='email@email.com');
  		insert acc;
        
        List<c2g__codaInvoice__c> invoices = new List<c2g__codaInvoice__c>();
        for (Integer i = 0; i < count; i++) {
            c2g__codaInvoice__c inv = new c2g__codaInvoice__c(
            c2g__Account__c = acc.Id,
			c2g__DueDate__c = Date.today().addDays(30),
			c2g__FirstDueDate__c = Date.today().addDays(30),
			c2g__InvoiceDate__c = Date.today().addDays(10)            			              
            );
            invoices.add(inv);
        }
        insert invoices;
        return invoices;
    }

    // Test method to verify the Queueable job
    @isTest static void testAshEmailSenderQueueable() {
        // Setup - create test data
        List<c2g__codaInvoice__c> testInvoices = createTestInvoices(2);

        // Prepare the list of Ids for the queueable class
        List<Id> invoiceIds = new List<Id>();
        for (c2g__codaInvoice__c inv : testInvoices) {
            invoiceIds.add(inv.Id);
        }

        // Test - execute the queueable job
        Test.startTest();
        ashEmailSenderQueueable queueableJob = new ashEmailSenderQueueable(invoiceIds);
        Id jobId = System.enqueueJob(queueableJob);
        Test.stopTest();

    }
}