@isTest(SeeAllData=true)
public class PersonifyReconcilerControllerTest {

    @isTest
    public static void testDataFetch() {
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
		Id company = provider.getCompany('ASH');        
        c2g__codaPeriod__c somePeriod = provider.getPeriod('ASH', '202312');        
        Id someGeeElAccount = provider.getGlaCode('1340');
        
        // Set up rec template and rec; required to correctly identify the bank statement lines / transactions in question.
        Reconciliation_Template__c someTemplate = new Reconciliation_Template__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = company);
        insert someTemplate;
        Reconciliation__c someReconcilation = new Reconciliation__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = company, Period__c = somePeriod.Id, Reconciliation_Template__c = someTemplate.Id);
        insert someReconcilation;
        System.debug(someReconcilation);
        
        List<sObject> results = PersonifyReconcilerController.personifyTransactions( someReconcilation.Id,
                                                                               '',
                                                                               '',
            																   '99999999',// Customer
                                                                               '88888888',// Order
                                                                               'Axomoaxoa', // Bill To
                                                                               '1000000'); // Amount
        System.assert(results.size() == 0);
    }

    @isTest
    public static void testMatchHandling() {
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
		Id company = provider.getCompany('ASH');        
        c2g__codaPeriod__c somePeriod = provider.getPeriod('ASH', '202312');        
        Id someGeeElAccount = provider.getGlaCode('1340');
        
        Reconciliation_Template__c someTemplate = new Reconciliation_Template__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = company);
        insert someTemplate;
        Reconciliation__c someReconcilation = new Reconciliation__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = company, Period__c = somePeriod.Id, Reconciliation_Template__c = someTemplate.Id);
        insert someReconcilation;
        
		final String INTERNAL_ACCOUNT = '1340-100-000-000-00';
        final String MATCH_STATUS = 'Unmatched';
              
        Map<Id, Personify_Transaction__c> personifyRecordMap = 
            new Map<Id, Personify_Transaction__c>([SELECT Id, Amount__c FROM Personify_Transaction__c
			WHERE Internal_Account__c = :INTERNAL_ACCOUNT AND Match_Status__c = :MATCH_STATUS LIMIT 2]);
		Set<Id> someIds = personifyRecordMap.keySet();
        List<Id> personifyRecords = new List<Id>(someIds);
        
        // Because match totalling is only enforced on the front-end, we can send two adhoc transactions 
        // to the match and verify that matches are successful.
        boolean result = PersonifyReconcilerController.handleMatch(personifyRecords, someReconcilation.Id);
        System.assertEquals(true, result);
    }
}