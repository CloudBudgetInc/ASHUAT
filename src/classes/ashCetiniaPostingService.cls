public class ashCetiniaPostingService {    
    public class Request {
        @InvocableVariable(required=true)
        public Id sourceId;
    }    
    public class Response {
        @InvocableVariable
        public String resultMessage;
    }

    @InvocableMethod(label='Certinia Document Posting Service' description='Posts Documents synchronously based on the provided Source IDs')
    public static List<Response> postTransactions(List<Request> requests) {
        List<Response> responses = new List<Response>();        
        
        Set<Id> sourceIds = new Set<Id>();
        for (Request req : requests) {
            sourceIds.add(req.sourceId);
        }        
        
        Set<Id> transactionIds;
        try {
            transactionIds = c2g.PostingPxService.postSync(sourceIds);
            System.debug('Transactions created: ' + transactionIds);
            // On successful operation, prepare response
            for (Request req : requests) {
                Response res = new Response();
                res.resultMessage = 'Transactions created successfully for source ID: ' + req.sourceId;
                responses.add(res);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error while posting the Sales Invoice: ' + e.getMessage());
            System.debug('while posting the SIN Stack Trace: ' + e.getStackTraceString());
            // Handle exception, prepare error response
            for (Request req : requests) {
                Response res = new Response();
                res.resultMessage = 'Error while processing source ID: ' + req.sourceId + '. Error: ' + e.getMessage();
                responses.add(res);
            }
        }
        return responses;
    }
}