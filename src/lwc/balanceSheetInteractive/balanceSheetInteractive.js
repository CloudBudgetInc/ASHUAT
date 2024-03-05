import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';
import balanceSheetInteractiveCSS from '@salesforce/resourceUrl/balanceSheetInteractiveCSS';
import filters from '@salesforce/apex/FinReviewController.filters';
import filtersTb3 from '@salesforce/apex/FinReviewController.filtersTb3';
import balances from '@salesforce/apex/FinReviewController.balances';
import defaults from '@salesforce/apex/FinReviewController.defaults';
import transactions from '@salesforce/apex/FinReviewController.transactions';
import getAssignableUsers from '@salesforce/apex/FinReviewController.getAssignableUsers';
import rootDomain from '@salesforce/apex/FinReviewController.baseURL';
import insertComment from '@salesforce/apex/FinReviewController.insertComment';
import getComments from '@salesforce/apex/FinReviewController.comments';
import respondComment from '@salesforce/apex/FinReviewController.respondComment';
import resolveComment from '@salesforce/apex/FinReviewController.resolveComment';
import archiveComment from '@salesforce/apex/FinReviewController.archiveComment';
import archiveAllComments from '@salesforce/apex/FinReviewController.archiveAllComments';
import USER_ID from '@salesforce/user/Id';

const fields = ['User.Username'];

export default class BalanceSheetInteractive extends NavigationMixin(LightningElement) {
    
    @track selectedRowData = null;
    @track selectedRowAction = null;
    @track totalBalance = 0;

    // Default values for filters
    companyDefault = 'ASH';
    yearDefault = '2024';
    defaultPeriods = '';
    trialBalance1Default = null;

    // Button variant styles
    buttonActiveVariant = 'brand';
    buttonInactiveVariant = 'brand-outline';
    commandButtonVariant = 'base'

    // Filter arrays
    companyFilters = [];
    yearFilters = [];
    trialBalance1Filters = [];

    // Active button IDs
    activeCompanyId = '';
    activeYearId = '';
    activeTrialBalance1Id = '';

    // Selected values
    companySelected = '';
    yearSelected = '';
    trialBalance1Selected = '';
    trialBalance3Selected = '';

    filters = '';
    tb3filters = '';
    trialBalance3Filters = [];
    showSpinner = true;
    balancesData = [];
    originalBalancesData = [];
    showTransactionModal = false;
    selectedAccountSubaccount = '';
    modalHeader = '';
    saveButton = true;
    showModal = false;
    showFlagsOnly = false;
    isLoading = true;
    spinnerMessage = 'Loading...';
    SPINNER_DELAY_MS = 1000;    //  this is the delay before the spinner goes away. it seems to naturally go away to quickly.
    styleLoaded = false;

    baseUrl = '';

    isShowingArchived = false;
    zeroComments = true;

    @track userCanResolve = false;

    // temp until we can replace with a custom metadata setting.
    usersWhoCanResolve = ['rtolocka.itconsultant@hematology.org.ash', 'twhite@hematology.org.ash', 'jkingue@hematology.org.ash'];    
    @wire(getRecord, { recordId: USER_ID, fields: fields })
    userData({ error, data }) {
        if (data) {
            const username = data.fields.Username.value;            
            this.userCanResolve = this.usersWhoCanResolve.includes(username);
        } else if (error) {
            console.error('Error fetching user data:', error);
        }
    }

    get isUserCanResolve() {
        return this.userCanResolve;
    }

    @track accountTransactions = [];
    transactionColumns = [
        { label: 'Name', fieldName: 'c2g__Transaction__r.c2g__Period__r.Name'},
        { label: 'Description', fieldName: 'c2g__LineDescription__c' },
        { label: 'GL Account Name', fieldName: 'c2g__GeneralLedgerAccount__r.Name', },
        { label: 'Account Subaccount', fieldName: 'Account_Subaccount__c' },
        { label: 'Account Name', fieldName: 'c2g__Account__r.Name' },
        { label: 'DocumentNumber', fieldName: 'c2g__DocumentNumber__c' },
        { label: 'Value', fieldName: 'c2g__HomeValue__c' },
        
    ];

