@isTest
private class ashOpportunityLineItemCreatorTest {

    static testMethod void testCreateOpportunityLineItems() {
        // Setup test data
        // 

        
        Pricebook2 standardPricebook = createStandardPricebook();
        
        Product2 donationProduct = createDonationProduct();        
        
        Id pricebookId = Test.getStandardPricebookId();



        
        PricebookEntry donationPricebookEntry = createPricebookEntry(pricebookId, donationProduct);

        Opportunity testOpportunity = createTestOpportunity(pricebookId);
        List<npsp__Allocation__c> testAllocations = createTestAllocations(testOpportunity);

        // Prepare the request for the invocable method
        ashOpportunityLineItemCreator.Request req = new ashOpportunityLineItemCreator.Request();
        req.opportunityId = testOpportunity.Id;
        
        list<ashOpportunityLineItemCreator.Request> reqs = new List<ashOpportunityLineItemCreator.Request>();
        reqs.add(req); 

        // Execute the test
               
        Test.startTest();
        List<ashOpportunityLineItemCreator.Response> responses = ashOpportunityLineItemCreator.createOpportunityLineItems(reqs);
        
        //With Custom Settings
        
        ash_ar_custom_settings__c CustomSettings = new ash_ar_custom_settings__c();
        CustomSettings.Name = 'Default';
        CustomSettings.Default_Donation_Product__c = donationProduct.Id;
        insert CustomSettings;
        
        List<ashOpportunityLineItemCreator.Response> responses_2 = ashOpportunityLineItemCreator.createOpportunityLineItems(reqs);
        
        // for catching exception
        // 
        //Opportunity testOpportunity_2 = createTestOpportunity(pricebookId);
       // ashOpportunityLineItemCreator.Request req_2 = new ashOpportunityLineItemCreator.Request();
       // req_2.opportunityId = testOpportunity_2.Id;
        
       // list<ashOpportunityLineItemCreator.Request> reqs_2 = new List<ashOpportunityLineItemCreator.Request>();
       // reqs.add(req_2); 
        
        //List<ashOpportunityLineItemCreator.Response> responses_3 = ashOpportunityLineItemCreator.createOpportunityLineItems(reqs_2);
        
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, responses, 'Responses should not be null.');
        System.assertEquals('Ready', responses[0].status, 'Status should be Ready.');

        // Verify Opportunity Line Items creation
        List<OpportunityLineItem> createdLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpportunity.Id];
        System.assertEquals(testAllocations.size() * 2, createdLineItems.size(), 'Incorrect number of line items created.');
    }

    private static Pricebook2 createStandardPricebook() {
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
        Id = pricebookId,
        IsActive = true
        );
        update standardPricebook;
        

        System.debug('Standard Price Book in Test: ' + standardPricebook);
        return standardPricebook;
    }

    private static Product2 createDonationProduct() {
        Product2 product = new Product2(Name = 'DONATION*', ProductCode = 'Donation*', Product_Manager__c = 'FND', IsActive = true);
        insert product;
        return product;
    }

  
    private static PricebookEntry createPricebookEntry(Id pricebookId, Product2 donationProduct) {

        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = donationProduct.Id, UnitPrice = 10000, IsActive = true);
        insert standardPrice;

        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;

        PricebookEntry customPrice = new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = donationProduct.Id, UnitPrice = 12000, IsActive = true);
        insert customPrice;
        
        return customPrice;
    }

    
    private static Opportunity createTestOpportunity(Id pb) {
        Account acc = new Account(Name='TestAccount');
        insert acc; 
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId=acc.Id, CloseDate = Date.today().addDays(10), StageName = 'Planned', Pricebook2Id = pb);
        insert opp;
        return opp;
    }

    private static List<npsp__Allocation__c> createTestAllocations(Opportunity opp) {
        List<npsp__Allocation__c> allocations = new List<npsp__Allocation__c>();
        
        npsp__General_Accounting_Unit__c testGAU = new npsp__General_Accounting_Unit__c(
        Name = 'TestGAU'
        );
        insert testGAU;
        // Assuming npsp__Allocation__c is related to Opportunity and has an Amount field
        for (Integer i = 0; i < 3; i++) {
            npsp__Allocation__c alloc = new npsp__Allocation__c(npsp__Opportunity__c = opp.Id, npsp__General_Accounting_Unit__c = testGAU.Id, npsp__Amount__c = 100.00);
            allocations.add(alloc);
        }
        insert allocations;
        return allocations;
    }

    // Add any additional test methods if needed
}