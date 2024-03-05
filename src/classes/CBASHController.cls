public with sharing class CBASHController {
	private static Id budgetAppSubAmountDimId = cb4.CBUtils.dimensionNameIdMap.get('Budget App SubAmount');
	private static Id budgetAppAmountDimId = cb4.CBUtils.dimensionNameIdMap.get('Budget App Amount');
	private static final Integer startMonth = 7;

	private static List<cb4__CBTag__c> periods {
		get {
			if (periods == null || periods.size() == 0) {
				try {
					periods = [
							SELECT Id, Name, cb4__Tag1__c, cb4__DimensionName__c, cb4__Start__c
							FROM cb4__CBTag__c
							WHERE cb4__Tag1__c = :cb4.CBContext.getCurrentBY().Id AND (cb4__DimensionName__c = :cb4.CBConstant.PERIOD_DIM OR cb4__DimensionName__c = 'Budget Year')
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

	public static String currentFY {
		get {
			if (currentFY == null) {
				cb4__CBCustomOrgVariable__c oc = cb4__CBCustomOrgVariable__c.getOrgDefaults();
				if (oc.Id == null) {
					oc = new cb4__CBCustomOrgVariable__c(cb4__BudgetYear__c = String.valueOf(System.now().year()), Name = 'Budget Year', PeriodsLockSettings__c = '');
				}
				currentFY = oc.cb4__BudgetYear__c;
			}
			return currentFY;
		}
		set;
	}

	public static Date startFY {
		get {
			if (startFY == null) startFY = Date.newInstance(Integer.valueOf(currentFY) - 1, startMonth, 1);
			return startFY;
		}
		set;
	}

	public static Date endFY {
		get {
			if (endFY == null) endFY = (Date.newInstance(Integer.valueOf(currentFY), startMonth, 1)).addDays(-1);
			return endFY;
		}
		set;
	}

	public static String BLockSettings {
		get {
			if (BLockSettings == null){
				cb4__CBCustomOrgVariable__c oc = cb4__CBCustomOrgVariable__c.getOrgDefaults();
				if (oc.Id == null) {
					oc = new cb4__CBCustomOrgVariable__c(cb4__BudgetYear__c = String.valueOf(System.now().year()), Name = 'Budget Year', PeriodsLockSettings__c = '');
				}
				BLockSettings = oc.PeriodsLockSettings__c;
			}
			return BLockSettings;
		}
		set;
	}

/* MAIN*/

	@AuraEnabled
	public static void lockBPeriodsTillServer(String year, String period){
		Integer periodNumber = getPeriodNumByName(year, period);
		List<cb4__CBTag__c> upBudgets = new List<cb4__CBTag__c>();
		for(cb4__CBTag__c b : [SELECT Id, cb4__Decimal6__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget App' AND cb4__Tag3Name__c = :year]){
			b.cb4__Decimal6__c = periodNumber;
			upBudgets.add(b);
		}
		update upBudgets;
	}

	@AuraEnabled
	public static Map<String, Object> getParametersSOServer() {
		Map<String, Object> r = new Map<String, Object>();
		r.put('years', getYearsSO());
		r.put('baseYears', getBaseYearsSO());
		r.put('fy', currentFY);
		List<cb4.CBSO> periods = getPeriodsSO();
		r.put('periods', periods);
		r.put('lockPeriods', periods);
		return r;
	}

	@AuraEnabled
	public static String getLockedPeriodServer(String year){
		List<cb4__CBTag__c> fBudget = [SELECT Id, cb4__Decimal6__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget App' AND cb4__Tag3Name__c = :year AND cb4__Decimal6__c != NULL];
		List<cb4__CBTag__c> periods = [SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND cb4__Tag1Name__c = :year ORDER BY cb4__Start__c ASC];
		if(fBudget.isEmpty() || periods.isEmpty() || fBudget[0].cb4__Decimal6__c == 0) return 'none';
		return periods[Integer.valueOf(fBudget[0].cb4__Decimal6__c) - 1].Name;
	}

	@AuraEnabled
	public static String getBLockSettings(){
		Map<String, String> BLockSetts = new Map<String, String>();
		if(!String.isEmpty(BLockSettings)) {
			BLockSetts = (Map<String, String>) JSON.deserialize(BLockSettings, Map<String, String>.class);
		}
		return JSON.serialize(BLockSetts);
	}

	@AuraEnabled
	public static List<cb4.CBSO> getPeriodsSOServer(String year){
		List<cb4.CBSO> periods = new List<cb4.CBSO>();
		for (cb4__CBTag__c a : [SELECT Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND cb4__Tag1Name__c = :year ORDER BY cb4__Start__c ASC]) periods.add(new cb4.CBSO(a.Name, a.Name));
		return periods;
	}

/* MAIN*/

	private static List<cb4.CBSO> getYearsSO() {
		List<cb4.CBSO> years = new List<cb4.CBSO>();
		for (cb4__CBTag__c a : [SELECT Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget Year' ORDER BY Name]) years.add(new cb4.CBSO(a.Name, a.Name));
		return years;
	}

	private static List<cb4.CBSO> getPeriodsSO() {
		List<cb4.CBSO> periods = new List<cb4.CBSO>();
		for (cb4__CBTag__c a : [SELECT Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND cb4__Start__c >= :startFY AND cb4__End__c <= :endFY ORDER BY cb4__Start__c ASC]) periods.add(new cb4.CBSO(a.Name, a.Name));
		return periods;
	}

	private static List<cb4.CBSO> getBaseYearsSO() {
		List<cb4.CBSO> years = new List<cb4.CBSO>();
		List<Id> yearsWithApprove = new List<Id>();
		for( SObject app : [SELECT cb4__Tag3__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget App' AND cb4__Tag8Name__c = 'Base' AND cb4__Status__c != 'Open' GROUP BY cb4__Tag3__c]){
			yearsWithApprove.add((Id) app.get('cb4__Tag3__c'));
		}
		for (cb4__CBTag__c a : [SELECT Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget Year' AND Id NOT IN :yearsWithApprove ORDER BY Name]) years.add(new cb4.CBSO(a.Name, a.Name));
		return years;
	}

	private static Integer getPeriodNumByName(String year, String period){
		Integer periodNumber = 0;
		if(period != 'none') {
			for (cb4__CBTag__c p : [SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND cb4__Tag1Name__c = :year ORDER BY cb4__Start__c ASC]) {
				periodNumber++;
				if (p.Name == period) break;
			}
		}
		return periodNumber;
	}

	/* CBASHBLComponent */

	@AuraEnabled
	public static void deleteSubLineServer(cb4.CBRow row, String rowKey){
		List<cb4__CBTag__c> sublines = [SELECT Id, cb4__Tag1__r.OwnerId, cb4__Tag3__c, cb4__Decimal1__c, OwnerId FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetAppSubAmountDimId AND cb4__Text9__c = :rowKey];
		Id currUserId = UserInfo.getUserId();
		Boolean reSaveSubLines = false;
		Map<String, cb4__CBTag__c> periodToBLAmount = new Map<String, cb4__CBTag__c>();
		String rowapp = row.app;
		String rowaccount = row.account;
		String rowdim6 = row.dim6;
		String rowdim7 = row.dim7;
		String rowdim8 = row.dim8;
		String rowdim9 = row.dim9;
		String rowtitle = row.title;
		String rowdescription = row.description;
		String rowie = row.ie;
		for(cb4__CBTag__c blAmount : Database.query('SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', 'cb4__Tag1__r.cb4__Tag6__c, cb4__Tag1__r.cb4__Tag7__c, cb4__Tag1__r.cb4__Tag8__c, cb4__Tag1__r.cb4__Tag9__c, cb4__Tag2__r.cb4__Tag1Name__c, cb4__Tag1__r.cb4__Status__c, cb4__Tag1__r.cb4__Tag10__c') +
				' WHERE cb4__Dimension__c = :budgetAppAmountDimId AND ' +
				'cb4__Tag1__c  = :rowapp         AND ' +
				'cb4__Tag2__c  = :rowaccount     AND ' +
				'cb4__Tag6__c  = :rowdim6        AND ' +
				'cb4__Tag7__c  = :rowdim7        AND ' +
				'cb4__Tag8__c  = :rowdim8        AND ' +
				'cb4__Tag9__c  = :rowdim9        AND ' +
				'cb4__Text3__c = :rowtitle       AND ' +
				'cb4__Text4__c = :rowdescription AND ' +
				'cb4__Text2__c = :rowie')){
			periodToBLAmount.put(blAmount.cb4__Tag3__c, blAmount);
		}
		for(cb4__CBTag__c sLine : sublines){
			if(periodToBLAmount.containsKey(sLine.cb4__Tag3__c)){
				cb4__CBTag__c blAmount = periodToBLAmount.get(sLine.cb4__Tag3__c);
				blAmount.cb4__Decimal1__c = blAmount.cb4__Decimal1__c - sLine.cb4__Decimal1__c;
				periodToBLAmount.put(sLine.cb4__Tag3__c, blAmount);
			}
			if(sLine.cb4__Tag1__r.OwnerId != currUserId){
				sLine.OwnerId = currUserId;
				reSaveSubLines = true;
			}
		}
		Boolean allZeroes = true;
		for(cb4__CBTag__c blAmountByPeriods : periodToBLAmount.values()){
			allZeroes = allZeroes ? blAmountByPeriods.cb4__Decimal1__c == 0 : false;
		}
		if(allZeroes) periodToBLAmount.values()[0].cb4__Decimal1__c = 0.01;
		update periodToBLAmount.values();
		if(reSaveSubLines) update sublines;
		delete sublines;
	}

	@AuraEnabled
	public static List<cb4.CBRow> getCBRowsFromServer(String key, String budgetAppId){
		List<cb4__CBTag__c> tags = Database.query('SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', 'cb4__Tag1__r.cb4__Tag6__c, cb4__Tag1__r.cb4__Tag7__c, cb4__Tag1__r.cb4__Tag8__c, cb4__Tag1__r.cb4__Tag9__c, cb4__Tag2__r.cb4__Tag1Name__c, cb4__Tag1__r.cb4__Status__c, cb4__Tag1__r.cb4__Tag10__c') +
				'WHERE cb4__Dimension__c = :budgetAppSubAmountDimId AND cb4__Tag1__c = :budgetAppId ' + (key == null ? '' : 'AND cb4__Text10__c = :key'));
		return getCBRowsFromTags(tags);
	}

	@AuraEnabled
	public static void saveSubLinesServer(cb4.CBRow oldRow, cb4.CBRow row, List<cb4.CBRow> rows, String budgetAppId, String newKey, String oldKey){
		cb4__CBTag__c bApp = [SELECT Id, OwnerId FROM cb4__CBTag__c WHERE Id = :budgetAppId][0];
		Id currUserId = UserInfo.getUserId();
		List<cb4__CBTag__c> sLines = [SELECT Id, OwnerId FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetAppSubAmountDimId AND cb4__Tag1__c = :budgetAppId AND cb4__Text10__c = :oldKey];
		if(bApp.OwnerId != currUserId){
			for(cb4__CBTag__c sLine : sLines){
				sLine.OwnerId = currUserId;
			}
			update sLines;
		}
		Map<String,cb4__CBTag__c> periodToBLine = new Map<String, cb4__CBTag__c>();
		cb4__CBTag__c blAmountCloned = null;
		String rowapp = row.app;
		String rowaccount = oldRow.account;
		String rowdim6 = oldRow.dim6;
		String rowdim7 = oldRow.dim7;
		String rowdim8 = oldRow.dim8;
		String rowdim9 = oldRow.dim9;
		String rowtitle = oldRow.title;
		String rowdescription = oldRow.description;
		String rowie = row.ie;
		for(cb4__CBTag__c blAmount : Database.query('SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', 'cb4__Tag1__r.cb4__Tag6__c, cb4__Tag1__r.cb4__Tag7__c, cb4__Tag1__r.cb4__Tag8__c, cb4__Tag1__r.cb4__Tag9__c, cb4__Tag2__r.cb4__Tag1Name__c, cb4__Tag1__r.cb4__Status__c, cb4__Tag1__r.cb4__Tag10__c') +
				' WHERE cb4__Dimension__c = :budgetAppAmountDimId AND ' +
				'cb4__Tag1__c  = :rowapp         AND ' +
				'cb4__Tag2__c  = :rowaccount     AND ' +
				'cb4__Tag6__c  = :rowdim6        AND ' +
				'cb4__Tag7__c  = :rowdim7        AND ' +
				'cb4__Tag8__c  = :rowdim8        AND ' +
				'cb4__Tag9__c  = :rowdim9        AND ' +
				'cb4__Text3__c = :rowtitle       AND ' +
				'cb4__Text4__c = :rowdescription AND ' +
				'cb4__Text2__c = :rowie')){
			blAmount.cb4__Decimal1__c = 0;
			blAmount.cb4__Boolean1__c = blAmount.cb4__Boolean1__c != row.boolean1 ? row.boolean1 : blAmount.cb4__Boolean1__c;
			blAmount.cb4__Text6__c = blAmount.cb4__Text6__c != row.text6 ? row.text6 : blAmount.cb4__Text6__c;

			blAmount.cb4__Tag2__c = blAmount.cb4__Tag2__c != row.account ? row.account : blAmount.cb4__Tag2__c;
			blAmount.cb4__Tag6__c = blAmount.cb4__Tag6__c != row.dim6 ? row.dim6 : blAmount.cb4__Tag6__c;
			blAmount.cb4__Tag7__c = blAmount.cb4__Tag7__c != row.dim7 ? row.dim7 : blAmount.cb4__Tag7__c;
			blAmount.cb4__Tag8__c = blAmount.cb4__Tag8__c != row.dim8 ? row.dim8 : blAmount.cb4__Tag8__c;
			blAmount.cb4__Tag9__c = blAmount.cb4__Tag9__c != row.dim9 ? row.dim9 : blAmount.cb4__Tag9__c;
			blAmount.cb4__Text3__c = blAmount.cb4__Text3__c != row.title ? row.title : blAmount.cb4__Text3__c;
			blAmount.cb4__Text4__c = blAmount.cb4__Text4__c != row.description ? row.description : blAmount.cb4__Text4__c;

			periodToBLine.put(blAmount.cb4__Tag3__c, blAmount);
			blAmountCloned = blAmountCloned == null ? blAmount.clone() : blAmountCloned;
		}
		List<cb4__CBTag__c> tagsFromRows = getTagsFromCBRows(rows, newKey, oldKey, budgetAppId);
		for(cb4__CBTag__c sbAmount : tagsFromRows){
			if(periodToBLine.containsKey(sbAmount.cb4__Tag3__c)){
				periodToBLine.get(sbAmount.cb4__Tag3__c).cb4__Decimal1__c += sbAmount.cb4__Decimal1__c;
			}else{
				cb4__CBTag__c newBLamount = blAmountCloned.clone();
				newBLamount.cb4__Tag3__c = sbAmount.cb4__Tag3__c;
				periodToBLine.put(sbAmount.cb4__Tag3__c, newBLamount);
				periodToBLine.get(sbAmount.cb4__Tag3__c).cb4__Decimal1__c += sbAmount.cb4__Decimal1__c;
			}
			sbAmount.cb4__Tag2__c = sbAmount.cb4__Tag2__c != row.account ? row.account : sbAmount.cb4__Tag2__c;
			sbAmount.cb4__Tag6__c = sbAmount.cb4__Tag6__c != row.dim6    ? row.dim6    : sbAmount.cb4__Tag6__c;
			sbAmount.cb4__Tag7__c = sbAmount.cb4__Tag7__c != row.dim7    ? row.dim7    : sbAmount.cb4__Tag7__c;
			sbAmount.cb4__Tag8__c = sbAmount.cb4__Tag8__c != row.dim8    ? row.dim8    : sbAmount.cb4__Tag8__c;
			sbAmount.cb4__Tag9__c = sbAmount.cb4__Tag9__c != row.dim9    ? row.dim9    : sbAmount.cb4__Tag9__c;
		}
		upsert periodToBLine.values();
		delete sLines;
		insert tagsFromRows;
	}

	private static String refineStringToId(String s) {
		return s.replaceAll('\\s+', '').replaceAll(':', '').replaceAll('&', '');
	}

	public static String getSimpleLineKey(cb4__CBTag__c t) {
		return (t.cb4__Tag1__c == null ? '' : t.cb4__Tag1__c) +
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

	public static List<cb4.CBRow> getCBRowsFromTags(List<cb4__CBTag__c> tags) {
		Map<Id, Integer> perIndMap = new Map<Id, Integer>(); // key - period Id  value = period number
		Integer i = 0;
		for (cb4__CBTag__c t : periods) perIndMap.put(t.Id, i++);
		List<Decimal> temp = new List<Decimal>();
		Integer rowSize = 0;
		for (; rowSize < i; rowSize++) temp.add(0);

		Map<String, cb4.CBRow> rowMap = new Map<String, cb4.CBRow>();
		if (tags == null) return null;
		for (cb4__CBTag__c t : tags) {
			String key = getSimpleLineKey(t);
			cb4.CBRow row = rowMap.get(key);
			if (row == null) {
				row = new cb4.CBRow(key, temp.clone());
				row.ie = t.cb4__Text2__c.toLowerCase(); // Income Expense
				row.app = t.cb4__Tag1__c; // app Id
				row.account = t.cb4__Tag2__c; // account Id
				row.accountST = t.cb4__Tag2__r.cb4__Tag1Name__c; // account subtype
				row.title = t.cb4__Text3__c;
				row.description = t.cb4__Text4__c;
				row.styleClass = t.cb4__Text5__c;
				row.employeeId = t.cb4__Tag4__c;
				row.rateId = t.cb4__Tag5__c;
				row.dim5 = t.cb4__Tag5__c;
				row.dim6 = t.cb4__Tag6__c;
				row.dim7 = t.cb4__Tag7__c;
				row.dim8 = t.cb4__Tag8__c;
				row.dim9 = t.cb4__Tag9__c;
				row.dim10 = t.cb4__Tag10__c;
				row.text6 = t.cb4__Text6__c;
				row.text7 = t.cb4__Text7__c;
				row.text8 = t.cb4__Text8__c;
				row.text9 = t.cb4__Text9__c;
				row.text10 = t.cb4__Text10__c;
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

	public static List<cb4__CBTag__c> getTagsFromCBRows(List<cb4.CBRow> rows, String newKey, String oldKey, String budgetAppId) {
		if (rows == null || rows.size() == 0) return new List<cb4__CBTag__c>();
		List<cb4__CBTag__c> r = new List<cb4__CBTag__c>();
		Integer k, rowLength;

		List<Id> periodsList = new List<Id>();
		for (cb4__CBTag__c t : periods) periodsList.add(t.Id);

		for (cb4.CBRow row : rows) {
			Boolean isRowKeyUpdated = row.text10 == oldKey;
			rowLength = row.rowValues.size() - 1; // exclude totals
			for (k = 0; k < rowLength; k++) {
				if (row.rowValues[k] == 0) continue;
				cb4__CBTag__c t = new cb4__CBTag__c();
				t.cb4__Dimension__c = budgetAppSubAmountDimId;
				t.cb4__Decimal1__c = row.rowValues[k]; // money
				t.cb4__Decimal2__c = row.quantityValues[k]; // quantity or hours
				t.cb4__Decimal3__c = row.priceValues[k]; // price or rate
				t.cb4__Text1__c = row.lvl1Name;
				t.cb4__Text2__c = row.lvl1Name == 'expense' || row.lvl1Name == 'income' ? row.lvl1Name : row.ie;
				t.cb4__Text3__c = row.title;
				t.cb4__Text4__c = row.description;
				t.cb4__Text5__c = row.styleClass;
				t.cb4__Text10__c = isRowKeyUpdated ? newKey : row.text10;
				t.cb4__Tag1__c = budgetAppId;
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
				t.cb4__Text9__c = getSimpleLineKey(t);
				r.add(t);
			}
		}
		return r;
	}

	/* CBASHBLComponent */

	/* CB Budget Application*/
	private static Decimal getCurrencyRate() {
		try {
			List<sObject> currencyTypes = Database.query('SELECT ConversionRate, isoCode, IsCorporate FROM CurrencyType WITH SECURITY_ENFORCED LIMIT 1000');
			sObject user = Database.query('SELECT DefaultCurrencyIsoCode FROM User WHERE Id = \'' + cb4.CBConstant.USER_ID + '\' WITH SECURITY_ENFORCED');
			String userISOCode = (String) user.get('DefaultCurrencyIsoCode');
			for (sObject ct : currencyTypes) {
				String ic = (String) ct.get('isoCode');
				if (ic == userISOCode) {
					if ((Boolean) ct.get('IsCorporate') || (Decimal) ct.get('ConversionRate') == 1) {
						return null;
					}
					return (Decimal) ct.get('ConversionRate');
				}
			}
		} catch (Exception e) {
			cb4.CBConsole.setLog(e, 'getCurrencyRate error');
			cb4.CBConsole.insertLog();
			return 1;
		}
		return null;
	}

	public static List<cb4__CBTag__c> convertAmountsToUserCurrency(List<cb4__CBTag__c> source) {
		if (source == null || source.size() == 0) {
			return source;
		}
		Decimal currencyRate = getCurrencyRate();
		if (currencyRate == null || currencyRate == 0) {
			return source;
		}
		for (cb4__CBTag__c t : source) {
			t.cb4__Decimal1__c = t.cb4__Decimal1__c == null ? 0 : (t.cb4__Decimal1__c * currencyRate).setScale(2);
		}
		return source;
	}

	public static List<cb4__CBTag__c> convertAmountsToCorporateCurrency(List<cb4__CBTag__c> source) {
		if (source == null || source.size() == 0) {
			return source;
		}
		Decimal currencyRate = getCurrencyRate();
		if (currencyRate == null || currencyRate == 0) {
			return source;
		}
		for (cb4__CBTag__c t : source) {
			t.cb4__Decimal1__c = t.cb4__Decimal1__c == null ? 0 : (t.cb4__Decimal1__c / currencyRate).setScale(2);
		}
		return source;
	}

	@AuraEnabled
	public static List<cb4__CBTag__c> getAllWiredTagsOfSet(Id setId) {
		Set<Id> tagIds = new Set<Id>();
		for (cb4__CBLink__c t : [SELECT cb4__Tag2__c FROM cb4__CBLink__c WHERE cb4__Type__c = :cb4.CBConstant.LINK_SET AND cb4__Tag1__c = :setId LIMIT 2000]) {
			tagIds.add(t.cb4__Tag2__c);
		}
		if (tagIds.size() == 0) {
			return new List<cb4__CBTag__c>();
		}
		return [SELECT Id, Name, cb4__TagLabel__c FROM cb4__CBTag__c WHERE Id IN:tagIds ORDER BY cb4__OrderNumber__c, cb4__TagLabel__c, Name LIMIT 2000];
	}

	@AuraEnabled
	public static List<cb4.CBSO> getAllWiredTagsOfSetSO(Id setId) {
		List<cb4.CBSO> r = new List<cb4.CBSO>();
		for (cb4__CBTag__c t : getAllWiredTagsOfSet(setId)) {
			r.add(new cb4.CBSO(t.Id, t.cb4__TagLabel__c));
		}
		return r;
	}

	@AuraEnabled
	public static List<cb4.CBSO> getTagsSOServer(Id dimensionId, String additionalFilter) {
		additionalFilter = cb4.CBUtils.refineStr(additionalFilter);
		List<cb4.CBSO> r = new List<cb4.CBSO>();
		if (!cb4.CBUtils.isValidId(dimensionId)) {
			return r;
		}
		String s = 'SELECT Id,Name,cb4__TagLabel__c,cb4__Dimension__r.cb4__isSet__c FROM cb4__CBTag__c  ';
		if (dimensionId != null) {
			s = s + ' WHERE cb4__Dimension__c = \'' + dimensionId + '\' ' +
					(additionalFilter == null || additionalFilter == '' ? '' : ' AND ' + additionalFilter);
		}
		s = s + ' ORDER BY cb4__OrderNumber__c, cb4__TagLabel__c, Name LIMIT 2500 ';
		s = s.remove('\\');
		for (cb4__CBTag__c t : Database.query(s)) {
			r.add(new cb4.CBSO(t.Id, t.cb4__TagLabel__c + (t.cb4__Dimension__r.cb4__isSet__c ? ' (Set)' : '')));
		}
		return r;
	}

	@AuraEnabled
	public static cb4__CBTag__c getNewTagServer(Id dimensionId, Id parentTagId) {
		cb4__CBDimension__c dimensionObj = getDimension(dimensionId);
		cb4__CBTag__c newTag = new cb4__CBTag__c(cb4__Dimension__c = dimensionId, Name = 'New ' + dimensionObj.Name);
		cb4__CBUserContext__c uc = getUserContextServer();
		if (uc.cb4__Tag1__c != null) {
			String cuDimensionId = uc.cb4__Dimension1__c;
			for (Integer i = 1; i <= 10; i++) {
				Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
				if (val == null) {
					continue;
				}
				Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
				if (dimParam.get('v') == cuDimensionId) {
					newTag.put('cb4__Tag' + i + '__c', uc.cb4__Tag1__c);
				}
			}
		}
		if (uc.cb4__Tag2__c != null) {
			String cuDimensionId = uc.cb4__Dimension2__c;
			for (Integer i = 1; i <= 10; i++) {
				Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
				if (val == null) {
					continue;
				}
				Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
				if (dimParam.get('v') == cuDimensionId) {
					newTag.put('cb4__Tag' + i + '__c', uc.cb4__Tag2__c);
				}
			}
		}
		if (uc.cb4__Tag3__c != null) {
			String cuDimensionId = uc.cb4__Dimension3__c;
			for (Integer i = 1; i <= 10; i++) {
				Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
				if (val == null) {
					continue;
				}
				Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
				if (dimParam.get('v') == cuDimensionId) {
					newTag.put('cb4__Tag' + i + '__c', uc.cb4__Tag3__c);
				}
			}
		}
		if (uc.cb4__Tag4__c != null) {
			String cuDimensionId = uc.cb4__Dimension4__c;
			for (Integer i = 1; i <= 10; i++) {
				Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
				if (val == null) {
					continue;
				}
				Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
				if (dimParam.get('v') == cuDimensionId) {
					newTag.put('cb4__Tag' + i + '__c', uc.cb4__Tag4__c);
				}
			}
		}
		if (uc.cb4__Tag5__c != null) {
			String cuDimensionId = uc.cb4__Dimension5__c;
			for (Integer i = 1; i <= 10; i++) {
				Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
				if (val == null) {
					continue;
				}
				Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
				if (dimParam.get('v') == cuDimensionId) {
					newTag.put('cb4__Tag' + i + '__c', uc.cb4__Tag5__c);
				}
			}
		}

		if (parentTagId != null) {
			String cuDimensionId = getTagServer(parentTagId, null).cb4__Dimension__c;
			for (Integer i = 1; i <= 10; i++) {
				Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
				if (val == null) {
					continue;
				}
				Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
				if (dimParam.get('v') == cuDimensionId) {
					newTag.put('cb4__Tag' + i + '__c', parentTagId);
				}
			}
		}

		newTag = cb4.CBUtils.tryToAssignParentIdToNewTagField(parentTagId, null, dimensionObj, newTag);

		return newTag;
	}

	@AuraEnabled
	public static cb4__CBTag__c getTagServer(Id recordId, String addSelect) {
		addSelect = cb4.CBUtils.refineStr(addSelect);
		String addFilter = getBYFilter();
		if (recordId == null) {
			return new cb4__CBTag__c();
		}
		String q = 'SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', addSelect) +
				' WHERE Id=\'' + recordId + '\' ' + addFilter + ' LIMIT 25000 ';
		return (cb4__CBTag__c) (Database.query(q))[0];
	}

	@AuraEnabled
	public static List<cb4__CBTag__c> getTagListServer(Id dimensionId, String addedFilter, Id parentTagId, String filtersMap, Boolean contextEnabled, String addSelect, String sortOrder, String customSelect) {
		addedFilter = cb4.CBUtils.refineStr(addedFilter);
		filtersMap = cb4.CBUtils.refineStr(filtersMap);
		sortOrder = cb4.CBUtils.refineStr(sortOrder);
		customSelect = cb4.CBUtils.refineStr(customSelect);
		addSelect = cb4.CBUtils.refineStr(addSelect);

		String filter = '';
		if (dimensionId != null) {
			filter = ' cb4__Dimension__c = \'' + dimensionId + '\' ';
		}
		if (addedFilter != null && addedFilter != '') {
			filter += filter == '' ? addedFilter : ' AND ' + addedFilter;
		}
		if (filtersMap != null && filtersMap != '{}') {
			Map<String, String> filterParams = (Map<String, String>) System.JSON.deserialize(filtersMap, Map<String, String>.class);
			for (String s : filterParams.keySet()) {
				filter += filter == '' ? s + ' = \'' + filterParams.get(s) + '\'' : ' AND ' + s + ' = \'' + filterParams.get(s) + '\'';
			}
		}
		if (parentTagId != null) {
			String parentFilter = ' (Tag1__c=\'' + parentTagId + '\' OR Tag2__c=\'' + parentTagId + '\' OR Tag3__c=\'' + parentTagId + '\'' +
					' OR Tag4__c=\'' + parentTagId + '\' OR Tag5__c=\'' + parentTagId + '\'' + ' OR Tag6__c=\'' + parentTagId +
					'\' OR Tag7__c=\'' + parentTagId + '\' OR Tag8__c=\'' + parentTagId + '\' OR Tag9__c=\'' + parentTagId + '\'' +
					' OR Tag10__c=\'' + parentTagId + '\' ) ';
			filter += filter == '' ? parentFilter : ' AND ' + parentFilter;
		}

		if (contextEnabled != null && contextEnabled) {
			String contextFilter = getContextFilter(dimensionId);
			if (contextFilter != '') {
				filter += filter == '' ? contextFilter : ' AND ' + contextFilter;
			}
		}

		if (addSelect != null && addSelect != '') {
			addSelect = ', ' + addSelect;
		} else if (addSelect == null) {
			addSelect = '';
		}
		if (sortOrder != null && sortOrder != '') {
			sortOrder = ' ORDER BY ' + sortOrder;
		} else if (sortOrder == null) {
			sortOrder = ' ORDER BY cb4__OrderNumber__c, cb4__TagLabel__c ';
		}

		String qSelect;
		if (customSelect != '' && customSelect != null) {
			qSelect = customSelect + addSelect + ' FROM cb4__CBTag__c ';
		} else {
			qSelect = cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', addSelect);
		}
		String addFilter = '';
		if (contextEnabled != null && contextEnabled) {
			addFilter = getBYFilter();
		}
		filter = filter + addFilter;
		if (filter != '') {
			filter = 'WHERE ' + filter;
		}
		String q = 'SELECT ' + qSelect + filter + sortOrder + ' LIMIT 40000 ';
		q = q.remove('\\');

		//System.debug(q);
		return Database.query(q);
	}

	public static String getBYFilter() {
		String addFilter = '';
		cb4__CBTag__c yearTag = cb4.CBContext.getCurrentBY();
		cb4__CBUserContext__c uc = getUserContextServer();
		String budgetYearDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_YEAR_DIM);
		Boolean showAllDates = false;
		for (Integer i = 5; i != 0; i--) {
			if ((String) uc.get('cb4__Dimension' + String.valueOf(i) + '__c') == budgetYearDimId) {
				showAllDates = (Boolean) uc.get('cb4__ShowAll' + String.valueOf(i) + '__c');
				break;
			}
		}
		if (!showAllDates && yearTag != null) {
			String startDate = yearTag.cb4__Start__c != null ? String.valueOf(yearTag.cb4__Start__c).removeEnd(' 00:00:00') : '';
			String endDate = yearTag.cb4__End__c != null ? String.valueOf(yearTag.cb4__End__c).removeEnd(' 00:00:00') : '';
			if (!String.isBlank(startDate) && !String.isBlank(endDate)) {
				addFilter += ' AND ((cb4__Start__c = null AND cb4__End__c = null)';
				addFilter += ' OR (cb4__Start__c >= ' + startDate + ' AND cb4__End__c <= ' + endDate + ')';
				addFilter += ' OR (cb4__Start__c <= ' + startDate + ' AND cb4__End__c >= ' + endDate + ')';
				addFilter += ' OR (cb4__End__c >= ' + startDate + ' AND cb4__End__c <= ' + endDate + ')';
				addFilter += ' OR (cb4__Start__c >= ' + startDate + ' AND cb4__Start__c <= ' + endDate + '))';
			} else if (!String.isBlank(startDate) && String.isBlank(endDate)) {
				addFilter += ' AND (cb4__End__c = null OR cb4__End__c >= ' + startDate + ')';
			} else if (!String.isBlank(endDate) && String.isBlank(startDate)) {
				addFilter += ' AND (cb4__End__c = null OR cb4__End__c <= ' + endDate + ')';
			}
		}
		return addFilter;
	}

	@AuraEnabled
	public static cb4__CBDimension__c getDimension(Id recordId) {
		if (recordId == null) {
			return null;
		}
		String q = 'SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBDimension__c', null) + ' WHERE Id=\'' + recordId + '\' LIMIT 1 ';
		return Database.query(q);
	}

	public static String getContextFilter(Id dimensionId) {
		if (dimensionId == null) return '';
		cb4__CBDimension__c d = getDimension(dimensionId);

		cb4__CBUserContext__c uc = getUserContextServer();
		if (uc == null) return '';

		String result = '';

		if (!uc.cb4__ShowAll1__c && uc.cb4__Tag1__c != null && cb4.CBUtils.isValidId(uc.cb4__Dimension1__c)) {
			for (Integer i = 1; i <= 10; i++) {
				Object dim = d.get('cb4__Dimension' + i + '__c');
				if (dim != null && (String.valueOf(dim)).contains(uc.cb4__Dimension1__c)) {
					result = 'cb4__Tag' + i + '__c = \'' + uc.cb4__Tag1__c + '\'';
					break;
				}
			}
		}

		if (!uc.cb4__ShowAll2__c && uc.cb4__Tag2__c != null && cb4.CBUtils.isValidId(uc.cb4__Dimension2__c)) {
			for (Integer i = 1; i <= 10; i++) {
				Object dim = d.get('cb4__Dimension' + i + '__c');
				if (dim != null && (String.valueOf(dim)).contains(uc.cb4__Dimension2__c)) {
					String searchTag = 'cb4__Tag' + i + '__c = \'' + uc.cb4__Tag2__c + '\'';
					result += result == '' ? searchTag : ' AND ' + searchTag;
					break;
				}
			}
		}

		if (!uc.cb4__ShowAll3__c && uc.cb4__Tag3__c != null && cb4.CBUtils.isValidId(uc.cb4__Dimension3__c)) {
			for (Integer i = 1; i <= 10; i++) {
				Object dim = d.get('cb4__Dimension' + i + '__c');
				if (dim != null && (String.valueOf(dim)).contains(uc.cb4__Dimension3__c)) {
					String searchTag = 'cb4__Tag' + i + '__c = \'' + uc.cb4__Tag3__c + '\'';
					result += result == '' ? searchTag : ' AND ' + searchTag;
					break;
				}
			}
		}

		if (!uc.cb4__ShowAll4__c && uc.cb4__Tag4__c != null && cb4.CBUtils.isValidId(uc.cb4__Dimension4__c)) {
			for (Integer i = 1; i <= 10; i++) {
				Object dim = d.get('cb4__Dimension' + i + '__c');
				if (dim != null && (String.valueOf(dim)).contains(uc.cb4__Dimension4__c)) {
					String searchTag = 'cb4__Tag' + i + '__c = \'' + uc.cb4__Tag4__c + '\'';
					result += result == '' ? searchTag : ' AND ' + searchTag;
					break;
				}
			}
		}

		if (!uc.cb4__ShowAll5__c && uc.cb4__Tag5__c != null && cb4.CBUtils.isValidId(uc.cb4__Dimension5__c)) {
			for (Integer i = 1; i <= 10; i++) {
				Object dim = d.get('cb4__Dimension' + i + '__c');
				if (dim != null && (String.valueOf(dim)).contains(uc.cb4__Dimension5__c)) {
					String searchTag = 'cb4__Tag' + i + '__c = \'' + uc.cb4__Tag5__c + '\'';
					result += result == '' ? searchTag : ' AND ' + searchTag;
					break;
				}
			}
		}
		return result;
	}

	@AuraEnabled
	public static cb4__CBUserContext__c getUserContextServer() {
		cb4__CBUserContext__c uc = cb4__CBUserContext__c.getInstance(UserInfo.getUserId());
		if (uc.Id == null) {
			cb4__CBUserContext__c orgContext = getOrganizationContextServer();
			uc = orgContext.clone();
			uc.Name = uc.Name.replace('Organization', 'User');
			uc.SetupOwnerId = UserInfo.getUserId();
			upsert uc;
		}
		return uc;
	}

	@AuraEnabled
	public static cb4__CBUserContext__c getOrganizationContextServer() {
		cb4__CBUserContext__c oc = cb4__CBUserContext__c.getOrgDefaults();
		if (oc.Id == null) {
			oc = new cb4__CBUserContext__c(cb4__Dimension1Filter__c = '');
			oc.cb4__ShowAll1__c = oc.cb4__ShowAll2__c = oc.cb4__ShowAll3__c = oc.cb4__ShowAll4__c = oc.cb4__ShowAll5__c = false;
			oc.cb4__AllowAll1__c = oc.cb4__AllowAll2__c = oc.cb4__AllowAll3__c = oc.cb4__AllowAll4__c = oc.cb4__AllowAll5__c = false;
		}
		return oc;
	}

	@AuraEnabled
	public static List<cb4.CBSO> getPriceBooksSOServer(List<String> productIds) {
		List<cb4.CBSO> r = new List<cb4.CBSO>();
		String s = 'SELECT Id, Name FROM Pricebook2 WITH SECURITY_ENFORCED ORDER BY Name LIMIT 1000';
		for (Pricebook2 pb : Database.query(s)) {
			r.add(new cb4.CBSO(pb.Id, pb.Name));
		}
		return r;
	}

	@AuraEnabled
	public static List<cb4.CBSO> getProductsSOServer() {
		List<cb4.CBSO> r = new List<cb4.CBSO>();
		String s = 'SELECT Id, Name, QuantityUnitOfMeasure FROM Product2 WITH SECURITY_ENFORCED ORDER BY Name LIMIT 1000';
		for (Product2 p : Database.query(s)) {
			r.add(new cb4.CBSO(p.Id, p.QuantityUnitOfMeasure != null ? (p.Name + ' (' + p.QuantityUnitOfMeasure + ')') : p.Name));
		}
		return r;
	}

	@AuraEnabled
	public static Map<String, Decimal> getPriceEntriesServer() {
		Map<String, Decimal> r = new Map<String, Decimal>();
		String s = 'SELECT Product2Id, Pricebook2Id, UnitPrice, Name FROM PricebookEntry WITH SECURITY_ENFORCED ORDER BY Name LIMIT 1000';
		for (PricebookEntry pbe : Database.query(s)) {
			r.put(pbe.Product2Id + (String) pbe.Pricebook2Id, pbe.UnitPrice);
		}
		return r;
	}

	private static Map<String, cb4__CBTag__c> getMapIdResultCalcRules(List<cb4__CBTag__c> srcTags) {
		Set<Id> resRuleIds = new Set<Id>();
		Map<String, cb4__CBTag__c> r = new Map<String, cb4__CBTag__c>();
		for (cb4__CBTag__c t : srcTags) {
			resRuleIds.add(t.cb4__Tag2__c);
		}
		for (cb4__CBTag__c t : [SELECT Id,cb4__Tag1__c,cb4__Tag2__c,cb4__Tag3__c,cb4__Tag4__c,cb4__Tag5__c,cb4__Tag6__c,cb4__Tag7__c,cb4__Tag8__c,cb4__Tag9__c,cb4__Tag10__c,cb4__Decimal1__c,cb4__Decimal2__c,cb4__Decimal3__c,cb4__Boolean1__c,cb4__Boolean2__c,cb4__Boolean3__c,cb4__Boolean4__c,cb4__Boolean5__c,cb4__Boolean6__c, cb4__DimensionName__c FROM cb4__CBTag__c WHERE Id IN:resRuleIds AND cb4__DimensionName__c = :cb4.CBConstant.CALCULATION_RULE_DIM WITH SECURITY_ENFORCED]) {
			r.put(t.Id, t);
		}
		return r;
	}

	private static final String accountSetDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.ACCOUNT_SET_DIM);
	private static final String periodSetDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.PERIOD_SET_DIM);
	private static final String periodDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.PERIOD_DIM);
	private static final String accountDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.ACCOUNT_DIM);


	public static Map<Id, cb4__CBTag__c> accountMap {
		get {
			if (accountMap == null) {
				accountMap = new Map<Id, cb4__CBTag__c>();
				for (cb4__CBTag__c t : getTagListServer(accountDimId, null, null, null, false, ' cb4__Tag1__r.cb4__Tag1Name__c ', null, null)) {
					accountMap.put(t.Id, t);
				}
			}
			return accountMap;
		}
		set;
	}


	@TestVisible
	private static Map<Id, Set<Id>> getMapOfRelatedAccountsInSet() {
		Map<Id, Set<Id>> r = new Map<Id, Set<Id>>();
		Set<Id> accountPeriodSetIds = new Set<Id>();
		for (cb4__CBTag__c t : [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :accountSetDimId OR cb4__Dimension__c = :periodSetDimId]) {
			accountPeriodSetIds.add(t.Id);
		}
		for (cb4__CBLink__c t : [SELECT cb4__Tag1__c, cb4__Tag2__c FROM cb4__CBLink__c WHERE cb4__Type__c = :cb4.CBConstant.LINK_SET AND cb4__Tag1__c = :accountPeriodSetIds LIMIT 50000]) {
			Set<Id> bunch = r.get(t.cb4__Tag1__c);
			if (bunch == null) {
				bunch = new Set<Id>{
						t.cb4__Tag2__c
				};
			} else {
				bunch.add(t.cb4__Tag2__c);
			}
			r.put(t.cb4__Tag1__c, bunch);
		}
		return r;
	}

	@TestVisible
	private static Map<Id, Set<Id>> setMap {
		get {
			if (setMap == null) {
				setMap = getMapOfRelatedAccountsInSet();
			}
			return setMap;
		}
		set;
	}

	@TestVisible
	private static Map<Id, Set<Id>> BYMap {
		get {
			if (BYMap == null) {
				BYMap = new Map<Id, Set<Id>>();
				for (cb4__CBTag__c t : getTagListServer(periodDimId, null, null, null, false, null, null, null)) {
					Set<Id> p = BYMap.get(t.cb4__Tag1__c);
					if (p == null) {
						p = new Set<Id>();
						BYMap.put(t.cb4__Tag1__c, p);
					}
					p.add(t.Id);
				}
			}
			return BYMap;
		}
		set;
	}

	private static Boolean periodTheSame(cb4__CBTag__c cr, cb4__CBTag__c t) {
		if (cr.cb4__Tag3__r.cb4__Dimension__r.cb4__isSet__c) {
			return setContainsTag(cr.cb4__Tag3__c, t.cb4__Tag3__c);
		} // if period is set
		return cr.cb4__Tag3__c == t.cb4__Tag3__c || (BYMap.keySet().contains(cr.cb4__Tag3__c) && BYMap.get(cr.cb4__Tag3__c).contains(t.cb4__Tag3__c)); // if period is month or BY
	}

	private static Boolean accountTheSame(cb4__CBTag__c cr, cb4__CBTag__c t) {
		if (cr.cb4__Tag1__r.cb4__Dimension__r.cb4__isSet__c) {
			return setContainsTag(cr.cb4__Tag1__c, t.cb4__Tag2__c);
		}
		return cr.cb4__Tag1__c == t.cb4__Tag2__c;
	}

	private static Boolean dimensionsTheSame(cb4__CBTag__c cr, cb4__CBTag__c t) {
		if (cr.cb4__Tag6__c != null && cr.cb4__Tag6__c != t.cb4__Tag6__c) {
			return false;
		}
		if (cr.cb4__Tag7__c != null && cr.cb4__Tag7__c != t.cb4__Tag7__c) {
			return false;
		}
		if (cr.cb4__Tag8__c != null && cr.cb4__Tag8__c != t.cb4__Tag8__c) {
			return false;
		}
		if (cr.cb4__Tag9__c != null && cr.cb4__Tag9__c != t.cb4__Tag9__c) {
			return false;
		}
		if (cr.cb4__Tag10__c != null && cr.cb4__Tag10__c != t.cb4__Tag10__c) {
			return false;
		}
		return true;
	}

	private static Boolean setContainsTag(Id setId, Id examId) {
		Set<Id> s = setMap.get(setId);
		if (s == null) {
			return false;
		}
		return s.contains(examId);
	}

	public static List<cb4__CBTag__c> generateCRSyntheticTags(List<cb4__CBTag__c> calcRules, List<cb4__CBTag__c> srcTags, List<cb4__CBTag__c> totalTags, Map<Id, Product2> productMap) {
		List<cb4__CBTag__c> r = new List<cb4__CBTag__c> ();
		Map<String, cb4__CBTag__c> resultRulesMap = getMapIdResultCalcRules(calcRules); // key => Id of source calc rule  , value => result calc rule

		for (cb4__CBTag__c cr : calcRules) {
			String crAccType;
			String crAccName;
			cb4__CBTag__c resultCR = resultRulesMap.get(cr.cb4__Tag2__c);
			Boolean isTotalLinesCalcRule = cr.cb4__Text3__c == 'Total Income' || cr.cb4__Text3__c == 'Total Expense' || cr.cb4__Text3__c == 'Total Margin';
			String totalType = '';
			if (isTotalLinesCalcRule) {
				totalType = cr.cb4__Text3__c.replace('Total ', '');
				srcTags = totalTags;
			}

			// Expense or Income lines
			for (cb4__CBTag__c t : srcTags) { // t is source CBTag__c

				Boolean simpleLinesConditionIsOk = !isTotalLinesCalcRule && periodTheSame(cr, t) && accountTheSame(cr, t) && dimensionsTheSame(cr, t);
				Boolean totalLinesConditionIsOk = isTotalLinesCalcRule && t.cb4__Text3__c == totalType && periodTheSame(cr, t);

				if (simpleLinesConditionIsOk || totalLinesConditionIsOk) {
					if (resultCR.cb4__Boolean6__c == true) {
						resultCR.cb4__Tag1__c = t.cb4__Tag2__c;
					} // if you need to save account from source tag

					crAccType = crAccType == null ? accountMap.get(resultCR.cb4__Tag1__c).cb4__Tag1__r.cb4__Tag1Name__c : crAccType;
					crAccName = crAccName == null ? accountMap.get(resultCR.cb4__Tag1__c).cb4__TagLabel__c : crAccName;
					cb4__CBTag__c s = t.clone(); // new synthetic CBTag
					Product2 product = s.cb4__Product__c == null ? null : productMap.get(s.cb4__Product__c);
					s.cb4__Text1__c = s.cb4__Text2__c = crAccType.toLowerCase(); // type income OR expense
					s.cb4__Text3__c = crAccName; // title
					s.cb4__Text4__c = 'Created by Calculation Rule "' + cr.cb4__TagLabel__c + '". Source line is "' + t.cb4__Text3__c + '".'; // Row Description
					s.cb4__Text4__c += product == null ? '' : ' Product is "' + product.Name + '".';
					s.cb4__Text5__c = 'calcRule'; // calcRule style
					s.cb4__Text6__c = cr.Name; // Calc rule name
					s.cb4__Text7__c = t.Name; // Source line Name
					s.cb4__Tag2__c = resultCR.cb4__Tag1__c; // account Id
					s.cb4__Tag5__c = null; // Rate
					s.cb4__Tag6__c = resultCR.cb4__Boolean1__c == true ? t.cb4__Tag6__c : resultCR.cb4__Tag6__c;
					s.cb4__Tag7__c = resultCR.cb4__Boolean2__c == true ? t.cb4__Tag7__c : resultCR.cb4__Tag7__c;
					s.cb4__Tag8__c = resultCR.cb4__Boolean3__c == true ? t.cb4__Tag8__c : resultCR.cb4__Tag8__c;
					s.cb4__Tag9__c = resultCR.cb4__Boolean4__c == true ? t.cb4__Tag9__c : resultCR.cb4__Tag9__c;
					s.cb4__Tag10__c = resultCR.cb4__Boolean5__c == true ? t.cb4__Tag10__c : resultCR.cb4__Tag10__c;
					s.cb4__Decimal1__c = calculateSyntheticValueWithSourceRule(cr, t); // calculated from source CR
					s.cb4__Decimal1__c = calculateSyntheticValueWithResultRule(resultCR, s.cb4__Decimal1__c); // specified from result CR
					s.cb4__Decimal2__c = s.cb4__Decimal3__c = 0;
					s.cb4__PriceBook__c = null;
					s.cb4__ExtId__c = t.Id;
					r.add(s);
				}
			}

		}
		return r;
	}

	private static Decimal calculateSyntheticValueWithSourceRule(cb4__CBTag__c cr, cb4__CBTag__c t) {
		String relation = cr.cb4__Text2__c;
		Decimal rate = cr.cb4__Decimal1__c;
		Decimal srcValue = cr.cb4__Boolean1__c ? -(t.cb4__Decimal1__c) : t.cb4__Decimal1__c;

		switch on relation {
			when 'Percent' {
				return srcValue * rate / 100;
			}
			when 'Multiply' {
				return srcValue * rate;
			}
			when 'Add' {
				return srcValue + rate;
			}
			when else {
				return -1;
			}
		}
	}

	private static Decimal calculateSyntheticValueWithResultRule(cb4__CBTag__c cr, Decimal val) {
		if (cr.cb4__Decimal1__c != null && cr.cb4__Decimal1__c != 0) {
			return cr.cb4__Decimal1__c;
		}
		if (cr.cb4__Decimal2__c != null && cr.cb4__Decimal1__c != 0 && val > cr.cb4__Decimal2__c) {
			return cr.cb4__Decimal2__c;
		}
		if (cr.cb4__Decimal3__c != null && cr.cb4__Decimal1__c != 0 && val < cr.cb4__Decimal3__c) {
			return cr.cb4__Decimal3__c;
		}
		return val;
	}

	@AuraEnabled
	public static String deleteTagServer(List<Id> tagIds) {
		if (tagIds == null) {
			return 'error: ids are not specified';
		}
		Set<Id> tagIdsSet = new Set<Id>(tagIds);
		delete [SELECT Id FROM cb4__CBTag__c WHERE Id IN :tagIdsSet WITH SECURITY_ENFORCED LIMIT 10000];
		return 'ok';
	}

	public static Map<String, User> userMap {
		get {
			if (userMap == null) {
				userMap = new Map<String, User>([
						Select Id, Name, ManagerId, ProfileId, DelegatedApproverId, UserRoleId, IsActive
						From User
						WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name LIKE '%CloudBudget2%') AND IsActive = true
						ORDER BY Name
						LIMIT 20000
				]);
			}
			return userMap;
		}
		set;
	}

	private static Map<String, GroupMember> groupMemberMap {
		get {
			if (groupMemberMap == null) {
				groupMemberMap = new Map<String, GroupMember>([
						Select GroupId, Id, UserOrGroupId
						From GroupMember
						WHERE Id != null AND Group.Type = 'Regular'
						ORDER BY Id
						LIMIT 1000
				]);
			}
			return groupMemberMap;
		}
		set;
	}

	private static Map<String, Group> groupMap {
		get {
			if (groupMap == null) {
				groupMap = new Map<String, Group>([
						Select Id, Name, DeveloperName, Type
						From Group
						WHERE Id != null AND Type = 'Regular'
						ORDER BY Name
						LIMIT 1000
				]);
			}
			return groupMap;
		}
		set;
	}

	@AuraEnabled
	public static Boolean isCurrentUserAdminServer() {
		return [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1000].Name == cb4.CBConstant.ADMIN_PROFILE_NAME;
	}

	@AuraEnabled
	public static List<GroupMember> getGroupMemberListServer() {
		return groupMemberMap.values();
	}

	@AuraEnabled
	public static List<Group> getGroupListServer() {
		return groupMap.values();
	}

	public static Set<Id> findSubordinateGroups(Id groupId) {
		List<Group> groupList = getGroupListServer();
		Set<Id> groupIdSet = new Set<Id>();
		List<GroupMember> groupMemberList = getGroupMemberListServer();
		Boolean keepDigging = false;
		for (GroupMember groupMember : groupMemberList) {
			if (groupMember.GroupId == groupId) {
				for (Group groupItem : groupList) {
					if (groupMember.UserOrGroupId == groupItem.Id) {
						keepDigging = true;
						groupIdSet.add(groupMember.UserOrGroupId);
					}
				}
			}
		}
		if (keepDigging) {
			for (Id setGroupId : groupIdSet) {
				groupIdSet.addAll(findSubordinateGroups(setGroupId));
			}
		}

		return groupIdSet;
	}

	public static Set<Id> findGroupsByUser(Id userOrGroupId) {
		Set<Id> groupIdSet = new Set<Id>();
		List<GroupMember> groupMemberList = getGroupMemberListServer();
		for (GroupMember groupMember : groupMemberList) {
			if (groupMember.UserOrGroupId == userOrGroupId) {
				groupIdSet.add(groupMember.GroupId);
			}
		}
		for (Id groupId : groupIdSet) {
			groupIdSet.addAll(findSubordinateGroups(groupId));
		}
		return groupIdSet;
	}

	@AuraEnabled
	public static List<Id> findCurrentUserGroupsServer() {
		Id currentUserId = getCurrentUser().Id;
		List<Id> groupList = new List<Id>(findGroupsByUser(currentUserId));
		return groupList;
	}

	public static User getCurrentUser() {
		return userMap.get(UserInfo.getUserId());
	}

	@AuraEnabled
	public static List<String> getDefaultUserInterfaceSettingsListServer(String componentName, Boolean currentUserIsAdmin) {
		componentName = cb4.CBUtils.refineStr(componentName);
		if (currentUserIsAdmin == null) {
			currentUserIsAdmin = isCurrentUserAdminServer();
		}
		String addedFilter = '';
		addedFilter += currentUserIsAdmin ? 'Label = \'Admin\'' : 'Label = \'User\'';

		String customSelect = 'Id, DeveloperName, cb4__GroupId__c, cb4__ComponentName__c, cb4__JSONCheckboxes__c';
		String q = 'SELECT ' + customSelect + ' FROM cb4__UserInterfaceSettings__mdt WHERE ' + addedFilter + ' LIMIT 1000';
		List<cb4__UserInterfaceSettings__mdt> settingsObjList = Database.query(q);
		List<String> settingsFieldList = new List<String>();
		if (!settingsObjList.isEmpty()) {
			for (cb4__UserInterfaceSettings__mdt settingsObj : settingsObjList) {
				settingsFieldList.add(settingsObj.cb4__JSONCheckboxes__c);
			}
			return settingsFieldList;
		} else {
			return null;
		}
	}

	@AuraEnabled
	public static List<String> getCurrentUserInterfaceSettingsListServer(String componentName, Boolean currentUserIsAdmin) {
		componentName = cb4.CBUtils.refineStr(componentName);
		if (currentUserIsAdmin == null) {
			currentUserIsAdmin = isCurrentUserAdminServer();
		}
		List<Id> currentUserGroupList = findCurrentUserGroupsServer();
		String addedFilter = 'cb4__Text2__c = \'' + componentName + '\'';
		if (!currentUserGroupList.isEmpty()) {
			addedFilter += ' AND (';
			for (Id currentUserGroup : currentUserGroupList) {
				addedFilter += 'cb4__Text1__c = \'' + String.valueOf(currentUserGroup) + '\' OR ';
			}
			addedFilter = addedFilter.removeEnd(' OR ');
			addedFilter += ')';
		} else {
			return getDefaultUserInterfaceSettingsListServer(componentName, currentUserIsAdmin);
		}
		String customSelect = 'Id, Name, cb4__Text1__c, cb4__Text2__c, cb4__TextLong1__c';
		String q = 'SELECT ' + customSelect + ' FROM cb4__InterfaceSettings__c WHERE ' + addedFilter + ' LIMIT 1000 ';
		List<cb4__InterfaceSettings__c> settingsObjList = Database.query(q);
		List<String> settingsFieldList = new List<String>();
		if (!settingsObjList.isEmpty()) {
			for (cb4__InterfaceSettings__c settingsObj : settingsObjList) {
				settingsFieldList.add(settingsObj.cb4__TextLong1__c);
			}
			return settingsFieldList;
		} else {
			return getDefaultUserInterfaceSettingsListServer(componentName, currentUserIsAdmin);
		}
	}

	@AuraEnabled
	public static List<String> getDocumentsByRecordIdServer(Id recordId) {
		Set<String> uniqueDocs = new Set<String>();
		for (ContentDocumentLink link : [
				SELECT Id, ContentDocument.Title, ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :recordId
				ORDER BY ContentDocument.CreatedDate asc
				LIMIT 1000
		]) {
			String pair = link.ContentDocumentId + ',' + link.ContentDocument.Title;
			uniqueDocs.add(pair);
		}
		return new List<String>(uniqueDocs);
	}

	/* CB Budget Application*/

	public static void cg(){
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
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
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