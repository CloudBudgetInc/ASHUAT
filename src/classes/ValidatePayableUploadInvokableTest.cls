@isTest(SeeAllData=true)
public class ValidatePayableUploadInvokableTest {

    public static testMethod void testInvokable() {
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Payable_Invoice_Upload__c testUpload = new Payable_Invoice_Upload__c();
        testUpload.Accounting_Company__c = provider.getCompany('ASH');
        c2g__codaPeriod__c somePeriod = provider.getPeriod('ASH', '202308');
        testUpload.Period__c = somePeriod.Id;
        insert testUpload;
        
        Attachment att = new Attachment(Name='test-invoice-upload.csv');
        String header = 'Company,Account,Sub account,Amount ,Traveler Name';
        String line1 = '9400,250-380-000-00,238.60,FRANK/ANNABEL\n';
        String line2 = '5270,DDD-000-000-00,418.70,EVOYAN/LEVON\n';
        String line3 = '5270,112-CCC-000-00,418.70,EVOYAN/LEVON\n';
        String line4 = '5270,112-555-BBB-00,418.70,EVOYAN/LEVON\n';
        String line5 = '5270,112-555-000-AA,418.70,EVOYAN/LEVON\n';        
		String combinedJournal = header + line1 + line2 + line3 + line4 + line5;
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
        contentVersion.PathOnClient = 'somePayableInvoice.txt'; // The files name, extension is very important here which will help the file in preview.
        contentVersion.Title = 'Some Test PIN Upload'; // Display name of the files
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
        ValidatePayableInvoiceUploadInvokable.validatePayableInvoiceUpload(params);        
        
        List<Payable_Invoice_Upload_Line__c> results = [SELECT Id, Analysis__c, Failed__c 
			FROM Payable_Invoice_Upload_Line__c WHERE Payable_Invoice_Upload__c = :testUpload.Id ];
        System.assert(results.size() > 0);
        Payable_Invoice_Upload_Line__c badResult1 = [SELECT Id, Analysis__c, Failed__c FROM Payable_Invoice_Upload_Line__c 
			WHERE Subaccount__c = 'DDD-000-000-00' AND Payable_Invoice_Upload__c = :testUpload.Id ];
        System.assert(badResult1.Analysis__c.indexOf('not found') > 0);
        System.assertEquals(badResult1.Failed__c, true);
        Payable_Invoice_Upload_Line__c badResult2 = [SELECT Id, Analysis__c, Failed__c FROM Payable_Invoice_Upload_Line__c 
			WHERE Subaccount__c = '112-CCC-000-00' AND Payable_Invoice_Upload__c = :testUpload.Id ];
        System.assert(badResult2.Analysis__c.indexOf('not found') > 0);
        System.assertEquals(badResult2.Failed__c, true);
        Payable_Invoice_Upload_Line__c badResult3 = [SELECT Id, Analysis__c, Failed__c FROM Payable_Invoice_Upload_Line__c 
			WHERE Subaccount__c = '112-555-BBB-00' AND Payable_Invoice_Upload__c = :testUpload.Id ];
        System.assert(badResult3.Analysis__c.indexOf('not found') > 0);
        System.assertEquals(badResult3.Failed__c, true);
        Payable_Invoice_Upload_Line__c badResult4 = [SELECT Id, Analysis__c, Failed__c FROM Payable_Invoice_Upload_Line__c 
			WHERE Subaccount__c = '112-555-000-AA' AND Payable_Invoice_Upload__c = :testUpload.Id ];
        System.assert(badResult4.Analysis__c.indexOf('not found') > 0);
        System.assertEquals(badResult1.Failed__c, true);        
    }
}