    allColumns = [
        // { label: '', fieldName: 'hasOpenComments', hideDefaultActions: true, fixedWidth: 60 },
        { label: 'Category', fieldName: 'trialBalance1',  sortable: true, fixedWidth: 120, },
        { label: 'Subcategory', fieldName: 'trialBalance3', sortable: true, fixedWidth: 240, },
        { label: 'Name', fieldName: 'name', sortable: true },
        // { label: 'Account Subaccount', fieldName: 'accountSubaccount', hideDefaultActions: true, sortable: true },
        {
            label: 'Account Subaccount', 
            fieldName: 'accountSubaccountUrl',  // This field will hold the complete URL
            type: 'url', 
            typeAttributes: {
                label: { fieldName: 'accountSubaccount' }, // The label uses the original accountSubaccount field
                target: '_blank',  // Optional: if you want to open the link in a new tab
            },
            sortable: true 
        },
        { label: 'Flag', fieldName: '',fixedWidth: 80, cellAttributes: { iconName: { fieldName: 'dynamicIcon' } } },
        { label: 'Assignee', fieldName: 'assignee', hideDefaultActions: true, sortable: true },
        { label: 'Balance', fieldName: 'balance', type: 'currency', hideDefaultActions: true, sortable: true,
            typeAttributes: {
                currencyCode: 'USD', 
                currencyDisplayAs: 'symbol', 
                minimumFractionDigits: 2
            }
        },   
        { label: '', type: 'button-icon', fixedWidth: 40, hideDefaultActions: true,
            typeAttributes: { variant:'brand', iconName:'action:question_post_action', label: '', name: 'Assign_Task', title: 'Assign Task', disabled: { fieldName: 'hideButtons' }, value: 'Assign_Task', iconPosition: 'left' }
        },
        { label: '', type: 'button-icon', fixedWidth: 40, hideDefaultActions: true,
            typeAttributes: { variant:'brand', iconName:'action:share_post', label: '', name: 'Respond', title: 'Respond', disabled: { fieldName: 'hideButtons' }, value: 'Respond', iconPosition: 'left' }
        },
        { label: '', type: 'button-icon', fixedWidth: 40, hideDefaultActions: true, 
            typeAttributes: { variant:'brand', iconName:'action:preview', label: '', name: 'View_Comments', title: 'View_Comments', disabled: { fieldName: 'hideButtons' }, value: 'View_Comments', iconPosition: 'left' }
        },  
        { label: '', type: 'button-icon', fixedWidth: 40, hideDefaultActions: true, showIf: 'userCanResolve', 
            typeAttributes: { variant: 'brand', iconName:'action:approval', label: '', name: 'Resolved', title: 'Resolved', disabled: { fieldName: 'disableViewComments' }, value: 'Resolved', iconPosition: 'left' }
        }                  
    ];

    // Lifecycle hook runs when component is inserted into the DOM
    connectedCallback() {
        
        this.loadPage();
    }

    renderedCallback() {
        // console.log('renderedCallback');
        this.loadStyle();
    }

    loadStyle() {
        // console.log('loadStyle');
        if (this.styleLoaded) {
            return;
        }
        this.styleLoaded = true;

        loadStyle(this, balanceSheetInteractiveCSS)
            .then(() => {
                // console.log("Custom styles loaded successfully");
            })
            .catch(error => {
                // console.error("Error loading custom styles:", error);
            });
    }

    loadPage() {
        // console.log('loadPage');
        this.spinnerMessage = 'Loading page.';        
        this.showSpinner = true;
        this.balancesData = [];
        this.originalBalancesData = [];
        this.trialBalance1Selected = '';
        this.trialBalance3Selected = '';
        this.showFlagsOnly = false;

        this.fetchDefaults();  // Fetch default settings like company and year
        this.getFilters();     // Get filters from your Apex controller
        //this.fetchBalances();  // Fetch initial balance data
        this.applyAllFilters('connectedCallback'); // Apply any default filters set by fetchDefaults
    }

