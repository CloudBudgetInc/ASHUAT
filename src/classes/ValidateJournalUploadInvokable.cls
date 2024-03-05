public class ValidateJournalUploadInvokable {

    @InvocableMethod(label='Validate Journal Upload' 
                     description='Validates a journal upload; identifies lines containing non-existant accounting codes.' 
                     category='Journals')
    public static void validateJournalUpload(List<List<String>> params) {    
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
        
   		List<String> nestedParams = params.get(0);
        String journalUploadId = nestedParams.get(0);

        // fetch the CSV attached to the Journal Upload item.
        List<ContentDocumentLink> someList = [SELECT Id, LinkedEntityId, ContentDocumentId
                                              FROM ContentDocumentLink WHERE LinkedEntityId = :journalUploadId];  
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
        
		List<Journal_Upload_Line__c> someUploadLines = new List<Journal_Upload_Line__c>();        
        for( String line : csvFileLines)
        {
            List<String> moreSplits = line.split(',');
            
            Integer i = 0;
            for( String more : moreSplits) {
                if( i == 9 ) { 
                    System.debug(more);
                    Journal_Upload_Line__c someUploadLine = new Journal_Upload_Line__c(Journal_Upload__c = journalUploadId, 
						Account_Subaccount__c = more, Analysis__c = '');
                    if(more.length() <> 19) {
                    	someUploadLine.Analysis__c += 'Account-subaccount string improper length.';
                        someUploadLine.Failed__c = true;
			            someUploadLines.add(someUploadLine); 
                        i++;
                        continue;
                    }
                    if(provider.checkGlaCode(more.substring(0,4)) == false) { 
                    	someUploadLine.Analysis__c += 'General ledger code not found. ';
                        someUploadLine.Failed__c = true;
                    }
                    if(provider.checkDimension1(more.substring(5,8)) == false) { 
						someUploadLine.Analysis__c += 'Department code not found. ';
                        someUploadLine.Failed__c = true;
                    }
                    if(provider.checkDimension2(more.substring(9,12)) == false) { 
						someUploadLine.Analysis__c += 'Program code not found. ';
                        someUploadLine.Failed__c = true;
                    }   
                    if(provider.checkDimension3(more.substring(13,16)) == false) { 
						someUploadLine.Analysis__c += 'Project code not found. ';
                        someUploadLine.Failed__c = true;
                    }  
                    if(provider.checkDimension4(more.substring(17,19)) == false) { 
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