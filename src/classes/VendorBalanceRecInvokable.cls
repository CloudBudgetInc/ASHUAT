public class VendorBalanceRecInvokable {
    
  	@InvocableMethod(label='Creates new Vendor Balances' description='Creates new Vendor Balances' category='Vendor')  
    public static void freshenVendorBalances(List<List<String>> params) {
      
        final String TYPE = 'Reconciliation';
        List<String> nestedParams = params.get(0);
        String reconciliation = nestedParams.get(0);
        
        Reconciliation__c thisRec = [SELECT Id, Accounting_Company__c, Period__c FROM Reconciliation__c WHERE Id = :reconciliation];
        c2g__codaPeriod__c thisPeriod = [SELECT Id, Name FROM c2g__codaPeriod__c WHERE Id = :thisRec.Period__c];
        
        List<Account_Balance__c> forDelete = [SELECT Id FROM Account_Balance__c WHERE Reconciliation__c = :reconciliation];
        delete forDelete;
	 
        List<AggregateResult> results = 
            [SELECT c2g__Account__r.Id Account, SUM(c2g__HomeValue__c) Balance 
            FROM c2g__ReportingBalance__c
            WHERE c2g__Account__r.Name <> '' AND 
            c2g__OwnerCompany__c = :thisRec.Accounting_Company__c AND
			c2g__Period__r.Name <= :thisPeriod.Name 
            GROUP BY c2g__Account__r.Id
            HAVING SUM(c2g__HomeValue__c) <> 0];
      
        List<Account_Balance__c> forInsert = new List<Account_Balance__c>();
          
        for( AggregateResult result : results ) {        
            Account_Balance__c balance = new Account_Balance__c();
            if( result.get('Account') != null ) { 
                balance.Organization__c = (Id) result.get('Account');
                balance.Balance__c = (Decimal) result.get('Balance');
                balance.Type__c = TYPE;
                balance.Reconciliation__c = thisRec.Id;
            }
            forInsert.add(balance);
        }
      
    	insert forInsert;
  }    
}