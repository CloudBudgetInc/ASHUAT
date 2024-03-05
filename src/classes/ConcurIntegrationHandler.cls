public class ConcurIntegrationHandler {

    @future(callout=true)
    public static void handleVendorChange(Id someAccountId, String type) {
        
        Account someAccount = [SELECT Id, Name, Vendor_ID__c, Remit_Address_1__c, 
                               Remit_Address_2__c, Remit_City__c, Remit_State__c, 
                               Remit_Postal_Code__c, Remit_Country_Code__c
                               FROM Account WHERE Id = :someAccountId];        
        
        Http http = new Http();
        HttpRequest vendorCreationRequest = new HttpRequest();
		// Concur’s Vendor API version 3.0 was deprecated on 02/01/2023 and decommissioned on 11/30/2023
        //String vendorEndpoint = 'https://us.api.concursolutions.com/api/v3.0/invoice/vendors';
        String vendorEndpoint = 'https://us.api.concursolutions.com/api/v3.1/invoice/vendors';
        vendorCreationRequest.setEndpoint(vendorEndpoint);
        vendorCreationRequest.setHeader('Content-Type', 'application/json');
        vendorCreationRequest.setHeader('Authorization', 'Bearer ' + getAccessToken());
        if( type == 'INSERT' ) {
        	vendorCreationRequest.setMethod('POST');
        } else {
            vendorCreationRequest.setMethod('PUT');
        }

        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject();
        generator.writeFieldName('Vendor');
        generator.writeStartArray();
        generator.writeStartObject();
        
        generator.writeStringField('VendorCode', someAccount.Vendor_ID__c); 
        generator.writeStringField('AddressCode', someAccount.Vendor_ID__c);
        if(someAccount.Name != null) { generator.writeStringField('VendorName', someAccount.Name); }
        if(someAccount.Remit_Address_1__c != null) { generator.writeStringField('Address1', someAccount.Remit_Address_1__c.left(50)); }
        if(someAccount.Remit_Address_2__c != null) { generator.writeStringField('Address2', someAccount.Remit_Address_2__c.left(50)); }        
        if(someAccount.Remit_City__c != null) { generator.writeStringField('City', someAccount.Remit_City__c); }
        if(someAccount.Remit_State__c != null) { generator.writeStringField('State', someAccount.Remit_State__c); }
        if(someAccount.Remit_Postal_Code__c != null) { generator.writeStringField('PostalCode', someAccount.Remit_Postal_Code__c); }  
        //if(someAccount.Remit_Country_Code__c  != null && someAccount.Remit_Country_Code__c != 'US') { generator.writeStringField('CountryCode', someAccount.Remit_Country_Code__c ); }
        if(someAccount.Remit_Country_Code__c  != null) { generator.writeStringField('CountryCode', someAccount.Remit_Country_Code__c ); }        
        generator.writeStringField('CurrencyCode', 'USD');
        generator.writeEndObject();
        generator.writeEndArray();
        generator.writeEndObject();
        
        String result = generator.getAsString();
        //System.debug(result); 
        vendorCreationRequest.setBody(result);
        HttpResponse someResponse = http.send(vendorCreationRequest);
        if (someResponse.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                someResponse.getStatusCode() + ' ' + someResponse.getStatus());
        }
        else {
            System.debug(someResponse.getStatusCode());
            System.debug('Vendor push to Concur successful.');
        }      
    }
    
    @TestVisible
    private static String getAccessToken() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://us.api.concursolutions.com/oauth2/v0/token');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setMethod('POST');

        String clientId = 'e8705374-2cc9-43ae-a71c-e3d2af1c21e0';
        String clientSecret = '19e6ec5a-cbd2-4802-aef6-5103e024e3b3';
        String username = 'wsadminPROD@hematology.org';
        String password = 'T<!~h[D7JK[A8"[V';

        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String payload = 'client_id='+EncodingUtil.urlEncode(clientId,'UTF-8')+
            '&client_secret='+EncodingUtil.urlEncode(clientSecret,'UTF-8')+
            '&username='+EncodingUtil.urlEncode(username,'UTF-8')+
            '&password='+EncodingUtil.urlEncode(password,'UTF-8')+
            '&grant_type=password';
        request.setBody(payload);
        HttpResponse response = http.send(request);

        String accessToken;
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                response.getStatusCode() + ' ' + response.getStatus());
        } else {
            JSONParser parser = JSON.createParser(response.getBody());
            while (parser.nextToken() != null) {
                parser.nextValue();
                String fieldName = parser.getCurrentName();
                if(fieldName == 'access_token') {
                    String fieldValue = parser.getText();
                    accessToken = fieldValue;
                }
            }
        }
		return accessToken;        
    }
}