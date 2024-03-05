@RestResource(urlMapping='/InvoiceService/*')
global class ashOpportunityInvoiceHandler {
    
    Global class FlowInput {
        @InvocableVariable(label='Opportunity ID' required=true)
        Global Id oppId;

        @InvocableVariable(label='Post Invoice' required=false)
        Global Boolean isInvoicePosted;

        @InvocableVariable(label='Invoice Type' required=false)
        Global String invoiceType;

        @InvocableVariable(label='SIN ID' required=false)
        Global Id sinId;

        @InvocableVariable(label='Sync SIN' required=false)
        Global Boolean sinSynced; 
        
    }
    
    global class FlowResponse {
        @InvocableVariable
        Global String invoiceId;
		
		@InvocableVariable
    	Global String paymentURL;
    }
  
    @InvocableMethod(label='Generate Invoice' description='Generates an Invoice from the provided Opportunity ID and options')
    Global static List<FlowResponse> createInvoice(List<FlowInput> inputs) {
        
        FlowResponse response = new FlowResponse();
        List<FlowResponse> responses = new List<FlowResponse>();
        
        // Considering a single record for simplicity. Could be enhanced for bulk processing.
        Id oppId = inputs[0].oppId;
        Id sinId = inputs[0].sinId;
        Boolean sinSynced = inputs[0].sinSynced;
        Boolean shouldPost = inputs[0].isInvoicePosted != null ? inputs[0].isInvoicePosted : false; // Default to false if not provided
        String invType = inputs[0].invoiceType != null ? inputs[0].invoiceType : 'Default'; // Default to 'Default' if not provided
        
        Map<String, String> asperatoPaymentPageCustomerDetails = new Map<String, String>();

        // Add items to the map with keys
        asperatoPaymentPageCustomerDetails.put('FirstName', '');
       	asperatoPaymentPageCustomerDetails.put('LastName', '');
        asperatoPaymentPageCustomerDetails.put('Email', '');
        asperatoPaymentPageCustomerDetails.put('Address1', '');
        asperatoPaymentPageCustomerDetails.put('Address2', '');
        asperatoPaymentPageCustomerDetails.put('City', '');
        asperatoPaymentPageCustomerDetails.put('State', '');
        asperatoPaymentPageCustomerDetails.put('country', '');
        asperatoPaymentPageCustomerDetails.put('PostalCode', '');
        
        
        try {
            Opportunity opp = [SELECT Id, CloseDate, AccountId, npsp__Primary_Contact__c, HasOpportunityLineItem, CurrencyIsoCode FROM Opportunity WHERE Id = :oppId LIMIT 1];
            Account relatedAccount = [SELECT Id, FirstName__c, LastName__c, BillingStreet, BillingCity, BillingState, BillingCountry,   
                                      BillingPostalCode, c2g__CODADimension1__c, c2g__CODADimension2__c, c2g__CODADimension3__c, 
                                      c2g__CODADimension4__c, c2g__CODAAccountsReceivableControl__c, c2g__CODAAccountTradingCurrency__c FROM Account WHERE Id = :opp.AccountId LIMIT 1];
            
            
            
            // Mapping the Asperator Payment Customer Details
            if (opp.npsp__Primary_Contact__c != null){
                Contact relatedContactNPSP = [SELECT Id, FirstName, LastName, Email From Contact where Id = :opp.npsp__Primary_Contact__c LIMIT 1];
                // try if the contact has NPSP address. 
                npsp__Address__c relatedAddressNPSP;
                try{
                	relatedAddressNPSP = [select id, npsp__MailingStreet__c, npsp__MailingStreet2__c, npsp__MailingCity__c, npsp__MailingState__c, 
                                                       npsp__MailingCountry__c, npsp__MailingPostalCode__c from npsp__Address__c where Contact__c = :opp.npsp__Primary_Contact__c LIMIT 1];
                }
                catch (Exception npsp) {
                    // Handle the exception
                    System.debug('An error occurred on NPSP Address Query:' + npsp.getMessage());
                }
                if (relatedContactNPSP != null){ 
                    asperatoPaymentPageCustomerDetails.put('FirstName', relatedContactNPSP.FirstName);
                    asperatoPaymentPageCustomerDetails.put('LastName', relatedContactNPSP.LastName);
                    asperatoPaymentPageCustomerDetails.put('Email', relatedContactNPSP.Email);  
                }
                
                
                if (relatedAddressNPSP != null){
                    asperatoPaymentPageCustomerDetails.put('Address1', relatedAddressNPSP.npsp__MailingStreet__c);
                    asperatoPaymentPageCustomerDetails.put('Address2', relatedAddressNPSP.npsp__MailingStreet2__c);
                    asperatoPaymentPageCustomerDetails.put('City', relatedAddressNPSP.npsp__MailingCity__c);
                    asperatoPaymentPageCustomerDetails.put('State', relatedAddressNPSP.npsp__MailingState__c);
                    asperatoPaymentPageCustomerDetails.put('country', relatedAddressNPSP.npsp__MailingCountry__c);
                    asperatoPaymentPageCustomerDetails.put('PostalCode', relatedAddressNPSP.npsp__MailingPostalCode__c);
                }
            }            
    		// Mapping the Asperato Payment Customer Details ends
    		// 
    		// setting up Account Demensions and AR Control Account if not present 
    		ash_ar_custom_settings__c setting = ash_ar_custom_settings__c.getInstance('Default'); // getting values from custom settings.
        	
    		if(invType == 'Website Donation' && relatedAccount.c2g__CODADimension1__c == null) relatedAccount.c2g__CODADimension1__c = setting.Website_Donation_Account_Default_D1__c;
            if(invType == 'Website Donation' && relatedAccount.c2g__CODADimension2__c == null) relatedAccount.c2g__CODADimension2__c = setting.Website_Donation_Account_Default_D2__c;
            if(invType == 'Website Donation' && relatedAccount.c2g__CODADimension3__c == null) relatedAccount.c2g__CODADimension3__c = setting.Website_Donation_Account_Default_D3__c;
            if(invType == 'Website Donation' && relatedAccount.c2g__CODADimension4__c == null) relatedAccount.c2g__CODADimension4__c = setting.Website_Donation_Account_Default_D4__c; 
            // AR Control Account
            if(invType == 'Website Donation' && relatedAccount.c2g__CODAAccountsReceivableControl__c == null) relatedAccount.c2g__CODAAccountsReceivableControl__c = setting.Website_Donation_Account_Default_AR__c;
            
           	// updating Account Trading Currency From Opportunity. 
            if(relatedAccount.c2g__CODAAccountTradingCurrency__c == null) relatedAccount.c2g__CODAAccountTradingCurrency__c = opp.CurrencyIsoCode;
            
    		update relatedAccount; // update the Related Account information. 
            
            c2g__codaInvoice__c invoice = new c2g__codaInvoice__c();
            
           	string companyFFA = 'a7s3u0000008eakAAA'; //Hard codded the Owner Compnay here..need to update this with the FF Fondation Company 
            
            // Getting time period
            c2g__codaPeriod__c periodRecord = [SELECT Id FROM c2g__codaPeriod__c WHERE c2g__StartDate__c <= :opp.CloseDate AND c2g__EndDate__c >= :opp.CloseDate AND c2g__OwnerCompany__c = :companyFFA LIMIT 1];
                
        
            // Mapped values
                invoice.c2g__Opportunity__c = opp.Id;
                invoice.c2g__Account__c = opp.AccountId;
                invoice.c2g__Dimension1__c = relatedAccount.c2g__CODADimension1__c;
                invoice.c2g__Dimension2__c = relatedAccount.c2g__CODADimension2__c;
                invoice.c2g__Dimension3__c = relatedAccount.c2g__CODADimension3__c;
                invoice.c2g__Dimension4__c = relatedAccount.c2g__CODADimension4__c;
                invoice.c2g__FirstDueDate__c = opp.CloseDate;
                invoice.c2g__InvoiceDate__c = opp.CloseDate;
                invoice.c2g__DueDate__c = opp.CloseDate.addDays(30); // accountMap.get(opp.AccountId).c2g__CODADaysOffset1__c Assumed mapping; might need adjustment
                invoice.c2g__Period__c = periodRecord.Id;
            	invoice.ASH_Invoice_Type__c = invType;
                   
                invoice.c2g__OwnerCompany__c = companyFFA;
                //invoice.c2g__OwnerCompany__c = companyFFA.c2g__msg_link_ffa_id__c;
                
                
                // Hard codded
                invoice.c2g__CopyAccountValues__c = FALSE;
                invoice.c2g__CopyDefaultPrintedTextDefinitions__c = FALSE;
                invoice.c2g__CreatingRecurringInvoice__c = FALSE;
                invoice.c2g__DeriveCurrency__c = FALSE;
                invoice.c2g__DeriveDueDate__c = FALSE;
                invoice.c2g__DerivePeriod__c = FALSE;
                invoice.c2g__GenerateAdjustmentJournal__c = TRUE;
                invoice.c2g__Interval__c = 'Monthly';                
                invoice.c2g__InvoiceCurrency__c = 'a7X3u000000XednEAC'; // need to look at
                invoice.c2g__InvoiceStatus__c = 'In Progress';
                invoice.c2g__InvoiceType__c = 'Standard';
                invoice.c2g__PrintedText1AllowEdit__c = FALSE;
                invoice.c2g__PrintedText2AllowEdit__c = FALSE;
                invoice.c2g__PrintedText3AllowEdit__c = FALSE;
                invoice.c2g__PrintedText4AllowEdit__c = FALSE;
                invoice.c2g__PrintedText5AllowEdit__c = FALSE;
                invoice.c2g__PrintStatus__c = 'Not Printed';
                invoice.c2g__SalesTaxStatus__c = 'Not Calculated';
                invoice.c2g__Usepartperiods__c = TRUE;          
                invoice.CurrencyIsoCode = 'USD';
                invoice.ffaci__CongaPrintStatus__c = 'Not Printed';
                invoice.ffaci__CurrencyCulture__c = 'en-AU';    // need to look at
                invoice.ffbext__Approved__c = FALSE;
                //invoice.ffgcp__CloudPrintStatus__c = 'Unavailable';   
    
           // invoicesToInsert.add(invoice);
            if (sinId != null && sinSynced) {
            invoice.Id = sinId;
			// checking the existing invoice. 
			c2g__codaInvoice__c existingInvoice = [SELECT ASH_Invoice_Type__c FROM c2g__codaInvoice__c  WHERE Id = :sinId LIMIT 1];
                if (existingInvoice != null) {
                    if(invType == 'Default') invoice.ASH_Invoice_Type__c = existingInvoice.ASH_Invoice_Type__c; 
                    
                    update invoice; // Updating existing Invoice
                    // deleting existing line items. 
                    List<c2g__codaInvoiceLineItem__c> existingLineItems = [SELECT Id FROM c2g__codaInvoiceLineItem__c WHERE c2g__Invoice__c = :sinId];
                    delete existingLineItems;                
                  }
            
                

            }
            else{
            insert invoice;
            }
            response.invoiceId = invoice.Id;  // Setting the returned invoice ID to the response.
            response.paymentURL = '';

             // ********************************************************************************* Adding Invoice Line Items
            if(opp.HasOpportunityLineItem) {    
            List<OpportunityLineItem> oppLineItems = [SELECT Description, Product2Id, Quantity, UnitPrice, c2g__CODAGeneralLedgerAccount__c, Dimension_1__c, Dimension_2__c, Dimension_3__c, 
                                                      Dimension_4__c, Fund_Dimension_5__c, GAU_Allocation__r.GAU_Name__c FROM OpportunityLineItem WHERE OpportunityId = :oppId];
    
            List<c2g__codaInvoiceLineItem__c> lineItemsToInsert = new List<c2g__codaInvoiceLineItem__c>();
    
            Integer lineNumber = 1; // Initialize line number
            for(OpportunityLineItem oli : oppLineItems) {
            
                c2g__codaInvoiceLineItem__c lineItem = new c2g__codaInvoiceLineItem__c();
    
                if(oli.Dimension_1__c != null) lineItem.c2g__Dimension1__c = oli.Dimension_1__c;
                if(oli.Dimension_2__c != null) lineItem.c2g__Dimension2__c = oli.Dimension_2__c;
                if(oli.Dimension_3__c != null) lineItem.c2g__Dimension3__c = oli.Dimension_3__c;
    			if(oli.Dimension_3__c != null) lineItem.c2g__Dimension4__c = oli.Dimension_4__c;
                if(oli.Fund_Dimension_5__c != null) lineItem.Fund_Dimension_5__c = oli.Fund_Dimension_5__c;
                if(oli.c2g__CODAGeneralLedgerAccount__c != null) lineItem.c2g__GeneralLedgerAccount__c = oli.c2g__CODAGeneralLedgerAccount__c;
                
                lineItem.c2g__CalculateIncomeSchedule__c = FALSE;
                lineItem.c2g__CalculateTaxValue1FromRate__c = FALSE;
                lineItem.c2g__CalculateTaxValue2FromRate__c = FALSE;
                lineItem.c2g__CalculateTaxValue3FromRate__c = FALSE;
                lineItem.c2g__DeriveLineNumber__c = FALSE;
                lineItem.c2g__DeriveTaxRate1FromCode__c = FALSE;
                lineItem.c2g__DeriveTaxRate2FromCode__c = FALSE;
                lineItem.c2g__DeriveTaxRate3FromCode__c = FALSE;
                lineItem.c2g__DeriveUnitPriceFromProduct__c = FALSE;
                
                // lineItem.c2g__Dimension1__c = ''; // this will be set later or has a default value
                // lineItem.c2g__Dimension2__c = ''; // this will be set later or has a default value
                // lineItem.c2g__Dimension3__c = ''; // this will be set later or has a default value
                // lineItem.c2g__Dimension4__c = ''; // this will be set later or has a default value
                
                lineItem.c2g__ExcludeFromWithholding__c = FALSE;
                lineItem.c2g__InternalCalculateIS__c = TRUE;                
                lineItem.c2g__SetTaxCode1ToDefault__c = FALSE;
                lineItem.c2g__SetTaxCode2ToDefault__c = FALSE;
                lineItem.c2g__SetTaxCode3ToDefault__c = FALSE;
                lineItem.c2g__UsePartPeriods__c = TRUE;
                lineItem.c2g__UseProductInformation__c = FALSE;
                lineItem.CurrencyIsoCode = 'USD';
                
                
                lineItem.c2g__OwnerCompany__c = companyFFA; // needed to change this
                
                lineItem.c2g__Invoice__c = invoice.Id; // Linking the line item to the invoice just created
                // Mapping the OpportunityLineItem fields to c2g__codaInvoiceLineItem__c
                lineItem.c2g__LineDescription__c = oli.Description;
                lineItem.c2g__Product__c = oli.Product2Id;
                lineItem.c2g__Quantity__c = oli.Quantity;
                lineItem.c2g__UnitPrice__c = oli.UnitPrice;
                lineItem.c2g__LineNumber__c = lineNumber++; // Increment the line number for each line item.
    
                // Add the line item to the list to insert.
                lineItemsToInsert.add(lineItem);
            }
    
            // Insert all the line items at once.
            if(lineItemsToInsert.size() > 0) {
                insert lineItemsToInsert;
            }
            }
            if(shouldPost) {
                // cheching if the Asperato Payment Integration Method exists for the given account, create a new one, if not by taking values from custom settings             
                               
                List<ffasp__PaymentIntegrationMethod__c> existingPaymentMethodList = [SELECT Id, ffasp__Account__c 
                                                                                        FROM ffasp__PaymentIntegrationMethod__c 
                                                                                        WHERE ffasp__Account__c = :opp.AccountId
                                                                                        LIMIT 1 ];
                
                // Check if a record was found
               if (existingPaymentMethodList.isEmpty()) {
                    // No record found, create a new one
                    ffasp__PaymentIntegrationMethod__c newAsperatoPaymentIntegrationMethod = new ffasp__PaymentIntegrationMethod__c(
                        ffasp__Provider__c = 'Asperato',
                        ffasp__ReceivablesBankAccount__c = setting.Default_Receivables_Bank_Account__c,
                        ffasp__Account__c = opp.AccountId
                    );
                    
                    // Insert the new record into the database
                    insert newAsperatoPaymentIntegrationMethod;
                }
                // Asperato payment Integration Method added.
	
                
                Set<Id> sourceIds = new Set<Id>{invoice.Id}; // Using the newly created invoice's Id
                Set<Id> transactionIds;
                try {
                    transactionIds = c2g.PostingPxService.postSync(sourceIds);
                    System.debug('Transactions created: ' + transactionIds);
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error while posting the Sales Invoice: ' + e.getMessage());
                    System.debug('while posting the SIN Stack  Trace: ' + e.getStackTraceString());
                }    
                         
            //}
            // Between Start
            //if(shouldPost && invType == 'Website Donation') { // Updating the Payment type to Website Donation on the Asperato Payment Object.
                try {        
                    c2g__codaInvoice__c postedInvoice = [SELECT ffasp__Payment__c FROM c2g__codaInvoice__c WHERE Id = :invoice.Id LIMIT 1];
            		System.debug('Payment_ID: ' + postedInvoice.ffasp__Payment__c);
                    if(postedInvoice != null && postedInvoice.ffasp__Payment__c != null) {
                        
                        asp04__Payment__c relatedRecord = [SELECT id, asp04__eCommerce_URL__c, ASH_Payment_Type__c FROM asp04__Payment__c WHERE Id = :postedInvoice.ffasp__Payment__c LIMIT 1];
                        
                        if(relatedRecord != null) {
                            String html_eCommerce_URL = relatedRecord.asp04__eCommerce_URL__c;
                            //Pattern p = Pattern.compile('<a[^>]*>(.*?)</a>');
                            Pattern p = Pattern.compile('<a[^>]+href="([^">]+)"[^>]*>(.*?)</a>');
                            Matcher m = p.matcher(html_eCommerce_URL);
                            
                            String extractedURL;
                            if (m.find()) {
                                extractedURL = m.group(1);
                                response.paymentURL = extractedURL.replace('&amp;', '&');
                                System.debug('paymentURL: ' + extractedURL);
                            }
                            
                            if(invType == 'Website Donation') relatedRecord.ASH_Payment_Type__c = 'Website Donation';
                            // updating the Asperato Payment Record Address. 
                            string webDonationAddress_1 = '';
                            string webDonationAddress_2 = '';
                            if (asperatoPaymentPageCustomerDetails.get('Address1') != null) webDonationAddress_1 = asperatoPaymentPageCustomerDetails.get('Address1');
                            if (asperatoPaymentPageCustomerDetails.get('Address2') != null) webDonationAddress_2 = asperatoPaymentPageCustomerDetails.get('Address2');
                            relatedRecord.asp04__First_Name__c = asperatoPaymentPageCustomerDetails.get('FirstName');
                            relatedRecord.asp04__Last_Name__c = asperatoPaymentPageCustomerDetails.get('LastName');
                            relatedRecord.asp04__Email__c = asperatoPaymentPageCustomerDetails.get('Email');
                            relatedRecord.asp04__Billing_Address_Street__c = webDonationAddress_1 + '\r\n' + webDonationAddress_2;
                            relatedRecord.asp04__Billing_Address_City__c = asperatoPaymentPageCustomerDetails.get('City');
                            relatedRecord.asp04__Billing_Address_State__c = asperatoPaymentPageCustomerDetails.get('State');
                            relatedRecord.asp04__Billing_Address_Country__c = asperatoPaymentPageCustomerDetails.get('country');
                            relatedRecord.asp04__Billing_Address_PostalCode__c = asperatoPaymentPageCustomerDetails.get('PostalCode');
                            update relatedRecord;
                        }
                    }
                } catch(QueryException qe) {
                    System.debug('Query Exception when trying to update related record: ' + qe.getMessage());
                } catch(DmlException dmlE) {
                    System.debug('DML Exception when trying to update related record: ' + dmlE.getMessage());
                }
            } 
            
            

        } // Between End
        catch(QueryException qe) {
            System.debug('Query Exception: ' + qe.getMessage());
            System.debug('Stack Trace: ' + qe.getStackTraceString());
            // Handle or log the error appropriately
        } catch(DmlException dmlE) {
            System.debug('DML Exception: ' + dmlE.getMessage());
            System.debug('Stack Trace: ' + dmlE.getStackTraceString());
            // Handle or log the error.
        } catch(Exception e) {
            System.debug('General Exception: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            // Handle or log the general exception.
        }
        
        responses.add(response);
        System.debug('responses' + responses);
        return responses; 
    }

    @HttpPost
    global static FlowResponse createInvoiceFromREST() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
     
        // Deserialize the request JSON body into the FlowInput class
        FlowInput input = (FlowInput) JSON.deserialize(req.requestBody.toString(), FlowInput.class);

        // Call original method 
        List<FlowResponse> responses = createInvoice(new List<FlowInput>{input});
        
        // Assuming that there will always be at least one response.
        // Adjust error handling as necessary.
        System.debug('responses' + responses[0]); 
        return responses[0];
    }

}