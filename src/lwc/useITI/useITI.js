import { LightningElement, api, track } from 'lwc';
import intlTellinputjs from '@salesforce/resourceUrl/intlTellinputjs';
import utils from '@salesforce/resourceUrl/utils';
import intlTellinputcss from '@salesforce/resourceUrl/intlTellinputcss';
import democss from '@salesforce/resourceUrl/democss';
import flags from '@salesforce/resourceUrl/flags';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

export default class UseITI extends LightningElement {
    @api CountryName = '';
    @track inputElem;
    @track iti;
    @api phoneVal
    @track genericphone = [];
    connectedCallback() {
        loadStyle(this, democss)
            .then(() => {

            });
        loadStyle(this, intlTellinputcss)
            .then(() => {

            });
        loadScript(this, utils)
            .then(() => {

            });
        loadScript(this, intlTellinputjs)

            .then(() => {
                this.inputElem = this.template.querySelector("[data-id=country]")

                /* initialize the intl plugin */
                var iti = window.intlTelInput(this.inputElem, {
                    initialCountry: "us",
                    preferredCountries: ['AU', 'NZ', 'us', 'CA',],
                    separateDialCode: true,
                    //nationalMode: true,
                    utilsScript: utils,

                })

                // store the instance variable so we can access it further down
                window.iti = iti;

            })
 	}
/* Event handler to push up to Aura CMP */
    handleChange(evt) {
        if(evt.target.value){
            this.template.querySelector('[data-id="country"]').classList.remove('disable-container');
        }else{
           this.template.querySelector('[data-id="country"]').classList.add('disable-container');
        }
 				var value = iti.getNumber(); //Get full number
                 console.log('values for cal --> ' + value);
        const telephoneValueChange = new CustomEvent("telephonevaluechange", {
            detail: { value }
        });
        // Fire the custom event
        this.dispatchEvent(telephoneValueChange);
        }
    }