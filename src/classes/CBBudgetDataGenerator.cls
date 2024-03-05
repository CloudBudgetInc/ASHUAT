public with sharing class CBBudgetDataGenerator implements Database.Batchable<SObject>, Database.Stateful{
	private static final Id BUDGETS_DIM_ID           = cb4.CBUtils.dimensionNameIdMap.get('Budget App');
	private static final Id BUDGET_AMOUNT_DIM_ID     = cb4.CBUtils.dimensionNameIdMap.get('Budget App Amount');
	private static final Id BUDGET_SUB_AMOUNT_DIM_ID = cb4.CBUtils.dimensionNameIdMap.get('Budget App SubAmount');
	private static final Id ACC_DIM_ID = cb4.CBUtils.dimensionNameIdMap.get('Account');
	private static final Id D1_DIM_ID = cb4.CBUtils.dimensionNameIdMap.get('CB_FF1');
	private static final Id D2_DIM_ID = cb4.CBUtils.dimensionNameIdMap.get('CB_FF2');
	private static final Id D3_DIM_ID = cb4.CBUtils.dimensionNameIdMap.get('CB_FF3');
	private static final Id D4_DIM_ID = cb4.CBUtils.dimensionNameIdMap.get('CB_FF4');
	private static final Id DEP_DIM_ID = cb4.CBUtils.dimensionNameIdMap.get('Department');

	private String PBBId = null;
	private String BudgetYear = null;
	private String PBBName = null;

	private static Map<String, cb4__CBTag__c> extIdToTag {
		get{
			if(extIdToTag == null){
				extIdToTag = new Map<String, cb4__CBTag__c>();
				for(cb4__CBTag__c t : [SELECT Id, Name, cb4__Index__c, cb4__ExtId__c, cb4__Tag1__r.cb4__Tag1Name__c FROM cb4__CBTag__c WHERE cb4__ExtId__c != NULL AND (cb4__Dimension__c = :ACC_DIM_ID OR cb4__Dimension__c = :D1_DIM_ID OR cb4__Dimension__c = :D2_DIM_ID OR cb4__Dimension__c = :D3_DIM_ID OR cb4__Dimension__c = :D4_DIM_ID OR cb4__Dimension__c = :DEP_DIM_ID)]){
					extIdToTag.put(t.cb4__ExtId__c, t);
				}
			}
			return extIdToTag;
		}
		set;
	}
	public static Map<String, cb4__CBTag__c> accIndexToTag {
		get{
			if(accIndexToTag == null){
				accIndexToTag = new Map<String, cb4__CBTag__c>();
				for(cb4__CBTag__c t : [SELECT Id, Name, cb4__Tag1__r.cb4__Tag1Name__c, cb4__Index__c FROM cb4__CBTag__c WHERE cb4__ExtId__c != NULL AND cb4__Dimension__c = :ACC_DIM_ID]){
					accIndexToTag.put(t.cb4__Index__c, t);
				}
			}
			return accIndexToTag;
		}
		set;
	}
	private static Map<String, cb4__CBTag__c> d1IndexToTag {
		get{
			if(d1IndexToTag == null){
				d1IndexToTag = new Map<String, cb4__CBTag__c>();
				for(cb4__CBTag__c t : [SELECT Id, cb4__Index__c FROM cb4__CBTag__c WHERE cb4__ExtId__c != NULL AND cb4__Dimension__c = :D1_DIM_ID]){
					d1IndexToTag.put(t.cb4__Index__c, t);
				}
			}
			return d1IndexToTag;
		}
		set;
	}
	private static Map<String, cb4__CBTag__c> d2IndexToTag {
		get{
			if(d2IndexToTag == null){
				d2IndexToTag = new Map<String, cb4__CBTag__c>();
				for(cb4__CBTag__c t : [SELECT Id, cb4__Index__c FROM cb4__CBTag__c WHERE cb4__ExtId__c != NULL AND cb4__Dimension__c = :D2_DIM_ID]){
					d2IndexToTag.put(t.cb4__Index__c, t);
				}
			}
			return d2IndexToTag;
		}
		set;
	}
	private static Map<String, cb4__CBTag__c> d3IndexToTag {
		get{
			if(d3IndexToTag == null){
				d3IndexToTag = new Map<String, cb4__CBTag__c>();
				for(cb4__CBTag__c t : [SELECT Id, cb4__Index__c FROM cb4__CBTag__c WHERE cb4__ExtId__c != NULL AND  cb4__Dimension__c = :D3_DIM_ID]){
					d3IndexToTag.put(t.cb4__Index__c, t);
				}
			}
			return d3IndexToTag;
		}
		set;
	}
	private static Map<String, cb4__CBTag__c> d4IndexToTag {
		get{
			if(d4IndexToTag == null){
				d4IndexToTag = new Map<String, cb4__CBTag__c>();
				for(cb4__CBTag__c t : [SELECT Id, cb4__Index__c FROM cb4__CBTag__c WHERE cb4__ExtId__c != NULL AND cb4__Dimension__c = :D4_DIM_ID]){
					d4IndexToTag.put(t.cb4__Index__c, t);
				}
			}
			return d4IndexToTag;
		}
		set;
	}
	private static Map<String, cb4__CBTag__c> depNameToTag {
		get{
			if(depNameToTag == null){
				depNameToTag = new Map<String, cb4__CBTag__c>();
				for(cb4__CBTag__c t : [SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__Dimension__c = :DEP_DIM_ID]){
					depNameToTag.put(t.Name, t);
				}
			}
			return depNameToTag;
		}
		set;
	}

	public static Map<String, String> periodMap{
		get{
			if(periodMap == null){
				periodMap = new Map<String, String>();
				for(cb4__CBTag__c q : [SELECT Id, Name, cb4__Tag1Name__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period']){
					if(q.Name == q.cb4__Tag1Name__c + ' Q1'){
						periodMap.put(q.cb4__Tag1Name__c + '01', q.Id);
						periodMap.put(q.cb4__Tag1Name__c + '02', q.Id);
						periodMap.put(q.cb4__Tag1Name__c + '03', q.Id);
					}
					if(q.Name == q.cb4__Tag1Name__c + ' Q2'){
						periodMap.put(q.cb4__Tag1Name__c + '04', q.Id);
						periodMap.put(q.cb4__Tag1Name__c + '05', q.Id);
						periodMap.put(q.cb4__Tag1Name__c + '06', q.Id);
					}
					if(q.Name == q.cb4__Tag1Name__c + ' Q3'){
						periodMap.put(q.cb4__Tag1Name__c + '07', q.Id);
						periodMap.put(q.cb4__Tag1Name__c + '08', q.Id);
						periodMap.put(q.cb4__Tag1Name__c + '09', q.Id);
					}
					if(q.Name == q.cb4__Tag1Name__c + ' Q4'){
						periodMap.put(q.cb4__Tag1Name__c + '10', q.Id);
						periodMap.put(q.cb4__Tag1Name__c + '11', q.Id);
						periodMap.put(q.cb4__Tag1Name__c + '12', q.Id);
					}
				}
			}
			return periodMap;
		}
		set;
	}
	private Map<String, String> ashBudgetsMap{
		get{
			if(ashBudgetsMap == null){
				ashBudgetsMap = new Map<String, String>();
				for(cb4__CBTag__c b : [SELECT Id, cb4__Tag6__r.cb4__Index__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :BUDGETS_DIM_ID AND cb4__Tag6__c != NULL AND cb4__Boolean2__c = TRUE AND cb4__Tag3Name__c = :BudgetYear AND cb4__Tag4Name__c = 'American Society of Hematology']){
					ashBudgetsMap.put(b.cb4__Tag6__r.cb4__Index__c, b.Id);
				}
			}
			return ashBudgetsMap;
		}
		set;
	}
	private Map<String, String> ashrcBudgetsMap{
		get{
			if(ashrcBudgetsMap == null){
				ashrcBudgetsMap = new Map<String, String>();
				for(cb4__CBTag__c b : [SELECT Id, cb4__Tag6__r.cb4__Index__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :BUDGETS_DIM_ID AND cb4__Tag6__c != NULL AND cb4__Boolean2__c = TRUE AND cb4__Tag3Name__c = :BudgetYear AND cb4__Tag4Name__c = 'ASH Research Collaborative']){
					ashrcBudgetsMap.put(b.cb4__Tag6__r.cb4__Index__c, b.Id);
				}
			}
			return ashrcBudgetsMap;
		}
		set;
	}

	public CBBudgetDataGenerator(){

	}

	public CBBudgetDataGenerator(String personnelBudgetBatchId){
		PBBId = personnelBudgetBatchId;
		Personnel_Budget_Batch__c PBB = [SELECT Id, Year__c, Name FROM Personnel_Budget_Batch__c WHERE Id = :personnelBudgetBatchId];
		BudgetYear = PBB.Year__c;
		PBBName = PBB.Name;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String q = 'SELECT Id, Name, Company__c, Accounting_Code__c, Period__c, Amount__c FROM Personnel_Budget_Stager__c WHERE Company__c != NULL AND Amount__c != 0';
		if(PBBId != null) q += ' AND Personnel_Budget_Batch__c = ' + '\'' + PBBId + '\'';
		return Database.getQueryLocator(q);
	}

	public void execute(Database.BatchableContext BC, List<SObject> scope) {
		List<Personnel_Budget_Stager__c> pbsList = scope;
		Map<String, cb4__CBTag__c> budgetLinesMap = new Map<String, cb4__CBTag__c>();
		Map<String, cb4__CBTag__c> ashBudgetTotalsByBudgetAndPeriodId = getTotalsMapByBudgetId(BudgetYear, 'American Society of Hematology');
		Map<String, cb4__CBTag__c> ashrcBudgetTotalsByBudgetAndPeriodId = getTotalsMapByBudgetId(BudgetYear, 'ASH Research Collaborative');

		for(Personnel_Budget_Stager__c pbs : pbsList){
			List<String> dList = pbs.Accounting_Code__c.trim().split('-');
			Boolean isASH = pbs.Company__c == 'ASH';
			if(dList.size() == 5 ){
				String bId = isASH ? ashBudgetsMap.get(dList[1]) : ashrcBudgetsMap.get(dList[1]);
				if(accIndexToTag.get(dList[0]) == null) System.debug(dList[0]);
				if(bId != null) {
					cb4__CBTag__c newLine = new cb4__CBTag__c(
							cb4__Dimension__c = BUDGET_AMOUNT_DIM_ID,
							cb4__Tag1__c = bId,
							cb4__Text1__c = accIndexToTag.get(dList[0]).cb4__Tag1__r.cb4__Tag1Name__c.toLowerCase(),
							cb4__Text2__c = accIndexToTag.get(dList[0]).cb4__Tag1__r.cb4__Tag1Name__c.toLowerCase(),
							cb4__Decimal1__c = 0,
							cb4__Text3__c = accIndexToTag.get(dList[0]).Name + ' (' + dList[1] + '-' + dList[2] + '-' + dList[3] + '-' + dList[4] + ')',
							cb4__Text4__c = '',
							cb4__Tag2__c = accIndexToTag.get(dList[0]).Id,
							cb4__Tag3__c = periodMap.get(pbs.Period__c),
							cb4__Tag6__c = d1IndexToTag.get(dList[1]).Id,
							cb4__Tag7__c = d2IndexToTag.get(dList[2]).Id,
							cb4__Tag8__c = d3IndexToTag.get(dList[3]).Id,
							cb4__Tag9__c = d4IndexToTag.get(dList[4]).Id,
							cb4__ExtId__c = PBBId
					);
					cb4__CBTag__c bTotal = isASH ? ashBudgetTotalsByBudgetAndPeriodId.get(bId + periodMap.get(pbs.Period__c) + newLine.cb4__Text2__c) : ashrcBudgetTotalsByBudgetAndPeriodId.get(bId + periodMap.get(pbs.Period__c) + newLine.cb4__Text2__c);
					if(bTotal == null) {
						bTotal = getNewTotalBudgetLine(newLine.cb4__Tag1__c, periodMap.get(pbs.Period__c), newLine.cb4__Text2__c);
						if(isASH) ashBudgetTotalsByBudgetAndPeriodId.put(String.valueOf(newLine.cb4__Tag1__c) + String.valueOf(periodMap.get(pbs.Period__c) + newLine.cb4__Text2__c), bTotal);
						else    ashrcBudgetTotalsByBudgetAndPeriodId.put(String.valueOf(newLine.cb4__Tag1__c) + String.valueOf(periodMap.get(pbs.Period__c) + newLine.cb4__Text2__c), bTotal);
					}

					String blKey = CBBudgetApplication.getSimpleLineKey(newLine, isASH ? ashBudgetsMap.get(dList[1]) : ashrcBudgetsMap.get(dList[1]));
					if (!budgetLinesMap.containsKey(blKey + periodMap.get(pbs.Period__c))) {
						budgetLinesMap.put(blKey + periodMap.get(pbs.Period__c), newLine);
					}
				}
			}
		}

		List<cb4__CBTag__c> newSubLines = new List<cb4__CBTag__c>();
		for (Personnel_Budget_Stager__c pbs : pbsList) {
			List<String> dList = pbs.Accounting_Code__c.trim().split('-');
			Boolean isASH = pbs.Company__c == 'ASH';
			if(dList.size() == 5){
				String bId = isASH ? ashBudgetsMap.get(dList[1]) : ashrcBudgetsMap.get(dList[1]);
				if(bId != null) {
					cb4__CBTag__c newLine = new cb4__CBTag__c(
							cb4__Dimension__c = BUDGET_SUB_AMOUNT_DIM_ID,
							cb4__Tag1__c = bId,
							cb4__Text1__c = accIndexToTag.get(dList[0]).cb4__Tag1__r.cb4__Tag1Name__c.toLowerCase(),
							cb4__Text2__c = accIndexToTag.get(dList[0]).cb4__Tag1__r.cb4__Tag1Name__c.toLowerCase(),
							cb4__Decimal1__c = pbs.Amount__c != null ? pbs.Amount__c.setScale(2) : 0,
							cb4__Text3__c = accIndexToTag.get(dList[0]).Name + ' (' + dList[1] + '-' + dList[2] + '-' + dList[3] + '-' + dList[4] + ')',
							cb4__Text4__c = '',
							cb4__Tag2__c = accIndexToTag.get(dList[0]).Id,
							cb4__Tag3__c = periodMap.get(pbs.Period__c),
							cb4__Tag6__c = d1IndexToTag.get(dList[1]).Id,
							cb4__Tag7__c = d2IndexToTag.get(dList[2]).Id,
							cb4__Tag8__c = d3IndexToTag.get(dList[3]).Id,
							cb4__Tag9__c = d4IndexToTag.get(dList[4]).Id,
							cb4__ExtId__c = PBBId
					);
					String sblKey = CBBudgetApplication.getSimpleLineKey(newLine, isASH ? ashBudgetsMap.get(dList[1]) : ashrcBudgetsMap.get(dList[1]));
					newLine.cb4__Text4__c = accIndexToTag.get(dList[0]).Name + ' (' + dList[1] + '-' + dList[2] + '-' + dList[3] + '-' + dList[4] + ') ' + PBBName;
					if (budgetLinesMap.containsKey(sblKey + periodMap.get(pbs.Period__c))) {
						budgetLinesMap.get(sblKey + periodMap.get(pbs.Period__c)).cb4__Decimal1__c = budgetLinesMap.get(sblKey + periodMap.get(pbs.Period__c)).cb4__Decimal1__c + newLine.cb4__Decimal1__c;
						newLine.cb4__Text10__c = sblKey;
						newSubLines.add(newLine);
					}
					if(isASH && ashBudgetTotalsByBudgetAndPeriodId.containsKey(bId + periodMap.get(pbs.Period__c) + newLine.cb4__Text2__c)){
						ashBudgetTotalsByBudgetAndPeriodId.get(bId + periodMap.get(pbs.Period__c) + newLine.cb4__Text2__c).cb4__Decimal1__c = ashBudgetTotalsByBudgetAndPeriodId.get(bId + periodMap.get(pbs.Period__c) + newLine.cb4__Text2__c).cb4__Decimal1__c + newLine.cb4__Decimal1__c;
					}else if(!isASH && ashrcBudgetTotalsByBudgetAndPeriodId.containsKey(bId + periodMap.get(pbs.Period__c) + newLine.cb4__Text2__c)){
						ashrcBudgetTotalsByBudgetAndPeriodId.get(bId + periodMap.get(pbs.Period__c) + newLine.cb4__Text2__c).cb4__Decimal1__c = ashrcBudgetTotalsByBudgetAndPeriodId.get(bId + periodMap.get(pbs.Period__c) + newLine.cb4__Text2__c).cb4__Decimal1__c + newLine.cb4__Decimal1__c;
					}
				}
			}
		}
		upsert ashBudgetTotalsByBudgetAndPeriodId.values();
		upsert ashrcBudgetTotalsByBudgetAndPeriodId.values();
		insert budgetLinesMap.values();
		insert newSubLines;

	}

	public void finish(Database.BatchableContext BC) {

	}

	private static Map<String,cb4__CBTag__c> getTotalsMapByBudgetId(String yearName, String departmentName){
		Map<String, cb4__CBTag__c> totalsMap = new Map<String, cb4__CBTag__c>();
		for(cb4__CBTag__c t : [SELECT Id, cb4__Decimal1__c, cb4__Tag1__c, cb4__Tag3__c, cb4__Text2__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :BUDGET_AMOUNT_DIM_ID AND cb4__Tag1__r.cb4__Tag3Name__c = :yearName AND cb4__Tag1__r.cb4__Tag4Name__c = :departmentName AND cb4__Text1__c = 'total' AND cb4__Tag1__r.cb4__Boolean2__c = TRUE]){
			totalsMap.put(String.valueOf(t.cb4__Tag1__c) + String.valueOf(t.cb4__Tag3__c) + String.valueOf(t.cb4__Text2__c), t);
		}
		return totalsMap;
	}

	private static cb4__CBTag__c getNewTotalBudgetLine(String bId, String perId, String totalType){
		return new cb4__CBTag__c(cb4__Text1__c = 'total', cb4__Text2__c = totalType, cb4__Text3__c = totalType, cb4__Tag1__c = bId, cb4__Tag3__c = perId, cb4__Dimension__c = BUDGET_AMOUNT_DIM_ID, cb4__Decimal1__c = 0, cb4__Decimal2__c = 0);
	}

	public static void codeGen(){
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
	}

}