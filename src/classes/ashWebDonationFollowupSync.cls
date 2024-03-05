// this class is for following up unpaid webdonation, and marking the oppty closed lost afte unsuccessful followups.
global class ashWebDonationFollowupSync implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        processWebAsperatoPayments();
    }
    
    public void processWebAsperatoPayments() {
        try {
            // Retrieve the custom setting value
            ash_ar_custom_settings__c customSetting = ash_ar_custom_settings__c.getInstance('Default');
            Integer daysThreshold = (Integer) customSetting.Unpaid_Website_Donations_keep_in_syst__c;
            Integer followUpAfterDays = (Integer) customSetting.Unpaid_Web_Donation_Followup_After_Days__c;
    
            // If the custom setting is not set, set a default value
            if(daysThreshold == null) daysThreshold = 30;
            
            if(followUpAfterDays == null) followUpAfterDays = 5;
            
            if(followUpAfterDays >= daysThreshold) daysThreshold = followUpAfterDays + 7;
            
            Date followUpDate = Date.today().addDays(-followUpAfterDays);
    
            Date thresholdDate = Date.today().addDays(-daysThreshold);
            
            System.debug('Followup Date for Unpaid Payments:'+ followUpDate);	
            System.debug('Threshold Date for Marking Opportunity Closed Lost:'+ thresholdDate);
            
    
            // SOQL query to retrieve the Asperato Payments based on the criteria
            List<asp04__Payment__c> payments = [SELECT Id, Name, asp04__Payment_Stage__c, ffasp__SalesInvoice__c, asp04__Due_Date__c
                                              FROM asp04__Payment__c
                                              WHERE ASH_Payment_Type__c = 'Website Donation' AND asp04__Payment_Stage__c IN ('Awaiting submission', 'Collected from customer', 'Failed')];

            if(payments.isEmpty()) {
                System.debug('No Payments found matching the criteria.');
                return;
            }
			
            List<Id> emailPaymentIds = new List<Id>(); // initializing for sending followup email.

            for(asp04__Payment__c pays : payments) {
                if(pays.asp04__Payment_Stage__c == 'Collected from customer' && pays.ffasp__SalesInvoice__c == '') {
                    // Actions for unmatched payment
                    System.debug('Unmatched Payment: Payment Number: ' + pays.Name);
                }
                
                // Follow up for making the payment
                else if((pays.asp04__Payment_Stage__c == 'Awaiting submission' ||  pays.asp04__Payment_Stage__c == 'Failed' ) && 
                        pays.asp04__Due_Date__c <= followUpDate && pays.asp04__Due_Date__c > thresholdDate) {
                    // Followup via email, using queueable Batch
                    
                    emailPaymentIds.add(pays.Id); // Adding email to the followup email list. 
                    System.debug('Follow Up for Unpaid Payments: Payment Number: ' + pays.Name);         
                }                
                // for discarding SIN VIA SCRs
                else if((pays.asp04__Payment_Stage__c == 'Awaiting submission' ||  pays.asp04__Payment_Stage__c == 'Failed' ) && 
                        pays.asp04__Due_Date__c <= thresholdDate) {                            
					// Update Oppportunity as Closed Lost.
                }
            }
            
            if (!emailPaymentIds.isEmpty()) { // Sending the payment ids for followup emails. 
                    try {
                        //System.enqueueJob(new ashEmailSenderQueueable(emailPaymentIds)); 
                    } catch (Exception e) {
                        System.debug('Error enqueuing EmailSenderQueueable: ' + e.getMessage());                        
                    }
                }

        } catch(Exception e) {
            // Handle the exception and log it
            System.debug('Error in processPayments: ' + e.getMessage());
			System.debug('Stack Trace: ' + e.getStackTraceString());            
            System.debug(System.LoggingLevel.ERROR, 'Error in processPayments: ' + e.getMessage());
        }
    }
}