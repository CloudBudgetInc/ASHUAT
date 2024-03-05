@isTest(SeeAllData=true)
private class ashCashEntryCancellationServiceTest {

    
    static void setup() {
        // Assuming 'CashEntry__c' and 'FinancialPeriod__c' are custom objects. Adjust as necessary.
        Account acc = new Account(Name='TestAccount');
  		insert acc;
        
        // Mock Cash Entry record
        c2g__codaCashEntry__c testCashEntry = new c2g__codaCashEntry__c(            
            c2g__Account__c = acc.Id
        );
       // insert testCashEntry;

        // Mock Financial Period record
        c2g__codaPeriod__c testPeriod = new c2g__codaPeriod__c(
            Name = 'TestPeriod',
            c2g__StartDate__c = Date.today(),
            c2g__EndDate__c = Date.today().addDays(30)
        );
        insert testPeriod;

    }

    static testMethod void testCancelCashEntry() {
        // Retrieve setup data
        c2g__codaCashEntry__c testCashEntry = [SELECT Id FROM c2g__codaCashEntry__c LIMIT 1];
        c2g__codaPeriod__c testPeriod = [SELECT Id FROM c2g__codaPeriod__c LIMIT 1];
        
        Account acc = new Account(Name='TestAccount');
  		insert acc;
        c2g__codaInvoice__c testInvoice = new c2g__codaInvoice__c(
        c2g__Account__c = acc.Id,
		c2g__DueDate__c = Date.today().addDays(30),
		c2g__FirstDueDate__c = Date.today().addDays(30),
		c2g__InvoiceDate__c = Date.today().addDays(10)
        );
		insert testInvoice;
        
        //ashSetCompanyQueueable queueableJob = new ashSetCompanyQueueable('American Society of Hematology', testInvoice.Id);

        // Prepare the request
        List<ashCashEntryCancellationService.CancelCashEntryRequest> requests = new List<ashCashEntryCancellationService.CancelCashEntryRequest>();
        ashCashEntryCancellationService.CancelCashEntryRequest req = new ashCashEntryCancellationService.CancelCashEntryRequest();
        req.OriginalCashEntryId = testCashEntry.Id;
        req.PeriodId = testPeriod.Id;
        requests.add(req);


        Test.startTest();
        ashCashEntryCancellationService.invokeFromFlow(requests);
        Test.stopTest();

    }
}