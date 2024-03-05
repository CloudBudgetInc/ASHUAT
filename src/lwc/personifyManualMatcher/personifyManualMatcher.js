import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import personifyTransactions from '@salesforce/apex/PersonifyReconcilerController.personifyTransactions';
import handleMatch from '@salesforce/apex/PersonifyReconcilerController.handleMatch';

export default class PersonifyReconcile extends LightningElement {

    @api recordId;
    loading = false;
    showModal = false;
    reconciled = true;
    isMatching = false; // [CM5]: hide the 'difference' indicator as needed.
    buttondisabled = true;
    buttonLabel = 'Match';
    sortedBy = 'Period__c'; // Set initial sort field
    sortDirection = 'asc'; // Set initial sort direction    

    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    PERSONIFYstartDate;
    PERSONIFYendDate;
    PERSONIFYCustomerFilter;
    PERSONIFYOrderFilter;
    PERSONIFYBillToFilter;
    PERSONIFYAmountFilter;
    PERSONIFYrecordData = {};
    PERSONIFYselectedRows = [];
    PERSONIFYhasRows = false;
    PERSONIFYselectedTotal = 0;
    PERSONIFYcolumns = [
        { label: 'Effective Date', fieldName: 'Effective_Date__c', type: 'date', hideDefaultActions: true, sortable: true },
        { label: 'Period', fieldName: 'Period__c', type: 'text', hideDefaultActions: true, sortable: true },
        { label: 'Transaction ID', fieldName: 'Name', type: 'text', hideDefaultActions: true, sortable: true },
        { label: 'Customer ID', fieldName: 'Customer_Id__c', type: 'text', hideDefaultActions: true, sortable: true },
        { label: 'Order Number', fieldName: 'Order_Number__c', type: 'text', hideDefaultActions: true, sortable: true },  
        { label: 'Bill To', fieldName: 'Bill_To_Name__c', type: 'text', hideDefaultActions: true, sortable: true },
        { label: 'Comments', fieldName: 'Comments__c', type: 'text', hideDefaultActions: true, sortable: true },      
        { label: 'Source', fieldName: 'Source__c', type: 'text', hideDefaultActions: true, sortable: true },
        { label: 'Amount', fieldName: 'Amount__c', type: 'currency', fixedWidth: 160, hideDefaultActions: true, sortable: true },
    ];
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Load data when the component is connected
    connectedCallback() {
        this.LoadAllData();
    }
    renderedCallback() {
    }
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Load data for both STATEMENT and LEDGER sections
    LoadAllData() {
        this.buttondisabled = true;
        this.buttonLabel = 'Loading';
        this.loading = true; // Show loading spinner        
        this.PERSONIFYloadRecordData();
    }

