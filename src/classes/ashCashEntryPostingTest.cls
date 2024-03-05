@isTest(SeeAllData=true)
private class ashCashEntryPostingTest {
    
    @isTest
    static void testCashEntryPosting() {
         asp04__Payment__c testPayment = new asp04__Payment__c(
           asp04__Amount__c = 100.00,
           asp04__Payment_Stage__c = 'Collected from customer',
           asp04__Payment_Route_Selected__c = 'Card'                     
        );
        insert testPayment;     
           Account acc = new Account(Name='TestAccount');
            insert acc;
        c2g__codaCompany__c testCompany = new c2g__codaCompany__c(Name='TestCompany');

        

            c2g__codaCashEntry__c testCashEntry = new c2g__codaCashEntry__c(            
                c2g__Account__c = acc.Id,
              ffasp__Payment__c = testPayment.Id
            );
        insert testCashEntry; 


        ashCashEntryPosting queueable = new ashCashEntryPosting(testCashEntry.Id);


        Test.startTest();
        Id jobId = System.enqueueJob(queueable);
        Test.stopTest();


    }
}