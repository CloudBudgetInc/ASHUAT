global class Vendor1099Batch implements Database.Batchable<sObject> {

    String taxYear = '';
    Date startDate;
    Date endDate;
    String vendorId = '';
    String company = 'ASH';
    Boolean isTest = false;
    
    public Vendor1099Batch(String taxYear, Date startDate, Date endDate, String company, String isTest) {
        this.taxYear = taxYear;
        this.startDate = startDate;
        this.endDate = endDate;
        this.company = company;
        this.isTest = Boolean.valueOf(isTest);        
    }    
    
    public Vendor1099Batch(String taxYear, Date startDate, Date endDate, String company, String vendorId, String isTest) {
        this.taxYear = taxYear;
        this.startDate = startDate;
        this.endDate = endDate;        
        this.vendorId = vendorId;
        this.company = company;
        this.isTest = Boolean.valueOf(isTest);             
    }        
    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id vendorRecordType = provider.getVendorRecordTypeId();
        String query;
        if( vendorId != null && !vendorId.equals('') ) {
    		query = 'SELECT Id FROM Account WHERE Vendor_Id__c = :vendorId';  
		}
        else {
            if(!isTest) {
	        	query = 'SELECT Id FROM Account WHERE RecordTypeId = :vendorRecordType';
            }
            else {
                query = 'SELECT Id FROM Account WHERE RecordTypeId = :vendorRecordType LIMIT 1';
            }
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> results) {
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id companyId = provider.getCompany(company);
        
        List<AggregateResult> totalPayments = [
            SELECT c2g__Account__r.Id Account, 
        	SUM(c2g__InvoiceTotal__c) Total 
            FROM c2g__codaPurchaseInvoice__c 
            WHERE c2g__Period__r.c2g__StartDate__c >= :startDate 
            AND c2g__Period__r.c2g__EndDate__c <= :endDate
            AND c2g__OwnerCompany__c = :companyId
            AND c2g__PaymentStatus__c = 'Paid'
			AND c2g__Account__r.Id IN :results 
            GROUP BY c2g__Account__r.Id HAVING SUM(c2g__InvoiceTotal__c) > 0];
        
        List<AggregateResult> totalReimbursements = [
            SELECT c2g__PurchaseInvoice__r.c2g__Account__r.Id Account, 
        	SUM(c2g__NetValue__c) Total 
            FROM c2g__codaPurchaseInvoiceExpenseLineItem__c  
            WHERE Reimbursement__c = true
            AND c2g__PurchaseInvoice__r.c2g__Period__r.c2g__StartDate__c >= :startDate 
            AND c2g__PurchaseInvoice__r.c2g__Period__r.c2g__EndDate__c <= :endDate
            AND c2g__PurchaseInvoice__r.c2g__OwnerCompany__c = :companyId
            AND c2g__PurchaseInvoice__r.c2g__PaymentStatus__c = 'Paid'
			AND c2g__PurchaseInvoice__r.c2g__Account__r.Id IN :results 
            GROUP BY c2g__PurchaseInvoice__r.c2g__Account__r.Id HAVING SUM(c2g__NetValue__c) > 0];
        
        List<AggregateResult> totalAwards = [
            SELECT c2g__PurchaseInvoice__r.c2g__Account__r.Id Account, 
        	SUM(c2g__NetValue__c) Total 
            FROM c2g__codaPurchaseInvoiceExpenseLineItem__c  
            WHERE c2g__PurchaseInvoice__r.Type__c = 'Award'
            AND c2g__PurchaseInvoice__r.c2g__Period__r.c2g__StartDate__c >= :startDate 
            AND c2g__PurchaseInvoice__r.c2g__Period__r.c2g__EndDate__c <= :endDate
            AND c2g__PurchaseInvoice__r.c2g__OwnerCompany__c = :companyId
            AND c2g__PurchaseInvoice__r.c2g__PaymentStatus__c = 'Paid'
			AND c2g__PurchaseInvoice__r.c2g__Account__r.Id IN :results 
            GROUP BY c2g__PurchaseInvoice__r.c2g__Account__r.Id HAVING SUM(c2g__NetValue__c) > 0];            
        
        List<AggregateResult> totalOtherCompensation = [
            SELECT Account__r.Id Account, 
        	SUM(Amount__c) Total 
            FROM Other_Compensation__c   
            WHERE Payment_Date__c >= :startDate 
            AND Payment_Date__c <= :endDate
            AND Company__c = :companyId
			AND Account__r.Id IN :results 
            GROUP BY Account__r.Id HAVING SUM(Amount__c) > 0];                
        
        List<Account> knockdowns = new List<Account>();
        List<X1099_Year__c> forInsert = new List<X1099_Year__c>();
        
        Map<Id, Double> totalPaymentsMap = new Map<Id, Double>();
        for( AggregateResult paymentTotal : totalPayments ) {      
         	totalPaymentsMap.put((Id) paymentTotal.get('Account'), (Double) paymentTotal.get('Total'));
        }
        
        Map<Id, Double> totalReimbursementsMap = new Map<Id, Double>();
        for( AggregateResult reimbursementTotal : totalReimbursements ) {      
         	totalReimbursementsMap.put((Id) reimbursementTotal.get('Account'), (Double) reimbursementTotal.get('Total'));
        }
        
        Map<Id, Double> totalAwardsMap = new Map<Id, Double>();
        for( AggregateResult awardTotal : totalAwards ) {      
         	totalAwardsMap.put((Id) awardTotal.get('Account'), (Double) awardTotal.get('Total'));
        }
        
        Map<Id, Double> otherCompensationMap = new Map<Id, Double>();
        for( AggregateResult otherCompTotal : totalOtherCompensation ) {      
         	otherCompensationMap.put((Id) otherCompTotal.get('Account'), (Double) otherCompTotal.get('Total'));
        }
        
        for( Account result : results ) { 
            Double payments = totalPaymentsMap.get(result.Id);
            Double reimbursements = totalReimbursementsMap.get(result.Id);
            Double awards = totalAwardsMap.get(result.Id);
            Double otherCompensation = otherCompensationMap.get(result.Id);
            // Prevent insertion of empty records. Payments include reimbursements/awards, so we don't have to check for those explicitly.
            if((payments != null && payments <> 0) || (otherCompensation != null && otherCompensation <> 0)) {
                X1099_Year__c tenNinetyNineYear = new X1099_Year__c( 
                    Payments__c = payments, Reimbursements__c = reimbursements, Other_Compensation__c = otherCompensation,
                    Tax_Year__c = taxYear, Awards__c = awards, Company__c = companyId, Vendor__c = result.Id );
                forInsert.add(tenNinetyNineYear);
            }
            knockdowns.add(new Account(Id = result.Id, X1099_Processed__c = true));         	
        }
        insert forInsert;	
        update knockdowns;       
    }
       
    global void finish(Database.BatchableContext bc) { }
}