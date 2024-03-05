public class RevalidateJournalsInvokable {
  @InvocableMethod(label='Revalidate journals' 
                   description='Seeks any JLIs that share this combo rule / combo rule line item and marks them as valid.' 
                   category='Journals')
    public static void invokeRevalidateJournals(List<List<String>> params) {
        final String IN_PROGRESS = 'In Progress';
        List<String> nestedParams = params.get(0);
        Id comboRuleLineItemId = nestedParams.get(0);
        
        c2g__CombinationRuleLineItem__c thisRule = [SELECT Id, c2g__Dimension1Value__c, c2g__Dimension2Value__c , 
                                                   c2g__Dimension3Value__c, c2g__Dimension4Value__c, 
                                                   c2g__CombinationRule__r.c2g__Company__c, 
                                                   c2g__CombinationRule__r.c2g__GeneralLedgerAccount__c 
                                                   FROM c2g__CombinationRuleLineItem__c WHERE Id = :comboRuleLineItemId];
        
        List<c2g__codaJournalLineItem__c> results = [SELECT Id, Invalid__c 
			FROM c2g__codaJournalLineItem__c 
            WHERE c2g__Dimension1__c = :thisRule.c2g__Dimension1Value__c AND c2g__Dimension2__c = :thisRule.c2g__Dimension2Value__c 
            AND c2g__Dimension3__c = :thisRule.c2g__Dimension3Value__c AND c2g__Dimension4__c = :thisRule.c2g__Dimension4Value__c 
            AND c2g__GeneralLedgerAccount__c = :thisRule.c2g__CombinationRule__r.c2g__GeneralLedgerAccount__c
			AND (c2g__Journal__r.c2g__OwnerCompany__c = :thisRule.c2g__CombinationRule__r.c2g__Company__c 
			OR c2g__DestinationCompany__c = :thisRule.c2g__CombinationRule__r.c2g__Company__c)
			AND c2g__Journal__r.c2g__JournalStatus__c = :IN_PROGRESS];
        
        List<c2g__codaJournalLineItem__c> forUpdate = new List<c2g__codaJournalLineItem__c>();
        for(c2g__codaJournalLineItem__c journalLine : results) {
            journalLine.Invalid__c = false;
            forUpdate.add(journalLine);
        }
        update forUpdate;
    }   
}