    handleResetLite() { 

        // Clear selected rows for the PERSONIFY datatable
        const PERSONIFYDataTable = this.template.querySelector('[data-table="PERSONIFY"]');
        if (PERSONIFYDataTable) {
            PERSONIFYDataTable.selectedRows = [];
        }
        this.PERSONIFYselectedTotal = 0;
    }

    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Clear filters and reload data
    handleReset() {
        console.log('Reset');
        this.isMatching = false;

        // Clear selected rows for the LEDGER datatable
        const PERSONIFYDataTable = this.template.querySelector('[data-table="PERSONIFY"]');
        if (PERSONIFYDataTable) {
            PERSONIFYDataTable.selectedRows = [];
        }

        // Reset PERSONIFY filters
        this.PERSONIFYstartDate = null;
        this.PERSONIFYendDate = null;
        this.PERSONIFYCustomerFilter = '';
        this.PERSONIFYOrderFilter = '';
        this.PERSONIFYBillToFilter = '';
        this.PERSONIFYAmountFilter = '';
        this.PERSONIFYselectedRows = [];
        this.PERSONIFYselectedTotal = 0;

        // Reset any other filters as needed
        this.reconciled = true;
        this.LoadAllData();
    }
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    toggleStatementTable(event) {
        event.preventDefault();
        if(this.showStatement) {
            this.showStatement = false;
            this.statementLinkLabel = 'show table';
        } else {
            this.showStatement = true;
            this.statementLinkLabel = 'hide table';
        }
    }   
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Hide the modal
    hideModal() {
        this.showModal = false;
    }
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Display the modal
    displayModal() {
        this.showModal = true;
    }

    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        General Ledger Transactions Functions
    */
    // Load PERSONIFY record data
    PERSONIFYloadRecordData() {

        personifyTransactions({
            recordId: this.recordId,
            startDate: this.PERSONIFYstartDate,
            endDate: this.PERSONIFYendDate,
            CustomerFilter: this.PERSONIFYCustomerFilter,
            OrderFilter: this.PERSONIFYOrderFilter,
            BillToFilter: this.PERSONIFYBillToFilter,
            AmountFilter: this.PERSONIFYAmountFilter
        })
            .then(result => {
                if (result.length != 0) {
                    this.PERSONIFYrecordData = result;
                    this.PERSONIFYhasRows = true;
                } else {
                    this.PERSONIFYhasRows = false;
                }
            })
            .catch(error => {
                console.error('Error loading PERSONIFY record data:', error);
            })
            .finally(() => {
                this.loading = false; // Hide loading spinner
                this.buttondisabled = false;
                this.buttonLabel = 'Match';
            });
    }
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Handle PERSONIFY filter input changes
    PERSONIFYHandleInputChange(event) {
        // Extract the field name and value from the input event
        const fieldName = event.target.name;
        const fieldValue = event.target.value;

        // Update the corresponding property based on the field name
        if (fieldName === 'startDate') {
            this.PERSONIFYstartDate = fieldValue;
        } else if (fieldName === 'endDate') {
            this.PERSONIFYendDate = fieldValue;
        } else if (fieldName === 'CustomerFilter') {
            this.PERSONIFYCustomerFilter = fieldValue;
        } else if (fieldName === 'OrderFilter') {
            this.PERSONIFYOrderFilter = fieldValue;
        } else if (fieldName === 'BillToFilter') {
            this.PERSONIFYBillToFilter = fieldValue;
        } else if (fieldName === 'AmountFilter') {
            this.PERSONIFYAmountFilter = fieldValue;
        }

        // Load PERSONIFY data with updated filters
        this.PERSONIFYloadRecordData();
    }
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Handle PERSONIFY row selection
    PERSONIFYhandleRowSelection(event) {
        this.PERSONIFYselectedRows = event.detail.selectedRows;
        console.log(event.detail.selectedRows);

        let totalAmount = 0;
        this.PERSONIFYselectedRows.forEach(row => {
            totalAmount += row.Amount__c;
        });

        console.log(totalAmount);
        this.PERSONIFYselectedTotal = totalAmount.toFixed(2);
        console.log(this.PERSONIFYselectedTotal);
    }
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Separate function to check for matching
    checkMatch() {

        console.log('checkMatch');
        console.log(this.PERSONIFYselectedTotal);
        if (this.PERSONIFYselectedTotal !== 0.00 && this.PERSONIFYselectedTotal != '0.00' && 
            this.PERSONIFYselectedTotal !== -0.00 && this.PERSONIFYselectedTotal != '-0.00') {
            // Display the modal for partial match
            this.displayModal();
        } else {
            // Continue with reconciliation
            this.handleMatch();
        }
    }
    // Handle the reconciliation process
    handleMatch() {        
        console.log('handleMatch');
        this.hideModal();
        this.loading = true;
        this.buttondisabled = true;
        this.buttonLabel = 'Matching';
        console.log(this.PERSONIFYselectedRows);
        const selectedPersonifyRowIds = this.PERSONIFYselectedRows.map(row => row.Id);
        console.log(selectedPersonifyRowIds);

        handleMatch({
            selectedPersonifyRowIds: selectedPersonifyRowIds,
            recordId: this.recordId
        })
        .then(result => {
                if (result == true) {
                    this.showToast('Success', 'Records Matched Successfully', 'success');
                    this.reconciled = true;
                    this.PERSONIFYselectedRows = []; // add to clear checkboxes on match
                    this.handleResetLite();
                    this.LoadAllData();
                    this.isMatching = false;
                }
            })
            .catch(error => {
                // Handle any errors that occur
                this.showToast('Error', 'An error occurred while matching records', 'error');
            })
            .finally(() => {
                this.loading = false;
                this.buttondisabled = false;
                this.buttonLabel = 'Match';
            });
    }
    
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    // onsort event handler
    handleSort(event) {
        const { fieldName: newSortedBy, sortDirection: newSortDirection } = event.detail;
    
        // Toggle the sort direction manually if the field is the same
        const sortDirection = (this.sortedBy === newSortedBy && this.sortDirection === 'asc') ? 'desc' : 'asc';
        this.sortedBy = newSortedBy;
        this.sortDirection = sortDirection;
        this.sortData();
    }
    
    sortData() {
        const isReverse = this.sortDirection === 'asc' ? 1 : -1;
        const sortedData = [...this.PERSONIFYrecordData];
    
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
                valA = Math.abs(parseFloat(valA));
                valB = Math.abs(parseFloat(valB));
            }
    
            return isReverse * ((valA > valB) - (valB > valA));
        });
    
        this.PERSONIFYrecordData = sortedData;
    }    
}