public with sharing class SFMCConnector {
    
    @TestVisible
    private static Map<String, Object> getAuthToken(){
        SFMC_Connect__mdt credentials = SFMC_Connect__mdt.getInstance('SFMC');
        String endpoint = credentials.Auth_Token_Endpoint__c;
        String clientId = credentials.Client_Id__c;
        String clientSecret = credentials.Client_Secret__c;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody('{"grant_type": "client_credentials","client_id": "'+clientId+'","client_secret": "'+clientSecret+'"}');
        HttpResponse response = http.send(request);

        return (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
    }

    @future(callout=true)
    public static void updateSubscriberPreference(Id subscriberKey, Boolean unsubscribe){
        Boolean isSandbox = [SELECT Id, Name, IsSandbox FROM Organization].IsSandbox;
        String subscriberStatus = unsubscribe ? 'Unsubscribed' : 'Active';
        Map<String, Object> authMap = new Map<String, Object>();
        try {
            if(!Test.isRunningTest()){
                authMap = getAuthToken();
            } else {
                authMap.put('access_token', '12345');
            }
            String soapEnvelope =   '<?xml version="1.0" encoding="utf-8"?>' +
                                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
                                    '   <soapenv:Header>' +
                                    '      <soapenv:Action>Update</soapenv:Action>' +
                                    '      <fueloauth xmlns="http://exacttarget.com">'+authMap.get('access_token')+'</fueloauth>' +
                                    '   </soapenv:Header>' +
                                    '   <soapenv:Body>' +
                                    '      <UpdateRequest xmlns="http://exacttarget.com/wsdl/partnerAPI">' +
                                    '         <Options>' +
                                    '            <SaveOptions>' +
                                    '               <SaveOption>' +
                                    '                  <PropertyName>*</PropertyName>' +
                                    '                  <SaveAction>UpdateOnly</SaveAction>' +
                                    '               </SaveOption>' +
                                    '            </SaveOptions>' +
                                    '         </Options>' +
                                    '         <Objects xsi:type="Subscriber">' +
                                    '            <PartnerKey xsi:nil="true" />' +
                                    '            <ObjectID xsi:nil="true" />' +
                                    '            <Status>'+subscriberStatus+'</Status>' +
                                    '            <SubscriberKey>'+subscriberKey+'</SubscriberKey>' +
                                    '         </Objects>' +
                                    '      </UpdateRequest>' +
                                    '   </soapenv:Body>' +
                                    '</soapenv:Envelope>';     
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(authMap.get('soap_instance_url')+'/Service.asmx');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'text/xml');
            request.setHeader('SoapAction', 'Update');
            request.setBody(soapEnvelope);
            HttpResponse response = http.send(request);
            System.debug('response.getStatusCode(): ' + response.getStatusCode());
            System.debug('updateSubscriberOptInOut response.getBody() ' + response.getBody());
            // return response.getStatusCode() == 200 ? 'success' : 'error';
        }
        catch(System.CalloutException e){
            System.debug('Callout error: ' + e.getMessage());
            if(!Test.isRunningTest()){
            	sendEmail(new List<String>{SFMC_Connect__mdt.getInstance('SFMC').Group_Email__c}, 'Apex error message', 'Error from SFMC subscriber sync.', e.getMessage());
            }
        }
    }

     @TestVisible
     private static void sendEmail(List<String> recipients, String senderName, String subject, String errorMessage){
        // Id groupId = SFMC_Connect__mdt.getInstance('SFMC').Error_EmailRecipient_Group_Id__c;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipients);
        // mail.setReplyTo('support@id.com');  
        mail.setSenderDisplayName(senderName);
        mail.setSubject(subject);
        mail.setPlainTextBody(errorMessage);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
     }

    /*
    private static List<String> getGroupAddresses(Id groupId){
        List<String> addressList = new List<String>();
        Set<Id> groupUserIdSet = new Set<Id>();
        Group g;
        if(!Test.isRunningTest()){
            g = [SELECT(Select userOrGroupId From GroupMembers) FROM Group WHERE Id = :groupId];
        } else {
            g = [SELECT Id, Name, (Select userOrGroupId From GroupMembers) FROM Group WHERE Name = 'test group' LIMIT 1];
        }
        System.debug('g: ' + g);
        System.debug('g.GroupMembers: ' + g.GroupMembers);
        for(GroupMember gm : g.GroupMembers){
            groupUserIdSet.add(gm.userOrGroupId);
        }
        List<User> groupUserList = [SELECT Email FROM User WHERE Id IN :groupUserIdSet];
        System.debug('groupUserList: ' + groupUserList);
        for(User u : groupUserList){
            addressList.add(u.Email);
        }
        System.debug('addressList: ' + addressList);
        return addressList;
    }*/

}