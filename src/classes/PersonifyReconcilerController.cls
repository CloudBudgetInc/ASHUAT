public with sharing class PersonifyReconcilerController {

/*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */    
    @AuraEnabled(cacheable=false)
    public static List<sObject> personifyTransactions( String recordId, 
                                                           String startDate, 
                                                           String endDate, 
                                                           String CustomerFilter, 
                                                           String OrderFilter, 
                                                           String BillToFilter, 
                                                           String AmountFilter ) {
        // Convert AmountFilter to a decimal value
        Decimal amountFilterValue = (AmountFilter != null && AmountFilter != '') ? Decimal.valueOf(AmountFilter) : null;
        Decimal amountFilterValueInverse = (amountFilterValue != null) ? amountFilterValue * -1 : null;
        String matchStatus = 'Matched';
        String unMatchStatus = 'Unmatched';
                                                               
        // Get reconciliation including GL account Id.
        Reconciliation__c thisRec = [SELECT Id, General_Ledger_Account__r.c2g__ReportingCode__c, Accounting_Company__r.Key__c, 
                                     Period__r.PerPost__c FROM Reconciliation__c WHERE Id = :recordId];
		String accountCode = thisRec.General_Ledger_Account__r.c2g__ReportingCode__c;
        Id generalLedgerAccount = thisRec.General_Ledger_Account__c;
		final String accountSubaccountCode = accountCode + '-100-000-000-00';
		String companyKey = thisRec.Accounting_Company__r.Key__c;

        // Define the base query
        String baseQuery = 'SELECT Id, Name, Customer_Id__c, Order_Number__c, Bill_To_Name__c, Period__c, ' + 
            'Amount__c, Effective_Date__c, Comments__c, Source__c ' +
            'FROM Personify_Transaction__c WHERE Internal_Account__c = :accountSubaccountCode AND ' + 
            'Company__c = :companyKey AND ' + 
            'Match_Status__c != :matchStatus';

        // Create a list to hold the conditions for the WHERE clause
        List<String> conditions = new List<String>();

        Date startDateObj = (startDate != null && startDate != '') ? Date.valueOf(startDate) : null;
        Date endDateObj = (endDate != null && endDate != '') ? Date.valueOf(endDate) : null;

        // Add date range filter based on provided startDate and endDate
        if (startDateObj != null) {
            conditions.add('Effective_Date__c >= :startDateObj');
            System.debug(startDateObj);
        }
        if (endDateObj != null) {
            conditions.add('Effective_Date__c <= :endDateObj');
            System.debug(endDateObj);
        }

        // Add additional filters based on the "CustomerFilter" parameter for Reference__c field with wildcards
        if (!String.isEmpty(CustomerFilter)) {
            CustomerFilter = '%' + CustomerFilter + '%'; 
            conditions.add('Customer_Id__c LIKE :CustomerFilter');
            System.debug(CustomerFilter);
        }

        // Add additional filters based on the "OrderFilter" parameter for Reference__c field with wildcards
        if (!String.isEmpty(OrderFilter)) {
            OrderFilter = '%' + OrderFilter + '%'; 
            conditions.add('Order_Number__c LIKE :OrderFilter');
            System.debug(OrderFilter);
        }                                                         
                                                               
        // Add additional filters based on the "BillTo" parameter for Account__c field with wildcards
        if (!String.isEmpty(BillToFilter)) {
            BillToFilter = '%' + BillToFilter + '%'; 
            conditions.add('Bill_To_Name__c LIKE :BillToFilter');
            System.debug(BillToFilter);
        }

        // Add the AmountFilter as an additional filter
        if (amountFilterValue != null || amountFilterValueInverse != null) {
            String amountString = '%' + amountFilterValue + '%'; 
            conditions.add('Amount_as_String__c LIKE :amountString');
            System.debug(amountString);
        }
                                                               
		// Additional clause to ensure that all Personify Transactions are from this Reconciliation's period 
		// or earlier.
		String currentPeriod = thisRec.Period__r.PerPost__c;
		System.debug(currentPeriod);
		conditions.add('Period__c <= :currentPeriod');

        // Combine the conditions using AND
        if (!conditions.isEmpty()) {
            baseQuery += ' AND ' + String.join(conditions, ' AND ');
        }
        System.debug(baseQuery);
        List<sObject> response = Database.query(baseQuery + ' ORDER BY Effective_Date__c ASC LIMIT 5000');
        return response;
    }
    
/*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    @AuraEnabled(cacheable=false)
    public static boolean handleMatch(List<String> selectedPersonifyRowIds, String recordId ) {
        
        List<Personify_Transaction__c> personifyRecords = [SELECT Id, Amount__c, Personify_Match__c 
			FROM Personify_Transaction__c WHERE Id IN :selectedPersonifyRowIds];
		System.debug(personifyRecords.size());
        
        if( recordId != null || recordId != '' ) {
            Personify_Match__c newMatch = new Personify_Match__c();
            newMatch.Reconciliation__c = recordId;
            insert newMatch;

            for (Personify_Transaction__c pt : personifyRecords) {
                pt.Personify_Match__c = newMatch.Id;
                pt.Match_Status__c = 'Matched';
            }
        }    
        
        // Update the records with the new Match Status and Remaining_Amount__c values
        if (!personifyRecords.isEmpty()) {
            update personifyRecords;
        }

        return true;
    }
}