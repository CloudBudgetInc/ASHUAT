@isTest(SeeAllData=true)
public class FfaDataProviderTest {
    
	static testMethod void testGetGlaCode() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id someId = provider.getGlaCode('7020');
        System.assertNotEquals(null,someId);
    }
    
	static testMethod void testCheckGlaCode() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        boolean positiveResult = provider.checkGlaCode('7020');
        boolean negativeResult = provider.checkGlaCode('5555');
        Assert.isTrue(positiveResult);
        Assert.isFalse(negativeResult);
    }    
    
	static testMethod void testGetDimension1() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id someId = provider.getDimension1('100');
        System.assertNotEquals(null,someId);
    }
    
	static testMethod void testGetFullDimension1() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        c2g__codaDimension1__c someDim1 = provider.getFullDimension1('100');
        System.assertNotEquals(null,someDim1);
    }    
    
	static testMethod void testCheckDimension1() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        boolean positiveResult = provider.checkDimension1('112');
        boolean negativeResult = provider.checkDimension1('aaa');
        Assert.isTrue(positiveResult);
        Assert.isFalse(negativeResult);
    }        
    
	static testMethod void testGetDimension2() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id someId = provider.getDimension2('000');
        System.assertNotEquals(null,someId);
    }

	static testMethod void testGetFullDimension2() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        c2g__codaDimension2__c someDim2 = provider.getFullDimension2('000');
        System.assertNotEquals(null,someDim2);
    }
    
	static testMethod void testCheckDimension2() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        boolean positiveResult = provider.checkDimension2('359');
        boolean negativeResult = provider.checkDimension2('bbb');
        Assert.isTrue(positiveResult);
        Assert.isFalse(negativeResult);
    }       
    
	static testMethod void testGetDimension3() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id someId = provider.getDimension3('000');
        System.assertNotEquals(null,someId);        
    }
    
	static testMethod void testGetFullDimension3() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        c2g__codaDimension3__c someDim3 = provider.getFullDimension3('000');
        System.assertNotEquals(null,someDim3);
    }    
    
	static testMethod void testCheckDimension3() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        boolean positiveResult = provider.checkDimension3('000');
        boolean negativeResult = provider.checkDimension3('ccc');
        Assert.isTrue(positiveResult);
        Assert.isFalse(negativeResult);
    }         
    
	static testMethod void testGetDimension4() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id someId = provider.getDimension4('00');
        System.assertNotEquals(null,someId);        
    }
    
	static testMethod void testGetFullDimension4() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        c2g__codaDimension4__c someDim4 = provider.getFullDimension4('00');
        System.assertNotEquals(null,someDim4);
    }
    
	static testMethod void testCheckDimension4() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        boolean positiveResult = provider.checkDimension4('00');
        boolean negativeResult = provider.checkDimension4('dd');
        Assert.isTrue(positiveResult);
        Assert.isFalse(negativeResult);
    }             
    
    static testMethod void testGetVendor() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Account someAccount = provider.getVendor('1800');
        System.assertEquals(someAccount.Name,'1800ADMIN, LLC');
    }
    
    static testMethod void testGetCompany() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id someId = provider.getCompany('ASH');    
        System.assertNotEquals(null,someId);
    }   
    
    static testMethod void testGetAshPeriod() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        c2g__codaPeriod__c somePeriod = provider.getPeriod('ASH', '202103');
        System.assertEquals(somePeriod.c2g__StartDate__c, Date.newInstance(2020, 09, 01));
    }
    
    static testMethod void testGetAshRcPeriod() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        c2g__codaPeriod__c somePeriod = provider.getPeriod('ASHRC', '202103');
        System.assertEquals(somePeriod.c2g__StartDate__c, Date.newInstance(2020, 09, 01));
    }    
    
    static testMethod void testGetCurrentPeriod() {
		FfaDataProvider provider = FfaDataProvider.getInstance();
		Id someId = provider.getCurrentPeriod('ASH');
        Id someOtherId = provider.getCurrentPeriod('ASHRC');
        System.assertNotEquals(null, someOtherId);
        System.assertNotEquals(null, someId);
    }
    
    static testMethod void testGetPreviousPeriod() {
		FfaDataProvider provider = FfaDataProvider.getInstance();
		Id someId = provider.getCurrentPeriod('ASH');
        Id someOtherId = provider.getCurrentPeriod('ASHRC');
        System.assertNotEquals(null, someId);
        System.assertNotEquals(null, someOtherId);
    }    
    
    static testMethod void testGetVendorRecordTypeId() {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id someId = provider.getVendorRecordTypeId();
        System.assertNotEquals(null, someId); 
    }
}