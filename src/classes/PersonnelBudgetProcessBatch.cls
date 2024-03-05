global class PersonnelBudgetProcessBatch implements Database.Batchable<sObject> {
    
    String batchId;
    String company;
    
    public PersonnelBudgetProcessBatch(String batchId, String company) {
        this.batchId = batchId;
        this.company = company;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) { 
        
        String query = 'SELECT Id, Amount__c, Budget_Position__c, Budget_Position__r.Accounting_Company__c, ' + 
            'Period__c, Type__c, Budget_Position__r.Program__r.c2g__ReportingCode__c, Period__r.PerPost__c ' + 
            'FROM Personnel_Cost_Record__c WHERE Personnel_Budget_Batch__c = :batchId';
		return Database.getQueryLocator(query);
    }

    /**
     * This code effectively rolls up all of the previously generated Personnel Cost records (see: PersonnelBudgetStageBatch) into 
     * Reporting Balances of type 'Budget'. 
     * This task is challenging, because FF only allows a single Reporting Balance of a particular type per Period - no duplicates.
     * ----
     * 9030-302-Program-000-00. This is the budget code for all salaries.
	 * 9035-302-program-000-26. This is for Medical, Dental and Vision.
	 * 9035-302-Program-000-31. This is for Life and Long Term Disability insurance.
	 * 9035-302-Program-000-34. Retirement benefits (10% for each employee based on their eligibility date).
	 * 7500-302-Program-000-00. This is for employer paid taxes.
	 * 5560-302-Program-000-00. This is for executive employee bonuses.
	 * 9045-302-Program-000-00. This is for a bonus pool for all staff. 
	 */
    global void execute(Database.BatchableContext BC, List<Personnel_Cost_Record__c> costRecords) {

        FfaDataProvider provider = FfaDataProvider.getInstance();
        
		Map<String, String> glMappings = new Map<String, String>();
        glMappings.put('Base Salary', '9030');
        glMappings.put('Bonus', '5560');        
        glMappings.put('Medical, Dental, Vision', '9035');
        glMappings.put('Life and AD&D', '9035');
        glMappings.put('Long-Term Disability', '9035');
        glMappings.put('403b', '9035');
        glMappings.put('FICA', '7500');
        glMappings.put('FUTA', '7500');
        glMappings.put('SUTA', '7500');
        glMappings.put('Medicare', '7500');
        glMappings.put('PFML', '7500');
        
        Map<String, String> otherMappings = new Map<String, String>();
        otherMappings.put('Base Salary', '00');
        otherMappings.put('Bonus', '00');        
        otherMappings.put('Medical, Dental, Vision', '26');
        otherMappings.put('Life and AD&D', '31');
        otherMappings.put('Long-Term Disability', '31');          
        otherMappings.put('403b', '34');
        otherMappings.put('FICA', '00');
        otherMappings.put('FUTA', '00');
        otherMappings.put('SUTA', '00');
        otherMappings.put('Medicare', '00');
        otherMappings.put('PFML', '00');

        List<Personnel_Budget_Stager__c> stagers = [SELECT Account_Subaccount__c, Period__c, Amount__c
                                                    FROM Personnel_Budget_Stager__c
                                                   	WHERE Personnel_Budget_Batch__c = :batchId];
        
        Map<String, Personnel_Budget_Stager__c> preInsert = new Map<String, Personnel_Budget_Stager__c>();         
        for ( Personnel_Budget_Stager__c someStager : stagers ) {
            preInsert.put(someStager.Account_Subaccount__c+'-'+someStager.Period__c, someStager);            
        }
        
        for( Personnel_Cost_Record__c someCostRecord : costRecords ) {
            System.debug(someCostRecord);
            Id budgetPositionId = someCostRecord.Budget_Position__r.Id;

            String accountSubaccount = glMappings.get(someCostRecord.Type__c) + '-302-' + 
                someCostRecord.Budget_Position__r.Program__r.c2g__ReportingCode__c + '-000-' + 
                otherMappings.get(someCostRecord.Type__c);
            String account = glMappings.get(someCostRecord.Type__c);
            String subaccount = '302' + someCostRecord.Budget_Position__r.Program__r.c2g__ReportingCode__c + 
                '000' + otherMappings.get(someCostRecord.Type__c);
            String period = someCostRecord.Period__r.PerPost__c;
            Personnel_Budget_Stager__c stager = preInsert.get(accountSubaccount + '-' + period);
            if(stager == null) {   
                stager = new Personnel_Budget_Stager__c();
                stager.Period__c = period;
                stager.Company__c = company;
                stager.Accounting_Company__c = someCostRecord.Budget_Position__r.Accounting_Company__c;
                stager.Quarter__c = getQuarter(period);
                stager.Program__c = someCostRecord.Budget_Position__r.Program__r.c2g__ReportingCode__c;
                stager.Amount__c = someCostRecord.Amount__c;
                stager.Type__c = 'Regular';
                stager.Personnel_Budget_Batch__c = batchId;
                stager.General_Ledger_Account__c = provider.getGlaCode(glMappings.get(someCostRecord.Type__c));
                stager.Dimension_1__c = provider.getDimension1('302');
                stager.Dimension_2__c = provider.getDimension2(someCostRecord.Budget_Position__r.Program__r.c2g__ReportingCode__c);
                stager.Dimension_3__c = provider.getDimension3('000');
                stager.Dimension_4__c = provider.getDimension4(otherMappings.get(someCostRecord.Type__c));                
                preInsert.put(accountSubaccount + '-' + period, stager);
            }
            else {
                stager.Amount__c += someCostRecord.Amount__c;
            }
        }

        List<Personnel_Budget_Stager__c> forUpsert = preInsert.values();
        upsert forUpsert;
    }
    
    private static String getQuarter(String period) {
        if(period.right(2) == '01' || period.right(2) == '02' || period.right(2) == '03') {
            return 'Q1';  
        } 
        else if
        (period.right(2) == '04' || period.right(2) == '05' || period.right(2) == '06') {
            return 'Q2';              
        }
        else if
        (period.right(2) == '07' || period.right(2) == '08' || period.right(2) == '09') {
            return 'Q3';          
        }
        else if
        (period.right(2) == '10' || period.right(2) == '11' || period.right(2) == '12') {
            return 'Q4';          
        }     
        else return '00';
    }

    global void finish(Database.BatchableContext bc) { }
}