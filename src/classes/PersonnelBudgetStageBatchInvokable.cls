public class PersonnelBudgetStageBatchInvokable {
	@InvocableMethod(label='Stage personnel budget batch' 
                   description='Process a personnel budget batch.' 
                   category='Budgeting')
    public static void invokeStagePersonnelBatch(List<List<String>> params) {
        List<String> nestedParams = params.get(0);
        String batch = nestedParams.get(0);
		Id batchJobId = Database.executeBatch(new PersonnelBudgetStageBatch(batch));
  	}
}