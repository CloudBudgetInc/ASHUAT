public with sharing class ContactTriggerHandler {
    public static void afterUpdate(List<Contact> newList, Map<Id, Contact> oldMap){
        if(newList.size() == 1){
            System.debug('ContractTriggerHandler size = ' + newlist.size() + ' after update.');
            if(newList[0].HasOptedOutOfEmail != oldMap.get(newList[0].Id).HasOptedOutOfEmail){
                System.debug('HasOptedOutOfEmail field changed from ' + oldMap.get(newList[0].Id).HasOptedOutOfEmail + ' to ' + newList[0].HasOptedOutOfEmail);
                Boolean isSandbox = [SELECT Id, Name, IsSandbox FROM Organization].IsSandbox;
                SFMC_Connect__mdt SFMCConnect = SFMC_Connect__mdt.getInstance('SFMC');
                if(!isSandbox && !Test.isRunningTest() && UserInfo.getUserId() != SFMCConnect.Marketing_Cloud_Integration_UserId__c){
                    SFMCConnector.updateSubscriberPreference(newList[0].Id, newList[0].HasOptedOutOfEmail);
                } /*else {
                    SFMCConnector.updateSubscriberPreference('0033u00001u4croAAA', newList[0].HasOptedOutOfEmail);
                } */
            } else {
                System.debug('HasOptedOutOfEmail field not changed, remains ' + newList[0].HasOptedOutOfEmail + ', SFMC callout not made.');
            }
        }
        System.debug('newList.size() (' + newList.size() + ')  > 1, sync to SFMC not ran.');
    }
}