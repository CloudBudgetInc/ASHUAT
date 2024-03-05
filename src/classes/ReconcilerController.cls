public with sharing class ReconcilerController {
/*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    @AuraEnabled(cacheable=false)
    public static List<sObject> bankStatementTransactions( String recordId,
                                                           String startDate, 
                                                           String endDate, 
                                                           String TypeFilter, 
                                                           String ReferenceFilter, 
                                                           String AmountFilter, 
                                                           String strMatchStatus, 
                                                           String checkFilter) {
        // Convert AmountFilter to a decimal value
        Decimal amountFilterValue = (AmountFilter != null && AmountFilter != '') ? Decimal.valueOf(AmountFilter) : null;
        Decimal amountFilterValueInverse = (amountFilterValue != null) ? amountFilterValue * -1 : null;

        // Get reconciliation including GL account Id.
        Reconciliation__c thisRec = [SELECT Id, General_Ledger_Account__c FROM Reconciliation__c WHERE Id = :recordId];
        Id generalLedgerAccount = thisRec.General_Ledger_Account__c;
		System.debug(generalLedgerAccount);

        // Define the query
        String query = 'SELECT ' +
                        'Id, Name, Addenda_1__c, Addenda_2__c, Amount__c,' +
                        'Code__c, Match_Status__c, Remaining_Amount__c, Reference__c, Sign__c,' +
                        'Transaction_Date__c, Type__c, Transaction_Date_Display__c, Amount_as_String__c ' +
                        'FROM Bank_Statement_Line_Item__c ';

        // Create a list to hold the conditions for the WHERE clause
        List<String> conditions = new List<String>();

        // Add General Ledger as a default filter.
        conditions.add('General_Ledger_Account__c = :generalLedgerAccount');
                                                               
		// Temp exclude sweep transactions. At Period 4, we remove this.
		// String sweepReferenceWildcard = 'YC-%';
		// conditions.add('(NOT Reference__c LIKE :sweepReferenceWildcard)');
                                                               
        // Add condition to filter by Match_Status__c based on strMatchStatus parameter
        if (strMatchStatus != null && strMatchStatus != '' && strMatchStatus != 'All' ) {
            conditions.add('Match_Status__c = :strMatchStatus');
            System.debug(strMatchStatus);
         } else {
             conditions.add('Match_Status__c != \'Matched\' AND Match_Status__c != null');
        }

        Date startDateObj = (startDate != null && startDate != '') ? Date.valueOf(startDate) : null;
        Date endDateObj = (endDate != null && endDate != '') ? Date.valueOf(endDate) : null;

        // Add date range filter based on provided startDate and endDate
        if (startDateObj != null) {
            System.debug(startDateObj);
            conditions.add('Transaction_Date__c >= :startDateObj');
        }
        if (endDateObj != null) {
            System.debug(endDateObj);
            conditions.add('Transaction_Date__c <= :endDateObj');
        }

        // Add additional filters based on the "TypeFilter" parameter for Type__c field with wildcards        
        if (TypeFilter != null && TypeFilter != '' && TypeFilter != 'All' ) { // [CM5] 
            TypeFilter = '%' + TypeFilter + '%'; 
            System.debug(TypeFilter);
            conditions.add('Type__c LIKE :TypeFilter');
        }

        if (checkFilter != null && checkFilter != '' ) { 
            checkFilter = '%' + checkFilter + '%'; 
            System.debug(checkFilter);
            conditions.add('Addenda_1__c LIKE :checkFilter');
        }

        // Add additional filters based on the "ReferenceFilter" parameter for Reference__c field with wildcards
        if (!String.isEmpty(ReferenceFilter)) {
            ReferenceFilter = '%' + ReferenceFilter + '%'; 
            System.debug(ReferenceFilter);
            conditions.add('Reference__c LIKE :ReferenceFilter');
        }

        // Add the AmountFilter as an additional filter
        if (amountFilterValue != null || amountFilterValueInverse != null) {            
            String amountString = '%' + amountFilterValue + '%'; 
            System.debug(amountString);
            conditions.add('Amount_as_String__c LIKE :amountString');
            //conditions.add('(Amount__c = :amountFilterValue OR Amount__c = :amountFilterValueInverse)');
        }

        // Combine the conditions using AND
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        System.debug(query);
        List<sObject> response = Database.query(query + ' ORDER BY Transaction_Date__c ASC LIMIT 5000');
        return response;
    }
/*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */    
    @AuraEnabled(cacheable=false)
    public static List<sObject> generalLedgerTransactions( String recordId, 
                                                           String startDate, 
                                                           String endDate, 
                                                           String TypeFilter, 
                                                           String ReferenceFilter, 
                                                           String AccountFilter, 
                                                           String AmountFilter ) {
        System.debug(recordId);
                                                               
        // Convert AmountFilter to a decimal value
        Decimal amountFilterValue = (AmountFilter != null && AmountFilter != '') ? Decimal.valueOf(AmountFilter) : null;
        Decimal amountFilterValueInverse = (amountFilterValue != null) ? amountFilterValue * -1 : null;
        String matchStatus = 'Matched';
        String unMatchStatus = 'Unmatched';
                                                               
        // Get reconciliation including GL account Id.
        Reconciliation__c thisRec = [SELECT Id, General_Ledger_Account__c FROM Reconciliation__c WHERE Id = :recordId];
        Id generalLedgerAccount = thisRec.General_Ledger_Account__c; 

        // Define the query
        String query = 'SELECT Id, Account__c, Reference__c, Transaction_Type__c, Amount__c, Transaction_Date__c, Transaction_Date_Display__c ' +
                    'FROM Bank_Transaction__c WHERE Match_Status__c != :matchStatus';

        // Create a list to hold the conditions for the WHERE clause
        List<String> conditions = new List<String>();

        // Add General Ledger as a default filter.
        conditions.add('General_Ledger_Account__c = :generalLedgerAccount');        

        Date startDateObj = (startDate != null && startDate != '') ? Date.valueOf(startDate) : null;
        Date endDateObj = (endDate != null && endDate != '') ? Date.valueOf(endDate) : null;

        // Add date range filter based on provided startDate and endDate
        if (startDateObj != null) {
            conditions.add('Transaction_Date__c >= :startDateObj');
        }
        if (endDateObj != null) {
            conditions.add('Transaction_Date__c <= :endDateObj');
        }

        // Add additional filters based on the "TypeFilter" parameter for Transaction_Type__c field with wildcards
         if (TypeFilter != null && TypeFilter != '' && TypeFilter != 'All' ) { // [CM5] 
            TypeFilter = '%' + TypeFilter + '%'; 
            conditions.add('Transaction_Type__c LIKE :TypeFilter');
        }

        // Add additional filters based on the "ReferenceFilter" parameter for Reference__c field with wildcards
        if (!String.isEmpty(ReferenceFilter)) {
            ReferenceFilter = '%' + ReferenceFilter + '%'; 
            conditions.add('Reference__c LIKE :ReferenceFilter');
        }

        // Add additional filters based on the "AccountFilter" parameter for Account__c field with wildcards
        if (!String.isEmpty(AccountFilter)) {
            AccountFilter = '%' + AccountFilter + '%'; 
            conditions.add('Account__c LIKE :AccountFilter');
        }

        // Add the AmountFilter as an additional filter
        if (amountFilterValue != null || amountFilterValueInverse != null) {
            String amountString = '%' + amountFilterValue + '%'; 
            conditions.add('Amount_as_String__c LIKE :amountString');
            //conditions.add('(Amount__c = :amountFilterValue OR Amount__c = :amountFilterValueInverse)');
        }

        // Combine the conditions using AND
        if (!conditions.isEmpty()) {
            query += ' AND ' + String.join(conditions, ' AND ');
        }
        System.debug(query);
        List<sObject> response = Database.query(query + ' ORDER BY Transaction_Date__c ASC LIMIT 5000');
        return response;
    }
    
/*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    @AuraEnabled(cacheable=false)
    public static boolean handleMatch(List<String> selectedStatementRowIds, List<String> selectedBankTransactionRowIds, String recordId ) {
        System.debug('hiiiiiiii');
        System.debug(selectedStatementRowIds.size());
        System.debug(selectedBankTransactionRowIds.size());
        
        // Query the Statement records
        List<Bank_Statement_Line_Item__c> statementRecords = [SELECT Id, Amount__c, Match_Status__c, Remaining_Amount__c, Bank_Match__c FROM Bank_Statement_Line_Item__c WHERE Id IN :selectedStatementRowIds];

        // Query the Bank Transaction records
        List<Bank_Transaction__c> bankTransactionRecords = [SELECT Id, Amount__c, Match_Status__c, Bank_Match__c FROM Bank_Transaction__c  WHERE Id IN :selectedBankTransactionRowIds];

        if( recordId != null || recordId != '' ) {
            System.debug('doin the matching thing');
            Bank_Match__c newBankMatch = new Bank_Match__c();
            newBankMatch.Reconciliation__c = recordId;
            insert newBankMatch;

            for (Bank_Statement_Line_Item__c bsi : statementRecords) {
                System.debug(bsi);
                bsi.Bank_Match__c = newBankMatch.Id;
            }
            
            for (Bank_Transaction__c bt : bankTransactionRecords) {
                System.debug(bt);
                bt.Bank_Match__c = newBankMatch.Id;
            }
        }    

        // Calculate the sum of Amounts for statementRecords
        Decimal statementTotal = 0;
        for (Bank_Statement_Line_Item__c statementRecord : statementRecords) {
			statementTotal += statementRecord.Amount__c;
        }

        // Calculate the sum of Amounts for bankTransactionRecords
        Decimal bankTransactionTotal = 0;
        for (Bank_Transaction__c bankTransactionRecord : bankTransactionRecords) {
            bankTransactionTotal += bankTransactionRecord.Amount__c;
        }

        // Set the Match Status
        for (Bank_Statement_Line_Item__c statementRecord : statementRecords) {
            statementRecord.Match_Status__c = 'Matched';
        }
        
        for (Bank_Transaction__c bankTransactionRecord : bankTransactionRecords) {
            bankTransactionRecord.Match_Status__c = 'Matched';
        }

        // Update the records with the new Match Status values
        if (!statementRecords.isEmpty()) {
            update statementRecords;
        }
        if (!bankTransactionRecords.isEmpty()) {
            update bankTransactionRecords;
        }

        return true;
    }
/*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
/**
    @AuraEnabled(cacheable=false)
    public static void clear() {
        List<Bank_Statement_Line_Item__c> statementRecords = [SELECT Id, Amount__c, Match_Status__c, Remaining_Amount__c FROM Bank_Statement_Line_Item__c WHERE Match_Status__c = 'Matched' OR Match_Status__c = 'Partial Matched'];
 
        if( !statementRecords.isEmpty() ) {
            for( Bank_Statement_Line_Item__c s : statementRecords ) {
                s.Match_Status__c = 'Unmatched';
                s.Remaining_Amount__c = null;
            }
            update statementRecords; 
        }
        
        List<Bank_Transaction__c> bankTransactionRecords = [SELECT Id, Amount__c, Match_Status__c FROM Bank_Transaction__c WHERE Match_Status__c = 'Matched'];
        
        if( !bankTransactionRecords.isEmpty() ) {
            for( Bank_Transaction__c s : bankTransactionRecords ) {
                s.Match_Status__c = 'Unmatched';
            }
            update bankTransactionRecords; 
        }
    }
*/
    
//  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Combined Table
    @AuraEnabled
    public static List<mergedTransaction> transactions( String recordId,
                                                        String bankStartDate,
                                                        String bankEndDate,
                                                        String bankTypeFilter,
                                                        String bankReferenceFilter,
                                                        String bankAmountFilter,
                                                        String bankstrMatchStatus,
                                                        String bankcheckFilter,
                                                        String transactionStartDate,
                                                        String transactionEndDate,
                                                        String transactionTypeFilter,
                                                        String transactionReferenceFilter,
                                                        String transactionAccountFilter,
                                                        String transactionAmountFilter)
    {
        List<Bank_Statement_Line_Item__c> bankStatementTransactions = bankStatementTransactions( recordId, bankStartDate, bankEndDate, bankTypeFilter, bankReferenceFilter, bankAmountFilter, bankstrMatchStatus, bankcheckFilter );
        List<Bank_Transaction__c> generalLedgerTransactions = generalLedgerTransactions( recordId, transactionStartDate, transactionEndDate, transactionTypeFilter, transactionReferenceFilter, transactionAccountFilter, transactionAmountFilter ); 

        //system.debug( '\n\n' + JSON.serialize(bankStatementTransactions) + '\n') ;
        //system.debug( '\n\n' + JSON.serialize(generalLedgerTransactions) + '\n') ;

        List<mergedTransaction> response = new List<mergedTransaction>();
        mergedTransaction t;

        for( Bank_Statement_Line_Item__c s : bankStatementTransactions ) {
            t = new mergedTransaction();
            t.TransactionDate = s.Transaction_Date_Display__c;
            t.CheckNumber = s.Addenda_1__c;
            t.Reference = s.Reference__c;
            t.Type = s.Type__c;
            t.amount = s.Amount__c;
            t.remainingAmount = s.Remaining_Amount__c;
            t.transactionType = 'Bank';
            t.recordId = s.Id;
            //system.debug(t);
            response.add(t);
        }

        for( Bank_Transaction__c gl: generalLedgerTransactions ) {
            t = new mergedTransaction();
            t.TransactionDate = gl.Transaction_Date_Display__c;
            t.account = gl.Account__c;
            t.Reference = gl.Reference__c;
            t.Type = gl.Transaction_Type__c;
            t.amount = gl.Amount__c;            
            t.transactionType = 'GL';
            t.recordId = gl.id;
            //system.debug(t);
            response.add(t);
        }
        
        //System.debug(response);
        return response;
    }

    public class MergedTransaction {
        @AuraEnabled public date TransactionDate;
        @AuraEnabled public string CheckNumber;
        @AuraEnabled public string Reference;
        @AuraEnabled public string Type;
        @AuraEnabled public double amount;
        @AuraEnabled public double remainingAmount;
        @AuraEnabled public string matchedStatus;
        @AuraEnabled public string account;
        @AuraEnabled public string transactionType;
        @AuraEnabled public id recordId;
    }
}