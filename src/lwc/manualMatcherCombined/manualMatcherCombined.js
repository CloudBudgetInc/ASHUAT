import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import transactions from '@salesforce/apex/ReconcilerController.transactions';
import handleMatch from '@salesforce/apex/ReconcilerController.handleMatch';

export default class Reconcile extends LightningElement {

    @api recordId;
    loading = false;
    showModal = false;
    reconciled = true;
    isMatching = false; // [CM5]: hide the 'difference' indicator as needed.
    buttondisabled = true;
    buttonLabel = 'Match';
    sortedBy = 'TransactionDate'; // Set initial sort field
    sortDirection = 'asc'; // Set initial sort direction
    showStatement = true;
    statementLinkLabel = 'hide table';
    difference = 0;

    LEDGERselectedTotal = 0;
    LEDGERTypeOptions = [
        { label: 'All', value: 'All' },
        { label: 'ACH', value: 'ACH' },  
        { label: 'Check', value: 'Check' },                
        { label: 'Domestic Wire', value: 'Domestic Wire' },
        { label: 'International Wire', value: 'International Wire' },
        { label: 'Manual Wire', value: 'Manual Wire' },
        { label: 'Journal', value: 'Journal' },
    ];
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    columns = [
        { label: 'Transaction Type', fieldName: 'transactionType', type: 'text', hideDefaultActions: true },
        { label: 'Transaction Date', fieldName: 'TransactionDate', type: 'date', hideDefaultActions: true, sortable: true },
        { label: 'Check Number', fieldName: 'CheckNumber', type: 'text', hideDefaultActions: true, sortable: true },
        { label: 'Account', fieldName: 'account', type: 'text', hideDefaultActions: true, sortable: true },
        { label: 'Reference', fieldName: 'Reference', type: 'text', hideDefaultActions: true, sortable: true },
        { label: 'Type', fieldName: 'Type', type: 'text', hideDefaultActions: true, sortable: true },
        { label: 'Amount', fieldName: 'amount', type: 'currency', hideDefaultActions: true, sortable: true }        
    ];
    hasRows =  true;
    recordData = {};
    selectedRows = [];
    STATEMENTselectedRows = [];
    LEDGERselectedRows = [];

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
        this.loadRecordData();
    }

    handleResetLite() { 

        const transactionsDataTable = this.template.querySelector('[data-table="transactions"]');
        if (transactionsDataTable) {
            transactionsDataTable.selectedRows = [];
        }

        this.STATEMENTselectedTotal = 0;
        this.LEDGERselectedTotal = 0;        
    }

    handleRelay() { 
        this.LEDGERstartDate = this.STATEMENTstartDate;
        this.LEDGERendDate = this.STATEMENTendDate;
        this.loadRecordData();
    }    

    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Clear filters and reload data
    handleReset() {
        console.log('Reset');
        this.isMatching = false;

        const transactionsDataTable = this.template.querySelector('[data-table="transactions"]');
        transactionsDataTable.selectedRows = [];

        // Reset STATEMENT filters
        this.STATEMENTstartDate = null;
        this.STATEMENTendDate = null;
        this.STATEMENTTypeFilter = '';
        this.STATEMENTReferenceFilter = '';
        this.STATEMENTcheckFilter = '';
        this.STATEMENTAmountFilter = '';
        this.STATEMENTselectedRows = [];
        this.STATEMENTselectedTotal = 0;

        // Reset LEDGER filters
        this.LEDGERstartDate = null;
        this.LEDGERendDate = null;
        this.LEDGERAccountFilter = '';
        this.LEDGERTypeFilter = '';
        this.LEDGERReferenceFilter = '';
        this.LEDGERAmountFilter = '';
        this.LEDGERselectedRows = [];
        this.LEDGERselectedTotal = 0;

        this.difference = 0;
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
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Calculate the difference
    //  [CM5]: Only showing an icon when at least one row is selected.
    calculateDifference() {        
        this.difference = this.STATEMENTselectedTotal.toFixed(2) - this.LEDGERselectedTotal.toFixed(2);
        console.log('difference',this.difference);
        console.log('STATEMENTselectedTotal',this.STATEMENTselectedTotal);
        console.log('LEDGERselectedTotal',this.LEDGERselectedTotal);

        if (this.selectedRows.length > 0 ) {
            this.isMatching = true;            

            if (this.difference == 0) {
                this.reconciled = true;
            } else {
                this.reconciled = false;
            }
        } else {
            this.isMatching = false;
        }
    }
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        Bank Statement Transactions Functions
    */
    loadRecordData() {

        console.log(this.STATEMENTAmountFilter);

        transactions({
            recordId: this.recordId,
            bankStartDate: this.STATEMENTstartDate,
            bankEndDate: this.STATEMENTendDate,
            bankTypeFilter: this.STATEMENTTypeFilter,
            bankReferenceFilter: this.STATEMENTReferenceFilter,
            bankAmountFilter: this.STATEMENTAmountFilter,
            bankcheckFilter: this.STATEMENTcheckFilter,

            transactionStartDate: this.LEDGERstartDate,
            transactionEndDate: this.LEDGERendDate,
            transactionTypeFilter: this.LEDGERTypeFilter,
            transactionReferenceFilter: this.LEDGERReferenceFilter,
            transactionAccountFilter: this.STATEMENTAmountFilter,
            transactionAmountFilter: this.LEDGERAmountFilter,
        })
            .then(result => {

                if (result.length != 0 ) {
                    this.recordData = result;
                    this.hasRows = true;
                    this.sortData(); 
                } else {
                    this.hasRows = false;
                }
            })
            .catch(error => {
                console.error('Error loading  record data:', error);
            })
            .finally(() => {
                this.buttondisabled = false;
                this.buttonLabel = 'Match';
                this.loading = false; // Hide loading spinner
            });
    }
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Handle STATEMENT filter input changes
    HandleInputChange(event) {
        // Extract the field name and value from the input event
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        console.log(fieldName);
        console.log(fieldValue);

        // Update the corresponding property based on the field name
        if (fieldName === 'bankstartDate') {
            this.STATEMENTstartDate = fieldValue;
        } else if (fieldName === 'bankendDate') {
            this.STATEMENTendDate = fieldValue;
        } else if (fieldName === 'bankReferenceFilter') {
            this.STATEMENTReferenceFilter = fieldValue;
        } else if (fieldName === 'bankTypeFilter') {
            this.STATEMENTTypeFilter = fieldValue;
        } else if (fieldName === 'bankAmountFilter') {
            this.STATEMENTAmountFilter = fieldValue;
        } else if (fieldName === 'bankCheckFilter') {
            this.STATEMENTcheckFilter = fieldValue;
        } else if (fieldName === 'transactionstartDate') {
            this.LEDGERstartDate = fieldValue;
        } else if (fieldName === 'transactionendDate') {
            this.LEDGERendDate = fieldValue;
        } else if (fieldName === 'transactionAccountFilter') {
            this.LEDGERAccountFilter = fieldValue;
        } else if (fieldName === 'transactionReferenceFilter') {
            this.LEDGERReferenceFilter = fieldValue;
        } else if (fieldName === 'transactionTypeFilter') {
            this.LEDGERTypeFilter = fieldValue;
        } else if (fieldName === 'transactionAmountFilter') {
            this.LEDGERAmountFilter = fieldValue;
        }

        // Load STATEMENT data with updated filters
        this.loadRecordData();
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
        let ledgerTotal = 0;
        let statementTotal = 0;
        
        // Clear existing selections
        this.selectedStatementRowIds = [];
        this.selectedBankTransactionRowIds = [];
    
        // Iterate over each selected row
        this.selectedRows.forEach(row => {
            if (row.transactionType === 'GL') {
                // Add to LEDGER total and track selected rows
                ledgerTotal += row.amount;
                this.selectedBankTransactionRowIds.push(row.recordId); // Assuming 'id' is the unique identifier
            } else if (row.transactionType === 'Bank') {
                // Add to STATEMENT total and track selected rows
                statementTotal += row.amount;
                this.selectedStatementRowIds.push(row.recordId); // Assuming 'id' is the unique identifier
            }
        });
        
        // Update the totals
        this.LEDGERselectedTotal = ledgerTotal;
        this.STATEMENTselectedTotal = statementTotal;
    
        // Continue with other calculations or actions
        this.calculateDifference();
    }
    
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    //    
    /** RT - not used I don't think.
    handleSTATEMENTMatchStatusChange(event) {

        this.STATEMENTmatchStatus = event.detail.value;
        this.loadRecordData();
    }
    */

    /** RT - not used, I don't think.
    handleSTATEMENTTypeChange(event) {

        this.STATEMENTTypeFilter = event.detail.value;
        this.loadRecordData();
    }
    */

    handleLEDGERTypeChange(event) {
        this.LEDGERTypeFilter = event.detail.value;
        this.loadRecordData();
    }

    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        General Ledger Transactions Functions
    /*  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- */
    // Separate function to check for matching
    checkMatch() {
        // Calculate the difference
        this.calculateDifference();

        if (this.difference !== 0) {
            // Display the modal for partial match
            this.displayModal();
        } else {
            // Continue with reconciliation
            this.handleMatch();
        }
    }
    // Handle the reconciliation process
    handleMatch() {        
        this.hideModal();
        this.loading = true;
        this.buttondisabled = true;
        this.buttonLabel = 'Matching';
        //const selectedStatementRowIds = this.STATEMENTselectedRows.map(row => row.Id);
        //const selectedBankTransactionRowIds = this.LEDGERselectedRows.map(row => row.Id);

        handleMatch({
            selectedStatementRowIds: this.selectedStatementRowIds,
            selectedBankTransactionRowIds: this.selectedBankTransactionRowIds,
            recordId: this.recordId
        })
        .then(result => {
                if (result == true) {
                    this.showToast('Success', 'Records Matched Successfully', 'success');
                    this.reconciled = true;
                    this.selectedRows = [];   // add to clear checkboxes on match
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

    // The method onsort event handler
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
        const sortedData = [...this.recordData];
    
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
    
        this.recordData = sortedData;
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
}