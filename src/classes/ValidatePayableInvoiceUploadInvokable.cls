public class ValidatePayableInvoiceUploadInvokable {

    @InvocableMethod(label='Validate Payable Invoice Upload' 
                     description='Validates a Payable Invoice upload; identifies lines containing non-existant accounting codes.' 
                     category='Payable Invoices')
    public static void validatePayableInvoiceUpload(List<List<String>> params) {    
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
        
   		List<String> nestedParams = params.get(0);
        String payableInvoiceUploadId = nestedParams.get(0);
        System.debug(payableInvoiceUploadId);

        // fetch the CSV attached to the Journal Upload item.
        List<ContentDocumentLink> someList = [SELECT Id, LinkedEntityId, ContentDocumentId
                                              FROM ContentDocumentLink WHERE LinkedEntityId = :payableInvoiceUploadId];  
        ContentDocumentLink cdl = someList.get(0);
        Id contentDocumentId = cdl.ContentDocumentId;
        ContentVersion someCv = [SELECT FileExtension, Title, versiondata FROM ContentVersion 
                                 WHERE ContentDocumentId = :contentDocumentId and IsLatest=true];
        Blob csvFileBody = someCv.VersionData;
        String csvAsString = csvFileBody.toString();
        List<String> csvFileLines = csvAsString.split('\n');
        
        // Grab the header line, then remove it so it is gone when we iterate thru the journal lines.
        String headerLine = csvFileLines.get(0);
        List<String> headerSplits = headerLine.split(',');
        csvFileLines.remove(0);
        System.debug('Lines count: ' + csvFileLines.size());
        
		List<Payable_Invoice_Upload_Line__c> someUploadLines = new List<Payable_Invoice_Upload_Line__c>();        
        for( String line : csvFileLines)
        {
            List<String> moreSplits = line.split(',');
            Integer i = 0;
            System.debug('processing line: ' + i);
            for( String more : moreSplits) {
				if (i == 1) {
                    Payable_Invoice_Upload_Line__c someUploadLine = new Payable_Invoice_Upload_Line__c(
                        Payable_Invoice_Upload__c = payableInvoiceUploadId, Subaccount__c = more, Analysis__c = '');
                    if(more.length() <> 14) {
                    	someUploadLine.Analysis__c += 'Subaccount string improper length.';
                        someUploadLine.Failed__c = true;
			            someUploadLines.add(someUploadLine); 
                        i++;
                        continue;
                    }
                    if(provider.checkDimension1(more.substring(0,3)) == false) { 
						someUploadLine.Analysis__c += 'Department code not found. ';
                        someUploadLine.Failed__c = true;
                    }
                    if(provider.checkDimension2(more.substring(4,7)) == false) { 
						someUploadLine.Analysis__c += 'Program code not found. ';
                        someUploadLine.Failed__c = true;
                    }   
                    if(provider.checkDimension3(more.substring(8,11)) == false) { 
						someUploadLine.Analysis__c += 'Project code not found. ';
                        someUploadLine.Failed__c = true;
                    }  
                    if(provider.checkDimension4(more.substring(12,14)) == false) { 
						someUploadLine.Analysis__c += 'Other code not found. ';
                        someUploadLine.Failed__c = true;
                    }                      
		            someUploadLines.add(someUploadLine);
                }
                i++;
            }
        }
        insert someUploadLines;
    }        
}