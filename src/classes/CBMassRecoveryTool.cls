public with sharing class CBMassRecoveryTool {
	private static final String budgetAppDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_APP_DIM);
	private static final String budgetAppAmountDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_APP_AMOUNT_DIM);
	private static final String budgetYearDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_YEAR_DIM);
	private static final String periodDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.PERIOD_DIM);
	private static final String budgetSubAppAmountDimId = cb4.CBUtils.dimensionNameIdMap.get('Budget App SubAmount');
	private static final Id currentBudgetYear = cb4.CBContext.getCurrentBY().Id;

	@AuraEnabled
	public static Map<String, String> getUsersVariableServer(){
		Map<String, String> r = new Map<String, String>();
		cb4__CBUserContext__c context = CBASHController.getUserContextServer();
		String byName = [SELECT Name FROM cb4__CBTag__c WHERE Id = :context.cb4__Tag1__c].Name;
		r.put('budgetYearId', context.cb4__Tag1__c);
		r.put('budgetYearName', byName);
		return r;
	}

	@AuraEnabled
	public static Map<String, List<cb4.CBSO>> getSOServer(){
		Map<String, List<cb4.CBSO>> r = new Map<String, List<cb4.CBSO>>();
		List<cb4.CBSO> budgetYears = CBASHController.getTagsSOServer(budgetYearDimId, null);
		List<cb4.CBSO> periods = CBASHController.getTagsSOServer(periodDimId, 'cb4__Tag1__c = \'' + CBASHController.getUserContextServer().cb4__Tag1__c + '\'');
		budgetYears.sort();
		periods.sort();
		r.put('budgetYears', budgetYears);
		r.put('periods', periods);
		return r;
	}

	@AuraEnabled
	public static List<cb4__CBTag__c> createCBTagServer(List<cb4__CBTag__c> tags){
		if (!tags.isEmpty()) {
			if (tags[0].cb4__Dimension__c == budgetAppDimId) {
				insert tags;
				update assignParents(getBudgetsServer());
			}
			else {
				insert assignParents(tags);
			}
		}
		return tags;
	}

	@AuraEnabled
	public static void deleteBudgetDataServer(String byId){
		delete [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetAppDimId AND cb4__Tag3__c = :byId];
		delete [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetSubAppAmountDimId AND cb4__Tag1__c = NULL];
	}

	@AuraEnabled
	public static List<cb4__CBTag__c> getBudgetsServer(){
		String filterMap = JSON.serialize(new Map<String, String>{
				'cb4__Tag3__c' => currentBudgetYear
		});
		return CBASHController.getTagListServer(budgetAppDimId, null, null, filterMap, false, null, null,
				'Id, '             +
						'Name, '                       +
						'cb4__Dimension__c, '          +
						'cb4__DimensionName__c, '      +
						'cb4__Status__c, '             +
						'cb4__Text4__c, '              +             // Last Approved/Rejected By
						'HasAccessToChangeStatus__c, ' +             // Next Approver
						'NextStatus__c, '              +
						'cb4__Text3__c, '              +             // Description
						'cb4__Boolean1__c, '           +             // Lock Budget (Individual Lock function)
						'cb4__User__c, '               +             // Locker User (Individual Lock function)
						'cb4__Boolean2__c, '           +             // Personnel Budget
						'cb4__Tag1__c, '               +             // Parent Budget
						'cb4__Tag1Name__c, '           +
						'cb4__Tag2__c, '               +             // Template
						'cb4__Tag2Name__c, '           +
						'cb4__isLocked__c, '           +
						'cb4__Tag3__c, '               +             // Budget Year
						'cb4__Tag3Name__c, '           +
						'cb4__Tag4__c, '               +             // Company (ASH, ASH-RC etc.)
						'cb4__Tag4Name__c, '           +
						'cb4__Tag6__c, '               +             // CB_FF1
						'cb4__Tag6Name__c, '           +
						'cb4__Tag7__c, '               +             // CB_FF2
						'cb4__Tag7Name__c, '           +
						'cb4__Decimal1__c, '           +             // Income
						'cb4__Decimal2__c, '           +             // Expense
						'cb4__Decimal3__c, '           +             // Total
						'cb4__Decimal6__c, '           +             // Budget Locker Value (Home Page component)
						'cb4__Index__c, '              +
						'cb4__OrderNumber__c, '        +
						'cb4__ExtId__c, '              +
						'OwnerId, '                    +
						'Owner.Name '
		);
	}

	@AuraEnabled
	public static List<cb4__CBTag__c> getBudgetLinesServer(List<String> appIds){
		String addedFilter = 'cb4__Text1__c != \'total\' AND cb4__Tag1__c IN ' + cb4.CBUtils.getFormattedINQuery(new Set<String>(appIds));
		return CBASHController.getTagListServer(budgetAppAmountDimId, addedFilter, null, null, false, null, 'cb4__Tag1Name__c',
				'Id, '                +
						'cb4__Dimension__c, '     +
						'cb4__DimensionName__c, ' +
						'cb4__Text1__c, '         +             // Section
						'cb4__Text2__c, '         +             // Type
						'cb4__Text3__c, '         +             // Title
						'cb4__Text4__c, '         +             // Description
						'cb4__Text5__c, '         +             // Style Class
						'cb4__Text6__c, '         +             // Comment
						'cb4__Tag1__c, '          +             // Budget
						'cb4__Tag1Name__c, '      +
						'cb4__Tag2__c, '          +             // Account
						'cb4__Tag2Name__c, '      +
						'cb4__Tag3__c, '          +             // Period
						'cb4__Tag3Name__c, '      +
						'cb4__Tag5__c, '          +             // SubAccount Code
						'cb4__Tag5Name__c, '      +
						'cb4__Tag6__c, '          +             // CB_FF1 (Department)
						'cb4__Tag6Name__c, '      +
						'cb4__Tag7__c, '          +             // CB_FF2 (Program)
						'cb4__Tag7Name__c, '      +
						'cb4__Tag8__c, '          +             // CB_FF3 (Project)
						'cb4__Tag8Name__c, '      +
						'cb4__Tag9__c, '          +             // CB_FF4 (Other)
						'cb4__Tag9Name__c, '      +
						'cb4__Boolean1__c, '      +             // Flag
						'cb4__Decimal1__c, '      +             // Value
						'cb4__ExtId__c, '         +
						'OwnerId, '               +
						'Owner.Name '
		);
	}

	@AuraEnabled
	public static List<cb4__CBTag__c> getBudgetSubLinesServer(List<String> appIds){
		String addedFilter = 'cb4__Tag1__c IN ' + cb4.CBUtils.getFormattedINQuery(new Set<String>(appIds));
		return CBASHController.getTagListServer(budgetSubAppAmountDimId, addedFilter, null, null, false, null, 'cb4__Tag1Name__c',
				'Id, '                +
						'cb4__Dimension__c, '     +
						'cb4__DimensionName__c, ' +
						'cb4__Text1__c, '         +             // Section
						'cb4__Text2__c, '         +             // Type
						'cb4__Text3__c, '         +             // Title
						'cb4__Text4__c, '         +             // Description
						'cb4__Text5__c, '         +             // Style Class
						'cb4__Text10__c, '        +             // SubLine Key
						'cb4__Tag1__c, '          +             // Budget
						'cb4__Tag1Name__c, '      +
						'cb4__Tag2__c, '          +             // Account
						'cb4__Tag2Name__c, '      +
						'cb4__Tag3__c, '          +             // Period
						'cb4__Tag3Name__c, '      +
						'cb4__Tag5__c, '          +             // SubAccount Code
						'cb4__Tag5Name__c, '      +
						'cb4__Tag6__c, '          +             // CB_FF1 (Department)
						'cb4__Tag6Name__c, '      +
						'cb4__Tag7__c, '          +             // CB_FF2 (Program)
						'cb4__Tag7Name__c, '      +
						'cb4__Tag8__c, '          +             // CB_FF3 (Project)
						'cb4__Tag8Name__c, '      +
						'cb4__Tag9__c, '          +             // CB_FF4 (Other)
						'cb4__Tag9Name__c, '      +
						'cb4__Boolean1__c, '      +             // Flag
						'cb4__Decimal1__c, '      +             // Value
						'cb4__ExtId__c, '         +
						'OwnerId, '               +
						'Owner.Name '
		);
	}

	/*Utils*/
	public static List<cb4__CBTag__c> assignParents(List<cb4__CBTag__c> tags){
		Boolean isNotBudget = tags[0].cb4__Dimension__c != budgetAppDimId;
		Map<String, String> dimsToBudgetTemplateId = new Map<String, String>();
		Map<String, String> dimsToBudgetTemplateOwnerId = new Map<String, String>();
		Id consolidatedBudgetId = null;
		for(cb4__CBTag__c bt : getBudgetsServer()){
			if(bt.cb4__Tag6__c == null && bt.cb4__Tag7__c == null && bt.Name.contains('Consolidated')) {
				consolidatedBudgetId = bt.Id;
			}else{
				dimsToBudgetTemplateId.put(isNotBudget? (String.valueOf(bt.cb4__Tag6__c) + String.valueOf(bt.cb4__Tag7__c)) : (String.valueOf(bt.cb4__Tag6__c) + String.valueOf(bt.cb4__Tag7__c) + String.valueOf(bt.cb4__Tag4__c)), bt.Id);
				dimsToBudgetTemplateOwnerId.put(isNotBudget? (String.valueOf(bt.cb4__Tag6__c) + String.valueOf(bt.cb4__Tag7__c)) : (String.valueOf(bt.cb4__Tag6__c) + String.valueOf(bt.cb4__Tag7__c) + String.valueOf(bt.cb4__Tag4__c)), bt.OwnerId);
			}
		}
		for(cb4__CBTag__c t : tags){
			if(isNotBudget){
				if(t.cb4__Tag6__c == null && t.cb4__Tag7__c == null){
					t.cb4__Tag1__c = consolidatedBudgetId;
				}else{
					t.cb4__Tag1__c = dimsToBudgetTemplateId.get(String.valueOf(t.cb4__Tag6__c) + String.valueOf(t.cb4__Tag7__c));
					if(t.cb4__Tag1__c == null) t.cb4__Tag1__c = dimsToBudgetTemplateId.get(String.valueOf(t.cb4__Tag6__c) + 'null');
					if(t.cb4__Dimension__c == budgetSubAppAmountDimId) t.cb4__Text10__c = getSimpleLineKey(t, null);
				}
				t.OwnerId = dimsToBudgetTemplateOwnerId.get(String.valueOf(t.cb4__Tag6__c) + String.valueOf(t.cb4__Tag7__c));
				if(t.OwnerId == null) t.OwnerId = dimsToBudgetTemplateOwnerId.get(String.valueOf(t.cb4__Tag6__c) + 'null');
				if(t.OwnerId == null) t.OwnerId = UserInfo.getUserId();
			}else{
				if(t.cb4__Tag6__c == null && t.cb4__Tag7__c == null && !t.Name.contains('Consolidated')){
					t.cb4__Tag1__c = consolidatedBudgetId;
				}else if(!t.Name.contains('Consolidated')){
					Id bId = dimsToBudgetTemplateId.get(t.cb4__Tag7__c == null ? ('nullnull' + String.valueOf(t.cb4__Tag4__c)) : ((String.valueOf(t.cb4__Tag6__c)) + 'null' + String.valueOf(t.cb4__Tag4__c)));
					if(bId == null && t.cb4__Tag6__c != null && t.cb4__Tag7__c != null) bId = dimsToBudgetTemplateId.get('nullnull' + t.cb4__Tag4__c);
					t.cb4__Tag1__c = t.Id != bId ? bId : null;
				}
			}
		}
		return tags;
	}

	private static String getSimpleLineKey(cb4__CBTag__c t, String bAppId) {
		return (t.cb4__Tag1__c == null ? (String.isNotBlank(bAppId) ? bAppId : t.cb4__Tag1__c) : t.cb4__Tag1__c) +
				(t.cb4__Text2__c == null ? '' : t.cb4__Text2__c.toLowerCase()) +
				(t.cb4__Text3__c == null ? '' : CBBudgetApplication.refineStringToId(t.cb4__Text3__c).toLowerCase()) + // replace spaces
				//(t.cb4__Text4__c == null ? '' : CBBudgetApplication.refineStringToId(t.cb4__Text4__c.left(100))) +
				(t.cb4__Tag2__c == null ? '' : t.cb4__Tag2__c) +
				(t.cb4__Tag4__c == null ? '' : t.cb4__Tag4__c) +
				//(t.cb4__Tag5__c == null ? '' : t.cb4__Tag5__c) +
				(t.cb4__Tag6__c == null ? '' : t.cb4__Tag6__c) +
				(t.cb4__Tag7__c == null ? '' : t.cb4__Tag7__c) +
				(t.cb4__Tag8__c == null ? '' : t.cb4__Tag8__c) +
				(t.cb4__Tag9__c == null ? '' : t.cb4__Tag9__c) +
				(t.cb4__Tag10__c == null ? '' : t.cb4__Tag10__c);
	}
	/*Utils*/

}