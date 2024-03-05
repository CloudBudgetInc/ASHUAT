/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(SeeAllData=True)
private class FinReviewControllerTest {

    @isTest 
    static void testBalances() {
        Map<String,String> defaultValues = FinReviewController.defaults();
        String defaultCompany = defaultValues.get('Company');
        String defaultYear = defaultValues.get('Year');

        List<FinReviewController.Balance> result = FinReviewController.balances(defaultCompany, defaultYear);
    }

    @isTest 
    static void testTransactions() {
        Map<String,String> defaultValues = FinReviewController.defaults();
        String defaultCompany = defaultValues.get('Company');
        String defaultYear = defaultValues.get('Year');

        List<c2g__codaTransactionLineItem__c> result = FinReviewController.transactions(defaultCompany, defaultYear, key());
    }

    @isTest 
    static void testTransactionsVF() {
        Map<String,String> defaultValues = FinReviewController.defaults();
        String defaultCompany = defaultValues.get('Company');
        String defaultYear = defaultValues.get('Year');

        List<c2g__codaTransactionLineItem__c> result = FinReviewController.transactionsVF(defaultCompany, defaultYear, key(), 1,1);
    }
    
    
    @isTest 
    static void testIncome() {
         List<FinReviewController.Income> result = FinReviewController.income('ASHRC', '395');
    }
    
     @isTest 
    static void testbaseURL() {
         String result = FinReviewController.baseURL();
    }

    /**
    @isTest 
    static void testTransactionsToo() {
        c2g__codaTransactionLineItem__c tran = transaction();
        
        String defaultCompany = tran.c2g__OwnerCompany__r.Key__c;
        String defaultYear = tran.c2g__Transaction__r.c2g__Period__r.Fiscal_Year_Text__c;
        String defaultKey = tran.Account_Subaccount__c;

        List<FinReviewController.TransactionRow> result = FinReviewController.transactionsToo( defaultCompany, defaultYear, defaultKey );
    }*/

    @isTest 
    static void testfilters() {
        List<FinReviewController.FilterTag> result = FinReviewController.filters();
    }
    
    @isTest 
    static void testfiltersTb3() {
        List<FinReviewController.FilterTag> result = FinReviewController.filtersTb3( ledgerAccount().c2g__TrialBalance1__c );
    }
    
    @isTest 
    static void testPeriods() {
        List<FinReviewController.FilterTag> result = FinReviewController.tags( periods() );
    }
    
    @isTest 
    static void testInsertComment() {
        Map<String,String> defaultValues = FinReviewController.defaults();
        String defaultCompany = defaultValues.get('Company');
        
        Id result = FinReviewController.insertComment( defaultCompany, key(), 'test-comment', UserInfo.getUserId() );
    }
    
    @isTest 
    static void testRespondComment() {
        Map<String,String> defaultValues = FinReviewController.defaults();
        String defaultCompany = defaultValues.get('Company');
        
        Id result = FinReviewController.respondComment( defaultCompany, key(), 'test-comment', UserInfo.getUserId() );
    }
    
    @isTest 
    static void testComments() {
        Map<String,String> defaultValues = FinReviewController.defaults();
        String defaultCompany = defaultValues.get('Company');
        
        List<Comment__c> result = FinReviewController.comments( defaultCompany, key(), true );
    }
    
     
    @isTest 
    static void testArchiveComment() {
       boolean result = FinReviewController.archiveComment( key(), true );
    }
    
    @isTest 
    static void testarchiveAllComments() {
        Map<String,String> defaultValues = FinReviewController.defaults();
        String defaultCompany = defaultValues.get('Company');
        boolean result = FinReviewController.archiveAllComments( defaultCompany, key() );
    }
    
    @isTest 
    static void testGetAssignableUsers() {
        List<FinReviewController.UserOption> result = FinReviewController.getAssignableUsers();
    }
    
    private static c2g__codaTransactionLineItem__c transaction() {
        List<c2g__codaTransactionLineItem__c> items = [ SELECT Account_Subaccount__c, c2g__Transaction__r.c2g__Period__r.Fiscal_Year_Text__c, c2g__OwnerCompany__r.Key__c FROM c2g__codaTransactionLineItem__c LIMIT 1 ];

        if( !items.isEmpty() ) {
            return items.get(0);
        } else {
            return null;
        }
    }

    private static string key() {
        List<c2g__codaTransactionLineItem__c> items = [ SELECT Account_Subaccount__c FROM c2g__codaTransactionLineItem__c LIMIT 1 ];

        if( !items.isEmpty() ) {
            return items.get(0).Account_Subaccount__c;
        } else {
            return null;
        }

    }
    
    private static c2g__codaGeneralLedgerAccount__c ledgerAccount() {
        List<c2g__codaGeneralLedgerAccount__c> accounts = [ SELECT c2g__TrialBalance1__c FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__TrialBalance1__c != '' LIMIT 1] ;    
        if( !accounts.isEmpty() ) {
            return accounts.get(0);
        } else {
            return null;
        }
        
    }
    
    private static List<c2g__codaPeriod__c> periods() {
        List<c2g__codaPeriod__c> periods = [SELECT c2g__codaPeriod__c.Name FROM c2g__codaPeriod__c LIMIT 1];
        if( !periods.isEmpty() ) {
            return periods;
        } else {
            return null;
        }
    }
    
    

}