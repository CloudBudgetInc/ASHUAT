global class PrepBankTransactionsBatch implements Database.Batchable<sObject> {

    String periodId;
    String generalLedgerId;
    
    /**
     * This class takes a period's cash/bank-related transactions and augments them with information from 
     * the related Cash Entry and Payment objects. This is needed to support the bank/cash matching processes.
     */
    public PrepBankTransactionsBatch(String period, String generalLedger) {
        this.periodId = period;
        this.generalLedgerId = generalLedger;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) { 
        
        String query = 'SELECT Id, c2g__Account__r.Name, c2g__TransactionDate__c,  c2g__Transaction__r.c2g__TransactionType__c, ' + 
            'c2g__Transaction__r.c2g__CashEntry__r.c2g__PaymentMethod__c, c2g__LineDescription__c, ' + 
            'c2g__Transaction__r.c2g__Journal__r.Name, c2g__Transaction__r.c2g__Journal__r.Personify_Journal__c, ' +
            'c2g__Transaction__r.c2g__CashEntry__r.c2g__Reference__c, ' + 
            'c2g__Transaction__r.c2g__CashEntry__r.c2g__PaymentNumber__r.Name, ' + 
            'c2g__Transaction__r.c2g__CashEntry__r.c2g__BankAccount__r.c2g__ReportingCode__c, c2g__HomeValue__c ' + 
            'FROM c2g__codaTransactionLineItem__c ' + 
            'WHERE c2g__Transaction__r.c2g__Period__r.Id = :periodId ' + 
            'AND c2g__GeneralLedgerAccount__c = :generalLedgerId';
        return Database.getQueryLocator(query);
    }
        
    global void execute(Database.BatchableContext BC, List<c2g__codaTransactionLineItem__c> someBankTransactions) {
        
        List<Bank_Transaction__c> forInsert = new List<Bank_Transaction__c>();
        for(c2g__codaTransactionLineItem__c someItem : someBankTransactions) {

            if( someItem.c2g__Transaction__r.c2g__TransactionType__c == 'Cash') { 
                String reportingCode = someItem.c2g__Transaction__r.c2g__CashEntry__r.c2g__BankAccount__r.c2g__ReportingCode__c;
                String type = reportingCode.right(reportingCode.length()-5);
                String reference;
                if(type == 'Check') { 
					reference = someItem.c2g__Transaction__r.c2g__CashEntry__r.c2g__Reference__c;
                }
                else {
                    reference = someItem.c2g__Transaction__r.c2g__CashEntry__r.c2g__PaymentNumber__r.Name;
                }
      	   		Bank_Transaction__c newBankTransaction = new Bank_Transaction__c(
                    Account__c = someItem.c2g__Account__r.Name, 
					Amount__c = someItem.c2g__HomeValue__c, 
                    General_Ledger_Account__c = generalLedgerId, 
					Period__c = periodId, 
					Reference__c = reference,
                    Transaction__c = someItem.c2g__Transaction__c,
                    Transaction_Type__c = lookup(type),
                    Transaction_Date__c = someItem.c2g__TransactionDate__c);
            	forInsert.add(newBankTransaction);
			}
            else { // Journal
                // We need to eliminate Personify journals here, as the data needs to imported 
                // separately for adequate coverage on the reconciliations. 
                if(!someItem.c2g__Transaction__r.c2g__Journal__r.Personify_Journal__c) {
                    Bank_Transaction__c newBankTransaction = new Bank_Transaction__c(
                        Account__c = someItem.c2g__LineDescription__c, 
                        Amount__c = someItem.c2g__HomeValue__c, 
                        General_Ledger_Account__c = generalLedgerId, 
                        Period__c = periodId, 
                        Reference__c = someItem.c2g__Transaction__r.c2g__Journal__r.Name,
                        Transaction__c = someItem.c2g__Transaction__c,
                        Transaction_Type__c = 'Journal',
                        Transaction_Date__c = someItem.c2g__TransactionDate__c);
                    forInsert.add(newBankTransaction);   
                }
            }
        }
        insert forInsert;
    }
    
    /**
     * Cross-walks bank account reporting codes to human-readable transaction types.
     */
    private String lookup(String type) {
        if(type == 'ACH') return 'ACH';
        if(type == 'Check') return 'Check';
        if(type == 'DOM') return 'Domestic Wire';
        if(type == 'INT-WIRE') return 'International Wire';
        if(type == 'MAN-WIRE') return 'Manual Wire';
        return 'Unknown';
    }
    
    global void finish(Database.BatchableContext bc) {}
}