public with sharing class CustomSubcriptionCenterController {
	@AuraEnabled 
	public static User getUser() {
		User user = [SELECT Id, ASH_Member__c FROM User WHERE Id =: UserInfo.getUserId()];
		
		return user;
	}

	@AuraEnabled 
	public static Contact getSubscriptions() {
		User user = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId()];
		
		if (user.ContactId == null) {
			return null;
		}
		
		Contact contact = 
			[SELECT FirstName,LastName,Email,HasOptedOutOfEmail,Email_Subscriptions_Last_Updated_Date__c,
				ASH_Annual_Meeting__c,ASH_Meeting_on_Lymphoma_Biology__c,ASH_Consultative_Hematology_Course__c,
				Latest_in_Precision_Medicine_and_Immuno__c,ASH_Meeting_on_Hematologic_Malignancies__c,
				Highlights_of_ASH__c,Acute_Myeloid_Leukemia__c,Immune_Thrombocytopenia__c,Sickle_Cell_Disease__c,
				Venous_Thromboembolism__c,Von_Willebrand_Disease__c,Honorific_and_Mentor__c,Medical_Students__c,
				Career_and_Training__c,Webinars_Webcasts_Podcasts__c,Job_Center_Opportunities__c,Advance_Notice__c,
				Blood_Advances_Highlights__c,ASH_Clinical_Trials__c,The_Hematologist__c,ASH_Newslink__c,
				This_Week_in_Blood__c,ASH_Practice_Update__c,TraineE_News__c, FDA_Alerts__c
				FROM Contact WHERE Id =: user.ContactId];

		return contact;
	}

	@AuraEnabled 
	public static Contact subscribeAll(Boolean subscribe) {
		Boolean isSandbox = [SELECT Id, Name, IsSandbox FROM Organization].IsSandbox;
		User user = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId()];
		
		if (user.ContactId == null) {
			return null;
		}
		
		Contact contact = [SELECT Id FROM Contact WHERE Id =: user.ContactId];

		try {
			contact.HasOptedOutOfEmail = !subscribe;
			contact.ASH_Annual_Meeting__c = subscribe;
			contact.ASH_Meeting_on_Lymphoma_Biology__c = subscribe;
			contact.ASH_Consultative_Hematology_Course__c = subscribe;
			contact.Latest_in_Precision_Medicine_and_Immuno__c = subscribe;
			contact.ASH_Meeting_on_Hematologic_Malignancies__c = subscribe;
			contact.Highlights_of_ASH__c = subscribe;
			contact.Acute_Myeloid_Leukemia__c = subscribe;
			contact.Immune_Thrombocytopenia__c = subscribe;
			contact.Sickle_Cell_Disease__c = subscribe;
			contact.Venous_Thromboembolism__c = subscribe;
			contact.Von_Willebrand_Disease__c = subscribe;
			contact.Honorific_and_Mentor__c = subscribe;
			contact.Medical_Students__c = subscribe;
			contact.Career_and_Training__c = subscribe;
			contact.Webinars_Webcasts_Podcasts__c = subscribe;
			contact.Job_Center_Opportunities__c = subscribe;
			contact.Advance_Notice__c = subscribe;
			contact.Blood_Advances_Highlights__c = subscribe;
			contact.ASH_Clinical_Trials__c = subscribe;
			contact.The_Hematologist__c = subscribe;
			contact.ASH_Newslink__c = subscribe;
			contact.This_Week_in_Blood__c = subscribe;
			contact.ASH_Practice_Update__c = subscribe;
			contact.TraineE_News__c = subscribe;
			contact.FDA_Alerts__c = subscribe;
			contact.Email_Subscriptions_Last_Updated_Date__c = System.now();

			// update contact;
			Database.SaveResult sr = Database.update(contact);
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed and sync update in SFMC.
                System.debug('Successfully updated Contact record with ID: ' + sr.getId());
				if(!isSandbox && !Test.isRunningTest()){
					SFMCConnector.updateSubscriberPreference(sr.getId(), subscribe);
				}
            } else {
                // Operation failed, so get all errors 
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Contract fields that affected this error: ' + err.getFields());
                }
            }

		} catch (DmlException e) {
			System.debug('An unexpected error has occurred: ' + e.getMessage());
		}

		Contact updatedContact = 
			[SELECT FirstName,LastName,Email,HasOptedOutOfEmail,Email_Subscriptions_Last_Updated_Date__c,
				ASH_Annual_Meeting__c,ASH_Meeting_on_Lymphoma_Biology__c,ASH_Consultative_Hematology_Course__c,
				Latest_in_Precision_Medicine_and_Immuno__c,ASH_Meeting_on_Hematologic_Malignancies__c,
				Highlights_of_ASH__c,Acute_Myeloid_Leukemia__c,Immune_Thrombocytopenia__c,Sickle_Cell_Disease__c,
				Venous_Thromboembolism__c,Von_Willebrand_Disease__c,Honorific_and_Mentor__c,Medical_Students__c,
				Career_and_Training__c,Webinars_Webcasts_Podcasts__c,Job_Center_Opportunities__c,Advance_Notice__c,
				Blood_Advances_Highlights__c,ASH_Clinical_Trials__c,The_Hematologist__c,ASH_Newslink__c,
				This_Week_in_Blood__c,ASH_Practice_Update__c,TraineE_News__c, FDA_Alerts__c
				FROM Contact WHERE Id =: user.ContactId];

		return updatedContact;
	}

	@AuraEnabled 
	public static Contact updateSubscriptions(Contact updatedContact) {
		User user = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId()];
		
		if (user.ContactId == null) {
			return null;
		}
		
		Contact contact = [SELECT Id FROM Contact WHERE Id =: user.ContactId];

		try {
			contact.ASH_Annual_Meeting__c = updatedContact.ASH_Annual_Meeting__c;
			contact.ASH_Meeting_on_Lymphoma_Biology__c = updatedContact.ASH_Meeting_on_Lymphoma_Biology__c;
			contact.ASH_Consultative_Hematology_Course__c = updatedContact.ASH_Consultative_Hematology_Course__c;
			contact.Latest_in_Precision_Medicine_and_Immuno__c = updatedContact.Latest_in_Precision_Medicine_and_Immuno__c;
			contact.ASH_Meeting_on_Hematologic_Malignancies__c = updatedContact.ASH_Meeting_on_Hematologic_Malignancies__c;
			contact.Highlights_of_ASH__c = updatedContact.Highlights_of_ASH__c;
			contact.Acute_Myeloid_Leukemia__c = updatedContact.Acute_Myeloid_Leukemia__c;
			contact.Immune_Thrombocytopenia__c = updatedContact.Immune_Thrombocytopenia__c;
			contact.Sickle_Cell_Disease__c = updatedContact.Sickle_Cell_Disease__c;
			contact.Venous_Thromboembolism__c = updatedContact.Venous_Thromboembolism__c;
			contact.Von_Willebrand_Disease__c = updatedContact.Von_Willebrand_Disease__c;
			contact.Honorific_and_Mentor__c = updatedContact.Honorific_and_Mentor__c;
			contact.Medical_Students__c = updatedContact.Medical_Students__c;
			contact.Career_and_Training__c = updatedContact.Career_and_Training__c;
			contact.Webinars_Webcasts_Podcasts__c = updatedContact.Webinars_Webcasts_Podcasts__c;
			contact.Job_Center_Opportunities__c = updatedContact.Job_Center_Opportunities__c;
			contact.Advance_Notice__c = updatedContact.Advance_Notice__c;
			contact.Blood_Advances_Highlights__c = updatedContact.Blood_Advances_Highlights__c;
			contact.ASH_Clinical_Trials__c = updatedContact.ASH_Clinical_Trials__c;
			contact.The_Hematologist__c = updatedContact.The_Hematologist__c;
			contact.ASH_Newslink__c = updatedContact.ASH_Newslink__c;
			contact.This_Week_in_Blood__c = updatedContact.This_Week_in_Blood__c;
			contact.ASH_Practice_Update__c = updatedContact.ASH_Practice_Update__c;
			contact.TraineE_News__c = updatedContact.TraineE_News__c;
			contact.FDA_Alerts__c = updatedContact.FDA_Alerts__c;
			contact.Email_Subscriptions_Last_Updated_Date__c = System.now();

			update contact;
		} catch (DmlException e) {
			System.debug('An unexpected error has occurred: ' + e.getMessage());
		}

		Contact contactAfter = 
			[SELECT FirstName,LastName,Email,HasOptedOutOfEmail,Email_Subscriptions_Last_Updated_Date__c,
				ASH_Annual_Meeting__c,ASH_Meeting_on_Lymphoma_Biology__c,ASH_Consultative_Hematology_Course__c,
				Latest_in_Precision_Medicine_and_Immuno__c,ASH_Meeting_on_Hematologic_Malignancies__c,
				Highlights_of_ASH__c,Acute_Myeloid_Leukemia__c,Immune_Thrombocytopenia__c,Sickle_Cell_Disease__c,
				Venous_Thromboembolism__c,Von_Willebrand_Disease__c,Honorific_and_Mentor__c,Medical_Students__c,
				Career_and_Training__c,Webinars_Webcasts_Podcasts__c,Job_Center_Opportunities__c,Advance_Notice__c,
				Blood_Advances_Highlights__c,ASH_Clinical_Trials__c,The_Hematologist__c,ASH_Newslink__c,
				This_Week_in_Blood__c,ASH_Practice_Update__c,TraineE_News__c, FDA_Alerts__c
				FROM Contact WHERE Id =: user.ContactId];

		return contactAfter;
	}
}