@IsTest
private class SFMCConnectorTest {

    @IsTest
    private static void getAuthTest(){
        Test.setMock(HttpCalloutMock.class, new getAuthMock());
        Map<String, Object> testResponse = SFMCConnector.getAuthToken();
        // System.assertEquals(200, testResponse.getStatusCode(), 'We expect our callout to have been successful.');
        System.assertEquals('10987654321abc', testResponse.get('access_token'), 'We expect to have received the correct access token.');
        System.assertEquals('https://soap.com/', testResponse.get('soap_instance_url'), 'We expect to have received the correct soap endpoint.');
    }

    @IsTest
    private static void updateSubscriberPreferenceTest(){
        Id testSubscriberKey = '0033u00001u4croAAA';
        Test.setMock(HttpCalloutMock.class, new setSubscriberMock());
        SFMCConnector.updateSubscriberPreference(testsubscriberKey, true);
        // String testResponse = SFMCConnector.updateSubscriberPreference(testsubscriberKey, true);
        // System.assertEquals('success', testResponse, 'We expect our callout to have been successful.');
    }
    
    @IsTest
    private static void sendEmailTest(){
        List<String> recipients = new List<String>{'kevin.fleck@coastalcloud.us'};
        String sender = 'test sender';
        String subject = 'test subject';
        String errorMessage = 'error message';
        SFMCConnector.sendEmail(recipients, sender, subject, errorMessage);
    }
    
    public class getAuthMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token": "10987654321abc", "token_type": "Bearer", "expires_in": 1079, "scope": "offline list_and_subscribers_read list_and_subscribers_write accounts_read", "soap_instance_url": "https://soap.com/", "rest_instance_url": "https://rest.com/"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class setSubscriberMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"updated": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

}