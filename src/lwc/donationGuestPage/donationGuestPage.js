import { LightningElement, track, api, wire } from 'lwc';
import ashPayment from '@salesforce/apex/OpportunityService.ashPayment';
import isEmailUnique from '@salesforce/apex/OpportunityService.isEmailUnique';
import getActiveGeneralAccountingUnit from '@salesforce/apex/OpportunityService.getActiveGeneralAccountingUnit';
import { NavigationMixin } from "lightning/navigation";
import DonationLoadingLogo from "@salesforce/resourceUrl/Ash_Loading_Gif";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class DonationGuestPage extends NavigationMixin(LightningElement) {
	value = 'United States of America';
  @api DedFname = '';
	@api DedLname = '';
	phonenumbevalue
	@api DedEmail = '';	
	@api FName = '';
	@api LName = '';
	@api EmailId = '';
	@api Address1 = '';
	@api Address2 = '';	
	@api city = '';
  @api Cred = '';
	@api state = '';
	@api Country = '';
	@api postalCode = '';
	@api totalAmountValue = 0.00;
	@track alldonations = [];
	ShowURL;
	loadingGifUrl = DonationLoadingLogo;
	@track generalAccountingUnitList = [];
	isLoading = false;
	@track loadingSignASH ;
	@track currencyInputs = [];
	@track genericInputs = {};
	ifShowUrl = true;
	totalAmount = 0.00;
	isDedication = false;
	isNotifyDedication = false;
	telephoneval = false
	page1 = true;
	page2 = false;
	page3 = false;
	AddressTypevar = true;
	showErrorMessage = false;
	tributetype = ' ';
	dedicationName = '';
	dedicationMessage = '';
	errorMessage = 'Please enter at least one fund to donate.';
	@api CountryName = '';
	@track inputElem;
	@track iti;
	showStatededication = true;
	@track AmountCap = 0.00;

	connectedCallback() {

		this.resetPage1();
	}

	@wire(getActiveGeneralAccountingUnit)
	getGeneralAccountingUnitFunction({data,error}){
		if(data){	
			this.generalAccountingUnitList = data;
			console.log('this.generalAccountingUnitList ' + this.generalAccountingUnitList )
		}
		if(error){
			console.log('error in fetching data ' + JSON.stringify(error));
		}
	}

	get formattedData() {

		// Use Intl.NumberFormat to format the amount as currency

		const formatter = new Intl.NumberFormat('en-US', {

			style: 'currency',

			currency: 'USD'

		});

		// Loop through the data and format the amount as currency

		return this.data.map(row => {

			row.amount = formatter.format(row.amount);

			return row;

		});
	}

	@api sysId = '202';
	theIframe;



	@api isReloaded = false;


	// renderedCallback() {
	//     console.log('rendred callback called' + this.theIframe);
	//         if(this.theIframe==undefined){
	//             this.theIframe =  this.template.querySelector('iframe');
	//             this.theIframe.onload = ()=>{
	//                 console.log('Onload called'+this.isReloaded);

	//                 if(!this.isReloaded){
	//                     this.isReloaded = true;
	//                     this.theIframe.src = this.theIframe.src ;

	//                 }
	//             }
	//         }   

	//     }
	// renderedCallback() {
	// 	console.log('rendered callback called', this.theIframe);

	// 	// Check if theIframe is undefined
	// 	if (this.theIframe === undefined) {
	// 		this.theIframe = this.template.querySelector('iframe');

	// 			if(this.theIframe){
	// 		// Add a listener for the 'onload' event
	// 		this.theIframe.addEventListener('load', () => {
	// 			console.log('Onload called', this.isReloaded);

	// 			// Check if it's the initial load
	// 			if (!this.isReloaded) {
	// 				// Set isReloaded to true to prevent subsequent reloads
	// 				this.isReloaded = true;

	// 				// Reload the iframe content by assigning the same src
	// 				this.theIframe.src = this.theIframe.src;
	// 			}
	// 		});
	// 	}
	// 	}
	// }
	
		
		handleFChange(event){
			this.DedFName = event.target.value;
		this.handleChange(event);	
	 }
		handleLChange(event){
			this.DedLName = event.target.value;
		this.handleChange(event);	
	 }
		
		handleEChange(event){
			this.DedEmail = event.target.value;
		this.handleChange(event);	
	 }
		handleCredChange(event){
			this.Cred = event.target.value;	
			this.handleChange(event);	
		}
		
	handleFChange(event) {
		this.FName = event.target.value;
		this.handleChange(event);

	}
	handleLnameChange(event) {
		this.LName = event.target.value;
		this.handleChange(event);
	}

	handlemailChange(event) {
		this.EmailId = event.target.value;
		this.handleChange(event);
	}

	handleadd1Change(event) {

		this.Address1 = event.target.value;
		this.handleChange(event);
	}

		handleadd2Change(event) {

		this.Address2 = event.target.value;
		this.handleChange(event);
	}
	handleCityChange(event) {

		this.city = event.target.value;
		this.handleChange(event);

	}
	handleStateChange(event) {

		this.state = event.target.value;
		this.handleChange(event);
		//	alert('State'+this.state);
	}



   showState = true;
	handleCountryChange(event) {

		this.Country = event.target.value;
		if(event.target.value == 'United States of America'){
			this.stateOptions = [
		{ label: 'Armed Forces Americas', value: 'Armed Forces Americas'},
			{ label: 'Armed Forces Europe, Middle East', value: 'Armed Forces Europe, Middle East'},
			{ label: 'Alaska', value: 'Alaska'},
			{ label: 'Armed Forces Pacific', value: 'Armed Forces Pacific'},
			{ label: 'Arkansas', value: 'Arkansas'},
			{ label: 'Arizona', value: 'Arizona'},
			{ label: 'California', value: 'California'},
			{ label: 'Colorado', value: 'Colorado'},
			{ label: 'Connecticut', value: 'Connecticut'},
			{ label: 'Canal Zone', value: 'Canal Zone'},
			{ label: 'District of Columbia', value: 'District of Columbia'},
			{ label: 'Delaware', value: 'Delaware'},
			{ label: 'Florida', value: 'Florida'},
			{ label: 'Georgia', value: 'Georgia'},
			{ label: 'Guam', value: 'Guam'},
			{ label: 'Hawaii', value: 'Hawaii'},
			{ label: 'Iowa', value: 'Iowa'},
			{ label: 'Idaho', value: 'Idaho'},
			{ label: 'Illinois', value: 'Illinois'},
			{ label: 'Indiana', value: 'Indiana'},
			{ label: 'Kansas', value: 'Kansas'},
			{ label: 'Kentucky', value: 'Kentucky'},
			{ label: 'Louisiana', value: 'Louisiana'},
			{ label: 'Massachusetts', value: 'Massachusetts'},
			{ label: 'Maryland', value: 'Maryland'},
			{ label: 'Maine', value: 'Maine'},
			{ label: 'Michigan', value: 'Michigan'},
			{ label: 'Minnesota', value: 'Minnesota'},
			{ label: 'Missouri', value: 'Missouri'},
			{ label: 'Idaho', value: 'Idaho'},
			{ label: 'Illinois', value: 'Illinois'},
			{ label: 'Indiana', value: 'Indiana'},
			{ label: 'Kansas', value: 'Kansas'},
			{ label: 'Kentucky', value: 'Kentucky'},
			{ label: 'Louisiana', value: 'Louisiana'},
			{ label: 'Massachusetts', value: 'Massachusetts'},
			{ label: 'Maryland', value: 'Maryland'},
			{ label: 'Maine', value: 'Maine'},
			{ label: 'Michigan', value: 'Michigan'} ,
			{ label: 'Minnesota', value: 'Minnesota'},
			{ label: 'Missouri', value: 'Missouri'},
			{ label: 'Northern Mariana Islands', value: 'Northern Mariana Islands'},
			{ label: 'Mississippi', value: 'Mississippi'},
			{ label: 'Montana', value: 'Montana'},
			{ label: 'North Carolina', value: 'North Carolina'},
			{ label: 'North Dakota', value: 'North Dakota'},
			{ label: 'Nebraska', value: 'Nebraska'},
			{ label: 'New Hampshire', value: 'New Hampshire'},
			{ label: 'New Jersey', value: 'New Jersey'},
			{ label: 'New Mexico', value: 'New Mexico'},
			{ label: 'Nevada', value: 'Nevada'},
			{ label: 'New York', value: 'New York'},
			{ label: 'Ohio', value: 'Ohio'},
			{ label: 'Oklahoma', value: 'Oklahoma'},
			{ label: 'Oregon', value: 'Oregon'},
			{ label: 'Pennsylvania', value: 'Pennsylvania'},
			{ label: 'Pacific Islands', value: 'Pacific Islands'},
			{ label: 'Puerto Rico', value: 'Puerto Rico'},
			{ label: 'Rhode Island', value: ' Rhode Island'},
			{ label: 'South Carolina', value: 'South Carolina'},
			{ label: 'South Dakota', value: 'South Dakota'},
			{ label: 'Tennessee', value: 'Tennessee'},
			{ label: 'Trust Territories', value: 'Trust Territories'},
			{ label: 'Texas', value: 'Texas'},
			{ label: 'Utah', value: 'Utah' },
			{ label: 'Virginia', value: 'Virginia'},
			{ label: 'Virgin Islands', value: 'Virgin Islands'},
			{ label: 'Vermont', value: 'Vermont'},
			{ label: 'Washington', value: 'Washington'},
			{ label: 'Wisconsin', value: 'Wisconsin'},
			{ label: 'West Virginia', value: 'West Virginia'},
			{ label: 'Wyoming', value: 'Wyoming'}
			];
		}else{
			this.stateOptions = [];
		}
		if(this.stateOptions.length > 0){
			this.showState = true
		}else{
			this.showState = false;
		}
		this.handleChange(event);
	}

	handlePostalChange(event) {

		this.PostalCode = event.target.value;
		this.handleChange(event);
	}


	addOrUpdateDonation(label, value) {
		// Check if the label already exists in the array
		const existingIndex = this.alldonations.findIndex(item => item.label === label);

		if (existingIndex !== -1) {
			// Label already exists, update the value
			this.alldonations[existingIndex].value = value;
		} else {
			// Label doesn't exist, push a new object with label and value
			this.alldonations.push({ label: label, value: value });
		}
	}
	removeDonationByLabel(labelToRemove) {
		// Find the index of the object with the specified label
		const indexToRemove = this.alldonations.findIndex(item => item.label === labelToRemove);

		// If the object with the label is found, remove it
		if (indexToRemove != -1) {
			this.alldonations.splice(indexToRemove, 1);
		}
	}
	handleChange1(event) {
		if (event.target.value) {
			this.addOrUpdateDonation(event.target.label, event.target.value);
		} else {
			this.removeDonationByLabel(event.target.label);
		}
		console.log('this.alldonations' + this.alldonations + JSON.stringify(this.alldonations));
		this.handleChange(event);
	}
	handleChange(event) {
		let type = event.target.type;
		let formatter = event.target.formatter;
		let fieldName = event.target.name;
		let fieldValue = event.target.value;
		let fieldLabel = event.target.label;
		if(fieldName == 'dedicationCountry' && fieldValue == 'United States of America'){
			this.stateOptionsdedication = [
			{ label: 'Armed Forces Americas', value: 'Armed Forces Americas'},
			{ label: 'Armed Forces Europe, Middle East', value: 'Armed Forces Europe, Middle East'},
			{ label: 'Alaska', value: 'Alaska'},
			{ label: 'Armed Forces Pacific', value: 'Armed Forces Pacific'},
			{ label: 'Arkansas', value: 'Arkansas'},
			{ label: 'Arizona', value: 'Arizona'},
			{ label: ' California', value: 'California'},
			{ label: 'Colorado', value: 'Colorado'},
			{ label: 'Connecticut', value: 'Connecticut'},
			{ label: 'Canal Zone', value: 'Canal Zone'},
			{ label: 'District of Columbia', value: 'District of Columbia'},
			{ label: 'Delaware', value: 'Delaware'},
			{ label: 'Florida', value: 'Florida'},
			{ label: ' Georgia', value: 'Georgia'},
			{ label: 'Guam', value: 'Guam'},
			{ label: 'Hawaii', value: 'Hawaii'},
			{ label: 'Iowa', value: 'Iowa'},
			{ label: 'Idaho', value: 'Idaho'},
			{ label: 'Illinois', value: 'Illinois'},
			{ label: ' Indiana', value: 'Indiana'},
			{ label: 'Kansas', value: 'Kansas'},
			{ label: 'Kentucky', value: 'Kentucky'},
			{ label: 'Louisiana', value: 'Louisiana'},
			{ label: 'Massachusetts', value: 'Massachusetts'},
			{ label: 'Maryland', value: 'Maryland'},
			{ label: 'Maine', value: 'Maine'},
			{ label: 'Michigan', value: 'Michigan'},
			{ label: 'Minnesota', value: 'Minnesota'},
			{ label: 'Missouri', value: 'Missouri'},
			{ label: 'Idaho', value: 'Idaho'},
			{ label: 'Illinois', value: 'Illinois'},
			{ label: ' Indiana', value: 'Indiana'},
			{ label: 'Kansas', value: 'Kansas'},
			{ label: 'Kentucky', value: 'Kentucky'},
			{ label: 'Louisiana', value: 'Louisiana'},
			{ label: 'Massachusetts', value: 'Massachusetts'},
			{ label: 'Maryland', value: 'Maryland'},
			{ label: 'Maine', value: 'Maine'},
			{ label: ' Michigan', value: 'Michigan'} ,
			{ label: 'Minnesota', value: 'Minnesota'},
			{ label: 'Missouri', value: 'Missouri'},
			{ label: 'Northern Mariana Islands', value: 'Northern Mariana Islands'},
			{ label: 'Mississippi', value: 'Mississippi'},
			{ label: ' Montana', value: 'Montana'},
			{ label: 'North Carolina', value: 'North Carolina'},
			{ label: 'North Dakota', value: 'North Dakota'},
			{ label: 'Nebraska', value: 'Nebraska'},
			{ label: 'New Hampshire', value: 'New Hampshire'},
			{ label: 'New Jersey', value: 'New Jersey'},
			{ label: 'New Mexico', value: 'New Mexico'},
			{ label: ' Nevada', value: 'Nevada'},
			{ label: 'New York', value: 'New York'},
			{ label: 'Ohio', value: 'Ohio'},
			{ label: 'Oklahoma', value: 'Oklahoma'},
			{ label: 'Oregon', value: 'Oregon'},
			{ label: 'Pennsylvania', value: 'Pennsylvania'},
			{ label: 'Pacific Islands', value: 'Pacific Islands'},
			{ label: 'Puerto Rico', value: 'Puerto Rico'},
			{ label: ' Rhode Island', value: ' Rhode Island'},
			{ label: 'South Carolina', value: 'South Carolina'},
			{ label: 'South Dakota', value: 'South Dakota'},
			{ label: 'Tennessee', value: 'Tennessee'},
			{ label: 'rust Territories', value: 'Trust Territories'},
			{ label: 'Texas', value: 'Texas'},
			{ label: 'Utah', value: 'Utah' },
			{ label: 'Virginia', value: 'Virginia'},
			{ label: 'Virgin Islands', value: 'Virgin Islands'},
			{ label: 'Vermont', value: 'Vermont'},
			{ label: 'Washington', value: 'Washington'},
			{ label: 'Wisconsin', value: 'Wisconsin'},
			{ label: 'West Virginia', value: 'West Virginia'},
			{ label: 'Wyoming', value: 'Wyoming'}


			];
		}else{
			this.stateOptionsdedication = [];
		}
		if(this.stateOptionsdedication.length > 0){
			this.showStatededication = true
		}else{
			this.showStatededication = false;
		}
		if(fieldLabel == "ADDRESS TYPE:" && fieldName == "addressType" && fieldValue == "Home"){
			this.AddressTypevar = false;
		}
		if(fieldLabel == "ADDRESS TYPE:" && fieldName == "addressType" && fieldValue == "Work") {
			this.AddressTypevar = true;
		}
		if (type == 'number' && formatter == 'currency') {
			this.genericInputs[fieldName] = fieldValue;
			this.currencyInputs = this.currencyInputs.filter((item) => item.Label !== fieldLabel);
			if (fieldValue > 0) {
				this.currencyInputs.push({
					"Label": fieldLabel,
					"Amount": (parseFloat(fieldValue) + 0.00).toFixed(2)
				});
				this.totalAmount = 0.00;
				this.currencyInputs.forEach(x => {
					this.totalAmount += parseFloat(x.Amount);
				});
			} else {
				this.totalAmount -= parseFloat(this.currencyInputs.find((item) => item.Label == fieldLabel)?.Amount);
			}

			this.AmountCap = this.totalAmount.toFixed(2);
		} else if (type == 'checkbox') {
			this.genericInputs[fieldName] = event.target.checked;
			if (fieldName == 'isDedication') {
				this.isDedication = event.target.checked;
				if (!this.isDedication) this.isNotifyDedication = false;
			} else if (fieldName == 'isNotifyDedication') this.isNotifyDedication = event.target.checked;
		} else {
			this.genericInputs[fieldName] = fieldValue;
			if(event.target.name ==='dedicationMessage'){
				this.dedicationMessage = event.target.value;
			}
			if(event.target.name ==='dedicationName'){
				this.dedicationName = event.target.value;
			}
		}
	}

	/*get isDedication(){
			console.log('isDe: ',this.genericInputs.isDedication);
			return this.genericInputs.isDedication;
	}*/
	tributelable
	ondedicationOption(event){
		this.isNotifyDedication = true;
		console.log("Memory Value For Dedication "+event.target.value);
		this.tributetype = event.target.value;
		if(event.target.value == 'Honor'){
			this.tributelable = 'In Honor of';
		}else if(event.target.value == 'In Name of'){
			this.tributelable = 'In Memory of';
		}else{
			this.tributelable = 'In Memorial of';
		}
		
	}
	get dedicationOptions() {
		return [
			{ label: 'In Honor of', value: 'Honor' },
			{ label: 'In Memory of', value: 'In Name of' },
			{ label: 'In Memorial of', value: 'Memorial' }
		]
	}



	navigateNext(event) {
		// Prevent the default form submission
		this.isLoading = true;
		let curPage = event.target.dataset.pageno;
		if (curPage == '1') {

			if (this.totalAmount > 0) {
				this.showErrorMessage = false;
			} else {
				this.showErrorMessage = true;
				this.errorMessage = 'Please enter at least one fund to donate.';
			}
			const allValid = [
				...this.template.querySelectorAll('lightning-input'),
			].reduce((validSoFar, inputCmp) => {
				inputCmp.reportValidity();
				return validSoFar && inputCmp.checkValidity();
			}, true);
			if(this.phonenumbevalue == null || this.phonenumbevalue === "undefined" || this.phonenumbevalue == ""){
				this.telephoneval = true
			}else{
				if (allValid && !this.showErrorMessage) {
				isEmailUnique({ email: this.EmailId })
					.then(result => {
						if (!result) {
							console.log('Email exist error =>', !result)
							const toastEvent = new ShowToastEvent({
							//	title: 'Duplicate Email',
							//	message: 'The email value entered already exists.',
							});
							this.dispatchEvent(toastEvent);
							this.page1 = false;
							this.page2 = true;
						}else{
							this.page1 = false;
							this.page2 = true;
						}
					})
					.catch(error => {
						console.log('error ' + error);
					});
				
			}
			}
			
		} else if (curPage == '2') {
			if (!this.genericInputs.ashPrivacyPolicy || !this.genericInputs.ashServiceTerms) {
				this.showErrorMessage = true;
				this.errorMessage = 'Please accept all terms.';

			} else {
				debugger;
				const funds = JSON.stringify(this.alldonations);
			ashPayment({
				FName: this.FName,
				LName: this.LName,
				Email: this.EmailId,
				Address1: this.Address1,
			  Address2 : this.Address2,		
				City: this.city,
				State: this.state,
				Country: this.Country,
				PostalCode: this.PostalCode,
				totalAmountValue: this.AmountCap,
				Fund: JSON.stringify(this.alldonations),
				tributetype : this.tributetype,
				dedicationName: this.dedicationName,
				dedicationMessage: this.dedicationMessage,
			  dedicationFName : this.DedFname,
				dedicationlName : this.DedLName,
				dedicationEmail : this.DedEmail,
			  Cred      : this.Cred		
			})
				.then(result => {
					this.ShowURL = result;
					//alert('ShowURL'+	this.ShowURL);
				  setTimeout(() => {
						this.ifShowUrl = false;
					}, 4500);
				})
				.catch(error => {
					console.log('getting error on website ' + JSON.stringify(error));
					const event = new ShowToastEvent({
						title: 'Error',
						message: 'Error creating contact. Please Contact System Admin',
						variant: 'error'
					});
					this.dispatchEvent(event);
				});
				this.showErrorMessage = false;
				this.page2 = false;
				this.page3 = true;
			}
		}
		this.isLoading = false;
	}

	
	get fullUrl() {

		return this.ShowURL;
	//	 return 'https://test.protectedpayments.net/PMWeb1?pmRef=10750&pid=aCn540000008rOM&locale=en-GB&dit=ae03f30d258d9090ac8bb2523f9ea2922abf87f6675871aae5650e021abb1ef3';
	}

	handletelephoneValuechange(event) {
		this.genericInputs.telephone = event.detail.value;
		this.phonenumbevalue = event.detail.value;
		if(event.detail.value){
			this.telephoneval = false;
		}else{
			this.telephoneval = true;
		}
	}

	handlededicationtelephoneValuechange(event) {
		this.genericInputs.dedicationtelephone = event.detail.value;
		this.telephoneval = false;
		console.log('event detail value ' + event.detail.value);
		if(event.detail.value){
			this.telephoneval = false;
		}else{
			this.telephoneval = true;
		}	
	}

	handlePage2Edit() {
		this.page2 = false;
		this.page1 = true;
	}

	get options() {
		return [

			{ label: 'Afghanistan', value: 'Afghanistan' },
			{ label: 'Angola', value: 'Angola' },
			{ label: 'Aruba', value: 'Aruba' },
			{ label: 'Afghanistan', value: 'Afghanistan' },
			{ label: 'Angola', value: 'Angola' },
			{ label: 'Anguilla', value: 'Anguilla' },
			{ label: 'land Islands', value: 'land Islands' },
			{ label: 'Albania', value: 'Albania' },
			{ label: 'Andorra', value: 'Andorra' },
			{ label: 'Netherlands Antilles', value: 'Netherlands Antilles' },
			{ label: 'United Arab Emirates', value: 'United Arab Emirates' },
			{ label: 'Argentina', value: 'Argentina' },
			{ label: 'Armenia', value: 'Armenia' },
			{ label: 'American Samoa', value: 'American Samoa' },
			{ label: 'Antarctica', value: 'Antarctica' },
			{ label: 'French Southern Territories', value: 'French Southern Territorie' },
			{ label: 'Antigua and Barbuda', value: 'Antigua and Barbuda' },
			{ label: 'Australia', value: 'Australia' },
			{ label: 'Austria', value: 'Austria' },
			{ label: 'Azerbaijan', value: 'Azerbaijan' },
			{ label: 'Burundi', value: 'Burundi' },
			{ label: 'Belgium', value: 'Belgium' },
			{ label: 'Benin', value: 'Benin' },
			{ label: 'Bonaire, Sint Eustatius and Saba', value: 'Bonaire, Sint Eustatius and Saba' },
			{ label: 'Burkina Faso', value: 'Burkina Faso' },
			{ label: 'Bangladesh', value: 'Bangladesh' },
			{ label: 'Bulgaria', value: 'Bulgaria' },
			{ label: 'Bahrain', value: 'Bahrain' },
			{ label: 'Bahamas', value: 'Bahamas' },
			{ label: 'Bosnia and Herzegovina', value: 'Bosnia and Herzegovina' },
			{ label: 'Saint Barthlemy', value: 'Saint Barthlemy' },
			{ label: 'Belarus', value: 'Belarus' },
			{ label: 'Belize', value: 'Belize' },
			{ label: 'Bermuda', value: 'Bermuda' },
			{ label: 'Bolivia', value: 'Bolivia' },
			{ label: 'Brazil', value: 'Brazil' },
			{ label: 'Barbados', value: 'Barbados' },
			{ label: 'Brunei Darussalam', value: 'Brunei Darussalam' },
			{ label: 'Bhutan', value: 'Bhutan' },
			{ label: 'Bouvet Island', value: 'Bouvet Island' },
			{ label: 'Botswana', value: 'Botswana' },
			{ label: 'Central African Republic', value: 'Central African Republic' },
			{ label: 'Canada', value: 'Canada' },
			{ label: 'Cocos (Keeling) Islands', value: 'Cocos (Keeling) Islands' },
			{ label: 'Switzerland', value: 'Switzerland' },
			{ label: 'Chile', value: 'Chile' },
			{ label: 'China', value: 'China' },
			{ label: 'Cvoire', value: 'Cvoire' },
			{ label: 'Cameroon', value: 'Cameroon' },
			{ label: 'Congo, Democratic Republic of the', value: 'Congo, Democratic Republic of the' },
			{ label: 'Congo', value: 'Congo' },
			{ label: 'Cook Islands', value: 'Cook Islands' },
			{ label: 'Colombia', value: 'Colombia' },
			{ label: 'Comoros', value: 'Comoros' },
			{ label: 'Cabo Verde', value: 'Cabo Verde' },
			{ label: 'Costa Rica', value: 'Costa Rica' },
			{ label: 'Cuba', value: 'Cuba' },
			{ label: 'Curaao', value: 'Curaao' },
			{ label: 'Christmas Island', value: 'Christmas Island' },
			{ label: 'Cayman Islands', value: 'Cayman Islands' },
			{ label: 'Cyprus', value: 'Cyprus' },
			{ label: 'Czech Republic', value: 'Czech Republic' },
			{ label: 'Germany', value: 'Germany' },
			{ label: 'Djibouti', value: 'Djibouti' },
			{ label: 'Dominica', value: 'Dominica' },
			{ label: 'Denmark', value: 'Denmark' },
			{ label: 'Dominican Republic', value: 'Dominican Republic' },
			{ label: 'Algeria', value: 'Algeria' },
			{ label: 'Ecuador', value: 'Ecuador' },
			{ label: 'Egypt', value: 'Egypt' },
			{ label: 'Eritrea', value: 'Eritrea' },
			{ label: 'Western Sahara', value: 'Western Sahara' },
			{ label: 'Spain', value: 'Spain' },
			{ label: 'Estonia', value: 'Estonia' },
			{ label: 'Ethiopia', value: 'Ethiopia' },
			{ label: 'Finland', value: 'Finland' },
			{ label: 'Fiji', value: 'Fiji' },
			{ label: 'Falkland Islands', value: 'Falkland Islands' },
			{ label: 'France', value: 'France' },
			{ label: 'Faroe Islands', value: 'Faroe Islands' },
			{ label: 'Micronesia, Federated States of', value: 'Micronesia, Federated States of' },
			{ label: 'France - Metropolitan', value: 'France - Metropolitan' },
			{ label: 'Gabon', value: 'Gabon' },
			{ label: 'United Kingdom', value: 'United Kingdom' },
			{ label: 'Georgia', value: 'Georgia' },
			{ label: 'Guernsey', value: 'Guernsey' },
			{ label: 'Ghana', value: 'Ghana' },
			{ label: 'Gibraltar', value: 'Gibraltar' },
			{ label: 'Guinea', value: 'Guinea' },
			{ label: 'Guadeloupe', value: 'Guadeloupe' },
			{ label: 'Gambia', value: 'Gambia' },
			{ label: 'Guinea-Bissau', value: 'Guinea-Bissau' },
			{ label: 'Equatorial Guinea', value: 'Equatorial Guinea' },
			{ label: 'Greece', value: 'Greece' },
			{ label: 'Grenada', value: 'Grenada' },
			{ label: 'Greenland', value: 'Greenland' },
			{ label: 'Guatemala', value: 'Guatemala' },
			{ label: 'French Guiana', value: 'French Guiana' },
			{ label: 'Guam', value: 'Guam' },
			{ label: 'Guyana', value: 'Guyana' },
			{ label: 'Hong Kong', value: 'Hong Kong' },
			{ label: 'Heard Island and McDonald Islands', value: 'Heard Island and McDonald Islands' },
			{ label: 'Honduras', value: 'Honduras' },
			{ label: 'Croatia, Republic of', value: 'Croatia, Republic of' },
			{ label: 'Haiti', value: 'Haiti' },
			{ label: 'Hungary', value: 'Hungary' },
			{ label: 'Indonesia', value: 'Indonesia' },
			{ label: 'Isle of Man', value: 'Isle of Man' },
			{ label: 'India', value: 'India' },
			{ label: 'British Indian Ocean Territory', value: 'British Indian Ocean Territory' },
			{ label: 'Ireland', value: 'Ireland' },
			{ label: 'Iran, Islamic Republic of', value: 'Iran, Islamic Republic of' },
			{ label: 'Iraq', value: 'Iraq' },
			{ label: 'Iceland', value: 'Iceland' },
			{ label: 'Israel', value: 'Iceland' },
			{ label: 'Italy', value: 'Italy' },
			{ label: 'Jamaica', value: 'Jamaica' },
			{ label: 'Jersey', value: 'Jersey' },
			{ label: 'Jordan', value: 'Jordan' },
			{ label: 'Japan', value: 'Japan' },
			{ label: 'Kazakhstan', value: 'Kazakhstan' },
			{ label: 'Kenya', value: 'Kenya' },
			{ label: 'Kyrgyzstan', value: 'Kyrgyzstan' },
			{ label: 'Cambodia', value: 'Cambodia' },
			{ label: 'Kiribati', value: 'Kiribati' },
			{ label: 'Saint Kitts And Nevis', value: 'Saint Kitts And Nevis' },
			{ label: 'Korea, Republic of', value: 'Korea, Republic of' },
			{ label: 'Kosovo', value: 'Kosovo' },
			{ label: 'Kuwait', value: 'Kuwait' },
			{ label: 'Lao Peoples Democratic Republic', value: 'Lao Peoples Democratic Republic' },
			{ label: 'Lebanon', value: 'Lebanon' },
			{ label: 'Liberia', value: 'Liberia' },
			{ label: 'Libya', value: 'Libya' },
			{ label: 'Saint Lucia', value: 'Saint Lucia' },
			{ label: 'Liechtenstein', value: 'Liechtenstein' },
			{ label: 'Sri Lanka', value: 'Sri Lanka' },
			{ label: 'Lesotho', value: 'Lesotho' },
			{ label: 'Lithuania', value: 'Lithuania' },
			{ label: 'Luxembourg', value: 'Luxembourg' },
			{ label: 'Latvia', value: 'Latvia' },
			{ label: 'Macau', value: 'Macau' },
			{ label: 'Saint Martin (French part)', value: 'Saint Martin (French part)' },
			{ label: 'Morocco', value: 'Morocco' },
			{ label: 'Monaco', value: 'Monaco' },
			{ label: 'Moldova, Republic of', value: 'Moldova, Republic of' },
			{ label: 'Madagascar', value: 'Madagascar' },
			{ label: 'Maldives', value: 'Maldives' },
			{ label: 'Mexico', value: 'Mexico' },
			{ label: 'Marshall Islands', value: 'Marshall Islands' },
			{ label: 'Macedonia, Former Yugoslav Republic of', value: 'Macedonia, Former Yugoslav Republic of' },
			{ label: 'Mali', value: 'Mali' },
			{ label: 'Malta', value: 'Malta' },
			{ label: 'Myanmar', value: 'Myanmar' },
			{ label: 'Montenegro', value: 'Montenegro' },
			{ label: 'Mongolia', value: 'Mongolia' },
			{ label: 'Northern Mariana Islands', value: 'Northern Mariana Islands' },
			{ label: 'Mozambique', value: 'Mozambique' },
			{ label: 'Mauritania', value: 'Mauritania' },
			{ label: 'Montserrat', value: 'Montserrat' },
			{ label: 'Martinique', value: 'Martinique' },
			{ label: 'Mauritius', value: 'Mauritius' },
			{ label: 'Malawi', value: 'Malawi' },
			{ label: 'Malaysia', value: 'Malaysia' },
			{ label: 'Mayotte', value: 'Mayotte' },
			{ label: 'Namibia', value: 'Namibia' },
			{ label: 'New Caledonia', value: 'New Caledonia' },
			{ label: 'Niger', value: 'Niger' },
			{ label: 'Norfolk Island', value: 'Norfolk Island' },
			{ label: 'Nigeria', value: 'Nigeria' },
			{ label: 'Nicaragua', value: 'Nicaragua' },
			{ label: 'Niue', value: 'Niue' },
			{ label: 'Netherlands', value: 'Netherlands' },
			{ label: 'Norway', value: 'Norway' },
			{ label: 'Nepal', value: 'Nepal' },
			{ label: 'Nauru', value: 'Nauru' },
			{ label: 'New Zealand', value: 'New Zealand' },
			{ label: 'Oman', value: 'Oman' },
			{ label: 'Pakistan', value: 'Pakistan' },
			{ label: 'Panama', value: 'Panama' },
			{ label: 'Pitcairn', value: 'Pitcairn' },
			{ label: 'Peru', value: 'Peru' },
			{ label: 'Philippines', value: 'Philippines' },
			{ label: 'Palau', value: 'Palau' },
			{ label: 'Papua New Guinea', value: 'Papua New Guinea' },
			{ label: 'Poland', value: 'Poland' },
			{ label: 'Puerto Rico', value: 'Puerto Rico' },
			{ label: 'Democratic Peoples Republic of Korea', value: 'Democratic Peoples Republic of Korea' },
			{ label: 'Portugal', value: 'PPortugal' },
			{ label: 'Paraguay', value: 'Paraguay' },
			{ label: 'Palestine, State of', value: 'Palestine, State of' },
			{ label: 'French Polynesia', value: 'French Polynesia' },
			{ label: 'Qatar', value: 'Qatar' },
			{ label: 'union', value: 'union' },
			{ label: 'Romania', value: 'Romania' },
			{ label: 'Russian Federation', value: 'Russian Federation' },
			{ label: 'Rwanda', value: 'Rwanda' },
			{ label: 'Saudi Arabia', value: 'Saudi Arabia' },
			{ label: 'Sudan', value: 'Sudan' },
			{ label: 'Senegal', value: 'Senegal' },
			{ label: 'Singapore', value: 'Singapore' },
			{ label: 'South Georgia', value: 'South Georgia' },
			{ label: 'St. Helena', value: 'St. Helena' },
			{ label: 'Svalbard and Jan Mayen', value: 'Svalbard and Jan Mayen' },
			{ label: 'Solomon Islands', value: 'Solomon Islands' },
			{ label: 'Sierra Leone', value: 'Sierra LeoneL' },
			{ label: 'El Salvador', value: 'El Salvado' },
			{ label: 'San Marino', value: 'San Marino' },
			{ label: 'Somalia', value: 'Somalia' },
			{ label: 'St. Pierre And Miquelon', value: 'St. Pierre And Miquelon' },
			{ label: 'Serbia', value: 'Serbia' },
			{ label: 'South Sudan', value: 'South Sudan' },
			{ label: 'Sao Tome And Principe', value: 'Sao Tome And Principe' },
			{ label: 'Suriname', value: 'Suriname' },
			{ label: 'Slovakia', value: 'Slovakia' },
			{ label: 'Slovenia', value: 'Slovenia' },
			{ label: 'Sweden', value: 'Sweden' },
			{ label: 'Swaziland', value: 'Swaziland' },
			{ label: 'Sint Maarten (Dutch part)', value: 'Sint Maarten (Dutch part)' },
			{ label: 'Seychelles', value: 'Seychelles' },
			{ label: 'Syrian Arab Republic', value: 'Syrian Arab Republic' },
			{ label: 'Turks And Caicos Islands', value: 'Turks And Caicos Islands' },
			{ label: 'Chad', value: 'Chad' },
			{ label: 'Togo', value: 'Togo' },
			{ label: 'Thailand', value: 'Thailand' },
			{ label: 'Tajikistan', value: 'Tajikistan' },
			{ label: 'Tokelau', value: 'Tokelau' },
			{ label: 'Turkmenistan', value: 'Turkmenistan' },
			{ label: 'Timor-Leste', value: 'Timor-Leste' },
			{ label: 'Tonga', value: 'Tonga' },
			{ label: 'Trinidad And Tobago', value: 'Trinidad And Tobago' },
			{ label: 'Tunisia', value: 'Tunisia' },
			{ label: 'Turkey', value: 'Turkey' },
			{ label: 'Tuvalu', value: 'Tuvalu' },
			{ label: 'Taiwan', value: 'Taiwan' },
			{ label: 'Tanzania, United Republic of', value: 'Tanzania, United Republic of' },
			{ label: 'Uganda', value: 'Uganda' },
			{ label: 'Ukraine', value: 'Ukraine' },
			{ label: 'United States Minor Outlying Islands', value: 'United States Minor Outlying Islands' },
			{ label: 'Uruguay', value: 'Uruguay' },
			{ label: 'United States of America', value: 'United States of America' },
			{ label: 'Uzbekistan', value: 'Uzbekistan' },
			{ label: 'Holy See (Vatican City)', value: 'Holy See (Vatican City' },
			{ label: 'St Vincent And Grenadines', value: 'St Vincent And Grenadines' },
			{ label: 'Venezuela', value: 'Venezuela' },
			{ label: 'Virgin Islands (British)', value: 'Virgin Islands (British)' },
			{ label: 'Virgin Islands (U.S.)', value: 'Virgin Islands (British)' },
			{ label: 'Vietnam', value: 'Vietnam' },
			{ label: 'Vanuatu', value: 'Vanuatu' },
			{ label: 'Wallis And Futuna Islands', value: 'Wallis And Futuna Islands' },
			{ label: 'Samoa', value: 'Samoa' },
			{ label: 'Yemen', value: 'Yemen' },
			{ label: 'Serbia and Montenegro', value: 'Serbia and Montenegro' },
			{ label: 'South Africa', value: 'South Africa' },
			{ label: 'Zambia', value: 'Zambia' },
			{ label: 'Zimbabwe', value: 'Zimbabwe' },

		];
	}

	value = '';
	@track stateOptions = [
			{ label: 'Armed Forces Americas', value: 'Armed Forces Americas' },
			{ label: 'Armed Forces Europe, Middle East', value: 'Armed Forces Europe, Middle East' },
			{ label: 'Alaska', value: 'Alaska' },
			{ label: 'Armed Forces Pacific', value: 'Armed Forces Pacific' },
			{ label: 'Arkansas', value: 'Arkansas' },
			{ label: 'Arizona', value: 'Arizona' },
			{ label: ' California', value: 'California' },
			{ label: 'Colorado', value: 'Colorado' },
			{ label: 'Connecticut', value: 'Connecticut' },
			{ label: 'Canal Zone', value: 'Canal Zone' },
			{ label: 'District of Columbia', value: 'District of Columbia' },
			{ label: 'Delaware', value: 'Delaware' },
			{ label: 'Florida', value: 'Florida' },
			{ label: ' Georgia', value: 'Georgia' },
			{ label: 'Guam', value: 'Guam' },
			{ label: 'Hawaii', value: 'Hawaii' },
			{ label: 'Iowa', value: 'Iowa' },
			{ label: 'Idaho', value: 'Idaho' },
			{ label: 'Illinois', value: 'Illinois' },
			{ label: 'Indiana', value: 'Indiana' },
			{ label: 'Kansas', value: 'Kansas' },
			{ label: 'Kentucky', value: 'Kentucky' },
			{ label: 'Louisiana', value: 'Louisiana' },
			{ label: 'Massachusetts', value: 'Massachusetts' },
			{ label: 'Maryland', value: 'Maryland' },
			{ label: 'Maine', value: 'Maine' },
			{ label: 'Michigan', value: 'Michigan' },
			{ label: 'Minnesota', value: 'Minnesota' },
			{ label: 'Missouri', value: 'Missouri' },
			{ label: 'Idaho', value: 'Idaho' },
			{ label: 'Illinois', value: 'Illinois' },
			{ label: ' Indiana', value: 'Indiana' },
			{ label: 'Kansas', value: 'Kansas' },
			{ label: 'Kentucky', value: 'Kentucky' },
			{ label: 'Louisiana', value: 'Louisiana' },
			{ label: 'Massachusetts', value: 'Massachusetts' },
			{ label: 'Maryland', value: 'Maryland' },
			{ label: 'Maine', value: 'Maine' },
			{ label: ' Michigan', value: 'Michigan' },
			{ label: 'Minnesota', value: 'Minnesota' },
			{ label: 'Missouri', value: 'Missouri' },
			{ label: 'Northern Mariana Islands', value: 'Northern Mariana Islands' },
			{ label: 'Mississippi', value: 'Mississippi' },
			{ label: 'Montana', value: 'Montana' },
			{ label: 'North Carolina', value: 'North Carolina' },
			{ label: 'North Dakota', value: 'North Dakota' },
			{ label: 'Nebraska', value: 'Nebraska' },
			{ label: 'New Hampshire', value: 'New Hampshire' },
			{ label: 'New Jersey', value: 'New Jersey' },
			{ label: 'New Mexico', value: 'New Mexico' },
			{ label: 'Nevada', value: 'Nevada' },
			{ label: 'New York', value: 'New York' },
			{ label: 'Ohio', value: 'Ohio' },
			{ label: 'Oklahoma', value: 'Oklahoma' },
			{ label: 'Oregon', value: 'Oregon' },
			{ label: 'Pennsylvania', value: 'Pennsylvania' },
			{ label: 'Pacific Islands', value: 'Pacific Islands' },
			{ label: 'Puerto Rico', value: 'Puerto Rico' },
			{ label: 'Rhode Island', value: 'Rhode Island' },
			{ label: 'South Carolina', value: 'South Carolina' },
			{ label: 'South Dakota', value: 'South Dakota' },
			{ label: 'Tennessee', value: 'Tennessee' },
			{ label: 'Trust Territories', value: 'Trust Territories' },
			{ label: 'Texas', value: 'Texas' },
			{ label: 'Utah', value: 'Utah' },
			{ label: 'Virginia', value: 'Virginia' },
			{ label: 'Virgin Islands', value: 'Virgin Islands' },
			{ label: 'Vermont', value: 'Vermont' },
			{ label: 'Washington', value: 'Washington' },
			{ label: 'Wisconsin', value: 'Wisconsin' },
			{ label: 'West Virginia', value: 'West Virginia' },
			{ label: 'Wyoming', value: 'Wyoming' }

		];
	@track stateOptionsdedication = [
		 	{ label: 'Armed Forces Americas', value: 'Armed Forces Americas' },
			{ label: 'Armed Forces Europe, Middle East', value: 'Armed Forces Europe, Middle East' },
			{ label: 'Alaska', value: 'Alaska' },
			{ label: 'Armed Forces Pacific', value: 'Armed Forces Pacific' },
			{ label: 'Arkansas', value: 'Arkansas' },
			{ label: 'Arizona', value: 'Arizona' },
			{ label: ' California', value: 'California' },
			{ label: 'Colorado', value: 'Colorado' },
			{ label: 'Connecticut', value: 'Connecticut' },
			{ label: 'Canal Zone', value: 'Canal Zone' },
			{ label: 'District of Columbia', value: 'District of Columbia' },
			{ label: 'Delaware', value: 'Delaware' },
			{ label: 'Florida', value: 'Florida' },
			{ label: ' Georgia', value: 'Georgia' },
			{ label: 'Guam', value: 'Guam' },
			{ label: 'Hawaii', value: 'Hawaii' },
			{ label: 'Iowa', value: 'Iowa' },
			{ label: 'Idaho', value: 'Idaho' },
			{ label: 'Illinois', value: 'Illinois' },
			{ label: ' Indiana', value: 'Indiana' },
			{ label: 'Kansas', value: 'Kansas' },
			{ label: 'Kentucky', value: 'Kentucky' },
			{ label: 'Louisiana', value: 'Louisiana' },
			{ label: 'Massachusetts', value: 'Massachusetts' },
			{ label: 'Maryland', value: 'Maryland' },
			{ label: 'Maine', value: 'Maine' },
			{ label: 'Michigan', value: 'Michigan' },
			{ label: 'Minnesota', value: 'Minnesota' },
			{ label: 'Missouri', value: 'Missouri' },
			{ label: 'Idaho', value: 'Idaho' },
			{ label: 'Illinois', value: 'Illinois' },
			{ label: ' Indiana', value: 'Indiana' },
			{ label: 'Kansas', value: 'Kansas' },
			{ label: 'Kentucky', value: 'Kentucky' },
			{ label: 'Louisiana', value: 'Louisiana' },
			{ label: 'Massachusetts', value: 'Massachusetts' },
			{ label: 'Maryland', value: 'Maryland' },
			{ label: 'Maine', value: 'Maine' },
			{ label: ' Michigan', value: 'Michigan' },
			{ label: 'Minnesota', value: 'Minnesota' },
			{ label: 'Missouri', value: 'Missouri' },
			{ label: 'Northern Mariana Islands', value: 'Northern Mariana Islands' },
			{ label: 'Mississippi', value: 'Mississippi' },
			{ label: ' Montana', value: 'Montana' },
			{ label: 'North Carolina', value: 'North Carolina' },
			{ label: 'North Dakota', value: 'North Dakota' },
			{ label: 'Nebraska', value: 'Nebraska' },
			{ label: 'New Hampshire', value: 'New Hampshire' },
			{ label: 'New Jersey', value: 'New Jersey' },
			{ label: 'New Mexico', value: 'New Mexico' },
			{ label: ' Nevada', value: 'Nevada' },
			{ label: 'New York', value: 'New York' },
			{ label: 'Ohio', value: 'Ohio' },
			{ label: 'Oklahoma', value: 'Oklahoma' },
			{ label: 'Oregon', value: 'Oregon' },
			{ label: 'Pennsylvania', value: 'Pennsylvania' },
			{ label: 'Pacific Islands', value: 'Pacific Islands' },
			{ label: 'Puerto Rico', value: 'Puerto Rico' },
			{ label: ' Rhode Island', value: ' Rhode Island' },
			{ label: 'South Carolina', value: 'South Carolina' },
			{ label: 'South Dakota', value: 'South Dakota' },
			{ label: 'Tennessee', value: 'Tennessee' },
			{ label: 'rust Territories', value: 'Trust Territories' },
			{ label: 'Texas', value: 'Texas' },
			{ label: 'Utah', value: 'Utah' },
			{ label: 'Virginia', value: 'Virginia' },
			{ label: 'Virgin Islands', value: 'Virgin Islands' },
			{ label: 'Vermont', value: 'Vermont' },
			{ label: 'Washington', value: 'Washington' },
			{ label: 'Wisconsin', value: 'Wisconsin' },
			{ label: 'West Virginia', value: 'West Virginia' },
			{ label: 'Wyoming', value: 'Wyoming' }



		];
	get fullUrl() {

		return this.ShowURL;
		//  return 'https://test.protectedpayments.net/PMWeb1?pmRef=10750&pid=aCn540000008rOM&locale=en-GB&dit=ae03f30d258d9090ac8bb2523f9ea2922abf87f6675871aae5650e021abb1ef3';
	}


	get optionsaddr() {
		return [
			{ label: 'Home', value: 'Home' },
			{ label: 'Work', value: 'Work' }

		];
	}

	handleCancel(event) {
		this.resetPage1();
	}

	get optionPrefix() {
		return [
			{ label: 'Dr.', value: 'Dr.' },
			{ label: 'Mr.', value: 'Mr.' },
			{ label: 'Mrs', value: 'Mrs' },
			{ label: 'Ms', value: 'Ms' },
			{ label: 'Prof.', value: 'Prof.' }
		];
	}



	resetPage1() {
		this.genericInputs = {
			race2013: '',
			race2014: '',
			race2015: '',
			race2016: '',
			race2017: '',
			race2018: '',
			race2019: '',
			race2020: '',
			race2021: '',
			race2022: '',
			race2023: '',
			ashBrid: '',
			ashCar: '',
			ashCLin: '',
			ashCovid: '',
			ashGlob: '',
			ashGreat: '',
			ashMin: '',
			ashQual: '',
			ashResF: '',
			ashResRe: '',
			ashSic: '',
			ashSic: '',
			joan: '',
			dedicationprefix: '',
			dedicationFName: '',
			dedicationmName: '',
			dedicationlName: '',
			dedicationemail: '',
			dedicationtelephone: '',
			dedicationaddressType: '',
			dedicationompany: '',
			dedicationdepartment: '',
			dedicationCountry: '',
			dedicationaddress1: '',
			dedicationcity: '',
			dedicationaddress2: '',
			dedicationstate: '',
			dedicationpostalCode: '',
			prefix: '',
			fName: '',
			mName: '',
			lName: '',
			Cred: '',
			emailId: '',
			telephone: '',
			addressType: '',
			institution: '',
			department: '',
			Country: '',
			address1: '',
			address2: '',
			city: '',
			state: '',
			postalCode: '',
			recognitionName: '',
			ashPrivacyPolicy: false,
			ashServiceTerms: false
		};
	}

}