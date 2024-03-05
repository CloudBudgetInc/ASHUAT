@isTest(SeeAllData=true)
public class JournalTriggerTest {

    /**
     * Tests journal validation by inserting a few lines with invalid combination rules, then 
     * firing the trigger.
     */
	static testMethod void testJournalValidation() {    
    	    
        FfaDataProvider provider = FfaDataProvider.getInstance();
        
        c2g__codaJournal__c someJournal = new c2g__codaJournal__c();
        someJournal.c2g__JournalStatus__c = 'In Progress';
        someJournal.c2g__OwnerCompany__c = provider.getCompany('ASH');
        someJournal.Flag_for_Balance__c = true;
        someJournal.c2g__JournalDescription__c = 'Test Journal 999';
        insert someJournal;
        
        // bad 'native' line.
        c2g__codaJournalLineItem__c someLine = new c2g__codaJournalLineItem__c();
        someLine.c2g__Journal__c = someJournal.Id;
        someLine.c2g__GeneralLedgerAccount__c = provider.getGlaCode('7020');
        someLine.c2g__Dimension1__c = provider.getDimension1('100');
        someLine.c2g__Dimension2__c = provider.getDimension2('000');
        someLine.c2g__Dimension3__c = provider.getDimension3('000');
        someLine.c2g__Dimension4__c = provider.getDimension4('00');        
        someLine.c2g__LineType__c = 'General Ledger Account';
        someLine.c2g__LineDescription__c = 'Test Entry';
        someLine.c2g__Value__c = 100;
        insert someLine;
        
        // bad intercompany line.
        c2g__codaJournalLineItem__c anotherLine = new c2g__codaJournalLineItem__c();
        anotherLine.c2g__Journal__c = someJournal.Id;
        anotherLine.c2g__GeneralLedgerAccount__c = provider.getGlaCode('7020');
        anotherLine.c2g__Dimension1__c = provider.getDimension1('100');
        anotherLine.c2g__Dimension2__c = provider.getDimension2('000');
        anotherLine.c2g__Dimension3__c = provider.getDimension3('000');
        anotherLine.c2g__Dimension4__c = provider.getDimension4('00');        
        anotherLine.c2g__LineType__c = 'Intercompany';
        anotherLine.c2g__DestinationCompany__c = provider.getCompany('ASHRC');
        anotherLine.c2g__DestinationLineType__c = 'General Ledger Account';
        anotherLine.c2g__LineDescription__c = 'Test Entry';
        anotherLine.c2g__Value__c = 100;
        insert anotherLine;
        
        someJournal.Validate_Journal__c = true;
		update someJournal;
        
        c2g__codaJournal__c testJournal = [SELECT Id, Invalid_Lines__c FROM c2g__codaJournal__c 
                                          WHERE c2g__JournalDescription__c = 'Test Journal 999'];
        System.assertEquals(2, testJournal.Invalid_Lines__c);            
    }
}