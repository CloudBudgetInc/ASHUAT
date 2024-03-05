public class BankMatcherInvokable {
	@InvocableMethod(label='Invoke Automatic Bank Matching' 
                   description='Kicks off automatic bank matching.' 
                   category='Reconciliations')
    public static void invokeBankMatching(List<List<String>> params) { 
        
		final String UNMATCHED = 'Unmatched';
        
        List<String> nestedParams = params.get(0);
        String reconciliationId = nestedParams.get(0);    
        String generalLedgerAccountId = nestedParams.get(1);   
        
        // Create a single bank match for use later. All auto-matched transactions will end up 
        // affiliated to a single match so the process can be more easily traced - and reset.
        Bank_Match__c someBankMatch = new Bank_Match__c(Reconciliation__c = reconciliationId);
        insert someBankMatch;
        
        List<Bank_Transaction__c> bankTransactions = [SELECT Id, Amount__c FROM Bank_Transaction__c WHERE 
			General_Ledger_Account__c = :generalLedgerAccountId AND Match_Status__c = :UNMATCHED];

        List<Bank_Statement_Line_Item__c> bankStatementLines = [SELECT Id, Amount__c FROM Bank_Statement_Line_Item__c 
			WHERE General_Ledger_Account__c = :generalLedgerAccountId AND Match_Status__c = :UNMATCHED];
        
        // Gather a list of duplicate amounts. Any amounts that are duplicated on the GL side will not be matched.
        Map<Decimal, String> baddies = new Map<Decimal, String>();
        Set<Decimal> uniques = new Set<Decimal>();
  		for (Bank_Transaction__c someTransaction : bankTransactions) {
		    if (!uniques.add(someTransaction.Amount__c)) {
				baddies.put(someTransaction.Amount__c, 'Duplicate');
		    }
		}

	    // Gather a list of duplicate amounts. Any amounts that are duplicated on the bank side will not be matched.
        Set<Decimal> moreUniques = new Set<Decimal>();
        for (Bank_Statement_Line_Item__c someBankLineItem : bankStatementLines) {
		    if (!moreUniques.add(someBankLineItem.Amount__c)) {
				baddies.put(someBankLineItem.Amount__c, 'Duplicate');
		    }
		}

        List<Bank_Transaction__c> transactionsForUpdate = new List<Bank_Transaction__c>();
        List<Bank_Statement_Line_Item__c> bankStatementLineItemsForUpdate = new List<Bank_Statement_Line_Item__c>();

        // Simple nested-loop looking for exact matches on the bank statement and bank transaction sides.
        for(Bank_Statement_Line_Item__c someBankLineItem : bankStatementLines) {
            for(Bank_Transaction__c someTransaction : bankTransactions) {
                if(someBankLineItem.Amount__c == someTransaction.Amount__c) {
                    // If the amount wasn't previously registered as a duplicate, then match.
                    if(!baddies.containsKey(someBankLineItem.Amount__c)) {
						someBankLineItem.Match_Status__c = 'Matched';
    	                someTransaction.Match_Status__c = 'Matched';
                        someBankLineItem.Bank_Match__c = someBankMatch.Id;
                        someTransaction.Bank_Match__c = someBankMatch.Id;
                        transactionsForUpdate.add(someTransaction);
                        bankStatementLineItemsForUpdate.add(someBankLineItem);
                    }
                }       
            }
        }
        update transactionsForUpdate;
        update bankStatementLineItemsForUpdate;
    }
}