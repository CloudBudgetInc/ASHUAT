Global without sharing class OpportunityService {
    
    Global String label { get; set; }
    Global String value { get; set; }    
    
    @AuraEnabled
    @future
    Global static Void CreateOpp(map<string,string> Fund,String asp,Decimal Amount,String FName,String LName, string email,String Address1,String Address2, String City,String State,String Country,String PostalCode, string tributetype,string dedicationName, string dedicationMessage,String dedicationFName,String dedicationlName,String dedicationEmail,String Cred){
        List<Account> listOfAccount                = new List<Account>();
        List<Contact> listOfContact                = new List<Contact>();
        List<Contact> DoubleDedCon                = new List<Contact>();
        List<Opportunity> listOfOpp                = new List<Opportunity>();
        List<OpportunityContactRole> listOppRole   = new List<OpportunityContactRole>();
        List<npsp__Allocation__c>    npspDat       = new List<npsp__Allocation__c>();
        List<npsp__Address__c>  nspsAddr           = new List<npsp__Address__c>();
        Map<string,npsp__General_Accounting_Unit__c>  gacUpdatedMap = new Map<string,npsp__General_Accounting_Unit__c>();
        List<npsp__General_Accounting_Unit__c> gacList = [SELECT Id, Name,npsp__Active__c From npsp__General_Accounting_Unit__c WHERE Name IN: Fund.keyset()];
        For(npsp__General_Accounting_Unit__c ga : gacList){
            gacUpdatedMap.put(ga.Name,ga);
        }
        system.debug('tributetype ' + tributetype);
        system.debug('dedicationName ' + dedicationName);
        system.debug('dedicationMessage ' + dedicationMessage);
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();
        Id OpportunityrecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Donation').getRecordTypeId();
        List<Contact> getExistingContact =  [SELECT Id,AccountId FROM Contact WHERE Email =:email];
        
        if(getExistingContact.IsEmpty()){
            Account a = new Account();
            a.RecordTypeId  = recordTypeId;
            a.Name = FName +' '+ LName;
            listOfAccount.add(a);  
            system.debug(listOfAccount);
            if(!listOfAccount.isEmpty()){
                insert listOfAccount;
            }
            for(Account acc :listOfAccount){  
                npsp__Address__c opp = new npsp__Address__c();
                opp.npsp__Household_Account__c   =acc.Id;
                opp.npsp__MailingStreet__c       = Address1;
                opp.npsp__MailingStreet2__c     = Address2;
                opp.npsp__MailingCity__c         =  City;
                opp.npsp__MailingCountry__c      = Country;
                opp.npsp__MailingState__c        = State;
                opp.npsp__MailingPostalCode__c   = PostalCode;
                nspsAddr.add(opp);
            }
            if(!nspsAddr.isEmpty()){
                insert nspsAddr;
            }
            Contact consingleVar = new Contact();
            consingleVar.FirstName = FName;
            consingleVar.LastName = LName;
            consingleVar.Email = email;
            consingleVar.AccountId = listOfAccount[0].Id ;
            consingleVar.Main_Address_Line_1__c  = Address1;
            consingleVar.Main_Address_City__c     = City;
            consingleVar.Main_Address_Country__c  = Country;
            consingleVar.Main_Address_State__c    = State;
            consingleVar.Credentials__c  = Cred;
            
            
            listOfContact.add(consingleVar);
            	if(dedicationlName!=null && dedicationlName!=''){
                Contact DoubleDed = new Contact();
                DoubleDed.FirstName = dedicationFName;
                
                DoubleDed.LastName = dedicationlName;
                
                DoubleDed.Email = dedicationEmail;
                DoubleDed.AccountId = listOfAccount[0].Id ;
                DoubleDedCon.add(DoubleDed);
                if(!DoubleDedCon.isEmpty()){
                    insert DoubleDedCon;
                }
              }
            system.debug('listOfContact'+listOfContact);
            if(!listOfContact.isEmpty()){
                insert listOfContact;
            }  
        }else{
            listOfContact = null;
            listOfAccount = null;
             List<Account> getExistingAccount = [SELECT Id from Account WHERE Id =: getExistingContact[0].AccountId LIMIT 1];
             listOfAccount = getExistingAccount;
            listOfContact = getExistingContact;
            if(dedicationlName!=null && dedicationlName!=''){
                Contact DoubleDed = new Contact();
                DoubleDed.FirstName = dedicationFName;
                
                DoubleDed.LastName = dedicationlName;
                
                DoubleDed.Email = dedicationEmail;
                DoubleDed.AccountId = listOfAccount[0].Id ;
                DoubleDedCon.add(DoubleDed);
                if(!DoubleDedCon.isEmpty()){
                    insert DoubleDedCon;
                }
              }
           
            system.debug('getExistingAccount ' + getExistingAccount);
           
            for(Account acc :listOfAccount){  
                npsp__Address__c opp = new npsp__Address__c();
                opp.npsp__Household_Account__c   =acc.Id;
                opp.npsp__MailingStreet__c       = Address1;
                opp.npsp__MailingStreet2__c     = Address2;
                opp.npsp__MailingCity__c         =  City;
                opp.npsp__MailingCountry__c      = Country;
                opp.npsp__MailingState__c        = State;
                opp.npsp__MailingPostalCode__c   = PostalCode;
                nspsAddr.add(opp);
            }
            if(!nspsAddr.isEmpty()){
                insert nspsAddr;
            }
        }
        system.debug(' List of Account --> ' + listOfAccount);
        system.debug(' List of Contact --> ' + listOfContact);
        system.debug(' List of Addresses --> ' + nspsAddr);
        Map<id,id> mapacntwithcon= new Map<id,id>();
        for(Contact con :listOfContact){
            mapacntwithcon.put(con.Accountid,con.id);
            Opportunity opp = new Opportunity();
            opp.Name        = FName + ' ' +LName + ' '+  'Donation ' + '$'+Amount;
            opp.Closedate   = Date.today();
            opp.stageName   = 'Planned';
            opp.Type        = 'Online Giving';
            opp.npsp__Tribute_Type__c = tributetype;
            opp.ASH_Asperato_Payment__c = asp;
            opp.AccountId   = con.Accountid;
            if(Amount > 25){
                opp.npsp__Notification_Preference__c = 'Postal Mail';
            }else{
                opp.npsp__Notification_Preference__c = 'Email';
            }
            opp.npsp__Honoree_Name__c = dedicationName;
            opp.npsp__Notification_Recipient_Name__c = LName + ' ' +FName;
            opp.npsp__Notification_Message__c = dedicationMessage;
            opp.RecordTypeId = OpportunityrecordTypeId;
            opp.npsp__Notification_Recipient_Contact__c = con.Id;
            opp.amount      = Amount;
            listOfOpp.add(opp);
        }
        if(!listOfOpp.isEmpty()){
            try {
                if (!listOfOpp.isEmpty()) {
                    insert listOfOpp;
                }
            } catch (Exception e) {
                // Handle the exception
                System.debug('An error occurred while inserting opportunities: ' + e.getMessage());
            }
        }
        /*OpportunityContactRole opprole = new OpportunityContactRole();
opprole.ContactId=mapacntwithcon.get(listOfAccount[0].Id);
opprole.OpportunityId = listOfOpp[0].Id;
opprole.Role='Decision Maker';
opprole.IsPrimary=true;
listOppRole.add(opprole);
if(!listOppRole.isEmpty()){
insert listOppRole;
}  */
        integer g = 0;
        for(string F : Fund.keyset()){
            If(gacUpdatedMap.get(F).Name == F){
                npsp__Allocation__c  gaurec = new npsp__Allocation__c();
                gaurec.npsp__Opportunity__c = listOfOpp[0].Id;
                gaurec.npsp__Amount__c = decimal.valueOf(fund.get(F));
                gaurec.npsp__General_Accounting_Unit__c = gacUpdatedMap.get(F).Id;
                g++;
                npspDat.add(gaurec);
            }
            
        } 
        if(!npspDat.isEmpty()){
            insert npspDat;
        }    
        
    }
    @AuraEnabled
    Global static Boolean isEmailUnique(String email ){
        List<Contact> accReq = [SELECT Id FROM Contact WHERE Email =:email ];  
        return accReq.isEmpty();
    }
    @AuraEnabled(cacheable = true)
    Global static List<npsp__General_Accounting_Unit__c> getActiveGeneralAccountingUnit(){
        system.debug('list of GAC --> ' + [SELECT Id, Name,npsp__Active__c From npsp__General_Accounting_Unit__c WHERE npsp__Active__c =: true ]);
        List<npsp__General_Accounting_Unit__c> gacList = [SELECT Id, Name,npsp__Active__c From npsp__General_Accounting_Unit__c WHERE Active_for_Web_Donation__c =: true WITH SYSTEM_MODE];
        gacList.sort();
        return gacList;
    }
    
    @AuraEnabled
    Global static String ashPayment(String FName,String LName,String Email,String Address1,String Address2, String City,String State,String Country,String PostalCode,Double totalAmountValue,String Fund , string tributetype, string dedicationName, string dedicationMessage,String dedicationFName,String dedicationlName,String dedicationEmail,String Cred){
        Map<string,string> storeAllFund = new Map<string,string>();
        List<OpportunityService> dataList = (List<OpportunityService>) JSON.deserialize(fund, List<OpportunityService>.class);
        for (OpportunityService item : dataList) {
            System.debug('Label: ' + item.label + ', Value: ' + item.value);
            // Add your logic to do something with the data
            storeAllFund.put(item.label,item.value);
        }
        system.debug('storeAllFund ' + storeAllFund );
        System.debug('Funds value'+fund);
        asp04__Payment__c  asp = new asp04__Payment__c();
        asp.ASH_Payment_Type__c = 'Website Donation';
        asp.asp04__First_Name__c  = FName;
        asp.asp04__Last_Name__c   = LName; 
        asp.asp04__Email__c     =   Email;
        asp.asp04__Billing_Address_Street__c  = Address1 + '\r\n' + Address2;
        asp.asp04__Billing_Address_City__c    = City;
        asp.asp04__Billing_Address_State__c   = State;
        asp.asp04__Billing_Address_Country__c = Country;
        asp.asp04__Billing_Address_PostalCode__c = PostalCode;
        asp.asp04__Payment_Route_Options__c      ='Card';
        asp.asp04__Amount__c                     = totalAmountValue;
        String URLP;
        
        if(asp!=null)
            insert asp; 
        if(asp != null) {
            asp04__Payment__c  apsc = [select 	asp04__eCommerce_URL__c from asp04__Payment__c where Id =:asp.Id];
            String html_eCommerce_URL = apsc.asp04__eCommerce_URL__c;
            Pattern p = Pattern.compile('<a[^>]+href="([^">]+)"[^>]*>(.*?)</a>');
            Matcher m = p.matcher(html_eCommerce_URL);
            String extractedURL;
            if (m.find()) {
                extractedURL = m.group(1);
                URLP = extractedURL.replace('&amp;', '&');
                
            }
            
        }
        
        CreateOpp(storeAllFund,asp.Id,totalAmountValue,FName,LName,Email,Address1,Address2,City,State,Country,PostalCode,tributetype,dedicationName,dedicationMessage,dedicationFName,dedicationlName,dedicationEmail,Cred);
        return   URLP;
        
    }    
    
}