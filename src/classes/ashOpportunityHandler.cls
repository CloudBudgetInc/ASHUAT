global class ashOpportunityHandler implements Queueable {

    private List<Request> requests;

    public ashOpportunityHandler(List<Request> requests) {
        this.requests = requests;
    }

    public void execute(QueueableContext context) {
        createPayment(this.requests);
    }

    public class Request {
        @InvocableVariable(label='Invoice ID' required=true)
        public Id invoiceId;
        @InvocableVariable(label='Opportunity Stage to set' required=false)
        public string newOpportunityStage;
    }
    
    public class Response {
        @InvocableVariable
        public String message;
        @InvocableVariable
        public Id paymentId;
    }

    
    @InvocableMethod(label='Create Payment and Update Opportunity' description='Create an Opportunity Payment based on Invoice and Payment details.')
    public static List<Response> createPayment(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if(requests == null || requests.isEmpty()) {
            Response resp = new Response();
            resp.message = 'No request provided.';
            responses.add(resp);
            return responses;
        }

        Id invoiceId = requests[0].invoiceId;
        String newOpportunityStage_1 = requests[0].newOpportunityStage != null ? requests[0].newOpportunityStage : 'Default'; 

        try {
                        // Query for the Invoice
            c2g__codaInvoice__c invoice = [SELECT c2g__Opportunity__c
                                          FROM c2g__codaInvoice__c 
                                          WHERE Id = :invoiceId LIMIT 1];

            // Query for the related Payment
            asp04__Payment__c payment = [SELECT asp04__Amount__c, asp04__Payment_Date__c, CurrencyIsoCode, asp04__Payment_Route_Selected__c, asp04__Payment_Stage__c
                                         FROM asp04__Payment__c 
                                         WHERE ffasp__SalesInvoice__c = :invoiceId AND asp04__Payment_Stage__c = 'Collected from customer' LIMIT 1];

            if(payment == null) {
                Response resp = new Response();
                resp.message = 'No payment found with the status "Collected from customer".';
                responses.add(resp);
                return responses;
            }
            
            if(invoice == null || invoice.c2g__Opportunity__c == null) {
              Response resp = new Response();
                resp.message = 'No Invoice or Opportunity is found.';
                responses.add(resp);
                return responses;  
            }    

            // Create a new Opportunity Payment
            npe01__OppPayment__c oppPayment = new npe01__OppPayment__c();
            oppPayment.npe01__Opportunity__c = invoice.c2g__Opportunity__c; // From SIN
            oppPayment.npe01__Payment_Amount__c = payment.asp04__Amount__c; 
            oppPayment.npe01__Payment_Date__c = payment.asp04__Payment_Date__c;
            oppPayment.CurrencyIsoCode = payment.CurrencyIsoCode;

            if(payment.asp04__Payment_Route_Selected__c == 'Card') {
                oppPayment.npe01__Payment_Method__c = 'Credit Card';
            } else {
                oppPayment.npe01__Payment_Method__c = 'Credit Card'; // can be amended later ... payment.asp04__Payment_Route_Selected__c;
            }

            oppPayment.npe01__Paid__c = true;

            // Insert the new record
            insert oppPayment;
            
            if(newOpportunityStage_1 != 'Default') {
                Opportunity oppToUpdate = new Opportunity(Id = invoice.c2g__Opportunity__c, StageName = newOpportunityStage_1);
                update oppToUpdate;
            }

            Response resp = new Response();
            resp.message = 'Payment record created successfully.';
            resp.paymentId = oppPayment.Id; // Pass the Payment ID
            responses.add(resp);
       
        } catch(Exception e) {
            Response resp = new Response();
            resp.message = 'Unexpected Error: ' + e.getMessage();
            responses.add(resp);
        }

        System.debug('Response: ' + responses[0].message);
        return responses;
    }
}