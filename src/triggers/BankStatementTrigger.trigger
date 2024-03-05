trigger BankStatementTrigger on Bank_Statement__c (after update) {
    
    private static final String TEN_NINETEEN_REPORTING_CODE = '1019';
    private static final String TEN_SIXTEEN_REPORTING_CODE = '1016-ACH';
    private static final String RECEIVER_LINE = '88,RCVR';
    
    if ( Trigger.isAfter && trigger.isUpdate ) 
    {
        // Sets up a lookup/map of BAI type code matched to BAI type description.
        Map<String, BAITransactionType__c> transactionTypeLookup = new Map<String, BAITransactionType__c>();
        Map<Id, BAITransactionType__c> someTransactionTypes = 
            new Map<Id, BAITransactionType__c>([SELECT Id, Code__c, Type__c from BAITransactionType__c]);
        for( Id someId : someTransactionTypes.keySet() ) {
            BAITransactionType__c transactionType = someTransactionTypes.get(someId);
                String code = transactionType.Code__c;
            transactionTypeLookup.put(code, transactionType);
        }
        
        for(Bank_Statement__c statement : trigger.new) {
            List<Bank_Statement_Line_Item__c> previouslyInsertedItems = [SELECT Id FROM Bank_Statement_Line_Item__c
				WHERE Bank_Statement__c = :statement.Id];
            if(previouslyInsertedItems.size() == 0 ) {
                if( statement.Process_File__c == true && 
                    Trigger.oldMap.get(statement.Id).Process_File__c != statement.Process_File__c ) {
                        importBAIFormattedFile(statement, transactionTypeLookup);
                }
            }
            else {
                System.debug('Previously inserted bank statement lines found. Cancelling import operation.');
            }
        }
    }
    
    private void importBAIFormattedFile(Bank_Statement__c statement, Map<String, BAITransactionType__c> transactionTypeLookup)
    {
        // Fetch the file attached to the Bank Statement item, and split based on newlines.
        Id someId = statement.Id;
        List<ContentDocumentLink> someList = [SELECT Id, LinkedEntityId, ContentDocumentId
                                              FROM ContentDocumentLink WHERE LinkedEntityId = :someId];  
        ContentDocumentLink cdl = someList.get(0);
        Id contentDocumentId = cdl.ContentDocumentId;
        ContentVersion someCv = [SELECT FileExtension, Title, versiondata FROM ContentVersion 
                                 WHERE ContentDocumentId = :contentDocumentId and IsLatest=true];
        Blob baiFileBody = someCv.VersionData;
        String baiAsString = baiFileBody.toString();
        List<String> baiFileLines = baiAsString.split('\n');

        // Grab the bank account number we'll be searching for in the BAI file via a lookup to the Bank Account.
        c2g__codaBankAccount__c bankAccount = [SELECT Id, c2g__AccountNumber__c, c2g__ReportingCode__c 
                                               FROM c2g__codaBankAccount__c 
                               WHERE Id = :statement.Bank_Account__c];
        String bankAccountNumber = bankAccount.c2g__AccountNumber__c;
        String reportingCode = bankAccount.c2g__ReportingCode__c;
        List<Bank_Statement_Line_Item__c> linesForInsert = new List<Bank_Statement_Line_Item__c>();                 
        
        boolean process = false;
        String transactionDate = '';
        boolean eightyEightLineAlreadyProcessed = false;
        boolean sixteenLinesBegun = false;
        for(String line : baiFileLines) {
            // File is grouped by date using the 02 record.
            if(line.startsWith('02')) {
                List<String> moreSplits = line.split(',');
                transactionDate = moreSplits[4];                        
            }
            // File is further grouped by bank account number - only process records that match 
            // the bank account number set on the object.
            if( line.startsWith('03') ) {
                List<String> moreSplits = line.split(',');
                if(moreSplits[1].equals(bankAccountNumber)) {
                    process = true;
                }
                else {
                    process = false;
                }    
            }
            // 16 is a data transaction; we load these up for matching purposes.
            // Here we're finally doing "the work" of this trigger.
            if(line.startsWith('16') && process == true) { 
                eightyEightLineAlreadyProcessed = false;
                List<String> moreSplits = line.split(',');
                Bank_Statement_Line_Item__c newLine = new Bank_Statement_Line_Item__c();
                newLine.General_Ledger_Account__c = statement.General_Ledger_Account__c;
                String code = moreSplits[1];
                // If we don't have a lookup value for the BAI type, we still process it as 'unknown'.
                BAITransactionType__c typeLookup = transactionTypeLookup.get(code);
                if(typeLookup == null) {
                    typeLookup = transactionTypeLookup.get('999');
                }
                newLine.Type__c = typeLookup.Type__c;
                newLine.Code__c = code;
                // We use BAI standards to determine the sign of the transaction item.
                if(Integer.valueOf(code) < 400) { 
                    newLine.Amount__c = (Decimal.valueOf(moreSplits[2])/100);
                    newLine.Sign__c = 'Debit';
                }
                else {
                    newLine.Amount__c = (Decimal.valueOf(moreSplits[2])/100) * -1;
                    newLine.Sign__c = 'Credit';
                }
                newLine.Reference__c = moreSplits[4];
                String addenda1 = moreSplits[5];
                // Special handling for checks - grab the check number.
                if(code == '475') {
                    newLine.Addenda_1__c = addenda1.left(5);                        
                }
                newLine.Bank_Statement__c = statement.Id;
                newLine.Transaction_Date__c = 
                    Date.newInstance(Integer.valueOf('20' + transactionDate.left(2)), 
                                     Integer.valueOf(transactionDate.mid(2,2)), 
                                     Integer.valueOf(transactionDate.right(2)));
                
                linesForInsert.add(newLine);
                sixteenLinesBegun = true;
            }
            // If the next line is an 88 (not all lines have 88 records), grab the relevant 
            // addenda and add it. This is only relevent for incoming checks (debits); we don't want to 
            // overwrite the check number previously stored for outgoing checks, code 475 (credits). 
            // The purpose of this line is to grab the payer from the BAI file. Note that we only want to grab the 
            // first 88 line, and likewise, we only want to use 88 lines that come after a 16 line (they don't always).
            if(line.startsWith('88') && process == true && !eightyEightLineAlreadyProcessed && 
               sixteenLinesBegun && reportingCode == TEN_NINETEEN_REPORTING_CODE) {            
                  List<String> moreSplits = line.split(',');
                  Bank_Statement_Line_Item__c lastLine = linesForInsert.get(linesForInsert.size()-1);
                  if(lastLine.Code__c != '475') { 
                    String payer = moreSplits[1];
                    lastLine.Addenda_1__c = payer.left(50);
                  }
                  eightyEightLineAlreadyProcessed = true;
            }
            // Special handling for newly added lines from Truist that include the receiver. Only relevant for the 
            // 1016 account and for International Wires.
            if(line.startsWith(RECEIVER_LINE) && process == true && sixteenLinesBegun && reportingCode == TEN_SIXTEEN_REPORTING_CODE) {           
                List<String> moreSplits = line.split(',');
                Bank_Statement_Line_Item__c lastLine = linesForInsert.get(linesForInsert.size()-1);
                if(lastLine.Code__c == '508') { 
                    String receiverLineData = moreSplits[1];
                    lastLine.Reference__c = receiverLineData.substringAfter(' ').left(50);
                }
            }
        }
        insert linesForInsert;
    }
}