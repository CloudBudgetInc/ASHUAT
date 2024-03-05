@isTest(SeeAllData=true)
public class ReconcilerControllerTest {

    @isTest
    public static void testDataFetch() {
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
		Id company = provider.getCompany('ASH');        
        c2g__codaPeriod__c somePeriod = provider.getPeriod('ASH', '202402');        
        Id someGeeElAccount = provider.getGlaCode('1018');
        
        Bank_Statement__c bs = new Bank_Statement__c();
        insert bs;        
        List<Bank_Statement_Line_Item__c> statementRecords = new List<Bank_Statement_Line_Item__c>();
        List<Bank_Transaction__c> bankTransactionRecords = new List<Bank_Transaction__c>();
        System.debug(date.today().addDays(-1));
        
        for (Integer i = 0; i < 5; i++) {
            statementRecords.add(new Bank_Statement_Line_Item__c(
                Amount__c = 100.00,
                Match_Status__c = 'Unmatched',
                Transaction_Date__c = date.today().addDays(-1),
                Type__c = 'ACH',
                Reference__c = '2',                
                General_Ledger_Account__c = someGeeElAccount,
                Bank_Statement__c = bs.id,
                Addenda_1__c = '123'                
            ));
		
            bankTransactionRecords.add(new Bank_Transaction__c(
                Amount__c = 100.00,
                Match_Status__c = 'Unmatched',
                Transaction_Date__c = date.today().addDays(-1),
                Transaction_Type__c = 'ACH',
                Reference__c = '2',
                Period__c = somePeriod.Id,
                General_Ledger_Account__c = someGeeElAccount,
                Account__c = '2'                
            ));
        }
        insert statementRecords;
        insert bankTransactionRecords;        

        // Set up rec template and rec; required to correctly identify the bank statement lines / transactions in question.
        Reconciliation_Template__c someTemplate = new Reconciliation_Template__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = company);
        insert someTemplate;
        Reconciliation__c someReconcilation = new Reconciliation__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = company, Period__c = somePeriod.Id, Reconciliation_Template__c = someTemplate.Id);
        insert someReconcilation;
        System.debug(someReconcilation);
        
        List<sObject> results = ReconcilerController.bankStatementTransactions( someReconcilation.Id,
            																   string.valueOf(date.today().addDays(-120)),
                                                                               string.valueOf(date.today()), 
                                                                               'ACH', // Type
                                                                               '', // Reference
                                                                               '', // Amount
                                                                               'All', // Match Status
                                                                               ''); // Check Filter
        System.assert(results.size() > 0);
        
        List<sObject> moreResults = ReconcilerController.bankStatementTransactions( someReconcilation.Id,
            																   string.valueOf(date.today().addDays(-120)),
                                                                               string.valueOf(date.today()), 
                                                                               'ACH', // Type
                                                                               'Zaijsowi', // Reference
                                                                               '998.00', // Amount
                                                                               'All', // Match Status
                                                                               ''); // Check Filter
        System.assert(moreResults.size() == 0);        
        
        List<sObject> evenMoreResults = ReconcilerController.generalLedgerTransactions(someReconcilation.Id,
            																   string.valueOf(date.today().addDays(-120)), 
                                                                               string.valueOf(date.today()), 
                                                                               'ACH', 
                                                                               '', 
                                                                               '', 
                                                                               '');
        System.assert(evenMoreResults.size() > 0);
        
        List<ReconcilerController.MergedTransaction> yepMoreResults = ReconcilerController.transactions(someReconcilation.Id,
            																   string.valueOf(date.today().addDays(-120)), 
                                                                               string.valueOf(date.today()), 
                                                                               'ACH', // Type
                                                                               'Zaijsowi', // Reference
                                                                               '998.00', // Amount
                                                                               'All', // Match Status
                                                                               '', // Check Filter
            																   string.valueOf(date.today().addDays(-120)), 
                                                                               string.valueOf(date.today()), 
                                                                               'ACH', 
                                                                               '', 
                                                                               '', 
                                                                               '');    
        System.assert(yepMoreResults.size() > 0);             
    }

    @isTest
    public static void testMatchHandling() {
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id someGeeElAccount = provider.getGlaCode('1018');
        c2g__codaPeriod__c somePeriod = provider.getPeriod('ASH', '202402');
		Id company = provider.getCompany('ASH'); 
        
        Reconciliation_Template__c someTemplate = new Reconciliation_Template__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = company);
        insert someTemplate;
        Reconciliation__c someReconcilation = new Reconciliation__c(General_Ledger_Account__c = someGeeElAccount, 
			Accounting_Company__c = company, Period__c = somePeriod.Id, Reconciliation_Template__c = someTemplate.Id);
        insert someReconcilation;
        
        Bank_Statement__c bs = new Bank_Statement__c();
        insert bs;        
        List<Bank_Statement_Line_Item__c> statementLinesForInsert = new List<Bank_Statement_Line_Item__c>();
        List<Bank_Transaction__c> bankTransactionsForInsert = new List<Bank_Transaction__c>();
        
        for (Integer i = 0; i < 5; i++) {
            statementLinesForInsert.add(new Bank_Statement_Line_Item__c(
                Amount__c = 100.00,
                Match_Status__c = 'Unmatched',
                Transaction_Date__c = date.today().addDays(-1),
                Type__c = 'ACH',
                General_Ledger_Account__c = someGeeElAccount,
                Bank_Statement__c = bs.id
            ));

            bankTransactionsForInsert.add(new Bank_Transaction__c(
                Amount__c = 100.00,
                Match_Status__c = 'Unmatched',
                Transaction_Date__c = date.today().addDays(-1),
                Transaction_Type__c = 'ACH',
                Reference__c = '2',
                Period__c = somePeriod.Id,
                General_Ledger_Account__c = someGeeElAccount,
                Account__c = '2'
            ));
        }
        insert statementLinesForInsert;
        insert bankTransactionsForInsert;            
        
        List<Bank_Statement_Line_Item__c> statementRecords = [SELECT Id FROM Bank_Statement_Line_Item__c];
        List<Bank_Transaction__c> bankTransactionRecords = [SELECT Id FROM Bank_Transaction__c];
        List<String> statementIds = new List<String>();
        List<String> bankTransactionIds = new List<String>();
        for (Bank_Statement_Line_Item__c statement : statementRecords) {
            statementIds.add(statement.Id);
        }
        for (Bank_Transaction__c bankTransaction : bankTransactionRecords) {
            bankTransactionIds.add(bankTransaction.Id);
        }
        boolean result = ReconcilerController.handleMatch(statementIds, bankTransactionIds, someReconcilation.Id);
        System.assertEquals(true, result);
    }

    /**
    @isTest
    public static void testResetMethodAfterHandleMatch() {
        List<Bank_Statement_Line_Item__c> statementRecords = [SELECT Id, Match_Status__c FROM Bank_Statement_Line_Item__c];
        List<Bank_Transaction__c> bankTransactionRecords = [SELECT Id, Match_Status__c FROM Bank_Transaction__c];
        List<String> selectedStatementRowIds = new List<String> { statementRecords[0].Id };
        List<String> selectedBankTransactionRowIds = new List<String>();
        for (Bank_Transaction__c bankTransaction : bankTransactionRecords) {
            selectedBankTransactionRowIds.add(bankTransaction.Id);
        }
        boolean matchResult = ReconcilerController.handleMatch(selectedStatementRowIds, selectedBankTransactionRowIds, null);
        System.assertEquals(true, matchResult);
        ReconcilerController.reset();
        List<Bank_Statement_Line_Item__c> updatedStatementRecords = [SELECT Id, Match_Status__c FROM Bank_Statement_Line_Item__c WHERE Id IN :selectedStatementRowIds];
        List<Bank_Transaction__c> updatedBankTransactionRecords = [SELECT Id, Match_Status__c FROM Bank_Transaction__c WHERE Id IN :selectedBankTransactionRowIds];
        for (Bank_Statement_Line_Item__c updatedRecord : updatedStatementRecords) {
            System.assertEquals('Unmatched', updatedRecord.Match_Status__c); 
        }
        for (Bank_Transaction__c updatedRecord : updatedBankTransactionRecords) {
            System.assertEquals('Unmatched', updatedRecord.Match_Status__c);
        }
    }
	*/
}