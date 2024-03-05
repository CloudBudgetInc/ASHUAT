@isTest(SeeAllData=true)
private class ashOpportunityHandlerTest {
    @isTest
    static void testCreatePaymentAndUpdateOpportunity() {
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert testOpportunity;

        // Create a mock Invoice record related to the Opportunity
        c2g__codaInvoice__c testInvoice = new c2g__codaInvoice__c(
            c2g__Opportunity__c = testOpportunity.Id,
            c2g__Account__c = testAccount.Id,
            c2g__DueDate__c = Date.today().addDays(30),
			c2g__FirstDueDate__c = Date.today().addDays(30),
			c2g__InvoiceDate__c = Date.today().addDays(10) 
        );
        insert testInvoice;

        // Create a mock Payment record related to the Invoice
        asp04__Payment__c testPayment = new asp04__Payment__c(
            asp04__Amount__c = 100.00,
            asp04__Payment_Date__c = Date.today(),
            asp04__Payment_Stage__c = 'Collected from customer',
            asp04__Payment_Route_Selected__c = 'Card',
            ffasp__SalesInvoice__c = testInvoice.Id
            // Set other necessary fields
        );
        insert testPayment;
        
        // Prepare the request
        ashOpportunityHandler.Request req = new ashOpportunityHandler.Request();
        req.invoiceId = testInvoice.Id;
        req.newOpportunityStage = 'Closed Won'; // Specify a new Opportunity Stage to set

        // Instantiate the queueable class with the request data
       ashOpportunityHandler handler = new ashOpportunityHandler(new List<ashOpportunityHandler.Request>{req});
        

      ashOpportunityHandler handler3 = new ashOpportunityHandler(new List<ashOpportunityHandler.Request>{});
		
       c2g__codaInvoice__c testInvoice3 = new c2g__codaInvoice__c(            
       c2g__Account__c = testAccount.Id,
       c2g__DueDate__c = Date.today().addDays(30),
	   c2g__FirstDueDate__c = Date.today().addDays(30),
	   c2g__InvoiceDate__c = Date.today().addDays(10) 
        );
        insert testInvoice3;
        
        ashOpportunityHandler.Request req4 = new ashOpportunityHandler.Request(); // 
        req4.invoiceId = testInvoice3.Id;        
        ashOpportunityHandler handler4 = new ashOpportunityHandler(new List<ashOpportunityHandler.Request>{req4});
		
        
        
        // Execute the queueable job 
        Test.startTest();
        System.enqueueJob(handler);
        //System.enqueueJob(handler2);
		System.enqueueJob(handler3);   
        System.enqueueJob(handler4);
        
        Test.stopTest();
    }
    
 @isTest
static void testNoInvoiceOrOpportunityFound() {
   
    ashOpportunityHandler.Request req = new ashOpportunityHandler.Request();
    req.invoiceId = 'a1a1a000000XXXX'; // searching an invoice does not exist. 
    req.newOpportunityStage = 'Closed Won';
    
    ashOpportunityHandler handler = new ashOpportunityHandler(new List<ashOpportunityHandler.Request>{req});
    
    Test.startTest();
    System.enqueueJob(handler);
    Test.stopTest();    
    
}
}