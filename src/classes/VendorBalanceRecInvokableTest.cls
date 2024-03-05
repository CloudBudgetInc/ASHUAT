@isTest(SeeAllData=true)
public class VendorBalanceRecInvokableTest {
    
	static testMethod void testVendorBalances() {  
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
		Id company = provider.getCompany('ASH');        
        c2g__codaPeriod__c somePeriod = provider.getPeriod('ASH', '202402');        
        Id someGeeElAccount = provider.getGlaCode('2040');
        
        // Set up rec template and rec; required to correctly identify the bank statement lines / transactions in question.
        Reconciliation_Template__c someTemplate = new Reconciliation_Template__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = company);
        insert someTemplate;
        Reconciliation__c someReconciliation = new Reconciliation__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = company, Period__c = somePeriod.Id, Reconciliation_Template__c = someTemplate.Id);
        insert someReconciliation;        
        
		Test.startTest();
	    List<String> params = new List<String>();
        params.add(someReconciliation.Id);
        List<List<String>> outerParams = new List<List<String>>();
        outerParams.add(params);        
        
		VendorBalanceRecInvokable.freshenVendorBalances(outerParams);  
        List<Account_Balance__c> balances = [SELECT Id FROM Account_Balance__c WHERE CreatedDate = TODAY AND Reconciliation__c = :someReconciliation.Id];
        System.assert(balances.size() > 0);
    }

}