@isTest(SeeAllData=true)
global class ashCashMatchingServiceTest {

    @isTest
    static void testMatchCashEntriesToInvoices() {
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
        
        asp04__Payment__c testPayment = new asp04__Payment__c(
           asp04__Amount__c = 100.00,
           asp04__Payment_Stage__c = 'Collected from customer',
           asp04__Payment_Route_Selected__c = 'Card'                     
        );
        insert testPayment;     
           
        c2g__codaCompany__c testCompany = new c2g__codaCompany__c(Name='TestCompany');

        

        c2g__codaCashEntry__c test_CashEntry = new c2g__codaCashEntry__c(            
                c2g__Account__c = acc.Id,
              ffasp__Payment__c = testPayment.Id
            );
        insert test_CashEntry;        	
        
        c2g__codaCashEntry__c testCashEntry = [SELECT Id, Name FROM c2g__codaCashEntry__c WHERE c2g__Status__c = 'Complete' AND c2g__Type__c = 'Receipt' LIMIT 1];   
                  
        ashCashMatchingService.Request request = new ashCashMatchingService.Request();
        request.cashEntryId = testCashEntry.Id;
        List<ashCashMatchingService.Request> requests = new List<ashCashMatchingService.Request> { request };

        
        Test.startTest();
        List<ashCashMatchingService.Response> responses = ashCashMatchingService.matchCashEntriesToInvoices(requests);
        Test.stopTest();

    }

    
}