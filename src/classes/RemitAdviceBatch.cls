global class RemitAdviceBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful {

    boolean testMode = false;
    public RemitAdviceBatch(boolean testMode) {
        this.testMode = testMode;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        if(testMode) {
            String query = 'SELECT Id, c2g__Account__c, c2g__Account__r.Name, ' + 
                'Payment_Value_Total_Reversed__c, c2g__Payment__r.c2g__PaymentDate__c, ' + 
                'c2g__Payment__r.c2g__OwnerCompany__r.Key__c, c2g__Account__r.c2g__CODAInvoiceEmail__c, ' + 
                'c2g__Account__r.Staff_Email__c ' + 
                'FROM c2g__codaPaymentAccountLineItem__c ' + 
                'WHERE c2g__Payment__r.Force_Remit_Advice__c = true';
            return Database.getQueryLocator(query);            
        }
        else { 
            String query = 'SELECT Id, c2g__Account__c, c2g__Account__r.Name, ' + 
                'Payment_Value_Total_Reversed__c, c2g__Payment__r.c2g__PaymentDate__c, ' + 
                'c2g__Payment__r.c2g__OwnerCompany__r.Key__c, c2g__Account__r.c2g__CODAInvoiceEmail__c, ' + 
                'c2g__Account__r.Staff_Email__c ' + 
                'FROM c2g__codaPaymentAccountLineItem__c ' + 
                'WHERE c2g__Payment__r.CreatedDate = THIS_WEEK OR c2g__Payment__r.Force_Remit_Advice__c = true';
            return Database.getQueryLocator(query);
		}
    }
    
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new RemitAdviceBatch(false));
    }        
    
    global void execute(Database.BatchableContext BC, List<c2g__codaPaymentAccountLineItem__c> scope) {

        List<Remit_Advice__c> forInsert = new List<Remit_Advice__c>();
        
        List<c2g__codaPaymentLineItem__c> lineItems = [SELECT c2g__PaymentSummary__r.Id, c2g__TransactionValue__c, 
              c2g__Transaction__r.c2g__VendorDocumentNumber__c FROM c2g__codaPaymentLineItem__c 
              WHERE c2g__Payment__r.CreatedDate = THIS_WEEK OR 
			  c2g__Payment__r.Force_Remit_Advice__c = true];
        
        // Loop all the summaries, which are per account
        for( c2g__codaPaymentAccountLineItem__c paymentSummary : scope ) {
            
			// Setup.
            String invoicesPaid = '';
			List<String> formatArgs = new String[]{'0','number','###,###,##0.00'};

            // Loop details gathering vendor invoice numbers.                
            for( c2g__codaPaymentLineItem__c lineItem : lineItems) {
                if( lineItem.c2g__PaymentSummary__r.Id == paymentSummary.Id ) {

                    Double reversedValue = lineItem.c2g__TransactionValue__c * -1;
                    
                    // String formatting has some limitations, and after researching, this is 
                    // the most predictable way to solve issues surrounding right-padding with zeroes;
                    // that said, it is admittedly pretty barbaric.
                    String formattedValue = String.format(reversedValue.format(), formatArgs);
                    if(formattedValue.indexOf('.') == -1) {
                        formattedValue += '.00';
                    }
                    else if( formattedValue.right(2).startsWith('.') ) {
                        formattedValue += '0';
                    }

                    if(invoicesPaid.length() == 0) {
                        invoicesPaid += lineItem.c2g__Transaction__r.c2g__VendorDocumentNumber__c 
                            + ' ($' + formattedValue + ')';
                    } else {
                        invoicesPaid += (', ' + lineItem.c2g__Transaction__r.c2g__VendorDocumentNumber__c 
                                         + ' ($' + formattedValue + ')');
                    }
                }
            } // done looping line items.
            
            // Create a remit advice item if the notification email isn't null.
            if( paymentSummary.c2g__Account__r.c2g__CODAInvoiceEmail__c <> null ) { 
                
                String invoicesPaidRevised = invoicesPaid;
                if(invoicesPaid.length() > 255) { 
                	invoicesPaidRevised = invoicesPaid.left(235) + ' [INVOICES OMITTED]';
                }
                
            	Remit_Advice__c remitAdvice = new Remit_Advice__c( 
                    Recipient__c = paymentSummary.c2g__Account__r.c2g__CODAInvoiceEmail__c,
                    Additional_Recipient__c = paymentSummary.c2g__Account__r.Staff_Email__c,                                       
            		Vendor__c = paymentSummary.c2g__Account__c, 
                    Payment_Total__c = paymentSummary.Payment_Value_Total_Reversed__c, 
                	Invoices_Paid__c = invoicesPaidRevised,
                    Vendor_Name__c = paymentSummary.c2g__Account__r.Name, 
                    Company__c = paymentSummary.c2g__Payment__r.c2g__OwnerCompany__r.Key__c, 
                    Payment_Date__c = paymentSummary.c2g__Payment__r.c2g__PaymentDate__c);
            	forInsert.add(remitAdvice);
            }
        }
        insert forInsert;
    }
    
    global void finish(Database.BatchableContext bc) {}
}