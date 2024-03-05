@isTest(SeeAllData=true)
public class Vendor1099BatchTest {
    
	static testMethod void testVendor1099BatchOne() {   
        
        Test.startTest();
        Vendor1099Batch vendor1099Batch = new Vendor1099Batch('2023', Date.newInstance(2023,1,1), Date.newInstance(2023,12,31), 
			'ASH', 'ALLE12', 'true');
        Id jobId = Database.executeBatch(vendor1099Batch, 1);
        Test.stopTest();
        
        List<Account> vendorAccounts = [SELECT Id FROM Account WHERE Vendor_ID__c = 'ALLE12'];
        Account someAccount = vendorAccounts.get(0);
        
        X1099_Year__c some1099Year = [SELECT Payments__c, Reimbursements__c, Awards__c, Other_Compensation__c, 
                                      Tax_Year__c FROM X1099_Year__c WHERE 
        	CreatedDate = TODAY AND Vendor__c = :someAccount.Id];
        System.assertNotEquals(0, some1099Year.Payments__c);
        System.assertNotEquals(0, some1099Year.Reimbursements__c);
        System.assertEquals(null, some1099Year.Awards__c);
        System.assertEquals(null, some1099Year.Other_Compensation__c);        
        System.assertEquals(some1099Year.Tax_Year__c, '2023');
    }
    
	static testMethod void testVendor1099BatchTwo() {   
        
        Test.startTest();
        Vendor1099Batch vendor1099Batch = new Vendor1099Batch('2023', Date.newInstance(2023,1,1), Date.newInstance(2023,12,31), 
			'ASH', 'SLOA06', 'true');
        Id jobId = Database.executeBatch(vendor1099Batch, 1);
        Test.stopTest();
        
        List<Account> vendorAccounts = [SELECT Id FROM Account WHERE Vendor_ID__c = 'SLOA06'];
        Account someAccount = vendorAccounts.get(0);
        
        X1099_Year__c some1099Year = [SELECT Payments__c, Reimbursements__c, Awards__c, Other_Compensation__c, 
                                      Tax_Year__c FROM X1099_Year__c WHERE 
        	CreatedDate = TODAY AND Vendor__c = :someAccount.Id];
        System.assertNotEquals(0, some1099Year.Payments__c);
        System.assertEquals(null, some1099Year.Reimbursements__c);
        System.assertNotEquals(0, some1099Year.Awards__c);
        System.assertEquals(null, some1099Year.Other_Compensation__c);        
        System.assertEquals(some1099Year.Tax_Year__c, '2023');
    }    
}