@isTest(SeeAllData=true)
private class ashOpportunityInvoiceHandlerTest {
    
    @isTest
    static void testCreateInvoiceFromREST() {
        
        
        // Create a Household Account
        Account testHousehold = new Account(
            Name='Test Household',
            RecordTypeId = '0126A000000fD36'
        );
        insert testHousehold;
        
        // Create a Contact linked to the Household Account
        Contact testContact = new Contact(
            FirstName = 'Test Name',
            LastName = 'Test Last Name',
            AccountId = testHousehold.Id // Link to Household Account
        );
        insert testContact;
        
        // Create an Address linked to the Household Account
        npsp__Address__c testAddress = new npsp__Address__c(
            npsp__MailingStreet__c = 'Test Street',
            npsp__Household_Account__c = testHousehold.Id // Correctly link to Household Account
        );
        insert testAddress;      
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            AccountId = testHousehold.Id,
            CloseDate = System.today().addDays(30),
            npsp__Primary_Contact__c = testContact.Id
        );
        insert testOpp;
        
        Product2 testProduct = new  Product2(
        Name = 'Test Product',
        IsActive = true
        );
        insert testProduct;
        
        OpportunityLineItem oppLinteItems = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            Product2Id = testProduct.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        //insert oppLinteItems;
        // Create a JSON string representing the input for the REST service
       
        String jsonString = '{ ' +
            '"oppId" : "' + testOpp.Id + '",' +
            '"isInvoicePosted" : true,' +
            '"invoiceType" : "Website Donation",' +
            '"sinId" : null,' +
            '"sinSynced" : false' +
            '}';
        
        // Act: Make the call to the REST service
        Test.startTest();
        
        // Set up the RestRequest and RestResponse
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method to test
        ashOpportunityInvoiceHandler.FlowResponse result = ashOpportunityInvoiceHandler.createInvoiceFromREST();
        
        Test.stopTest();       

    }
    

     @isTest
     static void testCreateInvoiceFromREST_3() {       
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
        Id = pricebookId,
        IsActive = true
        );
        update standardPricebook;
         
       
         
        // Create a Household Account
        Account testHousehold = new Account(
            Name='Test Household',
            RecordTypeId = '0126A000000fD36'
        );
        insert testHousehold;         
            
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            AccountId = testHousehold.Id,
            //RecordTypeId  = '0126A000000fD38QAE',
            CloseDate = System.today().addDays(30),
            Pricebook2Id = pricebookId
        );
        insert testOpp;
        
        Product2 testProduct = new  Product2(
        Name = 'Test Product',
        IsActive = true
        );
        insert testProduct;
        
        PricebookEntry testPriceBookEntry = new PricebookEntry(
       Pricebook2Id = pricebookId, 
        Product2Id =   testProduct.Id,
        UnitPrice = 1,
        IsActive = true
       );
         insert testPriceBookEntry;
        OpportunityLineItem oppLinteItems = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            Product2Id = testProduct.Id,
            Quantity = 2,
            UnitPrice = 100,
            PricebookEntryId = testPriceBookEntry.Id
        );
        insert oppLinteItems; 
        //update testOpp;
     
            c2g__codaInvoice__c testInvoice = new c2g__codaInvoice__c(
            c2g__Opportunity__c = testOpp.Id,
            c2g__Account__c = testHousehold.Id,
            c2g__DueDate__c = Date.today().addDays(30),
            c2g__FirstDueDate__c = Date.today().addDays(30),
            c2g__InvoiceDate__c = Date.today().addDays(10) 
        );
        insert testInvoice; 
       
        asp04__Payment__c testPayment = new asp04__Payment__c(
            asp04__Amount__c = 100.00,
            asp04__Payment_Date__c = Date.today(),
            asp04__Payment_Stage__c = 'Awaiting Submission',
            asp04__Payment_Route_Selected__c = 'Card',
            ffasp__SalesInvoice__c = testInvoice.Id
            // Set other necessary fields
        );
        insert testPayment;
        
        testInvoice.ffasp__Payment__c = testPayment.Id; // Set the Payment ID on the Invoice
        update testInvoice; // Update the Invoice record in the database
         
        // Create a JSON string representing the input for the REST service        
        String jsonString = '{ ' +
            '"oppId" : "' + testOpp.Id + '",' +
            '"isInvoicePosted" : true,' +
            '"invoiceType" : "Website Donation",' +
            '"sinId" : "' + testInvoice.Id + '",' +
            '"sinSynced" : true' +
            '}';
        
        // Act: Make the call to the REST service
        Test.startTest();
        
        // Set up the RestRequest and RestResponse
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method to test
        ashOpportunityInvoiceHandler.FlowResponse result = ashOpportunityInvoiceHandler.createInvoiceFromREST();
        
        Test.stopTest();       

    }
}