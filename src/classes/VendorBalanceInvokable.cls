public class VendorBalanceInvokable {
    
  @InvocableMethod(label='Creates new Vendor Balances' description='Creates new Vendor Balances' category='Vendor')  
  public static void freshenVendorBalances() {
      
    final String TYPE = 'Current';
	List<Account_Balance__c> forDelete = [SELECT Id FROM Account_Balance__c WHERE CreatedDate = TODAY];
    delete forDelete;
	 
	List<AggregateResult> results = 
        [SELECT c2g__Account__r.Id Account, SUM(c2g__HomeValue__c) Balance 
        FROM c2g__ReportingBalance__c
        WHERE c2g__Account__r.Name <> ''
        GROUP BY c2g__Account__r.Id
        HAVING SUM(c2g__HomeValue__c) <> 0];
      
    List<Account_Balance__c> forInsert = new List<Account_Balance__c>();
      
    for( AggregateResult result : results ) {        
        Account_Balance__c balance = new Account_Balance__c();
        if( result.get('Account') != null ) { 
            balance.Organization__c = (Id) result.get('Account');
            balance.Balance__c = (Decimal) result.get('Balance');
            balance.Type__c = TYPE;
        }
        forInsert.add(balance);
    }
      
    insert forInsert;
  }    
}