public class ashEmailSenderQueueable implements Queueable {

    private List<Id> invoiceIds;

    public ashEmailSenderQueueable(List<Id> invoiceIds) {
        this.invoiceIds = invoiceIds;
    }

    public void execute(QueueableContext context) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Retrieve the custom setting value
        ash_ar_custom_settings__c customSetting = ash_ar_custom_settings__c.getInstance('Default');
        string orgWideEmailAddress = customSetting.org_Wide_From_Email__c;

        // Query the necessary information from c2g__codaInvoice__c records
        List<c2g__codaInvoice__c> invoices = [SELECT Id, ffaci__InvoiceEmail__c, ASH_Primary_Contact_Email__c, ASH_Primary_Contact_Name__c, ffasp__Payment_Link__c FROM c2g__codaInvoice__c WHERE Id IN :invoiceIds];

        for (c2g__codaInvoice__c invoice : invoices) {
            // Create and configure the email message
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            // Set the recipient's email address
            if(!String.isBlank(invoice.ASH_Primary_Contact_Email__c)) mail.setToAddresses(new String[] {invoice.ASH_Primary_Contact_Email__c});
            else if(!String.isBlank(invoice.ffaci__InvoiceEmail__c)) mail.setToAddresses(new String[] {invoice.ffaci__InvoiceEmail__c});   
			else continue; // skip the code if there is no email address. 
            
            if(!String.isBlank(orgWideEmailAddress)) mail.setOrgWideEmailAddressId(orgWideEmailAddress);
            
            // Set the subject and plain text body or use a text-only email template
            mail.setSubject('Complete Your Donation to Support American Society of Hematology');
            String emailBody = '<p>Dear ' + invoice.ASH_Primary_Contact_Name__c + ',</p>' +
                   '<p>We hope this message finds you well.</p>' +
                   '<p>We noticed that you recently started the process of making a donation to the American Society of Hematology through our website but didn\'t complete it. We understand that life gets busy, and sometimes these things can slip our mind.</p>' +
                   '<p>Your intended support means a lot to us and plays a vital role in advancing hematology research, education, and patient care. If you are still interested in contributing, we\'ve made it easy for you to pick up where you left off:</p>' +
                   '<p>'+ invoice.ffasp__Payment_Link__c +'</p>' +
                   '<p>Your generosity helps us in our mission to conquer blood diseases. If you have any questions or need assistance, please don\'t hesitate to reach out. We\'re here to help.</p>' +
                   '<p>Thank you for your consideration and support of the American Society of Hematology. Together, we can make a significant impact.</p>' +
                   '<p>Warm regards,<br>American Society of Hematology<br>http://www.hematology.org/</p>';

			mail.setHtmlBody(emailBody);


            // Add additional email configuration if needed

            emails.add(mail);
        }

        // Send the emails
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
                System.debug('Number of emails sent: ' + emails.size());
            } catch (Exception e) {
                // Log the exception for debugging and tracking purposes
                System.debug('Error while sending emails: ' + e.getMessage());
                
            }
        }
    }
}