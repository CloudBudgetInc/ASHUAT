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
private class TransactionDetailsControllerTest {

    @isTest
    static void testTransactionDetailsControllerTest() {
        
        Map<String,String> defaultValues = FinReviewController.defaults();
        String defaultCompany = defaultValues.get('Company');
        String defaultYear = defaultValues.get('Year');
        
        PageReference pageRef = Page.TransactionDetails; 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('company', defaultCompany );
        ApexPages.currentPage().getParameters().put('year', defaultYear );
        ApexPages.currentPage().getParameters().put('key', key() );

     
        TransactionDetailsController controller = new TransactionDetailsController();
     
    }
    
    @isTest 
    static void testGetTotalPages() {
        TransactionDetailsController controller = new TransactionDetailsController();
        Integer result = controller.getTotalPages();
    }
    
    @isTest 
    static void testNextPage() {
        TransactionDetailsController controller = new TransactionDetailsController();
        controller.nextPage();
    }
    
    @isTest 
    static void testPreviousPage() {
        TransactionDetailsController controller = new TransactionDetailsController();
        controller.previousPage();
    }
    
    @isTest 
    static void testGetPrevAvailable() {
        TransactionDetailsController controller = new TransactionDetailsController();
        Boolean result = controller.getPrevAvailable();
    }
    
    @isTest 
    static void testGetNextAvailable() {
        TransactionDetailsController controller = new TransactionDetailsController();
        Boolean result = controller.getNextAvailable();
    }
    
    private static string key() {
        List<c2g__codaTransactionLineItem__c> items = [ SELECT Account_Subaccount__c FROM c2g__codaTransactionLineItem__c LIMIT 1 ];

        if( !items.isEmpty() ) {
            return items.get(0).Account_Subaccount__c;
        } else {
            return null;
        }

    }
}