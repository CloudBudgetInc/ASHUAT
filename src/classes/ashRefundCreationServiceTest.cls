@isTest(SeeAllData=true)
private class ashRefundCreationServiceTest { 
 @isTest
    static void testRefundProcessWithImmediateProcessing() {
       //ashRefundCreationService.bypassQueueing = false; 
       asp04__Payment__c testPayment = new asp04__Payment__c(
       asp04__Amount__c = 100.00,
       asp04__Payment_Stage__c = 'Collected from customer',
       asp04__Payment_Route_Selected__c = 'Card'                     
        );
        insert testPayment;     
        List<ashRefundCreationService.RefundRequest> requests = new List<ashRefundCreationService.RefundRequest>();
        ashRefundCreationService.RefundRequest req = new ashRefundCreationService.RefundRequest();
        req.paymentId = testPayment.Id;
        req.amount = 0; // Specify refund amount
        req.processRefundImmediately = true; // Indicate immediate refund processing
        requests.add(req); 
        Test.startTest();
        List<String> response = ashRefundCreationService.enqueueRefundCreation(requests);        
        Test.stopTest();
    }
    
     @isTest
    static void testRefundProcess1() {
       //ashRefundCreationService.bypassQueueing = false;  
       asp04__Payment__c testPayment = new asp04__Payment__c(
           asp04__Amount__c = 100.00,
           asp04__Payment_Stage__c = 'Collected from customer',
           asp04__Payment_Route_Selected__c = 'Card'                     
        );
        insert testPayment;     
           Account acc = new Account(Name='TestAccount');
            insert acc;
        c2g__codaCompany__c testCompany = new c2g__codaCompany__c(Name='TestCompany');
        //insert testCompany;
        
            // Mock Cash Entry record
            c2g__codaCashEntry__c testCashEntry = new c2g__codaCashEntry__c(            
                c2g__Account__c = acc.Id,
            	ffasp__Payment__c = testPayment.Id
            );
        insert testCashEntry;        
        
        
        List<ashRefundCreationService.RefundRequest> requests = new List<ashRefundCreationService.RefundRequest>();
        ashRefundCreationService.RefundRequest req = new ashRefundCreationService.RefundRequest();
        
        
        
        req.processRefundImmediately = true;
        req.paymentId = testPayment.Id;
        req.amount = 100; // Specify refund amount         
        requests.add(req); 
        
        c2g__codaCashEntry__c cashEntry = [SELECT Id, c2g__OwnerCompany__c FROM c2g__codaCashEntry__c WHERE ffasp__Payment__c = :req.paymentId LIMIT 1];
        
        system.debug(cashEntry);
        Test.startTest();
        List<String> response = ashRefundCreationService.enqueueRefundCreation(requests);        
        system.debug(requests);
        Test.stopTest();
    }
    
    @isTest
    static void testRefundProcess2() {
       // ashRefundCreationService.bypassQueueing = true; 
        asp04__Payment__c testPayment = new asp04__Payment__c(
        asp04__Amount__c = 100.00,
        asp04__Payment_Stage__c = 'Collected from customer',
        asp04__Payment_Route_Selected__c = 'Card'                     
        );
        insert testPayment;     
        List<ashRefundCreationService.RefundRequest> requests = new List<ashRefundCreationService.RefundRequest>();
        ashRefundCreationService.RefundRequest req = new ashRefundCreationService.RefundRequest();
        req.paymentId = testPayment.Id;
        req.amount = 150; // Specify refund amount
        req.processRefundImmediately = True; // Indicate immediate refund processing
        requests.add(req); 
        Test.startTest();
        List<String> response = ashRefundCreationService.enqueueRefundCreation(requests);        
        Test.stopTest();
    }
    
        @isTest
    static void testRefundProcess3() {
      //  ashRefundCreationService.bypassQueueing = true; 
        asp04__Payment__c testPayment = new asp04__Payment__c(
        asp04__Amount__c = 100.00,
        asp04__Payment_Stage__c = 'Awaiting Submission',
        asp04__Payment_Route_Selected__c = 'Card'                     
        );
        insert testPayment;     
        List<ashRefundCreationService.RefundRequest> requests = new List<ashRefundCreationService.RefundRequest>();
        ashRefundCreationService.RefundRequest req = new ashRefundCreationService.RefundRequest();
        req.paymentId = testPayment.Id;
        req.amount = 150; // Specify refund amount
        req.processRefundImmediately = True; // Indicate immediate refund processing
        requests.add(req); 
        Test.startTest();
        List<String> response = ashRefundCreationService.enqueueRefundCreation(requests);        
        Test.stopTest();
    }
    @isTest
    static void testRefundProcess4() {
      //  ashRefundCreationService.bypassQueueing = true; 
        asp04__Payment__c testPayment = new asp04__Payment__c(
        asp04__Amount__c = 100.00,
        asp04__Payment_Stage__c = 'Collected from customer',
        asp04__Payment_Route_Selected__c = 'Direct Debit'                     
        );
        insert testPayment;     
        List<ashRefundCreationService.RefundRequest> requests = new List<ashRefundCreationService.RefundRequest>();
        ashRefundCreationService.RefundRequest req = new ashRefundCreationService.RefundRequest();
        req.paymentId = testPayment.Id;
        req.amount = 150; // Specify refund amount
        req.processRefundImmediately = True; // Indicate immediate refund processing
        requests.add(req); 
        Test.startTest();
        List<String> response = ashRefundCreationService.enqueueRefundCreation(requests);        
        Test.stopTest();
    }
    
    @isTest
    static void testRefundProcess5() {      
    	//ashRefundCreationService.bypassQueueing = true; 
        List<ashRefundCreationService.RefundRequest> requests = new List<ashRefundCreationService.RefundRequest>();
        ashRefundCreationService.RefundRequest req = new ashRefundCreationService.RefundRequest();        
        req.processRefundImmediately = True; // Indicate immediate refund processing
        requests.add(req); 
        Test.startTest();
        List<String> response = ashRefundCreationService.enqueueRefundCreation(requests);        
        Test.stopTest();
    }
}