    refreshPage() {
        // console.log('refreshPage');
        this.spinnerMessage = 'Refreshing page.';        
        this.showSpinner = true;
        this.balancesData = [];
        this.originalBalancesData = [];

        this.fetchBalances();  // Fetch initial balance data        
    }

    calculateTotalBalance() {
        let totalBalance = 0;
        this.balancesData.forEach(row => {
            totalBalance += parseFloat(row.balance); // assuming 'balance' is the field name
        });
        return totalBalance;
    }
    
    constructVFPageUrl(accountSubaccount) {
        const vfPageName = 'TransactionDetails';
        const namespace = 'persbudget'; // Replace with your actual namespace if different
        // const baseUrl = `https://${namespace}--c.visualforce.com/apex/${vfPageName}`;
        // const baseUrl = this.baseUrl`https://hematology--persbudget--c.sandbox.vf.force.com/apex/${vfPageName}`;
        const baseUrl = this.baseUrl + '/apex/TransactionDetails';        
        const company = this.companySelected || this.companyDefault;
        const year = this.yearSelected || this.yearDefault;
    
        return `${baseUrl}?company=${encodeURIComponent(company)}&year=${encodeURIComponent(year)}&key=${encodeURIComponent(accountSubaccount)}`;
    }

    // Checks if a TB1 filter is selected
    get isTb1Selected() {
        return !!this.activeTrialBalance1Id;
    }

    // Fetches balance data from Apex
    fetchBalances() {
        this.showSpinner = true;
        // console.log('fetchBalances');
        this.spinnerMessage = 'Loading balances.';

        // console.log( "companyDefault", this.companyDefault);
        // console.log( "companySelected", this.companySelected);
        
        // console.log( "yearDefault", this.yearDefault);
        // console.log( "yearSelected", this.yearSelected);

        const selectedCompany = this.companySelected || this.companyDefault;
        const selectedYear = this.yearSelected || this.yearDefault;

        // console.log( "selectedCompany", selectedCompany);
        // console.log( "selectedYear", selectedYear);
               
        balances({ company: selectedCompany, year: selectedYear })
            .then(result => {
                
                const updatedResult = result.map(row => {
                

                    const vfUrl = this.constructVFPageUrl(row.accountSubaccount);
    
                    return {
                        ...row,
                        accountSubaccountUrl: vfUrl, // Add the URL to the row data
                        dynamicIcon: row.hasOpenComments === 'true' ? 'action:priority' : null,
                        disableViewComments: row.hasOpenComments === 'true' ? false : true
                    };
                });
    
                this.originalBalancesData = updatedResult;
                this.balancesData = this.applyFiltersToBalancesData(updatedResult);
                this.applyAllFilters('fetchBalances');
            })
            .catch(error => {
                this.showToast('Error', 'Error fetching balances: ' + error, 'error');
            })
            .finally(() => {
                this.hideSpinner();
            });
    }
    
    fetchDefaults() {
        // console.log('fetchDefaults');
        this.spinnerMessage = 'Loading defaults.';
        defaults({})
            .then(result => {
                // console.log('DEFAULTS', JSON.stringify(result));
                
                if (result.Company !== null) {
                    this.companyDefault = result.Company;
                }
                if (result.Year !== null) {
                    this.yearDefault = result.Year;
                }
                if (result.Periods !== null) {
                    this.defaultPeriods = 'Periods: ' + result.Periods; 
                }
    
                // For debugging
                // console.log('Assigned Company Default:', this.companyDefault);
                // console.log('Assigned Year Default:', this.yearDefault);
                // console.log('Assigned Periods Default:', this.defaultPeriods);
            })
            .catch(error => {
                this.showToast('Error', 'Error fetching defaults: ' + error, 'error');
            })
            .finally(() => {
                this.fetchBalances();
                rootDomain({})
                .then(result => {
                    this.baseUrl = result;
                })
                .catch(error => {
                    this.showToast('Error', 'Error fetching base URL: ' + error, 'error');
                })
                .finally(() => {
                    this.hideSpinner();
                });              
            });
            
    }

