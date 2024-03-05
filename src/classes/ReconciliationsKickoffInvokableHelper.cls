public class ReconciliationsKickoffInvokableHelper {

  @InvocableMethod(label='Kickoff Reconciliations' 
                   description='Generates reconciliations for the period in question.' 
                   category='Reconciliations')
    public static void invokeRecsKickoff(List<List<String>> params) {
        List<String> nestedParams = params.get(0);
        // company, then period
    	Id batchJobId = Database.executeBatch(
            new ReconciliationsKickoffBatch(nestedParams.get(0), nestedParams.get(1)),1000);
    }
}