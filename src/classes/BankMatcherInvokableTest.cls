@isTest(SeeAllData=true)
public class BankMatcherInvokableTest {
    
	static testMethod void testBasicMatching() {
    	
        FfaDataProvider provider = FfaDataProvider.getInstance();
        c2g__codaPeriod__c somePeriod = provider.getPeriod('ASHRC', '202301'); 
        Id someCompany = provider.getCompany('ASH');
        Id someGeeElAccount = provider.getGlaCode('1018');
        c2g__codaBankAccount__c bankAccount = [SELECT Id, c2g__AccountNumber__c FROM c2g__codaBankAccount__c 
			WHERE c2g__AccountNumber__c = '0005163174849' LIMIT 1];
        Reconciliation_Template__c someRecTemplate = new Reconciliation_Template__c( General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = someCompany);
        insert someRecTemplate;
        Reconciliation__c reconciliation = new Reconciliation__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = someCompany, Period__c = somePeriod.Id, Reconciliation_Template__c = someRecTemplate.Id);
        insert reconciliation;
        Bank_Statement__c someBankStatement = new Bank_Statement__c(Bank_Account__c = bankAccount.Id, 
			General_Ledger_Account__c = someGeeElAccount, Period__c = somePeriod.Id);
        insert someBankStatement;
        
        Bank_Transaction__c transactionOne = new Bank_Transaction__c(Amount__c = 50.00, Reference__c = 'JjUxkAp4fG3W',
				General_Ledger_Account__c = someGeeElAccount, Period__c = somePeriod.Id);
        Bank_Transaction__c transactionTwo = new Bank_Transaction__c(Amount__c = 75.00, Reference__c = 'XYJgAUCjFHDF',
				General_Ledger_Account__c = someGeeElAccount, Period__c = somePeriod.Id);
        Bank_Transaction__c transactionThree = new Bank_Transaction__c(Amount__c = 50.00, Reference__c = 'hKcgJ49waZss',
				General_Ledger_Account__c = someGeeElAccount, Period__c = somePeriod.Id);
        List<Bank_Transaction__c> transactionsForInsert = new List<Bank_Transaction__c>();
        transactionsForInsert.add(transactionOne);
        transactionsForInsert.add(transactionTwo);
        transactionsForInsert.add(transactionThree); 
        insert transactionsForInsert;
        
        Bank_Statement_Line_Item__c bankLineItemOne = new Bank_Statement_Line_Item__c(Amount__c = 50.00, Reference__c = 'DrpuKsVgKrqy',
			Bank_Statement__c = someBankStatement.Id, General_Ledger_Account__c = someGeeElAccount );
        Bank_Statement_Line_Item__c bankLineItemTwo = new Bank_Statement_Line_Item__c(Amount__c = 75.00, Reference__c = 'R5TYRMn2KL2f',
			Bank_Statement__c = someBankStatement.Id, General_Ledger_Account__c = someGeeElAccount );
        Bank_Statement_Line_Item__c bankLineItemThree = new Bank_Statement_Line_Item__c(Amount__c = 125.00, Reference__c = 'QhyM3KYexJmR',
			Bank_Statement__c = someBankStatement.Id, General_Ledger_Account__c = someGeeElAccount );        
        List<Bank_Statement_Line_Item__c> bankLineItemsForInsert = new List<Bank_Statement_Line_Item__c>();
        bankLineItemsForInsert.add(bankLineItemOne);
        bankLineItemsForInsert.add(bankLineItemTwo);
        bankLineItemsForInsert.add(bankLineItemThree);
        insert bankLineItemsForInsert;
        
		Test.startTest();
      	List<String> params = new List<String>();
       	params.add(reconciliation.Id);
        params.add(someGeeElAccount);
        List<List<String>> outerParams = new List<List<String>>();
        outerParams.add(params); 
        BankMatcherInvokable.invokeBankMatching(outerParams);
        
        Bank_Transaction__c resultOne = [SELECT Id, Bank_Match__c, Match_Status__c FROM Bank_Transaction__c WHERE Reference__c = 'JjUxkAp4fG3W'];
        Bank_Transaction__c resultTwo = [SELECT Id, Bank_Match__c, Match_Status__c FROM Bank_Transaction__c WHERE Reference__c = 'XYJgAUCjFHDF'];
        Bank_Transaction__c resultThree = [SELECT Id, Match_Status__c FROM Bank_Transaction__c WHERE Reference__c = 'hKcgJ49waZss'];
        Bank_Statement_Line_Item__c resultFour = [SELECT Id, Bank_Match__c, Match_Status__c FROM Bank_Statement_Line_Item__c WHERE Reference__c = 'DrpuKsVgKrqy'];
        Bank_Statement_Line_Item__c resultFive = [SELECT Id, Bank_Match__c, Match_Status__c FROM Bank_Statement_Line_Item__c WHERE Reference__c = 'R5TYRMn2KL2f'];
        Bank_Statement_Line_Item__c resultSix = [SELECT Id, Bank_Match__c, Match_Status__c FROM Bank_Statement_Line_Item__c WHERE Reference__c = 'QhyM3KYexJmR'];
        System.assertEquals('Unmatched', resultOne.Match_Status__c);
        System.assertEquals('Matched', resultTwo.Match_Status__c);
        System.assertEquals('Unmatched', resultThree.Match_Status__c);
        System.assertEquals('Unmatched', resultFour.Match_Status__c);
        System.assertEquals('Matched', resultFive.Match_Status__c);
        System.assertEquals('Unmatched', resultSix.Match_Status__c);
        System.assertNotEquals(resultTwo.Bank_Match__c, null);
        System.assertNotEquals(resultFive.Bank_Match__c, null);
        System.assertEquals(resultFive.Bank_Match__c, resultTwo.Bank_Match__c);
    }
}