    // Fetches filters from Apex and processes them
    getFilters() {    
        // console.log('getFilters');
        this.spinnerMessage = 'Loading filters.';
        filters({})
            .then(result => {
                this.filters = JSON.stringify(result);
                this.processFilters(result, 'COMPANY', this.companyDefault, 'activeCompanyId', 'companySelected', 'companyFilters');
                this.processFilters(result, 'YEAR', this.yearDefault, 'activeYearId', 'yearSelected', 'yearFilters');
                this.processFilters(result, 'TRIAL_BALANCE_1', this.trialBalance1Default, 'activeTrialBalance1Id', 'trialBalance1Selected', 'trialBalance1Filters');
            })
            .catch(error => {
                this.showToast('Warning', 'Error loading filters: ' + error, 'warning');
            }).finally(() => {
                
            });
    }

    // Processes and maps filters
    processFilters(result, type, defaultVal, activeIdProp, selectedValProp, filterArrayProp) {
        const filters = result.filter(filter => filter.type === type);
        if (defaultVal !== null) {
            const defaultFilter = filters.find(filter => filter.value === defaultVal);
            if (defaultFilter) {
                this[activeIdProp] = defaultFilter.identifier;
                this[selectedValProp] = defaultFilter.value;
            }
        }
        this[filterArrayProp] = filters.map(filter => ({
            ...filter,
            buttonVariant: (this[activeIdProp] && filter.identifier === this[activeIdProp]) ? this.buttonActiveVariant : this.buttonInactiveVariant
        }));
    }

    // Handles click for company buttons
    handleClick(event) {
        this.updateActiveButton(event, 'activeCompanyId', 'companySelected', 'companyFilters');
        this.fetchBalances();
    }

    // Handles click for year buttons
    handleYearClick(event) {
        this.updateActiveButton(event, 'activeYearId', 'yearSelected', 'yearFilters');
        this.fetchBalances();
    }

    // Handles click for TB1 buttons
    handleTb1Click(event) {
        const clickedButtonId = event.target.dataset.id;

        if (this.activeTrialBalance1Id === clickedButtonId) {
            this.activeTrialBalance1Id = '';
            this.trialBalance1Selected = '';
            this.trialBalance3Selected = '';
            this.activeTrialBalance3Id = '';
            this.trialBalance3Filters = [];
        } else {            
            this.activeTrialBalance1Id = clickedButtonId;
            this.trialBalance1Selected = this.trialBalance1Filters.find(filter => filter.identifier === clickedButtonId).value;
            this.trialBalance3Selected = '';
            this.activeTrialBalance3Id = '';
            this.fetchTb3Filters();
        }

        this.updateButtonVariants(this.trialBalance1Filters, this.activeTrialBalance1Id);

        this.applyAllFilters('handleTb1Click');
    }
  
    handleFlagClick() {    
        this.showFlagsOnly = !this.showFlagsOnly;
        // this.applyFlagFilter();
        this.applyAllFilters('handleFlagClick'); 
    }

    applyFlagFilter() {
        if (this.showFlagsOnly) {            
            this.balancesData = this.originalBalancesData.filter(row => row.hasOpenComments === 'true');
        } else {            
            this.balancesData = [...this.originalBalancesData];
        }  
    }

