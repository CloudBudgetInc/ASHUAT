global with sharing class ashCashMatchingService {

    // Defines the input class for the invocable method
    global class Request {
        @InvocableVariable(required=true)
        global Id cashEntryId;
    }

    // Defines the output class for the invocable method
    global class Response {
    @InvocableVariable
    global String message;

    // Define a constructor that accepts a String message
    global Response(String message) {
        this.message = message;
    }
}


    @InvocableMethod(label='Match Cash Entries to Invoices' description='Finds transaction line items for cash entries and performs matching.')
    global static List<Response> matchCashEntriesToInvoices(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        // Process each request
        for (Request req : requests) {
            try {
                // Step 1: Find the Transaction ID for the Cash Entry
                c2g__codaTransaction__c transactions = [
                    SELECT Id, Name
                    FROM c2g__codaTransaction__c
                    WHERE c2g__CashEntry__c = :req.cashEntryId
                    LIMIT 1
                ];

                // Step 2: Find all Transaction Line Item IDs for the Transaction
                List<Id> transactionLineItemIds = new List<Id>();
                for (c2g__codaTransactionLineItem__c lineItem : [
                    SELECT Id
                    FROM c2g__codaTransactionLineItem__c
                    WHERE c2g__Transaction__c = :transactions.Id
                ]) {
                    transactionLineItemIds.add(lineItem.Id);
                }

                // Perform the matching process here using transactionLineItemIds
                // Assuming the matching process is encapsulated in a method like performMatching(List<Id> lineItemIds)
                performMatching(transactionLineItemIds);

                // Add a success message to the response for this request
                responses.add(new Response('Matching completed for Cash Entry ID: ' + req.cashEntryId));
            } catch (Exception e) {
                // Handle any exceptions, adding an error message to the response
                responses.add(new Response('Error processing Cash Entry ID: ' + req.cashEntryId + '. Error: ' + e.getMessage()));
            }
        }

        return responses;
    }

    private static void performMatching(List<Id> lineItemIds) {
    // Checks if there are line items to match
    if (lineItemIds.isEmpty()) {
        System.debug('No transaction line items to match.');
        return;
    }
	
    // Creates the matching service configuration
    c2g.BackgroundMatchingService.Configuration configuration = new c2g.BackgroundMatchingService.Configuration();
    configuration.MatchType = c2g.BackgroundMatchingService.MatchType.DocumentNumber; // matching by Document Number
    configuration.CurrencyMode = c2g.BackgroundMatchingService.CurrencyMode.Document; // matching in Document Currency
    configuration.Mode = c2g.BackgroundMatchingService.MatchMode.DocumentNumberNewestFirst; // Your chosen mode
    configuration.MatchActions = new List<c2g.BackgroundMatchingService.MatchAction>{
        c2g.BackgroundMatchingService.MatchAction.CASHRECEIPT_TO_INVOICE // Focusing on cash receipt to invoice matching
    };
    configuration.MatchingDateModeType = c2g.BackgroundMatchingService.MatchingDateMode.CashEntryDate; // Using Cash Entry Date
    
    // Executes the matching process with the list of transaction line item IDs
    try {
        c2g.BackgroundMatchingService.MatchResult matchResult = c2g.BackgroundMatchingService.matchCash(configuration, lineItemIds);
        System.debug('Matching completed successfully. Match Result: ' + matchResult);
    } catch (Exception e) {
        System.debug('Error during matching process: ' + e.getMessage());
        System.debug('Error Stack Message during Cash Matching: ' + e.getStackTraceString());
        insert new ASH_System_Logs__c(Message__c='Error Message' + e.getMessage(), Object__c='Cash Matching - Transaction LI', Reference_ID__c = 'Transaction line Item');
		insert new ASH_System_Logs__c(Message__c='Error Message Stack' + e.getStackTraceString(), Object__c='Cash Matching - Transactions LI', Reference_ID__c = 'Transaction line Item');
    }
}

}