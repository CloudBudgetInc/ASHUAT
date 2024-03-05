trigger PayableInvoiceUploadTrigger on Payable_Invoice_Upload__c (after update) {

    if (Trigger.isAfter && trigger.isUpdate )
    {
        for(Payable_Invoice_Upload__c upload : trigger.new) {
            
            if(Trigger.oldMap.get(upload.Id).Process_File__c != upload.Process_File__c ) {
                
        		FfaDataProvider dataProvider = FfaDataProvider.getInstance();
                
                // Fetch the CSV attached to the Payable Invoice Upload item.
                Id someId = upload.Id;
                List<ContentDocumentLink> someList = [SELECT Id, LinkedEntityId, ContentDocumentId
                                                      FROM ContentDocumentLink WHERE LinkedEntityId = :someId];  
                ContentDocumentLink cdl = someList.get(0);
                Id contentDocumentId = cdl.ContentDocumentId;
                ContentVersion someCv = [SELECT FileExtension, Title, versiondata FROM ContentVersion 
                                         WHERE ContentDocumentId = :contentDocumentId and IsLatest=true];
                Blob csvFileBody = someCv.VersionData;
                String csvAsString = csvFileBody.toString();
                List<String> csvFileLines = csvAsString.split('\n');
                
                // Grab the header line, then remove it so it is gone when we iterate thru the invoice lines.
                String headerLine = csvFileLines.get(0);
                List<String> headerSplits = headerLine.split(',');
                csvFileLines.remove(0);

                c2g__codaPurchaseInvoice__c  thisInvoice = new c2g__codaPurchaseInvoice__c();
                thisInvoice.Type__c = 'Invoice';
                thisInvoice.c2g__OwnerCompany__c = upload.Accounting_Company__c; 
                thisInvoice.c2g__DeriveCurrency__c = true;
                thisInvoice.c2g__Period__c = upload.Period__c;
                thisInvoice.c2g__DerivePeriod__c = false;
                thisInvoice.c2g__InvoiceDate__c = Date.today();
                thisInvoice.c2g__AccountInvoiceNumber__c = 'GTA/Amex - ' + Date.today().format();
                thisInvoice.c2g__InvoiceDescription__c = 'GTA/American Express - ' + Date.today().format();
                thisInvoice.c2g__Account__c = dataProvider.getVendor('AMER01').Id;
                insert thisInvoice;

                List<c2g__codaPurchaseInvoiceExpenseLineItem__c> linesForInsert = new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();                 
                for(String line : csvFileLines) {
                    
                    c2g__codaPurchaseInvoiceExpenseLineItem__c invoiceLine = new c2g__codaPurchaseInvoiceExpenseLineItem__c();
                    invoiceLine.c2g__PurchaseInvoice__c  = thisInvoice.Id;    
                    List<String> moreSplits = line.split(',');
                    
                    Integer i = 0;
                    String dimension2 = '';
                    Decimal netValue = 0.00;          
                    // Loop each column.
                    for( String more : moreSplits) {
                        if( i == 0 ) { 
                            invoiceLine.c2g__GeneralLedgerAccount__c = dataProvider.getGlaCode(more.substring(0,4));
                        }
                        else if( i == 1 ) {
                            invoiceLine.c2g__Dimension1__c = dataProvider.getDimension1(more.substring(0,3));
                            dimension2 = more.substring(4,7);
                            invoiceLine.c2g__Dimension2__c = dataProvider.getDimension2(dimension2);
                            invoiceLine.c2g__Dimension3__c = dataProvider.getDimension3(more.substring(8,11));
                            invoiceLine.c2g__Dimension4__c = dataProvider.getDimension4(more.substring(12,14));
                            
                            // ASHRC has designated programs, therefore we change certain values to intercompany 
                            // if the Program is flagged as ASHRC.
                            c2g__codaDimension2__c someDimension2 = dataProvider.getFullDimension2(dimension2);
                            if(someDimension2.ASHRC__c == true ) {
                                invoiceLine.c2g__DestinationCompany__c = dataProvider.getCompany('ASHRC');
                            }                               
                        }      
                        if( i == 2 ) { 
                            invoiceLine.c2g__NetValue__c = Decimal.valueOf(more);
                            netValue = Decimal.valueOf(more);
                            // ASHRC has designated programs, therefore we change certain values to intercompany 
                            // if the Program is flagged as ASHRC.
                            c2g__codaDimension2__c someDimension2 = dataProvider.getFullDimension2(dimension2);
                            if(someDimension2.ASHRC__c == true ) {
                                invoiceLine.c2g__DestinationNetValue__c = netValue;
                            }                                    
                        }
                        else if( i == 3 ) { 
                            invoiceLine.c2g__LineDescription__c  = more; 
                        }
                        i++;
                    }
                    linesForInsert.add(invoiceLine);
               }
               insert linesForInsert;
            }
        }
    }
}