    applyAllFilters(step) {
        let filteredData = [...this.originalBalancesData];

        if (this.trialBalance1Selected) {
            filteredData = filteredData.filter(row => row.trialBalance1 === this.trialBalance1Selected);
        }

        if (this.trialBalance3Selected) {
            filteredData = filteredData.filter(row => row.trialBalance3 === this.trialBalance3Selected);
        }

        if (this.showFlagsOnly) {
            filteredData = filteredData.filter(row => row.hasOpenComments === 'true');
        }

        this.totalBalance = this.calculateTotalBalance(filteredData); 
        this.balancesData = filteredData;

        console.log('Filtering step:', step);
        console.log('Filtered data count:', filteredData.length);

        if (filteredData.length === 0 && step !== 'connectedCallback') {
            this.showToast('Info', 'No data available for the selected filters.', 'warning');
        }
    }

    calculateTotalBalance(data) {
        let total = data.reduce((sum, row) => sum + parseFloat(row.balance || 0), 0);
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(total);
    }

   // Fetches TB3 filters
    fetchTb3Filters() {
        const selectedTb1Value = this.trialBalance1Selected;
        if (selectedTb1Value) {
            filtersTb3({ trialBalance1: selectedTb1Value })
                .then(result => {
                    this.trialBalance3Filters = result.map(filter => ({
                        ...filter,
                        buttonVariant: this.buttonInactiveVariant
                    }));
                })
                .catch(error => {
                    this.showToast('Error', 'Error fetching TB3 filters: ' + error, 'error');
                });
        } else {
            this.trialBalance3Filters = [];
        }
    }

    // Handles click for TB3 buttons
    handleTb3Click(event) {
        const clickedButtonId = event.target.dataset.id;
        if (this.activeTrialBalance3Id === clickedButtonId) {
            // If the same button is clicked, clear the filter
            this.activeTrialBalance3Id = '';
            this.trialBalance3Selected = '';
        } else {
            // Otherwise, set this filter as active
            this.activeTrialBalance3Id = clickedButtonId;
            this.trialBalance3Selected = this.trialBalance3Filters.find(filter => filter.identifier === clickedButtonId).value;
        }
        this.updateButtonVariants(this.trialBalance3Filters, this.activeTrialBalance3Id);
        this.applyAllFilters('handleTb3Click'); // Apply all active filters
    }
    

    // Updates button variants
    updateButtonVariants(filtersArray, activeId) {
        filtersArray.forEach(filter => {
            filter.buttonVariant = filter.identifier === activeId ? this.buttonActiveVariant : this.buttonInactiveVariant;
        });
    }

    // Applies TB1 and TB3 filters to balances data
    applyFiltersToBalancesData(data) {
        let filteredData = data;
        if (this.trialBalance1Selected) {
            filteredData = filteredData.filter(row => row.trialBalance1 === this.trialBalance1Selected);
        }
        if (this.trialBalance3Selected) {
            filteredData = filteredData.filter(row => row.trialBalance3 === this.trialBalance3Selected);
        }
        if ( ( this.trialBalance3Selected || this.trialBalance1Selected ) && filteredData.length === 0) {
            this.showToast('Info', 'No data available for the selected filters.', 'warning');
        }
        return filteredData;
    }

    // Updates active button state
    updateActiveButton(event, activeIdProp, selectedValProp, filterArrayProp) {
        const newActiveId = event.target.dataset.id;
        this[filterArrayProp] = this[filterArrayProp].map(filter => ({
            ...filter,
            buttonVariant: filter.identifier === newActiveId ? this.buttonActiveVariant : this.buttonInactiveVariant
        }));
        this[activeIdProp] = newActiveId;
        this[selectedValProp] = this[filterArrayProp].find(filter => filter.identifier === newActiveId).value;
    }

    // Sort table data
    handleSort(event) {
        const { fieldName: newSortedBy, sortDirection: newSortDirection } = event.detail;
    
        // Toggle the sort direction manually if the field is the same
        const sortDirection = (this.sortedBy === newSortedBy && this.sortDirection === 'asc') ? 'desc' : 'asc';
    
        this.sortedBy = newSortedBy;
        this.sortDirection = sortDirection;
    
        this.sortData();
    }   

    modalViewComments = false;
    modalAssignTask = false;
    modalRespond = false;
    @track comments = [];

