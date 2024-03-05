trigger VendorTrigger on Account (before insert, after update, after delete) {

    Id vendorRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId();
    
    /** 
     * If a new vendor, assign a vendor code and do an AP setup. Nothing goes to Concur at this point.
     */
    if (trigger.isBefore && trigger.isInsert) {
        // Not delighted with this query, but the nature of what we're doing here requires 
        // the freshest data so a cache-able approach isn't feasible for this purpose.
        Map<Id, Account> vendors = new Map<Id, Account>([SELECT Id, Vendor_ID__c FROM Account WHERE RecordTypeId = :vendorRecordTypeId]);
        Map<Id, Legacy_Vendor__c> legacyVendors = new Map<Id, Legacy_Vendor__c>([SELECT Id, Vendor_ID__c FROM Legacy_Vendor__c]); 
        FfaDataProvider provider = FfaDataProvider.getInstance();        
        
        for(Account vendor : trigger.new) {
            if( vendor.RecordTypeId == vendorRecordTypeId && !system.isBatch() ) {        
                String vendorCode = VendorCodeHandler.generateVendorCode(vendor, vendors, legacyVendors);
                vendor.Vendor_ID__c = vendorCode;
                vendor.c2g__CODAAccountTradingCurrency__c = 'USD';
                vendor.c2g__CODABaseDate1__c = 'Invoice Date';
                vendor.c2g__CODADaysOffset1__c = 30;
                vendor.c2g__CODAAccountsPayableControl__c = provider.getGlaCode('2040');
                vendor.c2g__CODADimension1__c = provider.getDimension1('100');
                vendor.c2g__CODADimension2__c = provider.getDimension2('000');
                vendor.c2g__CODADimension3__c = provider.getDimension3('000');
                vendor.c2g__CODADimension4__c = provider.getDimension4('00');
            }
        }
    }
    
    /**
     * If existing vendor and is now approved, send to Concur as new record. 
     * Alternatively, if it's an approved vendor and relevant changes have been made to the record, 
     * send an update to Concur.
     * 
     * Both updates to Concur happen via delegation to the ConcurIntegrationHandler.
     * Both types of changes are logged to the Vendor record in Salesforce.
     */
    if (trigger.isAfter && trigger.isUpdate) {
        Concur_Integration__mdt setting = [SELECT Id, Vendor_Integration_Enabled__c FROM Concur_Integration__mdt];
        System.debug('Vendor integration enabled: ' + setting.Vendor_Integration_Enabled__c);
        List<Concur_Log__c> forInsert = new List<Concur_Log__c>();
        for(Account vendor : trigger.new)
        {
            if( vendor.RecordTypeId == vendorRecordTypeId ) {
                // If the vendor has been approved, it's time to insert it into Concur.
                if(Trigger.oldMap.get(vendor.Id).Vendor_Status__c != vendor.Vendor_Status__c && 
                   vendor.Vendor_Status__c == 'Approved') {
                       if( vendor.Vendor_ID__c != null ) {
                           System.debug('Vendor approved; sending as new Vendor to Concur.');
                           Concur_Log__c someLog = new Concur_Log__c( Vendor_ID__c = vendor.Vendor_ID__c,
                                                                     Type__c = 'Insert', Event_Date_Time__c = System.now() );
                           someLog.Organization__c = vendor.Id;
                           if(setting.Vendor_Integration_Enabled__c == true) {
	                           forInsert.add(someLog);
                               ConcurIntegrationHandler.handleVendorChange(vendor.Id, 'INSERT');
                           }
                           else {
                               System.debug('Vendor push to Concur disabled.');
                           }
                       }
                   }
                if( vendor.Vendor_ID__c != null && vendor.Vendor_Status__c == 'Approved' )
                {
                    if( ( Trigger.oldMap.get(vendor.Id).Name != vendor.Name) || 
                       (Trigger.oldMap.get(vendor.Id).Remit_Address_1__c != vendor.Remit_Address_1__c ) ||
                       (Trigger.oldMap.get(vendor.Id).Remit_Address_2__c != vendor.Remit_Address_2__c ) ||
                       (Trigger.oldMap.get(vendor.Id).Remit_City__c != vendor.Remit_City__c ) ||
                       (Trigger.oldMap.get(vendor.Id).Remit_State__c != vendor.Remit_State__c ) ||
                       (Trigger.oldMap.get(vendor.Id).Remit_Postal_Code__c != vendor.Remit_Postal_Code__c ) || 
                       (Trigger.oldMap.get(vendor.Id).Remit_Country_Code__c != vendor.Remit_Country_Code__c ) || 
                       (Trigger.oldMap.get(vendor.Id).Send_To_Concur__c != vendor.Send_To_Concur__c )) {
                           System.debug('Vendor updated; sending update to Concur.');
                           Concur_Log__c someLog = new Concur_Log__c(Type__c = 'Update', 
                                                                     Vendor_ID__c = vendor.Vendor_ID__c, Event_Date_Time__c = System.now());
                           someLog.Organization__c = vendor.Id;
                           if(setting.Vendor_Integration_Enabled__c == true) {
	                           forInsert.add(someLog);
                               ConcurIntegrationHandler.handleVendorChange(vendor.Id, 'UPDATE');
                           }
                           else {
                               System.debug('Vendor push to Concur disabled.');
                           }                           
                       }
                }
            }
            insert forInsert;
        }
    }
    
    /** If a vendor is deleted/merged, we need to make sure we don't re-use that vendor ID, as it may 
    * still be 'live'/occupied in other systems - namely Concur, but potentially others.
    * So we add to our list of legacy vendor IDs to make sure it isn't used in the future.
    */
    if(trigger.isDelete && trigger.isAfter) {
        System.debug('Vendor is being deleted/merged; logging vendor ID to prevent further usage.');
        List<Legacy_Vendor__c> legacyVendorList = new List<Legacy_Vendor__c>();
        for(Account vendor : trigger.old) {
            if( vendor.RecordTypeId == vendorRecordTypeId ) {
                System.debug('Vendor deleted/merged; adding as legacy vendor to prevent vendor ID reuse.');
                Legacy_Vendor__c trackingRecord = new Legacy_Vendor__c(Vendor_ID__c = vendor.Vendor_ID__c, 
                                                                       Vendor_Name__c = vendor.Name);
                legacyVendorList.add(trackingRecord);
            }
        }
        insert legacyVendorList;
    }
}