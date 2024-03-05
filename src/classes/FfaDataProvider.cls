public class FfaDataProvider {

    private static FfaDataProvider instance = null;
    public String id {get;private set;} // the id of the record type
    
	List<c2g__codaPeriod__c> periods; 
    Map<String, Account> vendorLookup = new Map<String, Account>();
	Map<String, Id> companyLookup = new Map<String, Id>(); 
	Map<String, Id> glaLookup = new Map<String, Id>();
	Map<String, c2g__codaDimension1__c> dimension1Lookup = new Map<String, c2g__codaDimension1__c>();
	Map<String, c2g__codaDimension2__c> dimension2Lookup = new Map<String, c2g__codaDimension2__c>();	
    Map<String, c2g__codaDimension3__c> dimension3Lookup = new Map<String, c2g__codaDimension3__c>();
	Map<String, c2g__codaDimension4__c> dimension4Lookup = new Map<String, c2g__codaDimension4__c>();
   	Map<String, Id> bankAccountLookup = new Map<String, Id>();
  	Map<String, c2g__codaPeriod__c> ashPeriodLookup = new Map<String, c2g__codaPeriod__c>(); 
  	Map<String, c2g__codaPeriod__c> ashRcPeriodLookup = new Map<String, c2g__codaPeriod__c>();
    Map<String, Id> intersectLookup = new Map<String, Id>();
 
    public static FfaDataProvider getInstance() {
        if(instance == null) instance = new FfaDataProvider();
        return instance;
    }    
    
    // The constructor is private.
    private FfaDataProvider() {
        
    	Map<Id, c2g__codaPeriod__c> someAshPeriods = new Map<Id, c2g__codaPeriod__c>(
            [SELECT Id, c2g__StartDate__c, c2g__EndDate__c, c2g__PeriodNumber__c, c2g__OwnerCompany__r.Key__c, PerPost__c, Fiscal_Year__c, Year_Number__c
             FROM c2g__codaPeriod__c 
             WHERE c2g__OwnerCompany__r.Key__c IN ('ASH')]);
       	for( Id someId : someAshPeriods.keySet() ) {
    		c2g__codaPeriod__c somePeriod = someAshPeriods.get(someId);
            String key = somePeriod.PerPost__c;
		    ashPeriodLookup.put(key, somePeriod);
		}
        
    	Map<Id, c2g__codaPeriod__c> someAshRcPeriods = new Map<Id, c2g__codaPeriod__c>(
            [SELECT Id, c2g__StartDate__c, c2g__EndDate__c, c2g__PeriodNumber__c, c2g__OwnerCompany__r.Key__c, PerPost__c, Fiscal_Year__c, Year_Number__c
             FROM c2g__codaPeriod__c 
             WHERE c2g__OwnerCompany__r.Key__c IN ('ASHRC')]);
       	for( Id someId : someAshRcPeriods.keySet() ) {
    		c2g__codaPeriod__c someOtherPeriod = someAshRcPeriods.get(someId);
            String key = someOtherPeriod.PerPost__c;   
		    ashRcPeriodLookup.put(key, someOtherPeriod);
		}
                
		String vendorRecordType = this.getVendorRecordTypeId();
        Map<Id, Account> someVendors = new Map<Id, Account>([SELECT Id, Name, Vendor_ID__c, Officer__c FROM Account WHERE RecordTypeId = :vendorRecordType]);
        for( String key : someVendors.keySet() ) {
            Account someAccount = someVendors.get(key);
            vendorLookup.put(someAccount.Vendor_ID__c, someAccount);
        }        
        
        Map<Id, c2g__codaCompany__c > someCompanies = 
            new Map<Id, c2g__codaCompany__c >([SELECT Id, Key__c from c2g__codaCompany__c]);
		for( Id someId : someCompanies.keySet() ) {
    		c2g__codaCompany__c someCompany = someCompanies.get(someId);
            String key = someCompany.Key__c;
		    companyLookup.put(key, someCompany.Id);
		}
        
		Map<Id, c2g__codaGeneralLedgerAccount__c> accountCodes = 
            new Map<Id, c2g__codaGeneralLedgerAccount__c>([SELECT Id, c2g__ReportingCode__c FROM c2g__codaGeneralLedgerAccount__c]);
		for( String key : accountCodes.keySet() ) {
		    c2g__codaGeneralLedgerAccount__c blapp = accountCodes.get(key);
		    glaLookup.put(blapp.c2g__ReportingCode__c, key);
		}
        
		Map<Id, c2g__codaDimension1__c> dimensionOnes = 
            new Map<Id, c2g__codaDimension1__c>([SELECT Id, c2g__ReportingCode__c FROM c2g__codaDimension1__c]);
		for( c2g__codaDimension1__c item : dimensionOnes.values() ) {
		    dimension1Lookup.put(item.c2g__ReportingCode__c, item);
        }
        
		Map<Id, c2g__codaDimension2__c> dimensionTwos = 
            new Map<Id, c2g__codaDimension2__c>([SELECT Id, c2g__ReportingCode__c, ASHRC__c FROM c2g__codaDimension2__c]);
		for( c2g__codaDimension2__c item : dimensionTwos.values() ) {
		    dimension2Lookup.put(item.c2g__ReportingCode__c, item);
		}        

		Map<Id, c2g__codaDimension3__c> dimensionThrees = 
            new Map<Id, c2g__codaDimension3__c>([SELECT Id, c2g__ReportingCode__c FROM c2g__codaDimension3__c]);
		for( c2g__codaDimension3__c item : dimensionThrees.values() ) {
		    dimension3Lookup.put(item.c2g__ReportingCode__c, item);
		}

		Map<Id, c2g__codaDimension4__c> dimensionFours = 
            new Map<Id, c2g__codaDimension4__c>([SELECT Id, c2g__ReportingCode__c FROM c2g__codaDimension4__c]);
		for( c2g__codaDimension4__c item : dimensionFours.values() ) {
		    dimension4Lookup.put(item.c2g__ReportingCode__c, item);
		}
       
		Map<Id, c2g__codaBankAccount__c> bankAccounts = 
            new Map<Id, c2g__codaBankAccount__c>([SELECT Id, c2g__ReportingCode__c FROM c2g__codaBankAccount__c]);
		for( String key : bankAccounts.keySet() ) {
		    c2g__codaBankAccount__c someBankAccount = bankAccounts.get(key);
		    bankAccountLookup.put(someBankAccount.c2g__ReportingCode__c, key);
		}

        Map<Id, c2g__codaIntersectDefinition__c> intersectDefinitions = 
            new Map<Id, c2g__codaIntersectDefinition__c>([SELECT Id, Name FROM c2g__codaIntersectDefinition__c]);
        for( String key : intersectDefinitions.keySet() ) { 
        	c2g__codaIntersectDefinition__c intersectDefinition = intersectDefinitions.get(key);
            intersectLookup.put(intersectDefinition.Name, intersectDefinition.Id);
        }
    }
    
    public Id getIntersectDefinition(String name) {
        return intersectLookup.get(name);
    }
    
    public boolean checkGlaCode(String reportingCode) {
        return glaLookup.containsKey(reportingCode);
    }        
    
    public Id getGlaCode(String reportingCode) {
        return glaLookup.get(reportingCode);
    }
    
    public Id getDimension1(String reportingCode) {
        return dimension1Lookup.get(reportingCode).Id;
    } 
    
    public c2g__codaDimension1__c getFullDimension1(String reportingCode) {
        return dimension1Lookup.get(reportingCode);
    }      
    
    public boolean checkDimension1(String reportingCode) {
        return dimension1Lookup.containsKey(reportingCode);
    }    
    
    public Id getDimension2(String reportingCode) {
        return dimension2Lookup.get(reportingCode).Id;
    }  
    
    public c2g__codaDimension2__c getFullDimension2(String reportingCode) {
        return dimension2Lookup.get(reportingCode);
    }  
    
    public boolean checkDimension2(String reportingCode) {
        return dimension2Lookup.containsKey(reportingCode);
    }

    public boolean checkDimension3(String reportingCode) {
        return dimension3Lookup.containsKey(reportingCode);
    }        
    
    public Id getDimension3(String reportingCode) {
        return dimension3Lookup.get(reportingCode).Id;
    }
    
    public c2g__codaDimension3__c getFullDimension3(String reportingCode) {
        return dimension3Lookup.get(reportingCode);
    }      
    
    public boolean checkDimension4(String reportingCode) {
        return dimension4Lookup.containsKey(reportingCode);
    }        

    public Id getDimension4(String reportingCode) {
        return dimension4Lookup.get(reportingCode).Id;
    }
    
    public c2g__codaDimension4__c getFullDimension4(String reportingCode) {
        return dimension4Lookup.get(reportingCode);
    }      

    public Account getVendor(String vendorCode) {
        return vendorLookup.get(vendorCode);
    }
    
    public Id getBankAccount(String reportingCode) {
        return bankAccountLookup.get(reportingCode);
    }

    public Id getCompany(String companyKey) {
        return companyLookup.get(companyKey);
    }
    
    public c2g__codaPeriod__c getPeriod(String companyKey, String perPost) {
        if(companyKey == 'ASH') {
            return getAshPeriod(perPost);
        }
        else {
            return getAshRcPeriod(perPost);
        }
    }
    
    private c2g__codaPeriod__c getAshPeriod(String perPost) {
        return ashPeriodLookup.get(perPost);
    }
    
    private c2g__codaPeriod__c getAshRcPeriod(String perPost) {
        return ashRcPeriodLookup.get(perPost);
    }
    
    public Id getCurrentPeriod(String companyKey) {
        if(companyKey == 'ASH') {
            for( c2g__codaPeriod__c period : ashPeriodLookup.values() ) {
                if( period.c2g__StartDate__c <= System.today() && period.c2g__EndDate__c >= System.today() ) {
                    return period.Id;
                }
            }
        }
        else {
            for( c2g__codaPeriod__c period : ashRcPeriodLookup.values() ) {
                if( period.c2g__StartDate__c <= System.today() && period.c2g__EndDate__c >= System.today() ) {
                    return period.Id;
                }
            }
        }
        return null;
    }
    
    public Id getPreviousPeriod(String companyKey) {
        if(companyKey == 'ASH') {
            for( c2g__codaPeriod__c period : ashPeriodLookup.values() ) {
                //System.today().toStartOfMonth().addMonths(-1);
                if( period.c2g__StartDate__c == (System.today().toStartOfMonth().addMonths(-1))) {
                    return period.Id;
                }
            }
        }
        else {
            for( c2g__codaPeriod__c period : ashRcPeriodLookup.values() ) {
                if( period.c2g__StartDate__c == (System.today().toStartOfMonth().addMonths(-1))) {
                    return period.Id;
                }
            }
        }
        return null;
    }    
    
    public Id getVendorRecordTypeId() {
        Id vendorRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId();
        return vendorRecTypeId;
    }
    
    public Id getDummyAccount() {
        return '0013u00000xhZWlAAM';
    }
    
    public Id getCurrency() {
        return 'a7I4C0000008tSpUAI';
    }
}