@isTest(SeeAllData=true)
public class ValidateJournalUploadInvokableTest {

    public static testMethod void testInvokable() {
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
		Journal_Upload__c testUpload = new Journal_Upload__c();
        testUpload.Accounting_Company__c = provider.getCompany('ASH');
        c2g__codaPeriod__c somePeriod = provider.getPeriod('ASH', '202308');
        testUpload.Period__c = somePeriod.Id;
        insert testUpload;
        
        Attachment att = new Attachment(Name='test-journal.csv');
        String header = 'JER,Sesame Street,2/28/2023,Miscellaneous,,,,,,J-10A,Junior Accountant Workflow,System GL Calendar,July 2021,667754.85,2/9/2023,Y,N\n';
        String line1 = 'JEI,211645.51,D,,Bond /Treasury Invst-Vanguard,ASH,,,,1165-100-000-000-00,,,,,          ,,\n';
        String line2 = 'JEI,211645.51,D,,Bond /Treasury Invst-Vanguard,ASH,,,,9876-100-000-000-00,,,,,          ,,\n';         
        String line3 = 'JEI,211645.51,D,,Bond /Treasury Invst-Vanguard,ASH,,,,1165-665-000-000-00,,,,,          ,,\n'; 
        String line4 = 'JEI,211645.51,D,,Bond /Treasury Invst-Vanguard,ASH,,,,1165-100-555-000-00,,,,,          ,,\n'; 
        String line5 = 'JEI,211645.51,D,,Bond /Treasury Invst-Vanguard,ASH,,,,1165-100-000-555-00,,,,,          ,,\n'; 
        String line6 = 'JEI,211645.51,D,,Bond /Treasury Invst-Vanguard,ASH,,,,1165-665-000-000-18,,,,,          ,,\n'; 
		String combinedJournal = header + line1 + line2 + line3 + line4 + line5 + line6;
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
        contentVersion.PathOnClient = 'someJournal.txt'; // The files name, extension is very important here which will help the file in preview.
        contentVersion.Title = 'Some Test Journal'; // Display name of the files
        contentVersion.VersionData = Blob.valueOf(combinedJournal);
        insert contentVersion;       
        
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id].ContentDocumentId;
        ContentDocumentLink conDocLink = New ContentDocumentLink();
        conDocLink.LinkedEntityId = testUpload.Id; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object)
        conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
        conDocLink.shareType = 'V';
        insert conDocLink;           
        
        List<String> nestedParams = new List<String>();
        List<List<String>> params = new List<List<String>>();
        nestedParams.add(testUpload.Id);
        params.add(nestedParams);
        ValidateJournalUploadInvokable.validateJournalUpload(params);        
        
        List<Journal_Upload_Line__c> results = [SELECT Id, Analysis__c, Failed__c FROM Journal_Upload_Line__c WHERE Journal_Upload__c = :testUpload.Id ];
        System.assert(results.size() > 0);
        Journal_Upload_Line__c badResult = [SELECT Id, Analysis__c, Failed__c FROM Journal_Upload_Line__c 
			WHERE Account_Subaccount__c = '1165-665-000-000-00' AND Journal_Upload__c = :testUpload.Id ];
        System.assert(badResult.Analysis__c.indexOf('not found') > 0);
        System.assertEquals(badResult.Failed__c, true);
    }
}