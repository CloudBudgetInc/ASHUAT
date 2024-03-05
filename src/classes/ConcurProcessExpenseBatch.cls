global class ConcurProcessExpenseBatch implements Database.Batchable<sObject> {
	
    String company = 'ASH';
    String batchId;    
    public ConcurProcessExpenseBatch(String company, String batchId) {
        this.company = company;
        this.batchId = batchId;
    }
     
    global Database.QueryLocator start(Database.BatchableContext BC) { 
    
        String type = 'Expense';
        String query = 'SELECT Id, Invoice_Number__c, Vendor_ID__c, Intercompany_ID__c, Transaction_Amount__c, ' + 
            'Apply_Date__c, Description_1__c, Submitter__c, Company_ID__c, Payment_Type__c, Other_Payment_Type__c, ' + 
            'Account_Code__c, Department__c, Program__c, Project__c, Other__c, Processed__c, Concur_Key__c, Concur_ID__c, ' + 
            'Concur_Batch__r.Batch_ID__c ' + 
            'FROM Payment_Shuttle__c ' + 
            'WHERE Processed__c = false AND Failed__c = false AND Type__c = :type ' + 
            'AND Company_ID__c = :company AND Concur_Batch__c = :batchId';
		return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Payment_Shuttle__c> scope) { 
        
        FfaDataProvider provider = FfaDataProvider.getInstance();  
        
        List<c2g__codaPurchaseInvoice__c> somePins = new List< c2g__codaPurchaseInvoice__c>();
        Map<String, c2g__codaPurchaseInvoice__c> pinMap = new Map<String, c2g__codaPurchaseInvoice__c>();
        List<Payment_Shuttle__c> shuttlesForUpdate = new List<Payment_Shuttle__c>();

        for( Payment_Shuttle__c someShuttle : scope ) {
            // If we don't have an item for this in the Map, create a PIN for it.
            if(!pinMap.containsKey(someShuttle.Vendor_ID__c + '-' + someShuttle.Concur_Key__c + '-' + someShuttle.Apply_Date__c)) {
                c2g__codaPurchaseInvoice__c newPin = new c2g__codaPurchaseInvoice__c();
                newPin.c2g__OwnerCompany__c = provider.getCompany(someShuttle.Company_ID__c);
                newPin.c2g__InvoiceDate__c = Date.valueOf(someShuttle.Apply_Date__c);
                newPin.Submitter__c = someShuttle.Submitter__c;
                newPin.Vendor_ID__c = someShuttle.Vendor_ID__c;
                newPin.c2g__Period__c = provider.getCurrentPeriod(someShuttle.Company_ID__c);
                if( someShuttle.Payment_Type__c.contains('American Express') || someShuttle.Other_Payment_Type__c.contains('American Express') ) {
					newPin.c2g__Account__c = provider.getVendor('AMER01').Id;
                    newPin.c2g__InvoiceDescription__c = someShuttle.Vendor_ID__c + '/AMEX - ' + someShuttle.Apply_Date__c;
                    newPin.c2g__AccountInvoiceNumber__c = 'AMER01 - ' + someShuttle.Apply_Date__c;
                }
                else if (someShuttle.Payment_Type__c.contains('BB&T')) {
                    newPin.c2g__Account__c = provider.getVendor('BB&T04').Id;
                    newPin.c2g__InvoiceDescription__c = someShuttle.Vendor_ID__c + '/BB&T - ' + someShuttle.Apply_Date__c;
                    newPin.c2g__AccountInvoiceNumber__c = 'BB&T04 - ' + someShuttle.Apply_Date__c;
                }
                else {
                    Account someVendor = provider.getVendor(someShuttle.Vendor_ID__c); 
                    if(someVendor == null) { 
                    	someShuttle.Failed__c = true;
                    	someShuttle.Reason__c = 'Vendor not found.';
            			shuttlesForUpdate.add(someShuttle);
                    	continue;
                    }
                    else { 
                    	newPin.c2g__Account__c = someVendor.Id;
                    	newPin.c2g__InvoiceDescription__c = someShuttle.Vendor_ID__c + ' - ' + someShuttle.Apply_Date__c;
                    	newPin.c2g__AccountInvoiceNumber__c = someShuttle.Vendor_ID__c + ' - ' + someShuttle.Apply_Date__c;
                  	}
                }
                
                newPin.Concur_Key__c = someShuttle.Concur_Key__c;
                newPin.Concur_ID__c = someShuttle.Concur_ID__c;
                newPin.Source__c = 'Concur';
                newPin.Type__c = 'Expense';
                newPin.Batch__c = someShuttle.Concur_Batch__r.Batch_ID__c;                
                somePins.add(newPin);
                pinMap.put(someShuttle.Vendor_ID__c + '-' + someShuttle.Concur_Key__c + '-' + someShuttle.Apply_Date__c, newPin);
            }
        }
        insert somePins;
        
		List<c2g__codaPurchaseInvoiceExpenseLineItem__c> somePinLines = new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();
        for( Payment_Shuttle__c someShuttle : scope ) {
            c2g__codaPurchaseInvoice__c parentPin = pinMap.get(someShuttle.Vendor_ID__c + 
            	'-' + someShuttle.Concur_Key__c + '-' + someShuttle.Apply_Date__c);
            if(parentPin == null) { continue; }
            c2g__codaPurchaseInvoiceExpenseLineItem__c   someLine = new c2g__codaPurchaseInvoiceExpenseLineItem__c ();
            someLine.c2g__LineDescription__c = someShuttle.Vendor_ID__c + ' ' + someShuttle.Description_1__c;
            someLine.c2g__GeneralLedgerAccount__c = provider.getGlaCode(someShuttle.Account_Code__c);
            someLine.c2g__Dimension1__c = provider.getDimension1(someShuttle.Department__c);
            someLine.c2g__Dimension2__c = provider.getDimension2(someShuttle.Program__c);
            someLine.c2g__Dimension3__c = provider.getDimension3(someShuttle.Project__c);
            someLine.c2g__Dimension4__c = provider.getDimension4(someShuttle.Other__c);
            someLine.c2g__NetValue__c = Decimal.valueOf(someShuttle.Transaction_Amount__c);
            // Multi-company - ASH to ASHRC.            
            if(someShuttle.Intercompany_ID__c == 'ASHRC' && someShuttle.Company_ID__c == 'ASH') { 
                someLine.c2g__DestinationCompany__c = provider.getCompany('ASHRC');
                someLine.c2g__DestinationNetValue__c = Decimal.valueOf(someShuttle.Transaction_Amount__c);
            }
            // Multi-company - ASHRC to ASH.
            if(someShuttle.Intercompany_ID__c == 'ASH' && someShuttle.Company_ID__c == 'ASHRC') { 
                someLine.c2g__DestinationCompany__c = provider.getCompany('ASH');
                someLine.c2g__DestinationNetValue__c = Decimal.valueOf(someShuttle.Transaction_Amount__c);
            }            
            someLine.c2g__PurchaseInvoice__c = parentPin.Id;
            somePinLines.add(someLine);
	        someShuttle.Processed__c = true;
            shuttlesForUpdate.add(someShuttle);
        }
        insert somePinLines;
		update shuttlesForUpdate;
    }
    
    global void finish(Database.BatchableContext bc) { 
        Concur_Batch__c thisBatch = [SELECT Id FROM Concur_Batch__c WHERE Id = :batchId];
        thisBatch.Processed__c = true;
        update thisBatch;
    }
}