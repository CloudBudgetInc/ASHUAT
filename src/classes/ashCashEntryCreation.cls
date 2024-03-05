//Cash Entry Creation for Web Donation
Global class ashCashEntryCreation {     
    
    Global class FlowInput {
        @InvocableVariable(label='Invoice ID' required=true)
        Global Id invoiceId;
        
        @InvocableVariable(label='Cash Entry Type' required=true)
        Global string cashEntryType; 
        
        @InvocableVariable(label='Post Cash Entry' required=false)
        Global Boolean isCashEntryPosted;
        
        @InvocableVariable(label='Asperato Payment ID' required=false)
        Global Id asperatoId;
        
        @InvocableVariable(label='ASH Transaction Type' required=false)
        Global string ashType;
    }
    
    global class FlowResponse {
        @InvocableVariable
        Global String CashEntryID;
    }
    
    @InvocableMethod(label='Create Cash Entry and Line Items from Invoice')
    public static void createCashEntryFromInvoice(List<FlowInput> requestData) {
        // Since we are handling one invoice at a time, we take the first element from the list.
        //InvoiceData data = requestData[0];
        insert new ASH_System_Logs__c(Message__c='Cash Entry started for' + requestData, Object__c='Cash Entry', Reference_ID__c = requestData[0].invoiceId);      
        
        
		Id invoiceId = requestData[0].invoiceId;
		string cashEntryType = requestData[0].cashEntryType;
        
        Boolean shouldPost = requestData[0].isCashEntryPosted != null ? requestData[0].isCashEntryPosted : false; // Default to false if not provided
        
        string ashType = requestData[0].ashType != null ? requestData[0].ashType : 'Default'; // Default to false if not provided
        
        Id asperatoId = requestData[0].asperatoId;
        try {
            // Query the Invoice record
            c2g__codaInvoice__c invoice = [
                SELECT Id, Name, c2g__Account__c, c2g__OwnerCompany__c, c2g__InvoiceCurrency__c,                        
                       c2g__Period__c, c2g__InvoiceTotal__c, c2g__Dimension1__c, c2g__Dimension2__c, c2g__Dimension3__c, c2g__Dimension4__c
                FROM c2g__codaInvoice__c
                WHERE Id = :invoiceId
            ];
			
            c2g__codaCompany__c ownerCompany = [Select Id, c2g__BankAccount__c from c2g__codaCompany__c WHERE Id = :invoice.c2g__OwnerCompany__c];
            
            c2g__codaBankAccount__c companyBankAccount = [Select Id, c2g__Dimension1__c, c2g__Dimension2__c, c2g__Dimension3__c, c2g__Dimension4__c From c2g__codaBankAccount__c where Id = :ownerCompany.c2g__BankAccount__c];
            
            // Create the Cash Entry record
            c2g__codaCashEntry__c cashEntry = new c2g__codaCashEntry__c(
                c2g__Account__c = invoice.c2g__Account__c,
                c2g__BankAccountDimension1__c = companyBankAccount.c2g__Dimension1__c,
                c2g__BankAccountDimension2__c = companyBankAccount.c2g__Dimension2__c,
                c2g__BankAccountDimension3__c = companyBankAccount.c2g__Dimension3__c,
                c2g__BankAccountDimension4__c = companyBankAccount.c2g__Dimension4__c,
                c2g__CashEntryCurrency__c = invoice.c2g__InvoiceCurrency__c,
                c2g__ChargesGLA__c = 'a8C3u000000XcpI', // Need to update this later.
                c2g__PaymentMethod__c = 'Electronic', 
                c2g__Period__c = invoice.c2g__Period__c,
                c2g__Type__c = cashEntryType,
                ffasp__Payment__c = asperatoId,
                ASH_Type__c = ashType
            );

            try {
            insert cashEntry;
			System.debug('Cash Entry ID: ' + cashEntry.Id);
            insert new ASH_System_Logs__c(Message__c='Cash Entry ID: ' + cashEntry.Id, Object__c='Cash Entry', Reference_ID__c = cashEntry.Id);
			//creating the Cash Entry Line Items
            createCashEntryLineItems(invoice, cashEntry);         
			}
            catch (Exception ce){
            System.debug('Error creating Cash Entry: ' + ce.getMessage());
            System.debug('Error Stack Message: ' + ce.getStackTraceString());
            insert new ASH_System_Logs__c(Message__c='Error Message' + ce.getMessage(), Object__c='Cash Entry', Reference_ID__c = invoiceId);
			insert new ASH_System_Logs__c(Message__c='Error Message Stack' + ce.getStackTraceString(), Object__c='Cash Entry', Reference_ID__c = invoiceId);
            }            

            // Posting Cash Entry 
            if(shouldPost){//ashCashEntryCreation.postCashEntry(cashEntry.Id);
             System.enqueueJob(new ashCashEntryPosting(cashEntry.Id));
            } 
			
        } catch (Exception e) {
            // error handling
            System.debug('Error creating Cash Entry: ' + e.getMessage());
            // Other error handling logics.
        }
    }

    private static void createCashEntryLineItems(c2g__codaInvoice__c invoice, c2g__codaCashEntry__c cashEntry) {
        try {            
            	c2g__codaCashEntryLineItem__c lineItem = new c2g__codaCashEntryLineItem__c(
                c2g__CashEntry__c = cashEntry.Id,
                c2g__AccountDimension1__c = invoice.c2g__Dimension1__c,
                c2g__AccountDimension2__c = invoice.c2g__Dimension2__c,
                c2g__AccountDimension3__c = invoice.c2g__Dimension3__c,
                c2g__AccountDimension4__c = invoice.c2g__Dimension4__c,
                //c2g__AccountPaymentMethod__c = 
                //c2g__AccountReference__c =  invoice.Id,
                c2g__Account__c = invoice.c2g__Account__c, 
                c2g__BankAccountValue__c = invoice.c2g__InvoiceTotal__c, 
                c2g__CashEntryValue__c = invoice.c2g__InvoiceTotal__c,
                c2g__DocumentsToMatch__c = invoice.Name                
            );
            
            insert lineItem;       
         	insert new ASH_System_Logs__c(Message__c='Cash Entry Line Item ID: ' + lineItem.Id, Object__c='Cash Entry Line Item', Reference_ID__c = lineItem.Id);

        } catch (Exception e) {
            // Handle any exceptions specific to line item creation
            System.debug('Error creating Cash Entry Line Item: ' + e.getMessage());
			insert new ASH_System_Logs__c(Message__c='Error Message' + e.getMessage(), Object__c='Cash Entry', Reference_ID__c = 'NA');
        }
    }    
}