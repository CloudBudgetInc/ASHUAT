@isTest(SeeAllData=true)
global class ashCashEntryCreationTest {

    @isTest
    static void testCreateCashEntryFromInvoice() {
        // Arrange: Create a test Account and Invoice
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        c2g__codaInvoice__c testInvoice = new c2g__codaInvoice__c(
        c2g__Account__c = testAccount.Id,
    	c2g__DueDate__c = Date.today().addDays(30),
    	c2g__FirstDueDate__c = Date.today().addDays(30),
    	c2g__InvoiceDate__c = Date.today().addDays(10)
        );
   		insert testInvoice;       
        
	   asp04__Payment__c testPayment = new asp04__Payment__c(
       asp04__Amount__c = 100.00,
       asp04__Payment_Stage__c = 'Collected from customer',
       asp04__Payment_Route_Selected__c = 'Card'                     
        );
        insert testPayment; 		

        
        List<ashCashEntryCreation.FlowInput> inputs = new List<ashCashEntryCreation.FlowInput>();
        ashCashEntryCreation.FlowInput input = new ashCashEntryCreation.FlowInput();
        input.invoiceId = testInvoice.Id;
        input.cashEntryType = 'Receipt';
        input.isCashEntryPosted = true;
        input.asperatoId = testPayment.Id; 
        input.ashType = 'Website Donation'; 
        
        inputs.add(input);


        Test.startTest();       
        ashCashEntryCreation.createCashEntryFromInvoice(inputs);
        Test.stopTest();       
    }

    
}