    handleRowAction(event) {
        
        const action = event.detail.action;
        console.log('action.name', action.name)
        const row = event.detail.row;
        // console.log('action.name', action.name);
        // console.log('row', JSON.stringify(row));
        if (action.name === 'view_details') {            
            // this.openTransactionModal(event);
            // this.navigateToVFPage(row.accountSubaccount);
        }
        
        this.selectedRowData = row;
        this.selectedRowAction = action;
        
        this.modalViewComments = false;
        this.modalAssignTask = false;
        this.modalRespond = false;
        // console.log(action.name);
        if (action.name === 'Assign_Task') {
            this.openModal();
            this.modalAssignTask = true;
            this.modalHeader = 'Assign a task';
            this.saveButton = true;
        } else if (action.name === 'Respond') {
            this.openModal();
            this.modalRespond = true;
            this.modalHeader = 'Respond to task';
            this.saveButton = true;
        } else if (action.name === 'View_Comments') {
            this.openModal();
            
                getComments({ company: this.companySelected, 
                              key: this.selectedRowData.accountSubaccount,
                              archived: false
                })
                .then(result => {
                    console.log("Result from getComments:", result); // Log the raw result
                    this.comments = result;   
                    this.zeroComments = result.length === 0;
                    console.log("Zero Comments:", this.zeroComments); // Log after setting zeroComments                                
                })
                .catch(error => {
                    console.error('Error fetching comments:', error);
                    this.showToast('Error', 'Error fetching comments: ' + error, 'error');
                }).finally(() => {
                    
                });

            this.modalViewComments = true;
            this.modalHeader = 'All comments';
            this.saveButton = false;
        } else if (action.name === 'Resolved') {
            
            resolveComment({
                company: this.companySelected, 
                key: this.selectedRowData.accountSubaccount,
                status: 'resolved'
            })
            .then(result => {
                this.fetchBalances()
                // console.log('Comment inserted with Id:', result);   
            })
            .catch(error => {
                this.showToast('Error', 'Error inserting comment: ' + error, 'error');                        
            }).finally(() => {
                this.closeModal();
                
            });
        }  
    }

    // Method to navigate to the Visualforce page
    navigateToVFPage(accountSubaccount) {
        // Construct the base URL for the Visualforce page
        const vfPageName = 'TransactionDetails';
        const namespace = 'persbudget'; // replace with your actual namespace if different
        const baseUrl = `https://${namespace}--c.visualforce.com/apex/${vfPageName}`;

        // Retrieve other filter values
        const company = this.companySelected || this.companyDefault;
        const year = this.yearSelected || this.yearDefault;

        // Construct the full URL with query parameters
        const vfUrl = `${baseUrl}?company=${encodeURIComponent(company)}&year=${encodeURIComponent(year)}&key=${encodeURIComponent(accountSubaccount)}`;

        // Use standard JavaScript to open the URL in a new window or tab
        window.open(vfUrl, '_blank');
    }

    get highlightRow() {
        return this.contacts.filter(contact => !contact.Email);
    }

    get flaggedButtonVariant() {
        return this.showFlagsOnly ? 'brand' : 'base';
    }

    openModal() {    
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.selectedRowData = null;
        this.assigneeId = null;
        this.assigneeComment = null;
        this.assigneeResolved = null;
        this.comments = [];
        this.isShowingArchived = false;        
    }

    sortData() {
        const isReverse = this.sortDirection === 'asc' ? 1 : -1;
        const sortedData = [...this.balancesData];
    
        sortedData.sort((a, b) => {
            let valA = a[this.sortedBy];
            let valB = b[this.sortedBy];
    
            // Handle nulls
            valA = (valA === null) ? '' : valA;
            valB = (valB === null) ? '' : valB;
    
            // Adjust for different types
            if (typeof valA === 'string') valA = valA.toLowerCase();
            if (typeof valB === 'string') valB = valB.toLowerCase();
    
            // Adjust for numeric comparison
            if (!isNaN(valA) && !isNaN(valB)) {
                valA = parseFloat(valA);
                valB = parseFloat(valB);
            }
    
            return isReverse * ((valA > valB) - (valB > valA));
        });
    
        this.balancesData = sortedData;
    }

