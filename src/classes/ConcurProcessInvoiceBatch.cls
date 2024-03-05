global class ConcurProcessInvoiceBatch implements Database.Batchable<sObject> {

    String company = 'ASH';
    String batchId;
    
    public ConcurProcessInvoiceBatch(String company, String batchId) {
        this.company = company;
        this.batchId = batchId;
    }
     
    global Database.QueryLocator start(Database.BatchableContext BC) { 
    
        String source = 'Invoice';
        String query = 'SELECT Id, Invoice_Number__c, Vendor_ID__c, Intercompany_ID__c, Transaction_Amount__c, ' + 
            'Apply_Date__c, Description_1__c, Description_2__c, Company_ID__c, Payment_Type__c, Account_Code__c, Charitable_Program__c, ' + 
            'Department__c, Program__c, Project__c, Other__c, Invoice_Date__c, Officer__c, Expense_Year__c, X1099_Number__c,  ' + 
            'Concur_Key__c, Concur_Id__c, Sign__c, Prepaid_Start_Date__c, Prepaid_End_Date__c, Type__c, Submitter__c, Reimbursement__c, ' + 
            'Concur_Batch__r.Batch_ID__c ' + 
            'FROM Payment_Shuttle__c ' + 
            'WHERE Source__c = :source AND Processed__c = false AND Failed__c = false AND Company_ID__c = :company AND Concur_Batch__r.Id = :batchId';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Payment_Shuttle__c> scope) { 
        
		FfaDataProvider provider = FfaDataProvider.getInstance();
        
        List<c2g__codaPurchaseInvoice__c> somePins = new List< c2g__codaPurchaseInvoice__c>();
        Map<String, c2g__codaPurchaseInvoice__c> pinMap = new Map<String, c2g__codaPurchaseInvoice__c>();
        List<Payment_Shuttle__c> shuttlesForUpdate = new List<Payment_Shuttle__c>();        
        
        for( Payment_Shuttle__c someShuttle : scope ) {
            // If we don't have an item for this one in the Map, create a PIN for it, then add it.
            if(!pinMap.containsKey(someShuttle.Vendor_ID__c + ' - ' + someShuttle.Invoice_Number__c)) {
                c2g__codaPurchaseInvoice__c newPin = new c2g__codaPurchaseInvoice__c();
                newPin.c2g__OwnerCompany__c = provider.getCompany(someShuttle.Company_ID__c);
                newPin.c2g__Period__c = provider.getCurrentPeriod(someShuttle.Company_ID__c);
                newPin.c2g__InvoiceDate__c = Date.valueOf(someShuttle.Invoice_Date__c);
                newPin.c2g__AccountInvoiceNumber__c = someShuttle.Invoice_Number__c.abbreviate(25);
                newPin.Vendor_ID__c = someShuttle.Vendor_ID__c;
                newPin.Submitter__c = someShuttle.Submitter__c;
				newPin.Concur_Key__c = someShuttle.Concur_Key__c;
                newPin.Concur_Id__c = someShuttle.Concur_Id__c;
                newPin.Source__c = 'Concur';
                newPin.Batch__c = someShuttle.Concur_Batch__r.Batch_ID__c;
                newPin.Type__c = getInvoiceType(someShuttle.Type__c);
                Account someVendor = provider.getVendor(someShuttle.Vendor_ID__c);                
                if(someVendor == null ) { // Skip to next if the vendor isn't found.
                    someShuttle.Failed__c = true;
                    someShuttle.Reason__c = 'Vendor not found.';
            		shuttlesForUpdate.add(someShuttle);
                    continue;
                } 
                newPin.c2g__Account__c = someVendor.Id;               
                somePins.add(newPin);
                pinMap.put(someShuttle.Vendor_ID__c + ' - ' + someShuttle.Invoice_Number__c, newPin);
            }
        }
        insert somePins;
        
        List<c2g__codaPurchaseInvoiceExpenseLineItem__c> somePinLines = new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();
     
        for( Payment_Shuttle__c someShuttle : scope ) {
            System.debug('Creating line for ' + someShuttle.Vendor_ID__c + ' - ' + someShuttle.Invoice_Number__c);
            c2g__codaPurchaseInvoice__c parentPin = pinMap.get(someShuttle.Vendor_ID__c + ' - ' + someShuttle.Invoice_Number__c);
            if(parentPin == null) { continue; }
            c2g__codaPurchaseInvoiceExpenseLineItem__c someLine = new c2g__codaPurchaseInvoiceExpenseLineItem__c ();            
            someLine.c2g__GeneralLedgerAccount__c = provider.getGlaCode(overrideGeneralLedger(someShuttle.Account_Code__c, someShuttle.Charitable_Program__c));
            someLine.c2g__Dimension1__c = provider.getDimension1(overrideDimension1(someShuttle.Department__c, someShuttle.Charitable_Program__c));
            someLine.c2g__Dimension2__c = provider.getDimension2(overrideDimension2(someShuttle.Program__c, someShuttle.Charitable_Program__c));
            someLine.c2g__Dimension3__c = provider.getDimension3(overrideDimension3(someShuttle.Project__c, someShuttle.Charitable_Program__c));
            someLine.c2g__Dimension4__c = provider.getDimension4(overrideDimension4(someShuttle.Other__c, someShuttle.Charitable_Program__c));
            someLine.c2g__LineDescription__c = someShuttle.Description_1__c;
            if( someShuttle.Reimbursement__c != null && someShuttle.Reimbursement__c.equals('Y') ) { 
                someLine.Reimbursement__c = true;
            }

            // Prepaid handling.
            // If the prepaid start and end dates have been populated, evaluate for prepaid.
            if( someShuttle.Prepaid_Start_Date__c != null && someShuttle.Prepaid_End_Date__c != null ) { 
               if(
                   // Clause 1 - if either start or end date is in a future fiscal year, and the expense is 
                   // greater/equal to $1000, prepaid eligible.
                   ((FiscalYearFinder.isFutureFiscalYear(Date.valueOf(someShuttle.Prepaid_Start_Date__c)) || 
                   FiscalYearFinder.isFutureFiscalYear(Date.valueOf(someShuttle.Prepaid_End_Date__c))) && 
               	   Decimal.valueOf(someShuttle.Transaction_Amount__c) >= 1000) || 
                   // Clause 2 - greater/equal to $25000 and future fiscal quarter.
               	   Decimal.valueOf(someShuttle.Transaction_Amount__c) >= 25000 && 
               		FiscalYearFinder.isFutureFiscalQuarter(Date.valueOf(someShuttle.Prepaid_Start_Date__c))) {
                       someLine.c2g__PrepaidExpenses__c = true; 
                       someLine.c2g__DateFrom__c = Date.valueOf(someShuttle.Prepaid_Start_Date__c);
                       someLine.c2g__DateTo__c = Date.valueOf(someShuttle.Prepaid_End_Date__c);
                       someLine.Legacy_Account_Code__c = someShuttle.Account_Code__c + '-' + someShuttle.Department__c + 
                       '-' + someShuttle.Program__c + '-' + someShuttle.Project__c + '-' + someShuttle.Other__c;                   
                       someLine.c2g__GeneralLedgerAccount__c = provider.getGlaCode('1600');
                       someLine.c2g__Dimension1__c = provider.getDimension1('100');
                       someLine.c2g__Dimension2__c = provider.getDimension2('000');
                       someLine.c2g__Dimension3__c = provider.getDimension3('000');
                       someLine.c2g__Dimension4__c = provider.getDimension4('00');
            	}
            }
            
            // Multi-company handling - ASH to ASHRC.
            if(someShuttle.Intercompany_ID__c == 'ASHRC' && someShuttle.Company_ID__c == 'ASH') { 
                someLine.c2g__DestinationCompany__c = provider.getCompany('ASHRC');
                someLine.c2g__DestinationNetValue__c = Decimal.valueOf(someShuttle.Transaction_Amount__c);
            } // Multi-company handling - ASHRC to ASH.
            if(someShuttle.Intercompany_ID__c == 'ASH' && someShuttle.Company_ID__c == 'ASHRC') { 
                someLine.c2g__DestinationCompany__c = provider.getCompany('ASH');
                someLine.c2g__DestinationNetValue__c = Decimal.valueOf(someShuttle.Transaction_Amount__c);
            }
            
            // Sign reversals.
            if(someShuttle.Sign__c == 'CR') { 
				someLine.c2g__NetValue__c = (Decimal.valueOf(someShuttle.Transaction_Amount__c) * -1);
            }
            else {
    			someLine.c2g__NetValue__c = Decimal.valueOf(someShuttle.Transaction_Amount__c);
            }
            
            // Officer and box 3/7 handling.
            someLine.Officer_Name__c = someShuttle.Officer__c;
            someLine.Officer_Year__c = someShuttle.Expense_Year__c;
            someLine.Box_3_7__c = someShuttle.X1099_Number__c;
            
            // Finalize.
            someLine.c2g__PurchaseInvoice__c = parentPin.Id;
            somePinLines.add(someLine);
	        someShuttle.Processed__c = true;
            shuttlesForUpdate.add(someShuttle);
        }
        insert somePinLines;
   		update shuttlesForUpdate;
    }
    
    private static String getInvoiceType(String code) {
        switch on code {
            when 'AWS' 	{ return 'Award'; }
	        when 'HON' 	{ return 'Honorarium/Stipend'; }
	   	    when 'VP' 	{ return 'Vendor/Consultant Payment'; }
   			when 'NSER' { return 'Non-Staff Expense Reimbursement'; }
	        when else 	{ return code; }
        }
    }
    
    private static String overrideGeneralLedger(String glCode, String charitableProgram) {
        switch on charitableProgram {
            when 'COVID' 	{ return '4203'; }
	        when 'CAREER' 	{ return '4205'; }
	   	    when 'CLINRES' 	{ return '4199'; }
   			when 'GLOBAL' 	{ return '4199'; }
		    when 'GNEED' 	{ return '4196'; }
       		when 'MINORITY' { return '4199'; }
	        when 'QUALEDU' 	{ return '4204'; }
        	when 'RESAWD' 	{ return '4197'; }
        	when 'RESRAF' 	{ return '4197'; }
	        when 'SCELL' 	{ return '4199'; }
            when 'PLEDGE'	{ return '1001'; } 
	        when else 		{ return glCode; }
        }
    }
    
    private static String overrideDimension1(String dimension, String charitableProgram) {
        if(charitableProgram == null || charitableProgram == '') {
			return dimension;
        }
        else if(charitableProgram.contains('COVID') || charitableProgram.contains('CAREER') || charitableProgram.contains('CLINRES')
          || charitableProgram.contains('GLOBAL') || charitableProgram.contains('GNEED') || charitableProgram.contains('QUALEDU') 
          || charitableProgram.contains('RESAWD') || charitableProgram.contains('RESRAF') || charitableProgram.contains('SCELL')) {
               return '310';
        }
        else if (charitableProgram.contains('PLEDGE')) {
         	return '100';
        }
        else if (charitableProgram.contains('MINORITY')) {
            return '303';
        }
        return dimension;
    }
    
    private static String overrideDimension2(String dimension, String charitableProgram) {
		switch on charitableProgram {
            when 'COVID' 	{ return '136'; }
	        when 'CAREER' 	{ return '136'; }
	   	    when 'CLINRES' 	{ return '358'; }
   			when 'GLOBAL' 	{ return '370'; }
		    when 'GNEED' 	{ return '136'; }
       		when 'MINORITY' { return '352'; }
	        when 'QUALEDU' 	{ return '136'; }
        	when 'RESAWD' 	{ return '136'; }
        	when 'RESRAF' 	{ return '136'; }
	        when 'SCELL' 	{ return '379'; }
            when 'PLEDGE'   { return '000'; } 
	        when else 		{ return dimension; }
        }
    }

    private static String overrideDimension3(String dimension, String charitableProgram) {
		switch on charitableProgram {
            when 'COVID' 	{ return '000'; }
	        when 'CAREER' 	{ return '000'; }
	   	    when 'CLINRES' 	{ return '240'; }
   			when 'GLOBAL' 	{ return '000'; }
		    when 'GNEED' 	{ return '000'; }
       		when 'MINORITY' { return '285'; }
	        when 'QUALEDU' 	{ return '000'; }
        	when 'RESAWD' 	{ return '000'; }
        	when 'RESRAF' 	{ return '000'; }
	        when 'SCELL' 	{ return '000'; }
            when 'PLEDGE'   { return '000'; }
	        when else 		{ return dimension; }
        }
    }
    
    private static String overrideDimension4(String dimension, String charitableProgram) {
		switch on charitableProgram {
            when 'COVID' 	{ return '24'; }
	        when 'CAREER' 	{ return '24'; }
	   	    when 'CLINRES' 	{ return '24'; }
   			when 'GLOBAL' 	{ return '24'; }
		    when 'GNEED' 	{ return '24'; }
       		when 'MINORITY' { return '24'; }
	        when 'QUALEDU' 	{ return '24'; }
        	when 'RESAWD' 	{ return '24'; }
        	when 'RESRAF' 	{ return '24'; }
	        when 'SCELL' 	{ return '24'; }
            when 'PLEDGE'   { return '00'; }
	        when else 		{ return dimension; }
        }
    }

    global void finish(Database.BatchableContext bc) { 
      	Concur_Batch__c thisBatch = [SELECT Id FROM Concur_Batch__c WHERE Id = :batchId];
        thisBatch.Processed__c = true;
        update thisBatch;
    } 
}