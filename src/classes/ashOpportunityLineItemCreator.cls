public class ashOpportunityLineItemCreator {

    public class Request {
        @InvocableVariable(required = true)
        public Id opportunityId;
    }

    public class Response {
        @InvocableVariable
        public String status;
    }

    @InvocableMethod(label = 'Create Opportunity Line Items' description = 'Creates Opportunity Line Items based on npsp__Allocation__c records')
    public static List<Response> createOpportunityLineItems(List<Request> requests) {        
        List<Response> responses = new List<Response>();
        Response res = new Response();
        res.status = processOpportunity(requests[0].opportunityId) ? 'Ready' : null;
        responses.add(res);
        return responses;
    }

    private static Boolean processOpportunity(Id opportunityId) {
        try {
            Id standardPricebookId = getStandardPricebookId();
            Id donationProductId = getDonationProductId();
            Id PriceBookEntryId = getPriceBookEntry(standardPricebookId, donationProductId);
            updateOpportunityPricebook(opportunityId, standardPricebookId);
            List<npsp__Allocation__c> allocations = getAllocations(opportunityId);
            createOpportunityLineItems(opportunityId, allocations, donationProductId, PriceBookEntryId);
            //System.debug('PriceBookID: ' + standardPricebookId);
            return true;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            //System.debug('PriceBookID: ' + getStandardPricebookId());            
            return false;
        }
    }

    private static Id getStandardPricebookId() {
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true AND IsActive = true LIMIT 1];
        return standardPricebook.Id;
    }
    
     private static Id getPriceBookEntry(Id Pricebook2Id, Id Product2Id) {
        PricebookEntry PricebookEtnryVal = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Pricebook2Id AND Product2Id = :Product2Id LIMIT 1];
        return PricebookEtnryVal.Id;
    }
    

    private static Id getDonationProductId() {
        ash_ar_custom_settings__c setting = ash_ar_custom_settings__c.getInstance('Default'); // It is defined in the Custom settings, getting values from custom setting.
        if (setting != null && String.isNotEmpty(setting.Default_Donation_Product__c)) {
            return setting.Default_Donation_Product__c;
        }
        else{
            Product2 donationProduct = [SELECT Id FROM Product2 WHERE Name = 'DONATION*' AND Product_Manager__c = 'FND' LIMIT 1];
            return donationProduct.Id;
        }
    }

    private static void updateOpportunityPricebook(Id opportunityId, Id pricebookId) {
        Opportunity opp = new Opportunity(Id = opportunityId, Pricebook2Id = pricebookId);
        update opp;
    }

    private static List<npsp__Allocation__c> getAllocations(Id opportunityId) {
        return [SELECT Id, npsp__Amount__c FROM npsp__Allocation__c WHERE npsp__opportunity__c = :opportunityId];
    }

    private static void createOpportunityLineItems(Id opportunityId, List<npsp__Allocation__c> allocations, Id productId, Id PriceBookEntryId) {
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
        for (npsp__Allocation__c alloc : allocations) {
            lineItems.add(new OpportunityLineItem(
                GAU_Allocation__c = alloc.Id,
                OpportunityId = opportunityId,
                Quantity = 1,
                UnitPrice = alloc.npsp__Amount__c,
                Product2Id = productId,
                PricebookEntryId = PriceBookEntryId
            ));
        }
        insert lineItems;
    }
}