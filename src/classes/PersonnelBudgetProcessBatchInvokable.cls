public class PersonnelBudgetProcessBatchInvokable {
	@InvocableMethod(label='Process personnel budget batch' 
                   description='Process a personnel budget batch.' 
                   category='Budgeting')
    public static void invokeProcessPersonnelBatch(List<List<String>> params) {
        List<String> nestedParams = params.get(0);
        String batch = nestedParams.get(0);
        String company = nestedParams.get(1);
		Id batchJobId = Database.executeBatch(new PersonnelBudgetProcessBatch(batch, company));
  	}
}