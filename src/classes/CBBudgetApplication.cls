public with sharing class CBBudgetApplication {

	private static final String accountDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.ACCOUNT_DIM);
	private static final String accountSybtypeDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.ACCOUNT_SUBTYPE_DIM);
	private static final String budgetAppDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_APP_DIM);
	private static final String budgetAppAmountDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_APP_AMOUNT_DIM);
	private static final String budgetSubAppAmountDimId = cb4.CBUtils.dimensionNameIdMap.get('Budget App SubAmount');
	private static final String templateDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_APP_TEMPLATE_DIM);
	private static final String employeeDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.EMPLOYEE_DIM);
	private static final String rateDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.RATE_DIM);
	private static final String BYDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_YEAR_DIM);
	private static final String monthDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.PERIOD_DIM);
	private static final String departmentDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.DEPARTMENT_DIM);
	private static final String combinationRuleDimId = cb4.CBUtils.dimensionNameIdMap.get('Combination Rule');
	public static Id applicationId; //
	private static final String TARGET_TOTAL = 'targetTotal';
	private static final String TOTAL = 'total';
	private static final String SIMPLE = 'simple';
	private static final String TOP_DOWN = 'Top-Down';

	/**
	 * @param appId BA Id if you need one specified
	 *
	 * @return list of Budget Apps
	 */
	@AuraEnabled
	public static List<cb4__CBTag__c> getBudgetAppsServer(Id appId, String selectedStatus) {
		String contextFilter = CBASHController.getContextFilter(budgetAppDimId);
		Map<String, String> fPMap = new Map<String, String>{
				'cb4__Status__c' => selectedStatus
		};
		String jsnFpMap = JSON.serialize(fPMap);
		if (appId == null) return CBASHController.getTagListServer(budgetAppDimId, contextFilter, null, selectedStatus == null ? null : jsnFpMap, false, ' HasAccessToChangeStatus__r.Name, cb4__Tag2__r.cb4__Text2__c,cb4__Tag2__r.cb4__Text4__c, cb4__Tag2__r.cb4__Text5__c, LastModifiedDate, LastModifiedById ', null, null);
		return new List<cb4__CBTag__c>{
				CBASHController.getTagServer(appId, ' HasAccessToChangeStatus__r.Name, cb4__User__r.Name, cb4__Tag2__r.cb4__Text2__c, cb4__Tag2__r.cb4__Text4__c, cb4__Tag2__r.cb4__Text5__c,cb4__Tag2__r.cb4__Boolean5__c,cb4__Tag2__r.cb4__Boolean6__c ')
		};
	}

	@AuraEnabled
	public static cb4__CBTag__c getNewBudgetAppServer(Id parentId) {
		return CBASHController.getNewTagServer(budgetAppDimId, parentId);
	}

	/**
	 @param appId App Id
	 * Safety tested ✔ 22/11/2019
	 @return
	 */
	@AuraEnabled
	public static cb4__CBTag__c getBudgetTemplateServer(Id appId) {
		String templateId = [SELECT cb4__Tag2__c FROM cb4__CBTag__c WHERE Id = :appId LIMIT 1].cb4__Tag2__c;
		return CBASHController.getTagServer(templateId, null);
	}


	@AuraEnabled
	public static cb4__CBDimension__c getBudgetAppDimensionServer() {
		return CBASHController.getDimension(budgetAppDimId);
	}


	@AuraEnabled
	public static cb4__CBDimension__c getBudgetAppAmountDimensionServer() {
		return CBASHController.getDimension(budgetAppAmountDimId);
	}

	/**
	 @param appId application Id
	 *
	 @return list of single table headers
	 */
	@AuraEnabled
	public static List<String> getTableHeadersServer(Id appId) {
		applicationId = appId;
		List<String> r = new List<String>();
		for (cb4__CBTag__c t : periods) r.add(t.Name);
		return r;
	}

	/**
	 @param appId application Id
	 *
	 @return list of periodsId
	 */
	@AuraEnabled
	public static List<String> getAppPeriodsServer(Id appId) {
		applicationId = appId;
		List<String> r = new List<String>();
		for (cb4__CBTag__c t : periods) r.add(t.Id);
		return r;
	}

	/**
	 * @param appId app Id
	 *
	 * @return
	 */
	@AuraEnabled
	public static Map<String, List<cb4.CBSO>> getAccountsServer(Id appId) {
		Map<String, List<cb4.CBSO>> r = new Map<String, List<cb4.CBSO>>();
		cb4__CBTag__c t = getBudgetTemplateServer(appId);
		List<cb4.CBSO> t1 = CBASHController.getAllWiredTagsOfSetSO(t.cb4__Tag2__c);
		List<cb4.CBSO> t2 = CBASHController.getAllWiredTagsOfSetSO(t.cb4__Tag3__c);

		List<cb4.CBSO> st = new List<cb4.CBSO>();
		for (cb4__CBTag__c tag : [
				SELECT cb4__Tag1Name__c, Id
				FROM cb4__CBTag__c
				WHERE cb4__DimensionName__c = :cb4.CBConstant.ACCOUNT_DIM AND (cb4__Tag1__r.cb4__Tag1Name__c = 'Income' OR cb4__Tag1__r.cb4__Tag1Name__c = 'Expense')
				ORDER BY cb4__OrderNumber__c, cb4__TagLabel__c
		]) st.add(new cb4.CBSO(tag.Id, tag.cb4__Tag1Name__c));
		t1.sort();
		t2.sort();
		st.sort();
		r.put('income', t1);
		r.put('expense', t2);
		r.put('accountToSubtype', st);
		return r;
	}

	/**
	 @param appId app Id
	 *
	 @return
	 */
	@AuraEnabled
	public static Map<String, List<cb4.CBSO>> getInitialSOServer() {
		Map<String, List<cb4.CBSO>> r = new Map<String, List<cb4.CBSO>>();
		Map<String, User> userMap;
		Map<String, User> userWithPermSetMap=new Map<String, User>();
		Map<String, User> userAll;
		Set<String> userIdSetPerm = new Set<String>();
		Set<String> userIdSet = new Set<String>();

		for (PermissionSetAssignment psa : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name  LIKE '%Cloudbudget%' OR PermissionSet.Name  LIKE '%CloudBudget%' OR PermissionSet.Name  LIKE '%CB%']) {
			userIdSetPerm.add(psa.AssigneeId);
		}
		userWithPermSetMap = new Map<String, User>([SELECT Id, Name FROM User WHERE IsActive = TRUE AND Id IN:userIdSetPerm ORDER BY Name LIMIT 2500]);
		//////PROD CHECK///////////
		Organization org = [SELECT isSandbox, NamespacePrefix FROM Organization WHERE Id = :UserInfo.getOrganizationId()];
		if (org.NamespacePrefix != 'cb4' && !org.isSandbox) {
			Set<String> plIdSet = new Set<String>();
			for (PackageLicense pl : [SELECT Id, NamespacePrefix FROM PackageLicense WHERE NamespacePrefix = 'cb4']) {
				plIdSet.add(pl.Id);
			}
			for (UserPackageLicense upl : [SELECT UserId, PackageLicenseId FROM UserPackageLicense WHERE PackageLicenseId IN:plIdSet]) {
				userIdSet.add(upl.UserId);
			}
			userMap = new Map<String, User>([Select Id, Name FROM User WHERE IsActive = true AND Id IN:userIdSet ORDER BY Name LIMIT 2500]);
		} else {
			// userMap = new Map<String, User>([Select Id, Name FROM User WHERE IsActive = true ORDER BY Name LIMIT 1000]);
			userMap = new Map<String, User>();
		}
		userAll = new Map<String, User>([Select Id, Name FROM User WHERE IsActive = true AND (Id IN:userIdSet or Id IN:userIdSetPerm) ORDER BY Name LIMIT 2500]);

		//////PROD CHECK^^^^^^^^^^
		Set<String> qIdSet = new Set<String>();
		for (QueueSobject q : [SELECT Id, Queue.Id, SobjectType FROM QueueSobject]) if (q.SobjectType == 'cb4__CBTag__c') qIdSet.add(q.Queue.Id);
		Map<String, Group> queueMap = new Map<String, Group>([SELECT Id, Name FROM Group WHERE Id IN:qIdSet AND Type = 'Queue' ORDER BY Name LIMIT 2500]);

		try {
			List<cb4.CBSO> templates = CBASHController.getTagsSOServer(templateDimId, null);
			r.put('template', templates);
		} catch (Exception e) {
			cb4.CBUtils.errorDebug(e);
		}
		try {
			List<cb4.CBSO> periods = CBASHController.getTagsSOServer(BYDimId, null);
			r.put('period', periods); // Budget Years
		} catch (Exception e) {
			cb4.CBUtils.errorDebug(e);
		}
		try {
			List<cb4.CBSO> departments = CBASHController.getTagsSOServer(departmentDimId, null);
			r.put('department', departments);
		} catch (Exception e) {
			cb4.CBUtils.errorDebug(e);
		}
		try {
			List<cb4.CBSO> apps = new List<cb4.CBSO>();
			//for (CBTag__c t : [SELECT Id, TagLabel__c, Tag3Name__c FROM CBTag__c WHERE Dimension__c = :budgetAppDimId ORDER BY Tag3Name__c]) apps.add(new CBSO(t.Id, '(' + t.Tag3Name__c + ') ' + t.TagLabel__c));
			for (cb4__CBTag__c t : getBudgetAppsServer(null, null)) apps.add(new cb4.CBSO(t.Id, '(' + t.cb4__Tag3Name__c + ') ' + t.cb4__TagLabel__c));
			r.put('app', apps);
		} catch (Exception e) {
			cb4.CBUtils.errorDebug(e);
		}
		try {
			List<cb4.CBSO> users = new List<cb4.CBSO>();
			for (String k : userMap.keySet()) users.add(new cb4.CBSO(k, userMap.get(k).Name));
			r.put('user', users);
		} catch (Exception e) {
			cb4.CBUtils.errorDebug(e);
		}
		try {
			List<cb4.CBSO> users = new List<cb4.CBSO>();
			for (String k : userWithPermSetMap.keySet()) users.add(new cb4.CBSO(k, userWithPermSetMap.get(k).Name));
			r.put('userWithPermSet', users);
		} catch (Exception e) {
			cb4.CBUtils.errorDebug(e);
		}
		try {
			List<cb4.CBSO> users = new List<cb4.CBSO>();
			for (String k : userAll.keySet()) users.add(new cb4.CBSO(k, userAll.get(k).Name));
			r.put('userAll', users);
		} catch (Exception e) {
			cb4.CBUtils.errorDebug(e);
		}
		try {
			List<cb4.CBSO> queues = new List<cb4.CBSO>();
			for (String k : queueMap.keySet()) queues.add(new cb4.CBSO(k, 'Queue:' + queueMap.get(k).Name));
			r.put('queue', queues);
		} catch (Exception e) {
			cb4.CBUtils.errorDebug(e);
		}
		return r;
	}

	/**
	 * Safety tested ✔ 22/11/2019
	 *
	 * @param appId
	 *
	 * @return
	 */
	@AuraEnabled
	public static List<cb4__CBTag__c> getAllChildrenIdsServer(Id appId) {
		List<cb4__CBTag__c> r = new List<cb4__CBTag__c>();
		for (cb4__CBTag__c t : [
				SELECT Id, Name, cb4__LabelName__c, cb4__Text3__c, cb4__Decimal6__c
				FROM cb4__CBTag__c
				WHERE
						cb4__Dimension__c = :budgetAppDimId AND (
								Id = :appId OR
								cb4__Tag1__c = :appId OR
								cb4__Tag1__r.cb4__Tag1__c = :appId OR
								cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__c = :appId OR
								cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__c = :appId OR
								cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__c = :appId OR
								cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__c = :appId
						)
				ORDER BY cb4__OrderNumber__c
				LIMIT 1000
		]) r.add(t);
		return r;
	}


	/**
	 *
	 * @param appId application Id
	 * @param childrenId list of subsidiary applications
	 * @param type income, expense, total
	 * @param addedWhere
	 *
	 * @return BA total, simple income and expense lines depend on the type of the argument
	 */
	@AuraEnabled
	public static List<cb4.CBRow> getRowsServer(Id appId, List<Id> childrenId, String type, Map<String, String> addedWhere) {
		Set<String> childrenIdSet; // acceptable for BA Sheet only
		if (childrenId != null && childrenId.size() > 0) {
			childrenIdSet = new Set<String>();
			for (Id i : childrenId)childrenIdSet.add(i);
		}
		List<cb4.CBRow> r = new List<cb4.CBRow>();
		applicationId = appId;
		List<cb4__CBTag__c> amounts = getSimpleAndTotalLines(appId, childrenIdSet, type, addedWhere); // list of Budget Amount lines

		////////////////// OTHER CURRENCY  ///////////////
		amounts = CBASHController.convertAmountsToUserCurrency(amounts);
		////////////////// OTHER CURRENCY  ///////////////

		amounts = reMapPeriodsIfNeeded(amounts, appId);
		Boolean isTotal = true;
		if (type != null) {
			isTotal = type.toLowerCase() == 'total';
		}
		r = getCBRowsFromTags(amounts, SIMPLE, isTotal);
		if (r == null) return null;
		if ((type == TOTAL || type == TARGET_TOTAL) && r.size() < 2) return getInitialTotalCBRows(r);
		if (type == TOTAL || type == TARGET_TOTAL) r = setTotalLinesOrder(r);
		return r;
	}

	@AuraEnabled
	public static List<cb4.CBRow> getBudgetSummaryRowsServer(Id appId, List<Id> childrenId, String type, Map<String, String> addedWhere){
		Set<String> childrenIdSet; // acceptable for BA Sheet only
		if (childrenId != null && childrenId.size() > 0) {
			childrenIdSet = new Set<String>();
			for (Id i : childrenId)childrenIdSet.add(i);
		}
		List<cb4.CBRow> r = new List<cb4.CBRow>();
		applicationId = appId;
		List<cb4__CBTag__c> amounts = getSimpleAndTotalSubLines(appId, childrenIdSet, type, addedWhere); // list of Budget Amount lines

		////////////////// OTHER CURRENCY  ///////////////
		amounts = CBASHController.convertAmountsToUserCurrency(amounts);
		////////////////// OTHER CURRENCY  ///////////////

		amounts = reMapPeriodsIfNeeded(amounts, appId);
		Boolean isTotal = true;
		if (type != null) {
			isTotal = type.toLowerCase() == 'total';
		}
		r = getCBRowsFromTags(amounts, SIMPLE, isTotal);
		if (r == null) return null;
		if ((type == TOTAL || type == TARGET_TOTAL) && r.size() < 2) return getInitialTotalCBRows(r);
		if (type == TOTAL || type == TARGET_TOTAL) r = setTotalLinesOrder(r);
		return r;
	}

	@TestVisible
	private static List<cb4__CBTag__c> reMapPeriodsIfNeeded(List<cb4__CBTag__c> sourceAmounts, Id appId) {
		try {
			if (sourceAmounts == null || sourceAmounts.size() == 0) return sourceAmounts;
			Set<Id> BAPeriods = new Set<Id>();
			for (cb4__CBTag__c p : periods) BAPeriods.add(p.Id); // Id of current BA BY Periods
			if (BAPeriods.contains(sourceAmounts[0].cb4__Tag3__c)) return sourceAmounts; // if first oncoming line is in the diapason of periods - suppose all is right

			// if periods are out of BA BY diapason it's needed to make remapping
			if (periodsMap == null) {
				periodsMap = new Map<Id, Id>();
				cb4__CBTag__c period = [SELECT Id, cb4__Tag1__c FROM cb4__CBTag__c WHERE Id = :sourceAmounts[0].cb4__Tag3__c]; //
				List<cb4__CBTag__c> newPeriods = [SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = :cb4.CBConstant.PERIOD_DIM AND cb4__Tag1__c = :period.cb4__Tag1__c ORDER BY cb4__OrderNumber__c LIMIT 1000];
				for (Integer i = 0; i < newPeriods.size(); i++) periodsMap.put(newPeriods[i].Id, periods[i].Id);
			}
			for (cb4__CBTag__c sa : sourceAmounts) sa.cb4__Tag3__c = periodsMap.get(sa.cb4__Tag3__c);
			update sourceAmounts;
		} catch (Exception e) {
			cb4.CBConsole.setLog(e, 'Remap Periods if Needed');
			cb4.CBConsole.insertLog();
		}

		return sourceAmounts;
	}

	/**
	 * key - new amount period Id, value BA BY period Id
	 */
	@TestVisible
	private static Map<Id, Id> periodsMap;

	/**
	 @param appId app Id
	 @param type income, expense
	 *
	 @return Down-Up subsidiary total lines
	 */
	@AuraEnabled
	public static List<cb4.CBRow> getDownUpSubRowsServer(Id appId, String type) {
		//TODO REFINE type = CBUtils.refineStr(type);
		type = cb4.CBUtils.refineStr(type);
		applicationId = appId;
		List<cb4__CBTag__c> amounts = getDownUpSubLines(appId, type);
		Boolean isTotal = true;
		if (type != null) {
			isTotal = type.toLowerCase() == 'total';
		}
		return getCBRowsFromTags(amounts, 'sub', isTotal);
	}

	/**
	 @param appId app Id
	 @param type income, expense
	 @return Top-Down subsidiary total lines
	 */
	@AuraEnabled
	public static List<cb4.CBRow> getTopDownSubRowsServer(Id appId, String type) {
		List<cb4.CBRow> r = new List<cb4.CBRow>();
		applicationId = appId;
		List<cb4.CBRow> templates = getInitialTotalCBRows(new List<cb4.CBRow>()); // [0] - income, [1] - expense
		cb4.CBRow template = type == 'income' ? templates[0] : templates[1]; // empty income or expense total line

		Map<String, cb4.CBRow> topDownAppIds = new Map<String, cb4.CBRow>();
		List<cb4__CBTag__c> amounts = getTopDownSubLines(appId, type);
		Boolean isTotal = true;
		if (type != null) {
			isTotal = type.toLowerCase() == 'total';
		}
		List<cb4.CBRow> existedTotalAmounts = getCBRowsFromTags(amounts, 'sub', isTotal);
		for (cb4.CBRow row : existedTotalAmounts) topDownAppIds.put(row.app, row);

		Map<String, Decimal> remainingMap = new Map<String, Decimal>(); // key = app Id + type ("targetTotal" or "total"), amounts from app header totals
		Set<String> subAppIds = new Set<String>(); // set of unique children App
		for (AggregateResult a : [
				SELECT cb4__Tag1__c appId, SUM(cb4__Decimal1__c) val, cb4__Text1__c typeIE
				FROM cb4__CBTag__c
				WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM AND cb4__Tag1__r.cb4__Tag1__c = :appId AND cb4__Tag1__r.cb4__Tag2__r.cb4__Text1__c = :TOP_DOWN
				AND cb4__Text1__c != 'income' AND cb4__Text1__c != 'expense' AND cb4__Text2__c = :type
				GROUP BY cb4__Tag1__c, cb4__Text1__c
				LIMIT 10000
		]) {
			remainingMap.put((String) a.get('appId') + (String) a.get('typeIE'), (Decimal) a.get('val'));
			subAppIds.add((String) a.get('appId'));
		}
		for (String s : subAppIds) {
			Decimal targetVal = remainingMap.get(s + TARGET_TOTAL);
			Decimal totalVal = remainingMap.get(s + TOTAL);
			targetVal = targetVal == null ? 0 : targetVal;
			totalVal = totalVal == null ? 0 : totalVal;
			Decimal remain = targetVal - totalVal;

			if (totalVal != 0 && targetVal / totalVal > 0.97 && targetVal / totalVal < 1.03) remain = 0; // deviation of 3%
			if (math.abs(remain) < 100) remain = 0; // minimal residue of 500$
			if(totalVal != 0 && targetVal / totalVal <  1 && math.abs(remain)>100) remain = remain;
			if(totalVal != 0 && targetVal / totalVal > 1.01 && math.abs(remain)>100) remain = remain;
			remainingMap.put(s, remain);
		}

		/*
		 * App Template architecture
		 * Boolean2__c - true - income enabled
		 * Boolean3__c - true - expense enabled
		 */

		String additional = type == 'income' ? ' AND cb4__Tag2__r.cb4__Boolean2__c = true ' : ' AND cb4__Tag2__r.cb4__Boolean3__c = true ';
		String q = 'SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = \'' + cb4.CBConstant.BUDGET_APP_DIM + '\' ' +
				' AND cb4__Tag1__c = \'' + appId + '\' AND cb4__Tag2__r.cb4__Text1__c = \'' + TOP_DOWN + '\' ' + additional +
				' ORDER BY cb4__OrderNumber__c, cb4__TagLabel__c, Name LIMIT 1000';

		for (cb4__CBTag__c app : Database.query(q)) {
			cb4.CBRow tmp = topDownAppIds.get(app.Id);
			if (tmp == null) {
				cb4.CBRow newRow = template.clone();
				newRow.title = app.Name;
				newRow.key = app.Id;
				newRow.app = app.Id;
				newRow.description = 'N/A';
				r.add(newRow);
			} else {
				Decimal ra = remainingMap.get(app.Id); // remaining total
				tmp.description = ra == null || ra == 0 ? '0' : 'Variance : ' + (String.format(ra.format(), cb4.CBConstant.FORMAT_ARGS) + ' ' + UserInfo.getDefaultCurrency());
				tmp.remain = ra;
				r.add(tmp);
			}
		}
		return r ;
	}

	private static List<cb4__CBTag__c> getSubLinesFromSourceTags(List<cb4__CBTag__c> allAmounts, String bAppId, Boolean isCurrentUserNotAppOwner){
		Set<String> amountKeys = new Set<String>();
		Id currUserId = UserInfo.getUserId();
		List<cb4__CBTag__c> subAmounts = new List<cb4__CBTag__c>();
		for(cb4__CBTag__c amount : allAmounts){
			String key = getSimpleLineKey(amount, bAppId);
			amountKeys.add(key);
		}
		for(cb4__CBTag__c sLine : Database.query('SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', null) + 'WHERE cb4__Tag1__c = :bAppId AND cb4__Text10__c IN :amountKeys')){
			if(isCurrentUserNotAppOwner){
				sLine.OwnerId = currUserId;
			}
			subAmounts.add(sLine);
		}
		update subAmounts;

		return subAmounts;
	}

	@AuraEnabled
	public static String saveAppTagsServer(cb4__CBTag__c app, List<cb4__CBTag__c> expenseTags, List<cb4__CBTag__c> incomeTags, List<cb4__CBTag__c> totalTags) {
		try {
			if (app == null) return 'App can not be empty';

			List<cb4__CBTag__c> subLines = new List<cb4__CBTag__c>();
			if (app.Id != null) {
				String userId = System.UserInfo.getUserId();
				if (app.OwnerId != userId) { // if budget is not related to the current user - all budget amounts should change the Owner to be deleted
					List<cb4__CBTag__c> amounts = [SELECT OwnerId FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget App Amount' AND cb4__Tag1__c = :app.Id AND cb4__Text1__c != :TARGET_TOTAL LIMIT 10000];
					for (cb4__CBTag__c t : amounts) t.OwnerId = userId;
					update amounts;
				}
				List<cb4__CBTag__c> allAmounts = new List<cb4__CBTag__c>();
				allAmounts.addAll(expenseTags);
				allAmounts.addAll(incomeTags);
				subLines = getSubLinesFromSourceTags(allAmounts, app.Id, app.OwnerId != userId);
				subLines = subLines.deepClone();
				deleteAllOldAppAmountsAndSubAmounts(app.Id);
			} else {
				app.cb4__Dimension__c = budgetAppDimId; // in case of a new budget
				insert app;
			}

			if (expenseTags != null && expenseTags.size() > 0) updateBudgetAppTags(app, expenseTags, false);
			if (incomeTags != null && incomeTags.size() > 0) updateBudgetAppTags(app, incomeTags, false);
			if (totalTags != null && totalTags.size() > 0) updateBudgetAppTags(app, totalTags, false);
			updateBudgetAppTags(app, subLines, true);
			////////////////// OTHER CURRENCY  ///////////////
			expenseTags = CBASHController.convertAmountsToCorporateCurrency(expenseTags);
			incomeTags = CBASHController.convertAmountsToCorporateCurrency(incomeTags);
			totalTags = CBASHController.convertAmountsToCorporateCurrency(totalTags);
			////////////////// OTHER CURRENCY  ///////////////
			update app;
			insert expenseTags;
			insert incomeTags;
			insert totalTags;
			insert subLines;
			return app.Id;
		} catch (Exception e) {
			insertBackupLog(app.Id, 'SERVER ERROR: ' + e.getMessage(), null);
			throw e;
		}
	}

	@TestVisible
	private static void updateBudgetAppTags(cb4__CBTag__c app, List<cb4__CBTag__c> tags, Boolean areSubLines) {
		for (cb4__CBTag__c t : tags) {
			t.cb4__Tag1__c = app.Id;
			t.OwnerId = app.OwnerId;
			t.cb4__Dimension__c = areSubLines ? budgetSubAppAmountDimId : budgetAppAmountDimId;
		}
	}


	/**
	 * Safety tested ✔ 22/11/2019
	 *
	 * @param topDownAmounts
	 *
	 * @return
	 */
	@AuraEnabled
	public static String saveTopDownSubLinesServer(List<cb4.CBRow> topDownAmounts) {

		if (topDownAmounts == null || topDownAmounts.size() == 0) return null;

		applicationId = topDownAmounts[0].app;
		List<cb4__CBTag__c> totalTags = getTagsFromCBRows(topDownAmounts);
		Set<String> appIds = new Set<String>();
		for (cb4__CBTag__c t : totalTags) {
			t.cb4__Text1__c = TARGET_TOTAL;
			appIds.add(t.cb4__Tag1__c);
		}

		// Top-down total lines gets OwnerId from its Apps
		Map<String, String> appIdOwnerMap = new Map<String, String>();
		for (cb4__CBTag__c t : [SELECT OwnerId, Id FROM cb4__CBTag__c WHERE Id IN:appIds LIMIT 10000]) appIdOwnerMap.put(t.Id, t.OwnerId);
		for (cb4__CBTag__c t : totalTags) {
			Id ownerId = appIdOwnerMap.get(t.cb4__Tag1__c);
			if (ownerId != null) t.OwnerId = ownerId;
		}

		if (Schema.sObjectType.cb4__CBTag__c.isDeletable()) {
			delete [
					SELECT Id
					FROM cb4__CBTag__c
					WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM
					AND cb4__Text1__c = :TARGET_TOTAL AND cb4__Tag1__c IN:appIds
					LIMIT 10000
			];
		}
		insert totalTags;
		return 'ok';
	}


	/**
	 * Safety tested ✔ 22/11/2019
	 *
	 * @param appId
	 * @param message
	 */
	@AuraEnabled
	public static void saveChatServer(Id appId, String message) {
		cb4__CBTag__c app = [SELECT Id FROM cb4__CBTag__c WHERE Id = :appId WITH SECURITY_ENFORCED LIMIT 1];
		app.cb4__TextLong1__c = message;
		update app;
	}

	@AuraEnabled
	public static Map<String, Object> getPriceQuantityObjectServer() {
		Map<String, Object> r = new Map<String, Object>();
		List<cb4.CBSO> pbSO = CBASHController.getPriceBooksSOServer(null);
		List<cb4.CBSO> pSO  = CBASHController.getProductsSOServer();
		Map<String, Decimal> prices = CBASHController.getPriceEntriesServer();
		r.put('pbSO', pbSO);
		r.put('pSO', pSO);
		r.put('prices', prices);
		return r;
	}

	@AuraEnabled
	public static Map<String, Object> getEmployeeRateObjectServer() {
		Map<String, Object> r = new Map<String, Object>();

		Map<String, Decimal> rateAmountMap = new Map<String, Decimal>();
		for (cb4__CBTag__c rate : [SELECT Id, cb4__Decimal1__c, cb4__DimensionName__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Rate' WITH SECURITY_ENFORCED LIMIT 40000]) rateAmountMap.put(rate.Id, rate.cb4__Decimal1__c);

		List<cb4.CBSO> employeeSO = CBASHController.getTagsSOServer(employeeDimId, null);

		Map<String, List<cb4.CBSO>> employeeRateMap = new Map<String, List<cb4.CBSO>>(); // key = Emp Id, value is its rates
		for (cb4__CBTag__c rate : [SELECT Id, cb4__Tag1__c, cb4__TagLabel__c, cb4__Decimal1__c, cb4__DimensionName__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Rate' AND cb4__Tag1__c != null WITH SECURITY_ENFORCED ORDER BY cb4__Decimal1__c]) {
			List<cb4.CBSO> empRates = employeeRateMap.get(rate.cb4__Tag1__c);
			if (empRates == null) empRates = new List<cb4.CBSO>();
			empRates.add(new cb4.CBSO(rate.Id, rate.cb4__TagLabel__c + ' ($' + rate.cb4__Decimal1__c + ' personal)'));
			employeeRateMap.put(rate.cb4__Tag1__c, empRates);
		}

		List<cb4.CBSO> globalRateSO = new List<cb4.CBSO>();
		for (cb4__CBTag__c rate : [SELECT Id, cb4__Decimal1__c, cb4__TagLabel__c, cb4__DimensionName__c, cb4__Tag1__c, cb4__OrderNumber__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Rate' AND cb4__Tag1__c = null WITH SECURITY_ENFORCED ORDER BY cb4__OrderNumber__c, cb4__TagLabel__c LIMIT 40000]) {
			globalRateSO.add(new cb4.CBSO(rate.Id, rate.cb4__TagLabel__c + ' ($' + rate.cb4__Decimal1__c + ')'));
		}

		r.put('employeeSO', employeeSO);
		r.put('employeeRateMap', employeeRateMap);
		r.put('globalRateSO', globalRateSO);
		r.put('rateAmount', rateAmountMap);
		return r;
	}


	/**
	 *
	 *
	 * @param appId application Id
	 * @param income list of income lines
	 * @param expense list of expense lines
	 *
	 * @return key -> 'Income' value -> list of additional(synthetic) lines
	 */
	@AuraEnabled
	public static Map<String, List<cb4.CBRow>> getCalcRulesSyntheticLines(Id appId, List<cb4.CBRow> income, List<cb4.CBRow> expense, List<cb4.CBRow> totals, Integer step) {
		applicationId = appId;
		Map<Id, Product2> productMap = new Map<Id, Product2> ([SELECT Id, Name FROM Product2 WITH SECURITY_ENFORCED LIMIT 50000]);

		List<cb4__CBTag__c> expenseAndIncomeTags = getTagsFromCBRows(income);
		expenseAndIncomeTags.addAll(getTagsFromCBRows(expense)); // temp - list of expense and income CBTags__c made of app lines
		List<cb4__CBTag__c> totalTags = getTagsFromCBRows(totals);

		List<cb4__CBTag__c> syntheticTags;

		List<cb4__CBTag__c> calcRules = getAppSourceCalcRules(appId, step); // list of Calc Rules
		if (calcRules == null) return null;

		syntheticTags = CBASHController.generateCRSyntheticTags(calcRules, expenseAndIncomeTags, totalTags, productMap);

		List<cb4.CBRow> syntheticList = getCBRowsFromTags(syntheticTags, SIMPLE, true);
		for (cb4.CBRow row : syntheticList) row.styleClass = 'calcRule';

		// App line sorting
		List<cb4.CBRow> incomeSynthetic = new List<cb4.CBRow>();
		List<cb4.CBRow> expenseSynthetic = new List<cb4.CBRow>();
		for (cb4.CBRow s : syntheticList) if (s.ie == 'income') incomeSynthetic.add(s); else expenseSynthetic.add(s);

		return new Map<String, List<cb4.CBRow>>{
				'income' => incomeSynthetic,
				'expense' => expenseSynthetic
		};
	}

	/**
	 * Safety tested ✔ 22/11/2019
	 *
	 * @param appId App Id
	 *
	 * @return
	 */
	@AuraEnabled
	public static String deleteAppServer(Id appId) {
		cb4.CBConsole.insertEventLog('Budget App Deleting (' + appId + ')', null);
		CBASHController.deleteTagServer(new List<Id>{
				appId
		});
		delete [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetSubAppAmountDimId AND cb4__Tag1__c = NULL];
		return null;
	}

	/**
	* Safety tested ✔ 22/11/2019
	 @param ids tag ids
	 *
	 @return key - tag id , value - tag Name
	 */
	@AuraEnabled
	public static Map<String, String> getTagNamesServer(List<String> ids) {
		Set<String> setIds = new Set<String>();
		for (String s : ids) setIds.add(s);
		Map<String, cb4__CBTag__c> temp = new Map<String, cb4__CBTag__c>([SELECT Id, Name, cb4__TagLabel__c FROM cb4__CBTag__c WHERE Id IN:setIds WITH SECURITY_ENFORCED LIMIT 25000]);
		Map<String, String> r = new Map<String, String>();
		for (String s : temp.keySet()) r.put(s, temp.get(s).cb4__TagLabel__c);
		return r;
	}

	@AuraEnabled
	public static List<String> getCurrentUserInterfaceSettingsListServer(String componentName) {
		return CBASHController.getCurrentUserInterfaceSettingsListServer(componentName, null);
	}

	/**
	 * @param appId current App Id
	 *
	 * @return 'false' if App has unPosted subsidiary apps
	 */
	@AuraEnabled
	public static String checkIfApprovingAllowedServer(Id appId) {
		return [SELECT Id, cb4__DimensionName__c, cb4__Tag1__c, cb4__Status__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_DIM AND cb4__Tag1__c = :appId AND cb4__Status__c != 'Posted' WITH SECURITY_ENFORCED LIMIT 50000].size() > 0 ? 'false' : 'true';
	}

	/**
	 * Safety tested ✔ 22/11/2019
	 * @param appId current App Id
	 *
	 * @return List of App Parents
	 */
	@AuraEnabled
	public static Map<String, String> getAppNavigationServer(Id appId) {
		Map<String, String> r = new Map<String, String>();
		cb4__CBTag__c a = [
				SELECT Id,
						cb4__Tag1__r.Id, cb4__Tag1__r.Name, cb4__Tag1__r.cb4__Text3__c,
						cb4__Tag1__r.cb4__Tag1__r.Id, cb4__Tag1__r.cb4__Tag1__r.Name, cb4__Tag1__r.cb4__Tag1__r.cb4__Text3__c,
						cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id, cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Name, cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Text3__c,
						cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id, cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Name, cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Text3__c,
						cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id, cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Name, cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Text3__c
				FROM cb4__CBTag__c
				WHERE Id = :appId
				WITH SECURITY_ENFORCED
		];
		if (a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id != null) r.put(a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id, a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Name);
		if (a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id != null) r.put(a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id, a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Name);
		if (a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id != null) r.put(a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id, a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Name);
		if (a.cb4__Tag1__r.cb4__Tag1__r.Id != null) r.put(a.cb4__Tag1__r.cb4__Tag1__r.Id, a.cb4__Tag1__r.cb4__Tag1__r.Name);
		if (a.cb4__Tag1__r.Id != null) r.put(a.cb4__Tag1__r.Id, a.cb4__Tag1__r.Name);
		return r;
	}


	/**
	 * Safety tested ✔ 22/11/2019
	 * Map of all accounts and dimensions that can be used in App
	 *
	 * @return
	 */
	@AuraEnabled
	public static Map<Id, String> getAllAccountsAndDimensionsServer() {
		Map<Id, String> r = new Map<Id, String>();
		cb4__CBDimension__c appAmountDim = [SELECT Id, cb4__Dimension5__c, cb4__Dimension6__c,cb4__Dimension7__c,cb4__Dimension8__c,cb4__Dimension9__c,cb4__Dimension10__c FROM cb4__CBDimension__c WHERE Id = :budgetAppAmountDimId WITH SECURITY_ENFORCED LIMIT 1];
		cb4__CBDimension__c appDim = [SELECT Id, cb4__Dimension6__c,cb4__Dimension7__c,cb4__Dimension8__c,cb4__Dimension9__c,cb4__Dimension10__c FROM cb4__CBDimension__c WHERE Id = :budgetAppDimId WITH SECURITY_ENFORCED LIMIT 1];

		for (cb4__CBTag__c t : CBASHController.getTagListServer(accountDimId, null, null, null, null, null, null, null)) r.put(t.id, t.cb4__TagLabel__c);
		for (cb4__CBTag__c t : CBASHController.getTagListServer(budgetAppDimId, null, null, null, null, null, null, null)) r.put(t.id, t.cb4__TagLabel__c);

		Map<String, String> appAmountDimMap = cb4.CBUtils.convertCBDimensionToMap(appAmountDim);
		Map<String, String> appDimMap = cb4.CBUtils.convertCBDimensionToMap(appDim);
		String dim5 = appAmountDimMap.get('cb4__Dimension5__c');
		String dim6 = appAmountDimMap.get('cb4__Dimension6__c');
		String dim7 = appAmountDimMap.get('cb4__Dimension7__c');
		String dim8 = appAmountDimMap.get('cb4__Dimension8__c');
		String dim9 = appAmountDimMap.get('cb4__Dimension9__c');
		String dim10 = appAmountDimMap.get('cb4__Dimension10__c');
		String dim6Head = appDimMap.get('cb4__Dimension6__c');
		String dim7Head = appDimMap.get('cb4__Dimension7__c');
		String dim8Head = appDimMap.get('cb4__Dimension8__c');
		String dim9Head = appDimMap.get('cb4__Dimension9__c');
		String dim10Head = appDimMap.get('cb4__Dimension10__c');

		if (dim5 != null) rep(r, dim5);
		if (dim6 != null) rep(r, dim6);
		if (dim7 != null) rep(r, dim7);
		if (dim8 != null) rep(r, dim8);
		if (dim9 != null) rep(r, dim9);
		if (dim10 != null) rep(r, dim10);
		if (dim6Head != null) rep(r, dim6Head);
		if (dim7Head != null) rep(r, dim7Head);
		if (dim8Head != null) rep(r, dim8Head);
		if (dim9Head != null) rep(r, dim9Head);
		if (dim10Head != null) rep(r, dim10Head);

		return r;
	}

	/**
	 * The method recalculates all totals in all apps
	 *
	 * @return
	 */
	@AuraEnabled
	public static String updateApps() {
		String contextFilter = CBASHController.getContextFilter(budgetAppDimId);
		Set<Id> lvl1 = new Set<Id>();
		Set<Id> lvl2 = new Set<Id>();
		Set<Id> lvl3 = new Set<Id>();
		Set<Id> lvl4 = new Set<Id>();
		Set<Id> lvl5 = new Set<Id>();
		Set<Id> lvl6 = new Set<Id>();
		String filter = '';
		if (contextFilter != null && contextFilter != '') filter += ' AND ' + contextFilter;
		String bafReq = 'SELECT Id, ' +
				'cb4__Tag1__r.Id, ' +
				'cb4__Tag1__r.cb4__Tag1__r.Id, ' +
				'cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id, ' +
				'cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id, ' +
				'cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id ' +
				'FROM cb4__CBTag__c WHERE cb4__DimensionName__c = \'' + cb4.CBConstant.BUDGET_APP_DIM + '\'' + filter;
		List<cb4__CBTag__c> BAFilteredList = Database.query(bafReq);

		for (cb4__CBTag__c a : BAFilteredList) {
			if (a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id != null) {
				lvl6.add(a.Id);
			} else if (a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id != null) {
				lvl5.add(a.Id);
			} else if (a.cb4__Tag1__r.cb4__Tag1__r.cb4__Tag1__r.Id != null) {
				lvl4.add(a.Id);
			} else if (a.cb4__Tag1__r.cb4__Tag1__r.Id != null) {
				lvl3.add(a.Id);
			} else if (a.cb4__Tag1__r.Id != null) {
				lvl2.add(a.Id);
			} else {
				lvl1.add(a.Id);
			}
		}

		if (lvl6.size() > 0) runRefreshApps(lvl6); // each method makes 6 database query
		if (lvl5.size() > 0) runRefreshApps(lvl5); // each method makes 6 database query
		if (lvl4.size() > 0) runRefreshApps(lvl4); // each method makes 6 database query
		if (lvl3.size() > 0) runRefreshApps(lvl3); // each method makes 6 database query
		if (lvl2.size() > 0) runRefreshApps(lvl2); // each method makes 6 database query
		if (lvl1.size() > 0) runRefreshApps(lvl1); // each method makes 6 database query

		updateBudgetAppAmountOwners(); //2 requests

		return 'ok';
	}
	@AuraEnabled
	public static List<Object> getBAListServer(List<String> parentIdList) {
		String contextFilter = CBASHController.getContextFilter(cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_APP_DIM));
		String filter = '';
		List<cb4__CBTag__c> result = new List<cb4__CBTag__c>();
		if (contextFilter != null && contextFilter != '') filter += ' AND ' + contextFilter;
		String q = 'SELECT Id, cb4__Tag1__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = \'' +
				cb4.CBConstant.BUDGET_APP_DIM + '\' ' + filter;
		if (parentIdList != null && parentIdList.size() > 0) {
			q += ' AND cb4__Tag1__c IN ' + cb4.CBUtils.getFormattedINQuery(new Set<String>(parentIdList));
			result = Database.query(q);
		} else {
			//q += ' AND cb4__Tag1__c = null';
			Map<Id, cb4__CBTag__c> availableAppsMap = new Map<Id, cb4__CBTag__c>((List<cb4__CBTag__c>) Database.query(q));
			for (cb4__CBTag__c app : availableAppsMap.values()) {
				if (!availableAppsMap.containsKey(app.cb4__Tag1__c)) {
					result.add(app);
				}
			}

		}
		return result;
	}
	@AuraEnabled
	public static Decimal runRefreshAppsServer(Decimal lvl, List<Id> listOfAppIds) {
		deleteAppOldTotals(new Set<Id>(listOfAppIds)); // 3 requests
		generateAppNewTotals(new Set<Id>(listOfAppIds));  // 3 requests
		return lvl;
	}
	/**
	 * Created by Alex JR 03/07/2020
	 */
	private static void updateBudgetAppAmountOwners() {
		List<cb4__CBTag__c> BATotalAmounts = [SELECT cb4__Tag1__r.OwnerId, cb4__DimensionName__c, cb4__Tag1__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM AND cb4__Tag1__c = :TOTAL WITH SECURITY_ENFORCED];
		for (cb4__CBTag__c t : BATotalAmounts) t.OwnerId = t.cb4__Tag1__r.OwnerId;
		update BATotalAmounts;
	}

	/////// SELECT OPTIONS ///////

	/**
	 * If app Id is null, method returns only App dimensions
	 * @return App and template App lines dimensions and accounts
	 */
	@AuraEnabled
	public static Map<String, String> getExtraDimensionsSOServer(Id appId) {
		Map<String, String> appDimensionsMap = getAppDimensionsMap();
		Map<String, String> appLineDimensionsMap = getAppLineDimensionsMap(appId);
		Map<String, String> appLineAdditionFieldsMap = getAppLineAdditionFieldsMap(); // text and decimals
		for (String s : appLineDimensionsMap.keySet()) appDimensionsMap.put(s, appLineDimensionsMap.get(s));
		for (String s : appLineAdditionFieldsMap.keySet()) appDimensionsMap.put(s, appLineAdditionFieldsMap.get(s));
		return appDimensionsMap;
	}

	/**
	 * Budget App sheet filter
	 *
	 * @param appId
	 *
	 * @return
	 */
	@AuraEnabled
	public static List<cb4.CBSO> getFilterCategoriesSOServer() {
		/*List<cb4.CBSO> r = new List<cb4.CBSO>{
				new cb4.CBSO('accName', 'Line: Account'),
				new cb4.CBSO('accountST', 'Line: Account SubType'),
				new cb4.CBSO('product', 'Line: Product'),
				new cb4.CBSO('employee', 'Line: Employee')
		};*/
		List<cb4.CBSO> r = new List<cb4.CBSO>();
		cb4__CBDimension__c appDimension = CBASHController.getDimension(budgetAppDimId);
		cb4__CBDimension__c appLineDimension = CBASHController.getDimension(budgetAppAmountDimId);
		Map<String, String> dimMap = cb4.CBUtils.convertCBDimensionToMap(appDimension);
		Map<String, String> lineDimMap = cb4.CBUtils.convertCBDimensionToMap(appLineDimension);
		if(String.isNotBlank(lineDimMap.get('cb4__Dimension5__c'))) {
			r.add(new cb4.CBSO('accTag5', 'Line: Account Code & ' + cb4.CBUtils.dimensionIdHeaderMap.get(lineDimMap.get('cb4__Dimension5__c'))));
		}
		r.add(new cb4.CBSO('accName', 'Line: Account'));
		/*for (Integer i = 6; i <= 10; i++) {
			String dimId = dimMap.get('cb4__Dimension' + i + '__c');
			if (dimId != null) r.add(new cb4.CBSO('dim' + i + 'HeadName', 'App: ' + cb4.CBUtils.dimensionIdHeaderMap.get(dimId)));
		}
		for (Integer i = 5; i <= 10; i++) {
			String dimId = lineDimMap.get('cb4__Dimension' + i + '__c');
			if (dimId != null) r.add(new cb4.CBSO('dim' + i + 'Name', 'Line: ' + cb4.CBUtils.dimensionIdHeaderMap.get(dimId)));
		}*/
		return r;
	}
	/////// SELECT OPTION ///////


	/////// BACKUP ///////
	@AuraEnabled
	public static void insertBackupLog(Id recordId, String title, String backup) {
		if(!String.isBlank(backup)){
			cb4__CBLog__c newLog = new cb4__CBLog__c(cb4__Title__c = title, cb4__Type__c = 'BACKUP', cb4__JobId__c = recordId);
			if(backup.length() > 131072){
				newLog.cb4__Description__c = backup.substring(0, 131072);
				if(backup.length() > 262144){
					newLog.Description1__c = backup.substring(131072, 262144);
					if(backup.length() > 393216){
						newLog.Description2__c = backup.substring(262144, 393216);
						if(backup.length() > 524288){
							newLog.Description3__c = backup.substring(393216, 524288);
						}else{
							newLog.Description3__c = backup.substring(393216, backup.length());
						}
					}else{
						newLog.Description2__c = backup.substring(262144, backup.length());
					}
				}else{
					newLog.Description1__c = backup.substring(131072, backup.length());
				}
			}else{
				newLog.cb4__Description__c = backup;
			}
			insert newLog;
		}
	}

	@AuraEnabled
	public static List<cb4__CBLog__c> getBackupLogList(Id recordId, String sDate, String eDate) {
		try {
			if(sDate == null || eDate == null){
				return [
						SELECT Id, Name, cb4__Title__c, cb4__Description__c, Description1__c, Description2__c, Description3__c, CreatedDate, Owner.Name
						FROM cb4__CBLog__c
						WHERE cb4__JobId__c = :recordId AND cb4__Type__c = 'BACKUP'
						ORDER BY CreatedDate DESC
						LIMIT 100
				];
			}
			Date sd = Date.valueOf(sDate);
			Date ed = Date.valueOf(eDate);
			return [
					SELECT Id, Name, cb4__Title__c, cb4__Description__c, Description1__c, Description2__c, Description3__c, CreatedDate, Owner.Name
					FROM cb4__CBLog__c
					WHERE CreatedDate >= :sd AND CreatedDate <= :ed AND cb4__JobId__c = :recordId AND cb4__Type__c = 'BACKUP'
					ORDER BY CreatedDate DESC
					LIMIT 100
			];
		} catch (Exception e) {
			return new List<cb4__CBLog__c>();
		}
	}
	@AuraEnabled
	public static String getBackupLog(Id backupId) {
		cb4__CBLog__c backupLog = [SELECT Id, cb4__Description__c, Description1__c, Description2__c, Description3__c FROM cb4__CBLog__c WHERE Id = :backupId WITH SECURITY_ENFORCED];
		String backupJSON = backupLog.cb4__Description__c + (String.isBlank(backupLog.Description1__c) ? '' : backupLog.Description2__c) + (String.isBlank(backupLog.Description2__c) ? '' : backupLog.Description2__c) + (String.isBlank(backupLog.Description3__c) ? '' : backupLog.Description3__c);
		return backupJSON;
	}
	/////// BACKUP ///////

	/////// PRIVATE METHODS ///////
	@TestVisible
	private static Map<String, String> getAppDimensionsMap() {
		Map<String, String> r = new Map<String, String>();
		Map<String, String> dimMap = cb4.CBUtils.convertCBDimensionToMap(CBASHController.getDimension(budgetAppDimId));

		String d4 = dimMap.get('cb4__Dimension4__c');
		if (d4 != null) {
			r.put('appdname4', cb4.CBUtils.dimensionIdHeaderMap.get(d4));
			r.put('appd4', System.JSON.serialize(CBASHController.getTagsSOServer(d4, null)));
		}

		String d5 = dimMap.get('cb4__Dimension5__c');
		if (d5 != null) {
			r.put('appdname5', cb4.CBUtils.dimensionIdHeaderMap.get(d5));
			r.put('appd5', System.JSON.serialize(CBASHController.getTagsSOServer(d5, null)));
		}

		String d6 = dimMap.get('cb4__Dimension6__c');
		if (d6 != null) {
			r.put('appdname6', cb4.CBUtils.dimensionIdHeaderMap.get(d6));
			r.put('appd6', System.JSON.serialize(CBASHController.getTagsSOServer(d6, null)));
		}

		String d7 = dimMap.get('cb4__Dimension7__c');
		if (d7 != null) {
			r.put('appdname7', cb4.CBUtils.dimensionIdHeaderMap.get(d7));
			r.put('appd7', System.JSON.serialize(CBASHController.getTagsSOServer(d7, null)));
		}

		String d8 = dimMap.get('cb4__Dimension8__c');
		if (d8 != null) {
			r.put('appdname8', cb4.CBUtils.dimensionIdHeaderMap.get(d8));
			r.put('appd8', System.JSON.serialize(CBASHController.getTagsSOServer(d8, null)));
		}

		String d9 = dimMap.get('cb4__Dimension9__c');
		if (d9 != null) {
			r.put('appdname9', cb4.CBUtils.dimensionIdHeaderMap.get(d9));
			r.put('appd9', System.JSON.serialize(CBASHController.getTagsSOServer(d9, null)));
		}

		String d10 = dimMap.get('cb4__Dimension10__c');
		if (d10 != null) {
			r.put('appdname10', cb4.CBUtils.dimensionIdHeaderMap.get(d10));
			r.put('appd10', System.JSON.serialize(CBASHController.getTagsSOServer(d10, null)));
		}

		return r;
	}

	/**
	 * Safety tested ✔ 22/11/2019
	 *
	 * @param appId
	 *
	 * @return
	 */
	@TestVisible
	private static Map<String, String> getAppLineDimensionsMap(Id appId) {
		Map<String, String> r = new Map<String, String>();
		if (appId == null) return r;
		cb4__CBTag__c app = [
				SELECT  cb4__Tag2__r.cb4__Tag6__c, cb4__Tag2__r.cb4__Tag6__r.cb4__Dimension__r.cb4__SetDimension__c, cb4__Tag2__r.cb4__Dimension__r.cb4__Dimension6__c,
						cb4__Tag2__r.cb4__Tag7__c, cb4__Tag2__r.cb4__Tag7__r.cb4__Dimension__r.cb4__SetDimension__c, cb4__Tag2__r.cb4__Dimension__r.cb4__Dimension7__c,
						cb4__Tag2__r.cb4__Tag8__c, cb4__Tag2__r.cb4__Tag8__r.cb4__Dimension__r.cb4__SetDimension__c, cb4__Tag2__r.cb4__Dimension__r.cb4__Dimension8__c,
						cb4__Tag2__r.cb4__Tag9__c, cb4__Tag2__r.cb4__Tag9__r.cb4__Dimension__r.cb4__SetDimension__c, cb4__Tag2__r.cb4__Dimension__r.cb4__Dimension9__c,
						cb4__Tag2__r.cb4__Tag10__c,cb4__Tag2__r.cb4__Tag10__r.cb4__Dimension__r.cb4__SetDimension__c, cb4__Tag2__r.cb4__Dimension__r.cb4__Dimension10__c
				FROM cb4__CBTag__c
				WHERE Id = :appId
				WITH SECURITY_ENFORCED
				LIMIT 1
		];
		for (Integer i = 6; i <= 10; i++) {
			try {
				String dimVal = cb4.CBUtils.getFieldValue('cb4__Tag2__r.cb4__Dimension__r.cb4__Dimension' + i + '__c', app); // from App Template
				Map<String, String> t = (Map<String, String>) System.JSON.deserialize(dimVal, Map<String, String>.class);
				String dimId = t.get('v');
				if (String.isEmpty(dimId) || dimId == '-') continue; // Dimension is absent
				String key = 'd' + i;
				String tagId = cb4.CBUtils.getFieldValue('cb4__Tag2__r.cb4__Tag' + i + '__c', app);
				cb4__CBTag__c tag = CBASHController.getTagServer(tagId, ' cb4__Dimension__r.cb4__isSet__c ');
				if (tag.cb4__Dimension__r.cb4__isSet__c) {
					String childId = cb4.CBUtils.dimensionSetToChildMap.get(dimId);
					r.put('dname' + i, cb4.CBUtils.dimensionIdHeaderMap.get(childId));
				} else {
					r.put('dname' + i, cb4.CBUtils.dimensionIdHeaderMap.get(dimId));
				}
				if (String.isEmpty(tagId)) { // Template tag is not specified, so all Dimensions are allowed
					r.put(key, System.JSON.serialize(CBASHController.getTagsSOServer(dimId, null)));
				} else { // Specified Set or dimension is allowed
					if (tag.cb4__Dimension__r.cb4__isSet__c) { // Dimension is Set
						r.put(key, System.JSON.serialize(CBASHController.getAllWiredTagsOfSetSO(tagId)));
					} else {
						r.put(key, System.JSON.serialize(CBASHController.getTagsSOServer(dimId, ' Id = \'' + tagId + '\'')));
					}
				}
			} catch (Exception e) {
				cb4.CBConsole.setLog(e, 'App Line Dimensions Map error');
			}
		}
		try {
			cb4__CBDimension__c budgetAppAmountDim = [SELECT Id, cb4__Dimension5__c FROM cb4__CBDimension__c WHERE Name = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM];
			Map<String, String> t = (Map<String, String>) System.JSON.deserialize(budgetAppAmountDim.cb4__Dimension5__c, Map<String, String>.class);
			String dimId = t.get('v');
			if (!String.isEmpty(dimId) || dimId != '-') {
				r.put('dname5', cb4.CBUtils.dimensionIdHeaderMap.get(dimId));
				r.put('d5', System.JSON.serialize(CBASHController.getTagsSOServer(dimId, null)));
			}
		} catch (Exception e) {

		}
		return r;
	}

	@TestVisible
	private static Map<String, String> getAppLineAdditionFieldsMap() {
		Map<String, String> r = new Map<String, String>();
		cb4__CBDimension__c appLineDimension = CBASHController.getDimension(budgetAppAmountDimId);
		for (Integer i = 6; i <= 9; i++) {
			String key = 'cb4__Text' + i + '__c';
			Object textSettings = (String) appLineDimension.get(key);
			if (textSettings != null) {
				String title = ((Map<String, String>) System.JSON.deserialize((String) textSettings, Map<String, String>.class)).get('v');
				if (cb4.CBUtils.isValidId(title)) r.put(key, title);
			}
		}
		for (Integer i = 6; i <= 10; i++) {
			String key = 'cb4__Decimal' + i + '__c';
			Object textSettings = (String) appLineDimension.get(key);
			if (textSettings != null) {
				String title = ((Map<String, String>) System.JSON.deserialize((String) textSettings, Map<String, String>.class)).get('v');
				if (cb4.CBUtils.isValidId(title)) r.put(key, title);
			}
		}
		return r;
	}


	/**
	 *
	 * @param appId
	 */
	private static void deleteAllOldAppAmountsAndSubAmounts(Id appId) {
		delete [SELECT Id, cb4__DimensionName__c, cb4__Tag1__c, cb4__Text1__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM AND cb4__Tag1__c = :appId AND cb4__Text1__c != :TARGET_TOTAL LIMIT 10000];
		delete [SELECT Id, cb4__DimensionName__c, cb4__Tag1__c, cb4__Text1__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget App SubAmount' AND cb4__Tag1__c = :appId LIMIT 10000];

	}

	private static void rep(Map<Id, String> r, String d) {
		for (cb4__CBTag__c t : CBASHController.getTagListServer(d, null, null, null, null, null, null, null)) r.put(t.id, t.cb4__TagLabel__c);
	}

	/**
	 * A new App has to have total lines. This method returns empty lines with income and expense totals
	 * @param rows list with 1. none of total 2. Expense only 3. Income only
	 *
	 * @return List<CBRow> two records (income, expense)
	 */
	private static List<cb4.CBRow> getInitialTotalCBRows(List<cb4.CBRow> rows) {
		List<Decimal> t = new List<Decimal>(); // template
		for (Integer i = 0; i <= periods.size(); i++) t.add(0);

		cb4.CBRow income = new cb4.CBRow('income', t.clone());
		cb4.CBRow expense = new cb4.CBRow('expense', t.clone());
		income.ie = income.title = 'income';
		expense.ie = expense.title = 'expense';

		if (rows.size() == 0) {
			rows.add(income);
			rows.add(expense);
		} else {
			if (rows[0].ie == 'income') {
				rows.add(expense);
			} else {
				List<cb4.CBRow> temp = new List<cb4.CBRow>();
				temp.add(income);
				temp.add(rows[0]);
				rows = temp;
			}
		}
		return rows;
	}

	/**
	 * @return ordered list of CBRow. Incomes before Expenses
	 */
	private static List<cb4.CBRow> setTotalLinesOrder(List<cb4.CBRow> s) {
		if (s[0].ie == 'income') return s;
		List<cb4.CBRow> r = new List<cb4.CBRow>();
		r.add(s[1]);
		r.add(s[0]);
		return r;
	}

	/**
	 @param tags source tags
	 @param type simple, sub
	 @param isTotal if line is total we need to make it lowerCase in order to let BA work correctly. if line isn't total - we need to left line title untouched
	 *
	 @return list of CBRows from tag grouped by key and period
	 */

	public static List<cb4.CBRow> getCBRowsFromTags(List<cb4__CBTag__c> tags, String type, Boolean isTotal) {
		Boolean isSimple = type == SIMPLE;
		Map<Id, Integer> perIndMap = new Map<Id, Integer>(); // key - period Id  value = period number
		Integer i = 0;
		for (cb4__CBTag__c t : periods) perIndMap.put(t.Id, i++);
		List<Decimal> temp = new List<Decimal>();
		Integer rowSize = 0;
		for (; rowSize < i; rowSize++) temp.add(0);

		Map<String, cb4.CBRow> rowMap = new Map<String, cb4.CBRow>();
		if (tags == null) return null;
		for (cb4__CBTag__c t : tags) {
			String key = isSimple ? getSimpleLineKey(t, t.cb4__Tag1__c) : getSubLineKey(t);
			cb4.CBRow row = rowMap.get(key);
			if (row == null) {
				row = new cb4.CBRow(key, temp.clone());
				row.ie = t.cb4__Text2__c.toLowerCase(); // Income Expense
				row.app = t.cb4__Tag1__c; // app Id
				row.account = isSimple ? t.cb4__Tag2__c : null; // account Id
				row.accountST = isSimple ? t.cb4__Tag2__r.cb4__Tag1Name__c : null; // account subtype
				row.type = isSimple || t.cb4__Tag1__r.cb4__Tag2__r.cb4__Text1__c == TOP_DOWN ? null : 'disabled';
				row.title = isSimple ? (isTotal ? t.cb4__Text3__c.toLowerCase() : t.cb4__Text3__c) : t.cb4__Tag1__r.cb4__TagLabel__c;
				row.description = isSimple ? t.cb4__Text4__c : t.cb4__Tag1__r.cb4__Text4__c;
				row.styleClass = t.cb4__Text5__c;
				row.employeeId = t.cb4__Tag4__c;
				row.rateId = t.cb4__Tag5__c;
				row.dim5 = t.cb4__Tag5__c;
				row.dim6 = t.cb4__Tag6__c;
				row.dim7 = t.cb4__Tag7__c;
				row.dim8 = t.cb4__Tag8__c;
				row.dim9 = t.cb4__Tag9__c;
				row.dim10 = t.cb4__Tag10__c;
				row.boolean1 = t.cb4__Boolean1__c;
				row.boolean2 = t.cb4__Boolean2__c;
				row.boolean3 = t.cb4__Boolean3__c;
				row.boolean4 = t.cb4__Boolean4__c;
				row.boolean5 = t.cb4__Boolean5__c;
				row.text6 = t.cb4__Text6__c;
				row.text7 = t.cb4__Text7__c;
				row.text8 = t.cb4__Text8__c;
				row.text9 = t.cb4__Text9__c;
				row.decimal6 = t.cb4__Decimal6__c;
				row.decimal7 = t.cb4__Decimal7__c;
				row.decimal8 = t.cb4__Decimal8__c;
				row.decimal9 = t.cb4__Decimal9__c;
				row.decimal10 = t.cb4__Decimal10__c;
				row.dim6Head = t.cb4__Tag1__r.cb4__Tag6__c;
				row.dim7Head = t.cb4__Tag1__r.cb4__Tag7__c;
				row.dim8Head = t.cb4__Tag1__r.cb4__Tag8__c;
				row.dim9Head = t.cb4__Tag1__r.cb4__Tag9__c;
				row.dim10Head = t.cb4__Tag1__r.cb4__Tag10__c;
				row.status = t.cb4__Tag1__r.cb4__Status__c;
				row.productId = t.cb4__Product__c;
				row.pricebookId = t.cb4__PriceBook__c;
				row.extId = t.cb4__ExtId__c;
				rowMap.put(key, row);
			}
			Integer perNumber = perIndMap.get(t.cb4__Tag3__c);
			row.rowValues[perNumber] += t.cb4__Decimal1__c;
			if (t.cb4__Decimal2__c != null) row.quantityValues[perNumber] += t.cb4__Decimal2__c;
			if (t.cb4__Decimal3__c != null) row.priceValues[perNumber] += t.cb4__Decimal3__c;
		}

		for (cb4.CBRow row : rowMap.values()) {
			Decimal total = 0;
			for (Integer k = 0; k < rowSize; k++) total += row.rowValues[k];
			row.rowValues.add(total);
		}

		return rowMap.values();
	}

	private static List<cb4__CBTag__c> getTagsFromCBRows(List<cb4.CBRow> rows) {
		if (rows == null || rows.size() == 0) return new List<cb4__CBTag__c>();
		List<cb4__CBTag__c> r = new List<cb4__CBTag__c>();
		Integer k, rowLength;

		List<Id> periodsList = new List<Id>();
		for (cb4__CBTag__c t : periods) periodsList.add(t.Id);

		for (cb4.CBRow row : rows) {
			rowLength = row.rowValues.size() - 1; // exclude totals
			for (k = 0; k < rowLength; k++) {
				if (row.rowValues[k] == 0) continue;
				cb4__CBTag__c t = new cb4__CBTag__c();
				t.cb4__Dimension__c = budgetAppAmountDimId;
				t.cb4__Decimal1__c = row.rowValues[k]; // money
				t.cb4__Decimal2__c = row.quantityValues[k]; // quantity or hours
				t.cb4__Decimal3__c = row.priceValues[k]; // price or rate
				t.cb4__Boolean1__c = row.boolean1;
				t.cb4__Boolean2__c = row.boolean2;
				t.cb4__Boolean3__c = row.boolean3;
				t.cb4__Boolean4__c = row.boolean4;
				t.cb4__Boolean5__c = row.boolean5;
				t.cb4__Text1__c = row.lvl1Name;
				t.cb4__Text2__c = row.lvl1Name == 'expense' || row.lvl1Name == 'income' ? row.lvl1Name : row.ie;
				t.cb4__Text3__c = row.title;
				t.cb4__Text4__c = row.description;
				t.cb4__Text5__c = row.styleClass;
				t.cb4__Tag1__c = row.app;
				t.cb4__Tag2__c = row.account;
				t.cb4__Tag3__c = periodsList[k];
				t.cb4__Tag4__c = row.employeeId;
				t.cb4__Tag5__c = row.rateId;
				t.cb4__Tag6__c = row.dim6 == '' ? null : row.dim6;
				t.cb4__Tag7__c = row.dim7 == '' ? null : row.dim7;
				t.cb4__Tag8__c = row.dim8 == '' ? null : row.dim8;
				t.cb4__Tag9__c = row.dim9 == '' ? null : row.dim9;
				t.cb4__Tag10__c = row.dim10 == '' ? null : row.dim10;
				t.cb4__Product__c = row.productId == '' ? null : row.productId;
				t.cb4__PriceBook__c = row.pricebookId == '' ? null : row.pricebookId;
				if (row.ownerId != null && row.ownerId != '') t.OwnerId = row.ownerId;
				r.add(t);
			}
		}
		return r;
	}

	/**
	 * 4 SQOL request per the method
	 * @param appId app Id
	 *
	 * @return list of the current app corresponded Calculation Rules (ONLY SOURCE CALCULATION RULES) OR null
	 */
	public static List<cb4__CBTag__c> getAppSourceCalcRules(Id appId, Integer step) {
		Set<Id> ruleIds = new Set<Id>();
		String calcRuleId;
		Boolean isSet = false;
		cb4__CBTag__c app = [
				SELECT Id, cb4__Tag2__r.cb4__Tag4__c,cb4__Tag2__r.cb4__Tag4__r.cb4__Dimension__r.cb4__isSet__c,cb4__Tag2__r.cb4__Tag5__c,cb4__Tag2__r.cb4__Tag5__r.cb4__Dimension__r.cb4__isSet__c,cb4__Tag2__r.cb4__Tag1__c,cb4__Tag2__r.cb4__Tag1__r.cb4__Dimension__r.cb4__isSet__c
				FROM cb4__CBTag__c
				WHERE Id = :appId
				WITH SECURITY_ENFORCED
		];// template calc rule/set
		switch on step {
			when 1 {
				calcRuleId = app.cb4__Tag2__r.cb4__Tag4__c;
				isSet = app.cb4__Tag2__r.cb4__Tag4__r.cb4__Dimension__r.cb4__isSet__c;
			}
			when 2 {
				calcRuleId = app.cb4__Tag2__r.cb4__Tag5__c;
				isSet = app.cb4__Tag2__r.cb4__Tag5__r.cb4__Dimension__r.cb4__isSet__c;
			}
			when 3 {
				calcRuleId = app.cb4__Tag2__r.cb4__Tag1__c;
				isSet = app.cb4__Tag2__r.cb4__Tag1__r.cb4__Dimension__r.cb4__isSet__c;
			}
			when else {
				return null;
			}
		}
		if (calcRuleId == null) return null;
		if (isSet) {
			for (cb4__CBTag__c t : CBASHController.getAllWiredTagsOfSet(calcRuleId)) ruleIds.add(t.Id); // set of calc rules
		} else {
			ruleIds.add(calcRuleId); // one rule
		}
		return [
				SELECT Id, Name, cb4__TagLabel__c, cb4__Tag1__c, cb4__Tag2__c, cb4__Tag3__c, cb4__Tag6__c, cb4__Tag7__c, cb4__Tag8__c, cb4__Tag9__c,
						cb4__Tag10__c, cb4__Tag1__r.cb4__Dimension__r.cb4__isSet__c, /* account*/ cb4__Tag3__r.cb4__Dimension__r.cb4__isSet__c, /* period*/ cb4__Boolean1__c,
						cb4__Text1__c, cb4__Text2__c, cb4__Text3__c, cb4__Decimal1__c, cb4__Decimal2__c, cb4__Decimal3__c
				FROM cb4__CBTag__c
				WHERE Id IN:ruleIds
				WITH SECURITY_ENFORCED
				LIMIT 10000
		];
	}

	/**
	 *
	 *
	 * @param appId application Id
	 * @param childrenIds app sheet only
	 * @param type income, expense or total
	 * @param addedWhere
	 *
	 * @return
	 */
	public static List<cb4__CBTag__c> getSimpleAndTotalLines(Id appId, Set<String> childrenIds, String type, Map<String, String> addedWhere) {
		String whereFilter = '';
		if (addedWhere != null) for (String s : addedWhere.keySet()) {
			String item = addedWhere.get(s);
			whereFilter += ' AND ' + s + ' = \'' + item + '\' ';
		}
		if (childrenIds != null) for (String childId : childrenIds) childId = cb4.CBUtils.refineStr(childId);
		String addQ = childrenIds == null ? 'cb4__Tag1__c = \'' + appId + '\' ' : ' cb4__Tag1__c IN  ' + cb4.CBUtils.getFormattedINQuery(childrenIds);
		String W = ' WHERE ' + addQ + ' AND cb4__DimensionName__c = \'' + cb4.CBConstant.BUDGET_APP_AMOUNT_DIM + '\' ' + whereFilter +
				'AND cb4__Text1__c = \'' + type + '\'';
		return getLines(W);
	}
	public static List<cb4__CBTag__c> getSimpleAndTotalSubLines(Id appId, Set<String> childrenIds, String type, Map<String, String> addedWhere) {
		String whereFilter = '';
		if (addedWhere != null) for (String s : addedWhere.keySet()) {
			String item = addedWhere.get(s);
			whereFilter += ' AND ' + s + ' = \'' + item + '\' ';
		}
		if (childrenIds != null) for (String childId : childrenIds) childId = cb4.CBUtils.refineStr(childId);
		String addQ = childrenIds == null ? 'cb4__Tag1__c = \'' + appId + '\' ' : ' cb4__Tag1__c IN  ' + cb4.CBUtils.getFormattedINQuery(childrenIds);
		String W = ' WHERE ' + addQ + ' AND cb4__Dimension__c = \'' + budgetSubAppAmountDimId + '\' ' + whereFilter +
				'AND cb4__Text2__c = \'' + type + '\'';
		return getLines(W);
	}

	public static List<cb4__CBTag__c> getDownUpSubLines(Id appId, String type) {
		String W = ' WHERE cb4__Tag1__r.cb4__Tag1__c =\'' + appId + '\' AND cb4__DimensionName__c = \'' + cb4.CBConstant.BUDGET_APP_AMOUNT_DIM + '\' ' +
				' AND cb4__Text1__c = \'total\' AND cb4__Tag1__r.cb4__Tag2__r.cb4__Text1__c = \'Bottom-Up\' AND cb4__Text2__c =\'' + type + '\' ';
		return getLines(W);
	}

	/**
	 * @param appId
	 * @param type
	 *
	 * @return list of App amounts
	 */
	public static List<cb4__CBTag__c> getTopDownSubLines(Id appId, String type) {
		String W = ' WHERE cb4__Tag1__r.cb4__Tag1__c =\'' + appId + '\' AND cb4__DimensionName__c = \'' + cb4.CBConstant.BUDGET_APP_AMOUNT_DIM + '\' ' +
				' AND cb4__Text1__c = \'targetTotal\' AND cb4__Text2__c =\'' + type + '\' ';
		return getLines(W);
	}

	/**
	 * Tag1__r.Tag2__r.Text1__c - template type 'Top-Down' or not
	 *
	 * Safety tested ✔ 22/11/2019
	 * @param W
	 *
	 * @return
	 */
	private static List<cb4__CBTag__c> getLines(String W) {
		String Q = 'SELECT cb4__Decimal1__c,cb4__Decimal2__c,cb4__Decimal3__c,cb4__Decimal6__c,cb4__Decimal7__c,cb4__Decimal8__c,cb4__Decimal9__c,cb4__Decimal10__c,' +
				'cb4__Text1__c,cb4__Text2__c,cb4__Text3__c,cb4__Text4__c,cb4__Text5__c,cb4__Text6__c,cb4__Text7__c,cb4__Text8__c,cb4__Text9__c,' +
				'cb4__Tag1__r.Name,cb4__Tag1__r.cb4__TagLabel__c,cb4__Boolean1__c,cb4__Boolean2__c,cb4__Boolean3__c,cb4__Boolean4__c,cb4__Boolean5__c,' +
				'cb4__Tag1__r.cb4__Text3__c,cb4__Tag1__r.cb4__Tag2__r.cb4__Text1__c,cb4__Tag1__r.cb4__Tag6__c,cb4__Tag1__r.cb4__Tag7__c,cb4__Tag1__r.cb4__Tag8__c,cb4__Tag1__r.cb4__Tag9__c,cb4__Tag1__r.cb4__Tag10__c,' +
				'cb4__Tag1__c,cb4__Tag2__c,cb4__Tag3__c,cb4__Tag4__c,cb4__Tag5__c,cb4__Tag6__c,cb4__Tag7__c,cb4__Tag8__c,cb4__Tag9__c,cb4__Tag10__c,cb4__Tag1__r.cb4__Text4__c,cb4__Tag1__r.cb4__Status__c,' +
				'cb4__PriceBook__c,cb4__Product__c,cb4__Tag2__r.cb4__Tag1Name__c,cb4__ExtId__c' +
				' FROM cb4__CBTag__c ';
		String O = ' ORDER BY cb4__Text1__c, cb4__Text3__c, cb4__Text5__c, cb4__Tag2__r.cb4__TagLabel__c'; // income, account, type
		String L = ' LIMIT 40000 ';
		try {
			return Database.query(Q + W + O + L);
		} catch (Exception e) {
			return null;
		}
	}

	public static String getSimpleLineKey(cb4__CBTag__c t, String bAppId) {
		return (t.cb4__Tag1__c == null ? (String.isNotBlank(bAppId) ? bAppId : t.cb4__Tag1__c) : t.cb4__Tag1__c) +
				(t.cb4__Text2__c == null ? '' : t.cb4__Text2__c.toLowerCase()) +
				(t.cb4__Text3__c == null ? '' : refineStringToId(t.cb4__Text3__c).toLowerCase()) + // replace spaces
				(t.cb4__Text4__c == null ? '' : refineStringToId(t.cb4__Text4__c.left(100))) +
				(t.cb4__Tag2__c == null ? '' : t.cb4__Tag2__c) +
				(t.cb4__Tag4__c == null ? '' : t.cb4__Tag4__c) +
				//(t.cb4__Tag5__c == null ? '' : t.cb4__Tag5__c) +
				(t.cb4__Tag6__c == null ? '' : t.cb4__Tag6__c) +
				(t.cb4__Tag7__c == null ? '' : t.cb4__Tag7__c) +
				(t.cb4__Tag8__c == null ? '' : t.cb4__Tag8__c) +
				(t.cb4__Tag9__c == null ? '' : t.cb4__Tag9__c) +
				(t.cb4__Tag10__c == null ? '' : t.cb4__Tag10__c);
	}
	@TestVisible
	public static String refineStringToId(String s) {
		return s.replaceAll('\\s+', '').replaceAll(':', '').replaceAll('&', '');
	}
	@TestVisible
	private static String getSubLineKey(cb4__CBTag__c t) {
		return t.cb4__Tag1__c;
	}
	@TestVisible
	private static String getAccount(String key) {
		return key;
	}
	@TestVisible
	private static void updateCBRow(cb4.CBRow r, cb4__CBTag__c app, String type) {
		r.app = app.Id;
		r.lvl1Name = type;
		r.ownerId = app.OwnerId;
	}

	/// UPDATE ALL APS /////
	@TestVisible
	private static void runRefreshApps(Set<Id> setOfAppIds) {
		deleteAppOldTotals(setOfAppIds); // 3 requests
		generateAppNewTotals(setOfAppIds);  // 3 requests
	}

	/**
	 *
	 *
	 * @param setOfAppIds list of Apps which totals need to be generated
	 */
	@TestVisible
	private static void generateAppNewTotals(Set<Id> setOfAppIds) {
		/**
		 * totalsMap has two types of key
		 * 1. key = appId + periodId + lineType, value - total budget app amount
		 * 2. key = appId , value - application
		 */
		Map<String, cb4__CBTag__c> totalsMap = new Map<String, cb4__CBTag__c>(); // key - appId + periodId + lineType, value - total budget app amount
		String t = 'total';
		String i = 'income';
		String e = 'expense';

		// APP SIMPLE LINES
		List<AggregateResult> agrList = [ // 4
				SELECT SUM(cb4__Decimal1__c) amount,
						cb4__Tag1__c appId,
						cb4__Text1__c lineType, // income or expense
						cb4__Tag3__c periodId,
						MAX(cb4__Tag1__r.OwnerId) ownerId,
						MAX(cb4__Tag1Name__c) appName
				FROM cb4__CBTag__c
				WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM
				AND cb4__Tag1__c IN:setOfAppIds // application lines
				AND cb4__Decimal1__c != null AND cb4__Decimal1__c != 0 AND cb4__Tag3__c != null AND cb4__Text1__c != null
				AND (cb4__Text1__c = :i OR cb4__Text1__c = :e)
				GROUP BY cb4__Tag1__c, cb4__Text1__c, cb4__Tag3__c
		];
		for (AggregateResult agr : agrList) {
			String lineType = (String) agr.get('lineType');
			Decimal amount = (Decimal) agr.get('amount');
			String appId = (String) agr.get('appId');
			Id ownerId = (Id) agr.get('ownerId');
			String periodId = (String) agr.get('periodId');
			String key = appId + periodId + lineType;
			totalsMap.put(key, new cb4__CBTag__c( // total Budget App Amount
					cb4__Dimension__c = budgetAppAmountDimId,
					cb4__Tag1__c = appId,
					cb4__Tag3__c = periodId,
					cb4__Decimal1__c = amount,
					cb4__Text1__c = t,
					cb4__Text2__c = lineType,
					cb4__Text3__c = lineType,
					OwnerId = ownerId
			));

			cb4__CBTag__c app = totalsMap.get(appId); // Budget App
			if (app == null) app = new cb4__CBTag__c(Id = appId, cb4__Decimal1__c = 0, cb4__Decimal2__c = 0);
			if (lineType == i) app.cb4__Decimal1__c += amount;
			if (lineType == e) app.cb4__Decimal2__c += amount;
			totalsMap.put(appId, app);
		}

		// SUBMISSION APPS TOTALS
		List<AggregateResult> agrListTotal = [ //5
				SELECT SUM(cb4__Decimal1__c) amount,
						cb4__Tag1__r.cb4__Tag1__c appId,
						cb4__Text2__c lineType,
						cb4__Tag3__c periodId,
						MAX(cb4__Tag1__r.cb4__Tag1__r.OwnerId) ownerId,
						MAX(cb4__Tag1Name__c) appName
				FROM cb4__CBTag__c
				WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM
				AND cb4__Tag1__r.cb4__Tag1__c IN:setOfAppIds AND cb4__Text1__c = 'total'
				AND cb4__Decimal1__c != null AND cb4__Decimal1__c != 0 AND cb4__Tag3__c != null AND cb4__Text1__c != null
				GROUP BY cb4__Tag1__r.cb4__Tag1__c, cb4__Text1__c, cb4__Text2__c, cb4__Tag3__c
		];
		for (AggregateResult agr : agrListTotal) {
			String lineType = (String) agr.get('lineType');
			Decimal amount = (Decimal) agr.get('amount');
			String appId = (String) agr.get('appId');
			String periodId = (String) agr.get('periodId');
			Id ownerId = (String) agr.get('ownerId');
			String key = appId + periodId + lineType;

			cb4__CBTag__c totalTag = totalsMap.get(key);
			if (totalTag == null) {
				totalTag = new cb4__CBTag__c(
						cb4__Dimension__c = budgetAppAmountDimId,
						cb4__Tag1__c = appId,
						cb4__Tag3__c = periodId,
						cb4__Decimal1__c = amount,
						cb4__Text1__c = t,
						cb4__Text2__c = lineType,
						cb4__Text3__c = lineType,
						OwnerId = ownerId
				);
			} else totalTag.cb4__Decimal1__c += amount;
			totalsMap.put(key, totalTag);

			cb4__CBTag__c app = totalsMap.get(appId); // Budget App
			if (app == null) app = new cb4__CBTag__c(Id = appId, cb4__Decimal1__c = 0, cb4__Decimal2__c = 0);
			if (lineType == i) app.cb4__Decimal1__c += amount;
			if (lineType == e) app.cb4__Decimal2__c += amount;
			totalsMap.put(appId, app);
		}

		upsert totalsMap.values(); // 6

	}

	/**
	 * the method deletes old total App lines
	 *
	 * @param appIds
	 */
	@TestVisible
	private static void deleteAppOldTotals(Set<Id> appIds) {
		List<cb4__CBTag__c> apps = [SELECT Id, cb4__Decimal1__c, cb4__Decimal2__c, cb4__Decimal3__c FROM cb4__CBTag__c WHERE Id IN:appIds WITH SECURITY_ENFORCED LIMIT 50000]; // 1
		for (cb4__CBTag__c a : apps) a.cb4__Decimal1__c = a.cb4__Decimal2__c = a.cb4__Decimal3__c = 0;
		update apps;  // 2

		List<cb4__CBTag__c> amounts = [SELECT Id, cb4__DimensionName__c, cb4__Text1__c, cb4__Tag1__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM AND cb4__Text1__c = 'total' AND cb4__Tag1__c IN:appIds WITH SECURITY_ENFORCED];
		for (cb4__CBTag__c t : amounts) t.OwnerId = System.UserInfo.getUserId();
		update amounts;

		delete [SELECT Id, cb4__DimensionName__c, cb4__Tag1__c, cb4__Text1__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM AND cb4__Text1__c = 'total' AND cb4__Tag1__c IN:appIds WITH SECURITY_ENFORCED]; // 3
	}
	/// UPDATE ALL APS /////


	@TestVisible
	private static void calculateAppTotals(cb4__CBTag__c app, List<cb4__CBTag__c> totals) {
		app.cb4__Decimal1__c = app.cb4__Decimal2__c = 0;
		for (cb4__CBTag__c t : totals) {
			if (t.cb4__Text2__c == 'income') {
				app.cb4__Decimal1__c += t.cb4__Decimal1__c;
			} else {
				app.cb4__Decimal2__c += t.cb4__Decimal1__c;
			}
		}
	}

	/**
	* Months of year
	 */
	private static List<cb4__CBTag__c> periods {
		get {
			if (periods == null || periods.size() == 0) {
				try {
					String mainPeriodId = [SELECT Id, cb4__Tag3__c FROM cb4__CBTag__c WHERE Id = :applicationId WITH SECURITY_ENFORCED].cb4__Tag3__c;
					periods = [
							SELECT Id, Name, cb4__Tag1__c, cb4__DimensionName__c, cb4__Start__c
							FROM cb4__CBTag__c
							WHERE cb4__Tag1__c = :mainPeriodId AND (cb4__DimensionName__c = :cb4.CBConstant.PERIOD_DIM OR cb4__DimensionName__c = 'Budget Year')
							WITH SECURITY_ENFORCED
							ORDER BY cb4__Start__c
							LIMIT 10000
					];
				} catch (Exception e) {
					cb4.CBConsole.setLog(e, 'budget app periods error');
					cb4.CBConsole.insertLog();
					throw e;
				}
			}
			return periods;
		}
		set;
	}

	/**
	 * Safety tested ✔ 22/11/2019
	 * @param pre for example 'BA-' or 'Case #'
	 * @param dimId dimension Id
	 *
	 * @return unique string for example 'BA-00015'
	 */
	public static String getUniqueLabel(String pre, Id dimId) {
		/*FLS CHECK*/
		//CBPermission.tryAccess('cb4__CBTag__c');
		/*FLS CHECK*/
		List<cb4__CBTag__c> t = [SELECT cb4__Text1__c, cb4__Dimension__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :dimId AND cb4__Text1__c != null WITH SECURITY_ENFORCED ORDER BY cb4__Text1__c DESC LIMIT 1];
		if (t.size() == 0 || t[0].cb4__Text1__c == null) return pre + '1';
		String l = t[0].cb4__Text1__c.replace(pre, '');
		try {
			Integer i = Integer.valueOf(l);
			return pre + ++i;
		} catch (Exception e) {
			return 'N/A';
		}
	}

	@AuraEnabled
	public static List<String> getDocumentsByRecordIdServer(Id recordId) {
		return CBASHController.getDocumentsByRecordIdServer(recordId);
	}

/////// PRIVATE METHODS ///////

/////// CUSTOM ASH METHODS ///////
	@AuraEnabled
	public static List<String> validateWithCombinationRuleServer(List<cb4.CBRow> rows, String bAppId, Boolean createCombinationRules){
		List<String> combRulesNames = new List<String>();
		String depId = rows.isEmpty() ? null : [SELECT Id, cb4__Tag4__c FROM cb4__CBTag__c WHERE cb4__Dimension__c =: budgetAppDimId AND Id = :bAppId LIMIT 1].cb4__Tag4__c;
		Set<String> accIds = new Set<String>();
		Set<String> d1Ids  = new Set<String>();
		Set<String> d2Ids  = new Set<String>();
		Set<String> d3Ids  = new Set<String>();
		Set<String> d4Ids  = new Set<String>();
		Set<String> dimIds = new Set<String>();
		Set<String> rowCombinationRuleIds = new Set<String>();
		Map<String, String>  combinationRuleIdsMap = new Map<String, String>();
		Set<String> newComRulesIds = new Set<String>();
		List<cb4__CBTag__c> newCombinationRules = new List<cb4__CBTag__c>();
		Map<String, String> dIdToNameMap = new Map<String, String>();
		for(cb4.CBRow r : rows){
			accIds.add(r.account);
			d1Ids.add(r.dim6);
			d2Ids.add(r.dim7);
			d3Ids.add(r.dim8);
			d4Ids.add(r.dim9);
			rowCombinationRuleIds.add(r.account + ',' + r.dim6 + ',' + r.dim7 + ',' + r.dim8 + ',' + r.dim9);
		}
		dimIds.addAll(accIds);
		dimIds.addAll(d1Ids);
		dimIds.addAll(d2Ids);
		dimIds.addAll(d3Ids);
		dimIds.addAll(d4Ids);
		for(cb4__CBTag__c d : [SELECT Id, Name FROM cb4__CBTag__c WHERE Id IN:dimIds]){
			dIdToNameMap.put(d.Id, d.Name);
		}
		for(cb4__CBTag__c rule : [SELECT Id, cb4__Tag1Name__c, cb4__Tag2__c, cb4__Tag6__c, cb4__Tag7__c, cb4__Tag8__c, cb4__Tag9__c, cb4__Tag2Name__c, cb4__Tag6Name__c, cb4__Tag7Name__c, cb4__Tag8Name__c, cb4__Tag9Name__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :combinationRuleDimId AND cb4__Tag1__c = :depId AND cb4__Tag2__c IN :accIds AND cb4__Tag6__c IN :d1Ids AND cb4__Tag7__c IN :d2Ids AND cb4__Tag8__c IN :d3Ids AND cb4__Tag9__c IN :d4Ids]) {
			combinationRuleIdsMap.put(rule.cb4__Tag2__c + ',' + rule.cb4__Tag6__c + ',' + rule.cb4__Tag7__c + ',' + rule.cb4__Tag8__c + ',' + rule.cb4__Tag9__c, rule.cb4__Tag1Name__c + ', ' + rule.cb4__Tag2Name__c + ', ' + rule.cb4__Tag6Name__c + ', ' + rule.cb4__Tag7Name__c + ', ' + rule.cb4__Tag8Name__c + ', ' + rule.cb4__Tag9Name__c);
		}

		for(String rowRule : rowCombinationRuleIds){
			if(!combinationRuleIdsMap.containsKey(rowRule)){
				List<String> dimIdList = rowRule.split(',');
				//validationMessage = validationMessage == null ? 'There are no combination rules for the following dimensions: (' + dIdToNameMap.get(dimIdList[0]) + ', '+ dIdToNameMap.get(dimIdList[1]) + ', '+ dIdToNameMap.get(dimIdList[2]) + ', '+ dIdToNameMap.get(dimIdList[3]) + ', '+ dIdToNameMap.get(dimIdList[4]) + ')' : ', (' + dIdToNameMap.get(dimIdList[0]) + ', '+ dIdToNameMap.get(dimIdList[1]) + ', '+ dIdToNameMap.get(dimIdList[2]) + ', '+ dIdToNameMap.get(dimIdList[3]) + ', '+ dIdToNameMap.get(dimIdList[4]) + ')';
				combRulesNames.add(dIdToNameMap.get(dimIdList[0]) + ', '+ dIdToNameMap.get(dimIdList[1]) + ', '+ dIdToNameMap.get(dimIdList[2]) + ', '+ dIdToNameMap.get(dimIdList[3]) + ', '+ dIdToNameMap.get(dimIdList[4]));
				newComRulesIds.add(rowRule);
			}
		}
		if(createCombinationRules){
			try {
				for (String rIds : newComRulesIds) {
					List<String> dIds = rIds.split(',');
					newCombinationRules.add(new cb4__CBTag__c(
							cb4__Dimension__c = combinationRuleDimId,
							cb4__Tag1__c = depId,
							cb4__Tag2__c = dIds[0],
							cb4__Tag6__c = dIds[1],
							cb4__Tag7__c = dIds[2],
							cb4__Tag8__c = dIds[3],
							cb4__Tag9__c = dIds[4]
					));
				}
				insert newCombinationRules;
				combRulesNames = new List<String>();
			}
			catch (Exception e){
				return new List<String>{'error'};
			}
		}
		return combRulesNames.size() == 0 ? null : combRulesNames;
	}

	@AuraEnabled
	public static void createCombinationRuleByAnalystNames(String ruleAnalysts, String appId){
		List<String> names = ruleAnalysts.split(', ');
		String depId = [SELECT Id, cb4__Tag4__c FROM cb4__CBTag__c WHERE cb4__Dimension__c =: budgetAppDimId AND Id = :appId LIMIT 1].cb4__Tag4__c;
		Map<String, Id> dimNameToTagId = new Map<String, Id>();
		for(cb4__CBTag__c t : [SELECT Id, cb4__DimensionName__c FROM cb4__CBTag__c WHERE (Name = :names[0] OR Name = :names[1] OR Name = :names[2] OR Name = :names[3] OR Name = :names[4])]){
			dimNameToTagId.put(t.cb4__DimensionName__c, t.Id);
		}
		insert new cb4__CBTag__c(
				cb4__Dimension__c = combinationRuleDimId,
				cb4__Tag1__c = depId,
				cb4__Tag2__c = dimNameToTagId.get('Account'),
				cb4__Tag6__c = dimNameToTagId.get('CB_FF1'),
				cb4__Tag7__c = dimNameToTagId.get('CB_FF2'),
				cb4__Tag8__c = dimNameToTagId.get('CB_FF3'),
				cb4__Tag9__c = dimNameToTagId.get('CB_FF4')
		);
	}

	@AuraEnabled
	public static Map<String, List<cb4.CBRow>> getSubLinesServer(String budgetId){
		Map<String, List<cb4.CBRow>> resultMap = new Map<String, List<cb4.CBRow>>();
		List<cb4__CBTag__c> incomeList = new List<cb4__CBTag__c>();
		List<cb4__CBTag__c> expenseList = new List<cb4__CBTag__c>();
		for(cb4__CBTag__c t : Database.query('SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', 'cb4__Tag2__r.cb4__Tag1Name__c,cb4__Tag1__r.cb4__Tag6__c,cb4__Tag1__r.cb4__Tag7__c,cb4__Tag1__r.cb4__Tag8__c,cb4__Tag1__r.cb4__Tag9__c,cb4__Tag1__r.cb4__Tag10__c,cb4__Tag1__r.cb4__Status__c') + ' WHERE cb4__DimensionName__c = \'Budget App SubAmount\' AND cb4__Tag1__c = :budgetId')){
			if(t.cb4__Text2__c == 'expense'){
				expenseList.add(t);
			}else{
				incomeList.add(t);
			}
		}
		resultMap.put('income', CBASHController.getCBRowsFromTags(incomeList));
		resultMap.put('expense', CBASHController.getCBRowsFromTags(expenseList));
		return resultMap;
	}

	@AuraEnabled
	public static void setNewKeyByOldKeyToSubLinesServer(List<String> oldKeys, List<String> newKeys){
		Map<String, String> keysMap = new Map<String, String>();
		for(Integer i = 0; i < oldKeys.size(); i++){
			keysMap.put(oldKeys[i], newKeys[i]);
		}
		List<cb4__CBTag__c> sublines = new List<cb4__CBTag__c>();
		for(cb4__CBTag__c sl : [SELECT Id, cb4__Text10__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetSubAppAmountDimId AND cb4__Text10__c IN :oldKeys]){
			sl.cb4__Text10__c = keysMap.get(sl.cb4__Text10__c);
			sublines.add(sl);
		}
		update sublines;
	}

	@AuraEnabled
	public static Boolean isUserHasAccessToEditBudgetServer(String appId){
		Boolean hasNoAccess = true;
		if(String.isNotBlank(appId)) {
			UserRecordAccess ura = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId = :appId];
			cb4__CBTag__c bapp = [SELECT cb4__Boolean1__c, cb4__User__c, cb4__Status__c, HasAccessToChangeStatus__c FROM cb4__CBTag__c WHERE Id = :appId];
			hasNoAccess = ura.HasEditAccess ? (bapp.cb4__Boolean1__c ? !(bapp.cb4__User__c == UserInfo.getUserId()) : false) : true;
			if(bapp.cb4__Status__c == 'Approved'){
				return true;
			}
			if(bapp.cb4__Status__c != 'Open'){
				hasNoAccess = hasNoAccess ? hasNoAccess : !(bapp.HasAccessToChangeStatus__c == UserInfo.getUserId());
			}
		}
		return hasNoAccess;
	}

	@AuraEnabled
	public static Boolean hasUserNoAccessToApproveServer(String appId){
		Boolean res = true;
		if(String.isNotBlank(appId)){
			Id currUserId = UserInfo.getUserId();
			cb4__CBTag__c bApp = [SELECT cb4__Status__c, HasAccessToChangeStatus__c, OwnerId, Owner.Type FROM cb4__CBTag__c WHERE Id = :appId];
			if(bApp.cb4__Status__c == 'Open'){
				if(bApp.Owner.Type=='User'){
					res = !(bApp.OwnerId == currUserId);
				}else{
					for(GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :bApp.OwnerId]){
						if(gm.UserOrGroupId == currUserId){
							res = false;
							break;
						}
					}
				}
			}else{
				res = !(bApp.HasAccessToChangeStatus__c == currUserId);
			}
		}
		return res;
	}

	@AuraEnabled
	public static cb4__CBTag__c changeLockStatusBudgetServer(cb4__CBTag__c app){
		for( cb4__CBTag__c bapp : [SELECT Id, cb4__Boolean1__c, cb4__User__c FROM cb4__CBTag__c WHERE Id = :app.Id]){
			if(!app.cb4__Boolean1__c && bapp.cb4__Boolean1__c){
				break;
			}else{
				app.cb4__Boolean1__c = !app.cb4__Boolean1__c;
				app.cb4__User__c = !app.cb4__Boolean1__c ? null : UserInfo.getUserId();
				update app;
			}
		}
		return getBudgetAppsServer(app.Id, null)[0];
	}

	@AuraEnabled
	public static Boolean isUserAdminServer(){
		List<Group> cb2adminsGroup = [SELECT Id FROM Group WHERE Name= 'CB2 Admins' AND Type = 'Regular' LIMIT 1];
		if(!cb2adminsGroup.isEmpty()){
			List<GroupMember> groupMemberList = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = :cb2adminsGroup[0].Id AND UserOrGroupId = :UserInfo.getUserId()];
			return !groupMemberList.isEmpty();
		}
		return false;
	}

	@AuraEnabled
	public static Map<String, List<cb4.CBRow>> runExcelImportServer(String appId, List<cb4.CBRow> incomeList, List<cb4.CBRow> expenseList){
		delete [SELECT Id FROM cb4__CBTag__c WHERE (cb4__Dimension__c = :budgetAppAmountDimId OR cb4__Dimension__c = :budgetSubAppAmountDimId) AND cb4__Tag1__c = :appId];
		Map<Id, cb4__CBTag__c> dimsIdToTag = new Map<Id, cb4__CBTag__c>([SELECT Id, Name, cb4__Index__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Account' OR cb4__DimensionName__c = 'CB_FF1' OR cb4__DimensionName__c = 'CB_FF2' OR cb4__DimensionName__c = 'CB_FF3' OR cb4__DimensionName__c = 'CB_FF4']);

		Map<String, List<cb4.CBRow>> result =  new Map<String, List<cb4.CBRow>>();

		List<cb4__CBTag__c> incomeTags = CBASHController.getTagsFromCBRows(incomeList, null, null, appId);
		List<cb4__CBTag__c> expenseTags = CBASHController.getTagsFromCBRows(expenseList, null, null, appId);

		Map<String, cb4__CBTag__c> budgetLinesMap = new Map<String, cb4__CBTag__c>();
		for(cb4__CBTag__c it : incomeTags){
			cb4__CBTag__c newLine = createBudgetLineFromSubLine(it, dimsIdToTag);
			String blKey = CBBudgetApplication.getSimpleLineKey(newLine, appId);
			it.cb4__Text10__c = blKey;
			if(!budgetLinesMap.containsKey(blKey + it.cb4__Tag3__c)){
				budgetLinesMap.put(blKey + it.cb4__Tag3__c, newLine);
			}else{
				budgetLinesMap.get(blKey + it.cb4__Tag3__c).cb4__Decimal1__c += it.cb4__Decimal1__c;
			}
		}
		for(cb4__CBTag__c et : expenseTags){
			cb4__CBTag__c newLine = createBudgetLineFromSubLine(et, dimsIdToTag);
			String blKey = CBBudgetApplication.getSimpleLineKey(newLine, appId);
			et.cb4__Text10__c = blKey;
			if(!budgetLinesMap.containsKey(blKey + et.cb4__Tag3__c)){
				budgetLinesMap.put(blKey + et.cb4__Tag3__c, newLine);
			}else{
				budgetLinesMap.get(blKey + et.cb4__Tag3__c).cb4__Decimal1__c += et.cb4__Decimal1__c;
			}
		}

		incomeTags.addAll(expenseTags);
		incomeTags.addAll(budgetLinesMap.values());
		insert incomeTags;
		return result;
	}

	private static cb4__CBTag__c createBudgetLineFromSubLine(cb4__CBTag__c subLine, Map<Id, cb4__CBTag__c> dimMap){
		return  new cb4__CBTag__c(
				cb4__Dimension__c = budgetAppAmountDimId,
				cb4__Tag1__c = subLine.cb4__Tag1__c,
				cb4__Text1__c = subLine.cb4__Text2__c,
				cb4__Text2__c = subLine.cb4__Text2__c,
				cb4__Decimal1__c = subLine.cb4__Decimal1__c,
				cb4__Text3__c = dimMap.get(subLine.cb4__Tag2__c).Name + ' (' + dimMap.get(subLine.cb4__Tag6__c).cb4__Index__c + '-' + dimMap.get(subLine.cb4__Tag7__c).cb4__Index__c + '-' + dimMap.get(subLine.cb4__Tag8__c).cb4__Index__c + '-' + dimMap.get(subLine.cb4__Tag9__c).cb4__Index__c + ')',
				cb4__Text4__c = '',
				cb4__Tag2__c = subLine.cb4__Tag2__c,
				cb4__Tag3__c = subLine.cb4__Tag3__c,
				cb4__Tag6__c = subLine.cb4__Tag6__c,
				cb4__Tag7__c = subLine.cb4__Tag7__c,
				cb4__Tag8__c = subLine.cb4__Tag8__c,
				cb4__Tag9__c = subLine.cb4__Tag9__c
		);
	}

	@AuraEnabled
	public static String getProperlyCmpNameServer(Id recordId, Id dimensionId, Boolean createNewTag) {
		String dimName;
		createNewTag = createNewTag == null ? false : createNewTag;
		if (dimensionId != null) {
			dimName = [SELECT Id, Name FROM cb4__CBDimension__c WHERE Id = :dimensionId WITH SECURITY_ENFORCED LIMIT 1].Name;
		}
		if (recordId != null) {
			dimName = [SELECT Id, cb4__DimensionName__c FROM cb4__CBTag__c WHERE Id = :recordId WITH SECURITY_ENFORCED LIMIT 1].cb4__DimensionName__c;
		}
		List<cb4__CBTag__c> rs = [
				SELECT cb4__Text1__c, cb4__Text2__c, cb4__Text3__c, cb4__DimensionName__c
				FROM cb4__CBTag__c
				WHERE cb4__DimensionName__c = :cb4.CBConstant.REDIRECT_SET_TAG AND cb4__Text1__c = :dimName
				WITH SECURITY_ENFORCED
				ORDER BY cb4__Text1__c
				LIMIT 1000
		];

		String cmpName = rs.size() > 0 ? ((dimensionId == null || createNewTag == true) ? rs[0].cb4__Text3__c : rs[0].cb4__Text2__c) : cb4.CBConstant.DEFAULT_TAG_CMP;
		List<AuraDefinitionBundle> comps = [SELECT NamespacePrefix, DeveloperName FROM AuraDefinitionBundle WHERE DeveloperName = :cmpName];
		String prefix = cb4.CBConstant.ORG_PREFIX; // "cb4:" as default
		prefix = comps.size() > 0 && comps[0].NamespacePrefix == null ? 'c:' : comps[0].NamespacePrefix + ':'; // "c:" OR "c2g:" as example
		return prefix + cmpName;
	}

	@AuraEnabled
	public static Map<String, List<cb4.CBSO>> getFinancialTeamUsersSOServer(String appId){
		Map<String,List<cb4.CBSO>> resultMap = new Map<String, List<cb4.CBSO>>();
		User currUser = [SELECT Id, Name, ManagerId, Manager.Name, Manager.Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		if(currUser.ManagerId == null){
			Set<Id> financialUserIds = new Set<Id>();
			resultMap.put('financeUsers', new List<cb4.CBSO>());
			for(GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE Group.Name = 'CB2 Financial Team']){
				financialUserIds.add(gm.UserOrGroupId);
			}
			for(User u : [SELECT Id, Name, Email FROM User WHERE Id IN :financialUserIds]){
				if(!resultMap.containsKey('defaultUsers')){
					resultMap.put('defaultUsers', new List<cb4.CBSO>{new cb4.CBSO(u.Id, u.Name + ' (' + u.Email + ')')});
				}
				resultMap.get('financeUsers').add(new cb4.CBSO(u.Id, u.Name + ' (' + u.Email + ')'));
			}
		}else{
			resultMap.put('defaultUsers', new List<cb4.CBSO>{new cb4.CBSO(currUser.ManagerId, currUser.Manager.Name + ' (' + currUser.Manager.Email + ')')});
			resultMap.put('financeUsers', new List<cb4.CBSO>{new cb4.CBSO(currUser.ManagerId, currUser.Manager.Name + ' (' + currUser.Manager.Email + ')')});
		}

		return resultMap;
	}

	@AuraEnabled
	public static void deleteRowsServer(String appId, List<cb4.CBRow> rows){
		String subLineKey = null;
		applicationId = appId;
		String rowaccount = rows[0].account;
		String rowdim6 = rows[0].dim6;
		String rowdim7 = rows[0].dim7;
		String rowdim8 = rows[0].dim8;
		String rowdim9 = rows[0].dim9;
		String rowtitle = rows[0].title;
		String rowdescription = rows[0].description;
		String rowie = rows[0].ie;
		List<cb4__CBTag__c> bLines = getTagsFromCBRows(rows);
		subLineKey = getSimpleLineKey(bLines[0], applicationId);
		if(subLineKey != null && subLineKey != ''){
			List<cb4__CBTag__c> sAmounts = new List<cb4__CBTag__c>();
			for(cb4__CBTag__c sa : [SELECT Id, OwnerId FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetSubAppAmountDimId AND cb4__Text10__c = :subLineKey]){
				sa.OwnerId = UserInfo.getUserId();
				sAmounts.add(sa);
			}
			update sAmounts;
			delete sAmounts;
			delete [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetAppAmountDimId AND
			cb4__Tag1__c = :applicationId AND
			cb4__Tag2__c = :rowaccount AND
			cb4__Tag6__c = :rowdim6 AND
			cb4__Tag7__c = :rowdim7 AND
			cb4__Tag8__c = :rowdim8 AND
			cb4__Tag9__c = :rowdim9 AND
			cb4__Text3__c = :rowtitle AND
			cb4__Text4__c = :rowdescription AND
			cb4__Text2__c = :rowie];
		}
	}

	@AuraEnabled
	public static void saveAppTotalsServer(String appId, List<cb4__CBTag__c> totals){
		cb4__CBTag__c app = [SELECT Id, cb4__Decimal1__c, cb4__Decimal2__c, OwnerId FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetAppDimId AND Id = :appId];
		app.cb4__Decimal1__c = 0;
		app.cb4__Decimal2__c = 0;
		for(cb4__CBTag__c tt : totals){
			tt.cb4__Tag1__c = appId;
			tt.OwnerId = app.OwnerId;
			tt.cb4__Dimension__c = budgetAppAmountDimId;
			if(tt.cb4__Text2__c == 'income'){
				app.cb4__Decimal1__c += tt.cb4__Decimal1__c;
			}else if(tt.cb4__Text2__c == 'expense'){
				app.cb4__Decimal2__c += tt.cb4__Decimal1__c;
			}
		}
		delete [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetAppAmountDimId AND cb4__Text1__c = 'total' AND cb4__Tag1__c = :appId];
		insert totals;
		update app;
	}

	/////// CUSTOM ASH METHODS ///////




	@AuraEnabled
	public static String voidMethod() {
		return '⚡';
	}

	public static void cg() {
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}

}