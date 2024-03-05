@IsTest
private class ContactTriggerHandlerTest {

    @IsTest
    private static void testSFMCSync(){
        Account testAccount = new Account(Name = 'TestAccountCC');
        insert testAccount;
        Contact testContact = new Contact(LastName = 'test contact', HasOptedOutOfEmail = false);
        insert testContact;
        testContact.HasOptedOutOfEmail = true;
        update testContact;

        Contact queriedContact = [SELECT Id, HasOptedOutOfEmail FROM Contact WHERE Id = :testContact.Id];
        System.debug('queriedContact: ' + queriedContact);
        // System.assertEquals(true, queriedContact.HasOptedOutOfEmail, 'We want to make sure our trigger updated our test contact correctly.');
    }

}