    // Displays toast notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    @track userOptions = [];
    assigneeId;
    assigneeComment = '';
    assigneeResolved;

    @wire(getAssignableUsers)
    wiredUserOptions({ error, data }) {
        if (data) {
            this.userOptions = data;
        } else if (error) {
            console.error('Error fetching user options:', error);
        }
    }

    handleAssigneeChange(event) {
        this.assigneeId = event.detail.value;
    }

    handleCommentChange(event) {
        this.assigneeComment = event.detail.value;
    }

    handleResolvedChange(event) {        
        this.assigneeResolved = event.target.checked;        
    }

    handleModalSave(event) {
        
        // console.log('Assignee ID:', this.assigneeId);
        // console.log('Assignee Comment:', this.assigneeComment);
        // console.log('Assignee Resolved:', this.assigneeResolved);
        // console.log('Action:', this.selectedRowAction.name);
        // console.log('Key:', this.selectedRowData.accountSubaccount); 

        if (!this.assigneeComment || this.assigneeComment.trim() === '') {
            this.showToast('Error', 'Comment cannot be empty.', 'error');
            return;
        }
    
        // Additional check for 'Assign_Task' to ensure assigneeId is not null
        if (this.selectedRowAction.name === 'Assign_Task' && !this.assigneeId) {
            this.showToast('Error', 'You must select an assignee for the task.', 'error');
            return;
        }
    
        switch (this.selectedRowAction.name) {
            case 'Assign_Task':
                insertComment({
                        company: this.companySelected, 
                        key: this.selectedRowData.accountSubaccount, 
                        content: this.assigneeComment, 
                        assigneeId: this.assigneeId 
                    })
                    .then(result => {
                        this.fetchBalances()
                        // console.log('Comment inserted with Id:', result);   
                    })
                    .catch(error => {
                        this.showToast('Error', 'Error inserting comment: ' + error, 'error');                        
                    }).finally(() => {
                        this.closeModal();
                        
                    });
                break;        
                case 'Respond':
                    respondComment({
                            company: this.companySelected, 
                            key: this.selectedRowData.accountSubaccount, 
                            content: this.assigneeComment, 
                            assigneeId: this.assigneeId
                        })
                        .then(result => {
                            this.fetchBalances()
                            // console.log('Comment inserted with Id:', result);   
                        })
                        .catch(error => {
                            this.showToast('Error', 'Error inserting comment: ' + error, 'error');                        
                        }).finally(() => {
                            this.closeModal();
                            
                        });
                    break;        
            default:
                
                break;
        }
    }

    handleArchiveChange(event) {
        console.log('handleArchiveChange');
        const commentId = event.target.dataset.id;
        const isArchived = event.target.checked;
        this.spinnerMessage = 'Archiving.';
        // this.hideSpinner();
        archiveComment({
            commentID: commentId, 
            archived: isArchived
        })
        .then(result => {
            console.log(result);
            getComments({ company: this.companySelected, 
                          key: this.selectedRowData.accountSubaccount,
                          archived: this.isShowingArchived
            })
            .then(result => {
                console.log("Result from getComments:", result); // Log the raw result
                this.comments = result;   
                this.zeroComments = result.length === 0;
                console.log("Zero Comments:", this.zeroComments); // Log after setting zeroComments                                                                  
            })
            .catch(error => {
                console.error('Error fetching comments:', error);
                this.showToast('Error', 'Error fetching comments: ' + error, 'error');
            }).finally(() => {
                
            });
        })
        .catch(error => {
            this.showToast('Error', 'Error archiving comment: ' + error, 'error');                        
        }).finally(() => {
            this.spinnerMessage = '';
            this.hideSpinner();
        });
        
    }

