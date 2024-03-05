// This class posts a cash entry Asynchronous 
public class ashCashEntryPosting implements Queueable {
    private Id cashEntryId;

    public ashCashEntryPosting(Id cashEntryId) {
        this.cashEntryId = cashEntryId;
    }

    public void execute(QueueableContext context) {
        c2g.CODAAPICommon_7_0.Context apiContext = new c2g.CODAAPICommon_7_0.Context();
        c2g.CODAAPICommon.Reference cashEntryRef = new c2g.CODAAPICommon.Reference();
        cashEntryRef.Id = this.cashEntryId; 

        try {
            // API Call to post the cash entry
            c2g.CODAAPICashEntry_7_0.PostCashEntry(apiContext, cashEntryRef);
            System.debug('Successfully posted Cash Entry: ' + cashEntryId);
        } catch(Exception e) {
            //Exception handling from the API call
            System.debug('Error posting Cash Entry: ' + e.getMessage());
            insert new ASH_System_Logs__c(Message__c='Cash Entry ID: ' + e.getMessage(), Object__c='Cash Entry', Reference_ID__c = cashEntryId);
        }
    }
}