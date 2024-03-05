trigger JournalTrigger on c2g__codaJournal__c (after update) {

    if( Trigger.isAfter && trigger.isUpdate ) {

        List<c2g__codaJournalLineItem__c> journalLines = 
            [SELECT c2g__GeneralLedgerAccount__c, c2g__Dimension1__c, c2g__Dimension2__c, 
             c2g__Dimension3__c, c2g__Dimension4__c, c2g__LineType__c, c2g__OwnerCompany__c, c2g__DestinationCompany__c 
             FROM c2g__codaJournalLineItem__c 
             WHERE c2g__Journal__c IN :trigger.new];
        List<c2g__codaJournalLineItem__c> forUpdate = new List<c2g__codaJournalLineItem__c>();
        
        /** Allows the user to force pro-active validation on a journal's line against the list of 
         * active Combination Rules. We cannot wait for post-time to determine if a line is valid.
         */
        for(c2g__codaJournal__c journal : trigger.new)
        {
            if((Trigger.oldMap.get(journal.Id).Validate_Journal__c  != journal.Validate_Journal__c) && 
               journal.Validate_Journal__c == true) {
                   
                   ComboRuleProvider provider = ComboRuleProvider.getInstance();
                   for( c2g__codaJournalLineItem__c someLine : journalLines ) {
                       boolean valid = true;
                       if(someLine.c2g__LineType__c == 'Intercompany') {
                           valid = provider.validate(someLine.c2g__DestinationCompany__c,
                                                     someLine.c2g__GeneralLedgerAccount__c,
                                                     someLine.c2g__Dimension1__c, 
                                                     someLine.c2g__Dimension2__c,
                                                     someLine.c2g__Dimension3__c,
                                                     someLine.c2g__Dimension4__c);
                       } else {
                           valid = provider.validate(someLine.c2g__OwnerCompany__c, 
                                                     someLine.c2g__GeneralLedgerAccount__c,
                                                     someLine.c2g__Dimension1__c, 
                                                     someLine.c2g__Dimension2__c,
                                                     someLine.c2g__Dimension3__c, 
                                                     someLine.c2g__Dimension4__c);
                       }
                       if( valid == false ) {
                           someLine.Invalid__c = true; 
                           someLine.Validation_Timestamp__c = System.now();
                       } else {
                           // Necessary to 'reset' line items that were previously bad, but are now fixed.
                           someLine.Invalid__c = false;
                           someLine.Validation_Timestamp__c = System.now();
                       } 
                       forUpdate.add(someLine);
                   }                        
               }
        }
        update forUpdate;
    }
}