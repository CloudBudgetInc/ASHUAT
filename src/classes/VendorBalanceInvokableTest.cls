@isTest(SeeAllData=true)
public class VendorBalanceInvokableTest {
    
	static testMethod void testVendorBalances() {   
        
		VendorBalanceInvokable.freshenVendorBalances();  
        List<Account_Balance__c> balances = [SELECT Id FROM Account_Balance__c WHERE CreatedDate = TODAY];
        System.assert(balances.size() > 0);
    }
}