    showArchivedComments() {
        this.isShowingArchived = !this.isShowingArchived;

        getComments({ 
            company: this.companySelected, 
            key: this.selectedRowData.accountSubaccount,
            archived: this.isShowingArchived
        })
        .then(result => {
            console.log("Result from getComments:", result); // Log the raw result
            this.comments = result;   
            this.zeroComments = result.length === 0;
            console.log("Zero Comments:", this.zeroComments); // Log after setting zeroComments                                
        })
        .catch(error => {
            console.error('Error fetching comments:', error);
            this.showToast('Error', 'Error fetching comments: ' + error, 'error');
        });
    }

    handleArchiveAllComments(event) {        
        this.spinnerMessage = 'Archiving all comments.';
        this.showSpinner = true;

        console.log('companySelected',this.companySelected);
        console.log('accountSubaccount',this.selectedRowData.accountSubaccount);
        archiveAllComments({ company: this.companySelected,
                             key: this.selectedRowData.accountSubaccount
        })
        .then(result => {
            console.log(result);
            this.isShowingArchived = false;
            getComments({ company: this.companySelected, 
                          key: this.selectedRowData.accountSubaccount,
                          archived: false
            })
            .then(result => {
                console.log("Result from getComments:", result); // Log the raw result
                this.comments = result;   
                this.zeroComments = result.length === 0;
                console.log("Zero Comments:", this.zeroComments); // Log after setting zeroComments                                
            })
            .catch(error => {
                console.error('Error fetching comments:', error);
                this.showToast('Error', 'Error fetching comments: ' + error, 'error');
            }).finally(() => {

            });
        })
        .catch(error => {
            this.showToast('Error', 'Error archiving comment: ' + JSON.stringify(error), 'error');                        
        }).finally(() => {
            this.hideSpinner();
        });
        
    }

    get archiveButtonText() {
        return this.isShowingArchived ? 'Hide Archived' : 'Show Archived';
    }

    get processedComments() {
        return this.comments.map(comment => ({
            ...comment,
            AssigneeName: comment.Assignee__r ? comment.Assignee__r.Name : ''
            // AssigneeName: comment.Assignee__r ? comment.Assignee__r.Name : comment.LastModifiedBy.Name
        }));
    }

    get columns() {
        return this.allColumns.filter(col => {
            // If the column does not have the 'showIf' attribute, always show it
            if (!col.showIf) return true;
            // Otherwise, return the result of evaluating the condition associated with 'showIf'
            return this[col.showIf];
        });
    }

    get username() {
        if (this.currentUser.data) {
            const username = this.currentUser.data.fields.Username.value;
            console.log('Current username:', username); // This logs the username once available
            return username;
        }
        return '';
    }



    openTransactionModal(event) {        
        this.selectedAccountSubaccount = event.detail.row.accountSubaccount;

        // console.log('company', this.companySelected);
        // console.log('year', this.yearSelected);
        // console.log('key', this.selectedAccountSubaccount);

        transactions({
            company: this.companySelected, 
            year: this.yearSelected,
            key: this.selectedAccountSubaccount            
        })
        .then(result => {     
            if (result.length === 0) {
                this.showToast('Nothing to display.', 'No transactions found for ' + this.selectedAccountSubaccount + '.', 'warning');
            } else {
                this.accountTransactions = result;
                this.showTransactionModal = true;
            }      
            console.log('result :', JSON.stringify(result));   
        })
        .catch(error => {
            this.showToast('Error', 'Error fetching transaction history: ' + error, 'error');                        
        }).finally(() => {            
            
        });

        // Here you would also call your Apex method to fetch the transaction details
        // and process them for display in the modal
    }

    // Method to close the transaction modal
    closeTransactionModal() {
        this.accountTransactions = [];
        this.showTransactionModal = false;
    }

    hideSpinner() {
        this.isLoading = false;
        setTimeout(() => {
            this.spinnerMessage = 'Finishing...';      
            this.showSpinner = false;           
        }, this.SPINNER_DELAY_MS); 
    }
    
}