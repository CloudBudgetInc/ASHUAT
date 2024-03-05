@isTest(SeeAllData=true)
public class PersonnelBudgetProcessBatchTest {

    /**
     * Basic test to get this deployed to production, mostly for storage/continuity needs: 
     * note that this code will typically execute in Sandbox due to data visibility considerations.
     */    
	public static testmethod void testBasics() {
        
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id company = provider.getCompany('ASH');
        Id department = provider.getDimension1('115');
        Id program = provider.getDimension2('364');          
        
        Budget_Position__c budgetPosition = new Budget_Position__c(
            Accounting_Company__c = company, 
            Department__c = department,
            Program__c = program,
        	Annual_Salary__c = 120000.00, 
            Bonus__c = 5000.00, 
            Bonus_Date__c = Date.newInstance(2024, 08, 01),
            Review_Date__c = Date.newInstance(2024, 10, 01), 
			Hire_Date__c = Date.newInstance(2021, 04, 01),
            Targeted_Increase__c = .015,
            Medical_Dental_and_Vision__c = 2500.00, 
            Benefits_Eligible__c = true,
            Executive_Disability_Amount__c = 0.00,
            Employer_457b_Contributions__c = 5600.00,
            Employee_Name__c = 'Ronald McDonald');
        insert budgetPosition;        
        
		Personnel_Budget_Batch__c someBatch = new Personnel_Budget_Batch__c(Year__c = '2024');
        insert someBatch;
        
		Personnel_Cost_Record__c someCostRecord = new Personnel_Cost_Record__c(
            Personnel_Budget_Batch__c = someBatch.Id,
			Amount__c = 100000.00,
            Budget_Position__c = budgetPosition.Id,
            Period__c = provider.getPeriod('ASH', '202402').Id,
            Type__c = 'Base Salary');
        insert someCostRecord;
        
        Test.startTest();
        PersonnelBudgetProcessBatch pbpb = new PersonnelBudgetProcessBatch(someBatch.Id, 'ASH');
        Id jobid = Database.executeBatch(pbpb, 1);
        Test.stopTest();        
        
    }
}