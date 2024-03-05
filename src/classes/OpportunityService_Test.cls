@isTest
public class OpportunityService_Test {
    
    @isTest
    Public Static Void OppMethod(){
        	string fund = '[{"label":"ASH Career Development and Training Fund","value":"20"},{"label":"ASH Clinical Research Training Institute Fund","value":"20"}]';
        	Double myDoubleVariable = 40;
 			insert new npsp__General_Accounting_Unit__c(Name = 'ASH Career Development and Training Fund', npsp__Active__c = true);
        	insert new npsp__General_Accounting_Unit__c(Name = 'ASH Clinical Research Training Institute Fund', npsp__Active__c = true);
            List<npsp__General_Accounting_Unit__c> getAllGac = OpportunityService.getActiveGeneralAccountingUnit();
        	// System.assertEquals(0, getAllGac.size(), 'The General Accounting Units are found.');
       // System.assertEquals(1, getAccount.size(), 'The Account iS found');
         Test.startTest();            
        string fund2 = '[{"label":"ASH Career Development and Training Fund","value":"10"},{"label":"ASH Clinical Research Training Institute Fund","value":"10"}]';
        OpportunityService.ashPayment('Test1','Test2','test@sfdc.com',
                                         'valley ranch','parkway', 'Irving',
                                         'Ukraine','California','523168',
                                         myDoubleVariable, fund,'Honor', 
                                         'test', 'In dedication mas is msg','first Name Dedication ',
                                         'Test','Test@gmail.com','Testing');        
        Test.stopTest();

    }
    @Istest
    Public Static Void OppMethodForexistingContact(){
        	string fund = '[{"label":"2021 Ash Fund","value":"20"},{"label":"2023 Ash Fund","value":"20"}]';
        	Double myDoubleVariable = 40;
 			insert new npsp__General_Accounting_Unit__c(Name = '2021 Ash Fund', npsp__Active__c = true);
        	insert new npsp__General_Accounting_Unit__c(Name = '2023 Ash Fund', npsp__Active__c = true);
        Account acc = new Account(Name = 'test');
        contact con = new Contact(FirstName = 'First' ,LastName= 'Last',Email ='Test@gmail.com', AccountId = acc.Id);
        insert acc;
        insert con;
        boolean variable = OpportunityService.isEmailUnique('Test@gmail.com');
         System.assertEquals(false,variable, 'The related contact is found');
         boolean variable2 = OpportunityService.isEmailUnique('guet@gmail.com');
         System.assertEquals(true,variable2, 'The related contact is not found');
        
        
        Test.startTest();            
        
        OpportunityService.ashPayment('Test1','Test2','Test@gmail.com',
                                         'valley ranch','parkway', 'Irving',
                                         'Ukraine','California','523168',
                                         myDoubleVariable, fund,'Honor', 
                                         'test', 'In dedication mas is msg','first Name Dedication ',
                                         'Test','Test@gmail.com','Testing');        
        Test.stopTest();
        list<Account> getAccount = [Select Id From Account];
       // System.assertEquals(2, getAccount.size(), 'The Account is Found');

    }
}