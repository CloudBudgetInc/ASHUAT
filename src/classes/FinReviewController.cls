public with sharing class FinReviewController {

    private static final Integer UPPER_QUERY_LIMIT = 50000;
    private static final Integer TEST_QUERY_LIMIT = 1;

    Enum TYPE { COMPANY, PERIOD, YEAR, TRIAL_BALANCE_1, TRIAL_BALANCE_3, PROGRAM }
    
    @AuraEnabled(cacheable=false)
    // ASH, 353. Returns data for the 'main' table. One column of dollars for now; Rich to caffeinate.
    public static List<Income> income(String company, String programCode) {

        Integer queryLimit = !Test.isRunningTest() ? UPPER_QUERY_LIMIT : TEST_QUERY_LIMIT;     
        Financial_Review__mdt settings = Financial_Review__mdt.getInstance('Default');
        String year = settings.Year__c;
        String period = settings.Period__c;        
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id targetCompany = provider.getCompany(company);
		c2g__codaPeriod__c targetPeriod = provider.getPeriod(company, period);
        
		AggregateResult[] periodIncome = [SELECT 
			SUM(c2g__HomeValue__c) Income, 
			c2g__Dimension2__r.Name programName,
			c2g__GeneralLedgerAccount__r.Name geeElName,    
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c trialBalance1,
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c trialBalance3,
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c geeElAccount, 
			c2g__Dimension1__r.c2g__ReportingCode__c department,
			c2g__Dimension2__r.c2g__ReportingCode__c program, 
			c2g__Dimension3__r.c2g__ReportingCode__c project, 
			c2g__Dimension4__r.c2g__ReportingCode__c other                                        
			FROM c2g__ReportingBalance__c 
			WHERE c2g__GeneralLedgerAccount__r.c2g__Type__c = 'Profit and Loss' AND 
			c2g__Period__c = :targetPeriod.Id AND
            c2g__OwnerCompany__c = :targetCompany AND 
			c2g__Dimension2__r.c2g__ReportingCode__c = :programCode AND 
			c2g__Type__c = 'Actual'  
			GROUP BY c2g__Dimension2__r.Name,
			c2g__GeneralLedgerAccount__r.Name,
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c,   
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c,                           
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c,                                    
			c2g__Dimension1__r.c2g__ReportingCode__c,
			c2g__Dimension2__r.c2g__ReportingCode__c, 
			c2g__Dimension3__r.c2g__ReportingCode__c, 
			c2g__Dimension4__r.c2g__ReportingCode__c
			LIMIT :queryLimit];
        
		AggregateResult[] ytdIncome = [SELECT 
			SUM(c2g__HomeValue__c) Income, 
			c2g__Dimension2__r.Name programName,
			c2g__GeneralLedgerAccount__r.Name geeElName,    
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c trialBalance1,
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c trialBalance3,
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c geeElAccount, 
			c2g__Dimension1__r.c2g__ReportingCode__c department,
			c2g__Dimension2__r.c2g__ReportingCode__c program, 
			c2g__Dimension3__r.c2g__ReportingCode__c project, 
			c2g__Dimension4__r.c2g__ReportingCode__c other                                        
			FROM c2g__ReportingBalance__c 
			WHERE c2g__GeneralLedgerAccount__r.c2g__Type__c = 'Profit and Loss' AND 
			Year__c = :year AND 
            c2g__OwnerCompany__c = :targetCompany AND 
			c2g__Dimension2__r.c2g__ReportingCode__c = :programCode AND 
			c2g__Type__c = 'Actual'  
			GROUP BY c2g__Dimension2__r.Name,
			c2g__GeneralLedgerAccount__r.Name,
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c,   
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c,                           
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c,                                    
			c2g__Dimension1__r.c2g__ReportingCode__c,
			c2g__Dimension2__r.c2g__ReportingCode__c, 
			c2g__Dimension3__r.c2g__ReportingCode__c, 
			c2g__Dimension4__r.c2g__ReportingCode__c
			LIMIT :queryLimit];
        
		AggregateResult[] budgetedIncome = [SELECT 
			SUM(c2g__HomeValue__c) Income, 
			c2g__Dimension2__r.Name programName,
			c2g__GeneralLedgerAccount__r.Name geeElName,    
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c trialBalance1,
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c trialBalance3,
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c geeElAccount, 
			c2g__Dimension1__r.c2g__ReportingCode__c department,
			c2g__Dimension2__r.c2g__ReportingCode__c program, 
			c2g__Dimension3__r.c2g__ReportingCode__c project, 
			c2g__Dimension4__r.c2g__ReportingCode__c other                                        
			FROM c2g__ReportingBalance__c 
			WHERE c2g__GeneralLedgerAccount__r.c2g__Type__c = 'Profit and Loss' AND 
			Year__c = :year AND 
            c2g__OwnerCompany__c = :targetCompany AND 
			c2g__Dimension2__r.c2g__ReportingCode__c = :programCode AND 
			c2g__Type__c = 'Budget'  
			GROUP BY c2g__Dimension2__r.Name,
			c2g__GeneralLedgerAccount__r.Name,
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c,   
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c,                           
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c,                                    
			c2g__Dimension1__r.c2g__ReportingCode__c,
			c2g__Dimension2__r.c2g__ReportingCode__c, 
			c2g__Dimension3__r.c2g__ReportingCode__c, 
			c2g__Dimension4__r.c2g__ReportingCode__c
			LIMIT :queryLimit];   
        
		AggregateResult[] budgetedYtdIncome = [SELECT 
			SUM(c2g__HomeValue__c) Income, 
			c2g__Dimension2__r.Name programName,
			c2g__GeneralLedgerAccount__r.Name geeElName,    
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c trialBalance1,
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c trialBalance3,
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c geeElAccount, 
			c2g__Dimension1__r.c2g__ReportingCode__c department,
			c2g__Dimension2__r.c2g__ReportingCode__c program, 
			c2g__Dimension3__r.c2g__ReportingCode__c project, 
			c2g__Dimension4__r.c2g__ReportingCode__c other                                        
			FROM c2g__ReportingBalance__c 
			WHERE c2g__GeneralLedgerAccount__r.c2g__Type__c = 'Profit and Loss' AND 
			PerPost__c <= :targetPeriod.PerPost__c AND 
			Year__c = :year AND                                         
            c2g__OwnerCompany__c = :targetCompany AND 
			c2g__Dimension2__r.c2g__ReportingCode__c = :programCode AND 
			c2g__Type__c = 'Budget'  
			GROUP BY c2g__Dimension2__r.Name,
			c2g__GeneralLedgerAccount__r.Name,
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c,   
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c,                           
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c,                                    
			c2g__Dimension1__r.c2g__ReportingCode__c,
			c2g__Dimension2__r.c2g__ReportingCode__c, 
			c2g__Dimension3__r.c2g__ReportingCode__c, 
			c2g__Dimension4__r.c2g__ReportingCode__c
			LIMIT :queryLimit];         
        
		AggregateResult[] projectedIncome = [SELECT 
			SUM(c2g__HomeValue__c) Income, 
			c2g__Dimension2__r.Name programName,
			c2g__GeneralLedgerAccount__r.Name geeElName,    
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c trialBalance1,
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c trialBalance3,
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c geeElAccount, 
			c2g__Dimension1__r.c2g__ReportingCode__c department,
			c2g__Dimension2__r.c2g__ReportingCode__c program, 
			c2g__Dimension3__r.c2g__ReportingCode__c project, 
			c2g__Dimension4__r.c2g__ReportingCode__c other                                        
			FROM c2g__ReportingBalance__c 
			WHERE c2g__GeneralLedgerAccount__r.c2g__Type__c = 'Profit and Loss' AND 
			Year__c = :year AND 
            c2g__OwnerCompany__c = :targetCompany AND 
			c2g__Dimension2__r.c2g__ReportingCode__c = :programCode AND 
			c2g__Type__c = 'Projection'  
			GROUP BY c2g__Dimension2__r.Name,
			c2g__GeneralLedgerAccount__r.Name,
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c,   
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c,                           
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c,                                    
			c2g__Dimension1__r.c2g__ReportingCode__c,
			c2g__Dimension2__r.c2g__ReportingCode__c, 
			c2g__Dimension3__r.c2g__ReportingCode__c, 
			c2g__Dimension4__r.c2g__ReportingCode__c
			LIMIT :queryLimit];               
        
        Map<String, FinReviewController.Income> keyedIncome = new Map<String, FinReviewController.Income>();
        
        // Iterate through periodIncome. Here, we'll do an initial setup of the keyedIncome map.
        for (AggregateResult ar : periodIncome) {
			String key = getKey(ar);
            FinReviewController.Income someIncome = incomeFactory(key, ar);
            
            // Handle value reversal. Only necessary for Actuals.            
            Decimal amount = (Decimal) ar.get('Income');
            if( someIncome.trialBalance1 == 'Income' ) { 
	            someIncome.periodTotal = amount * -1;
            } else {
                someIncome.periodTotal = amount;
            }
            keyedIncome.put(key, someIncome);
            System.debug(someIncome);
        }
        
        // Iterate through YTD income
        for (AggregateResult ar : ytdIncome) {
			String key = getKey(ar);
			FinReviewController.Income someIncome;         
            if(keyedIncome.get(key) != null) { 
            	someIncome = keyedIncome.get(key);
            } else { 
                someIncome = incomeFactory(key, ar);
            }
            
            // Handle value reversal. Only necessary for Actuals.
            Decimal amount = (Decimal) ar.get('Income');
            if( someIncome.trialBalance1 == 'Income' ) { 
	            someIncome.ytdTotal = amount * -1;
            } else {
                someIncome.ytdTotal = amount;
            }            
            keyedIncome.put(key, someIncome);
            System.debug(someIncome);                
        }        
        
        // Iterate through budgeted YTD income
        for (AggregateResult ar : budgetedYtdIncome) {
			String key = getKey(ar);
			FinReviewController.Income someIncome;
            if(keyedIncome.get(key) != null) { 
            	someIncome = keyedIncome.get(key);
            } else { 
                someIncome = incomeFactory(key, ar);
            }
            someIncome.budgetedYtdTotal = (Decimal) ar.get('Income');
            keyedIncome.put(key, someIncome);
            System.debug(someIncome);
        }             
        
        // Iterate through budgeted income
        for (AggregateResult ar : budgetedIncome) {
			String key = getKey(ar);
			FinReviewController.Income someIncome;
            if(keyedIncome.get(key) != null) { 
            	someIncome = keyedIncome.get(key);
            } else { 
                someIncome = incomeFactory(key, ar);
            }
            someIncome.budgetedTotal = (Decimal) ar.get('Income');
            keyedIncome.put(key, someIncome);
            System.debug(someIncome);
        }      
        
        // Iterate through projected income
        for (AggregateResult ar : projectedIncome) {
			String key = getKey(ar); 
          	FinReviewController.Income someIncome;            
            if(keyedIncome.get(key) != null) { 
            	someIncome = keyedIncome.get(key);
            } else { 
                someIncome = incomeFactory(key, ar);
			}    
            someIncome.projectedTotal = (Decimal) ar.get('Income');                
            keyedIncome.put(key, someIncome);
            System.debug(someIncome);            
        }          
                
        // Return.
        List<FinReviewController.Income> results = keyedIncome.values();
        return results;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Balance> balances(String company, String year) {
        
        Integer queryLimit = !Test.isRunningTest() ? UPPER_QUERY_LIMIT : TEST_QUERY_LIMIT;
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id targetCompany = provider.getCompany(company);
        
		AggregateResult[] periodResults = [SELECT 
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c ReportingCode,
			c2g__GeneralLedgerAccount__r.Name GeneralLedgerAccount, 
            c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c Category, 
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c Subcategory,                                
			c2g__Dimension1__r.c2g__ReportingCode__c Dimension1, 
			c2g__Dimension2__r.c2g__ReportingCode__c Dimension2, 
			c2g__Dimension3__r.c2g__ReportingCode__c Dimension3, 
			c2g__Dimension4__r.c2g__ReportingCode__c Dimension4,      
			SUM(c2g__HomeValue__c) Balance
			FROM c2g__ReportingBalance__c 
			WHERE c2g__GeneralLedgerAccount__r.c2g__Type__c = 'Balance Sheet' AND 
			c2g__Period__r.Trial_Balance_Ready__c = true AND 
            c2g__OwnerCompany__c = :targetCompany AND                      
			Year__c = :year AND 
			c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c <> '2999' AND 
            c2g__GeneralLedgerAccount__r.Is_Suspense__c = false
			GROUP BY c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c, 
			c2g__GeneralLedgerAccount__r.Name, 
            c2g__GeneralLedgerAccount__r.c2g__TrialBalance1__c, 
			c2g__GeneralLedgerAccount__r.c2g__TrialBalance3__c,                                              
			c2g__Dimension1__r.c2g__ReportingCode__c,
			c2g__Dimension2__r.c2g__ReportingCode__c, 
			c2g__Dimension3__r.c2g__ReportingCode__c, 
			c2g__Dimension4__r.c2g__ReportingCode__c
			LIMIT :queryLimit];
        
        // Used to set a flag on the key value regarding whether there are open comments.
        Map<String, String> commentCounter = new Map<String, String>();
        AggregateResult[] comments = [SELECT COUNT(Id) CommentCount, Key__c FROM Comment__c 
			WHERE Status__c = 'Open' AND Company__c = :company GROUP BY Key__c];
        for (AggregateResult ar : comments) { 
            commentCounter.put((String)ar.get('Key__c'), 'true');
        }
        
		AggregateResult[] assignees = [SELECT MAX(Id), Key__c Key, Assignee__r.Name Assignee FROM Comment__c 
			WHERE Status__c = 'Open' AND Company__c = :company GROUP BY Key__c, Assignee__r.Name];
        Map<String,String> assigneesToKey = new Map<String,String>();
        for( AggregateResult ar : assignees ) {
            assigneesToKey.put((String) ar.get('Key'), (String) ar.get('Assignee'));
        }

        List<Balance> results = new List<Balance>();
        for (AggregateResult ar : periodResults) {
            Balance someBalance = new Balance();
            someBalance.name = (String) ar.get('GeneralLedgerAccount');
            String key = ar.get('ReportingCode') + '-' + ar.get('Dimension1') + '-' + ar.get('Dimension2') + '-' 
				+ ar.get('Dimension3') + '-' + ar.get('Dimension4');
            someBalance.accountSubaccount = key;
            someBalance.trialBalance1 = (String) ar.get('Category');
            someBalance.trialBalance3 = (String) ar.get('Subcategory');
            someBalance.balance = (Decimal) ar.get('Balance');
            someBalance.hasOpenComments = commentCounter.get(key)==null?'false':commentCounter.get(key);
            someBalance.assignee = assigneesToKey.get(key)==null?'':assigneesToKey.get(key);
            results.add(someBalance);
		}
        // system.debug(JSON.serialize(results));
        return results;
    }    
    
    @AuraEnabled(cacheable=false)
    public static List<c2g__codaTransactionLineItem__c> transactions(String company, String year, String key) {
        Integer queryLimit = !Test.isRunningTest() ? UPPER_QUERY_LIMIT : TEST_QUERY_LIMIT;
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id targetCompany = provider.getCompany(company);
        
        List<c2g__codaTransactionLineItem__c> results = 
            [SELECT c2g__Transaction__r.c2g__Period__r.Name, c2g__LineDescription__c, c2g__TransactionDate__c, 
            	c2g__GeneralLedgerAccount__r.Name, Account_Subaccount__c, c2g__Account__r.Name, 
             	c2g__DocumentNumber__c, c2g__HomeValue__c 
        	FROM c2g__codaTransactionLineItem__c    
        	WHERE Account_Subaccount__c = :key AND 
            c2g__OwnerCompany__r.Key__c = :company AND 
            c2g__Transaction__r.c2g__Period__r.Trial_Balance_Ready__c = true AND
            c2g__Transaction__r.c2g__Period__r.Fiscal_Year_Text__c = :year
            ORDER BY c2g__TransactionDate__c DESC
            LIMIT :queryLimit];
            
        return results;
    }
    // Overloaded for pagination
    // @AuraEnabled(cacheable=false)
    public static List<c2g__codaTransactionLineItem__c> transactionsVF(String company, String year, String key, Integer limitSize, Integer offset) {
        FfaDataProvider provider = FfaDataProvider.getInstance();
        Id targetCompany = provider.getCompany(company);
        
        List<c2g__codaTransactionLineItem__c> results = 
            [SELECT c2g__Transaction__r.c2g__Period__r.Name, c2g__LineDescription__c, c2g__TransactionDate__c, 
                c2g__GeneralLedgerAccount__r.Name, Account_Subaccount__c, c2g__Account__r.Name, 
                c2g__DocumentNumber__c, c2g__HomeValue__c 
            FROM c2g__codaTransactionLineItem__c    
            WHERE Account_Subaccount__c = :key AND 
            c2g__OwnerCompany__r.Key__c = :company AND 
            c2g__Transaction__r.c2g__Period__r.Trial_Balance_Ready__c = true AND             
            c2g__Transaction__r.c2g__Period__r.Fiscal_Year_Text__c = :year
            ORDER BY c2g__TransactionDate__c DESC             
            LIMIT :limitSize OFFSET :offset];
            // system.debug(JSON.serialize(results));
        return results;
    }

    @AuraEnabled(cacheable=false)
    public static List<FilterTag> filters() {        
        Integer queryLimit = !Test.isRunningTest() ? UPPER_QUERY_LIMIT : TEST_QUERY_LIMIT;
        List<c2g__codaCompany__c> companies = [SELECT Id, Key__c FROM c2g__codaCompany__c LIMIT :queryLimit];
		List<c2g__codaYear__c> years = [SELECT Id, Name FROM c2g__codaYear__c WHERE Name > '2022' AND Name < '2025' LIMIT :queryLimit];
        List<c2g__codaGeneralLedgerAccount__c> geeEls = [SELECT c2g__TrialBalance1__c, c2g__TrialBalance3__c FROM c2g__codaGeneralLedgerAccount__c 
			WHERE c2g__Type__c = 'Balance Sheet' ORDER BY c2g__TrialBalance1__c, c2g__TrialBalance3__c LIMIT :queryLimit];
        List<c2g__codaDimension2__c> programs = [SELECT Name, c2g__ReportingCode__c, ASHRC__c FROM c2g__codaDimension2__c WHERE Active__c = true];
        List<FilterTag> results = new List<FilterTag>();
        results.addAll(tags(companies));
        results.addAll(tags(years));
        results.addAll(tags(geeEls, TYPE.TRIAL_BALANCE_1));
        results.addAll(tags(programs));
		return results;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<FilterTag> filtersTb3(String trialBalance1) {
        Integer queryLimit = !Test.isRunningTest() ? UPPER_QUERY_LIMIT : TEST_QUERY_LIMIT;
        List<c2g__codaGeneralLedgerAccount__c> geeEls = [SELECT c2g__TrialBalance1__c, c2g__TrialBalance3__c FROM c2g__codaGeneralLedgerAccount__c 
	        WHERE c2g__Type__c = 'Balance Sheet' AND c2g__TrialBalance1__c = :trialBalance1 ORDER BY c2g__TrialBalance3__c ASC  LIMIT :queryLimit];
        List<FilterTag> results = new List<FilterTag>();
        results.addAll(tags(geeEls, TYPE.TRIAL_BALANCE_3));
		return results;
    }    
    
    @TestVisible
    private static List<FilterTag> tags(List<c2g__codaCompany__c> companies) {
        List<FilterTag> results = new List<FilterTag>();
        for (c2g__codaCompany__c someCompany : companies) {
            FinReviewController.FilterTag someTag = new FinReviewController.FilterTag();
            someTag.identifier = someCompany.Key__c;
            someTag.type = TYPE.COMPANY.name(); 
            someTag.value = someCompany.Key__c;
            results.add(someTag);
        }
        return results;
    }
    
    @TestVisible
    private static List<FilterTag> tags(List<c2g__codaPeriod__c> periods) {
        Map<String, FilterTag> results = new Map<String, FilterTag>();        
        for (c2g__codaPeriod__c somePeriod : periods) {
            FinReviewController.FilterTag someTag = new FinReviewController.FilterTag();
            someTag.identifier = somePeriod.Id;
            someTag.type = TYPE.PERIOD.name(); 
            someTag.value = somePeriod.Name;
            results.put(somePeriod.Name, someTag);
        }
        return results.values();
    }
    
    @TestVisible 
    private static List<FilterTag> tags(List<c2g__codaYear__c> years) {
        Map<String, FilterTag> results = new Map<String, FilterTag>();        
        for (c2g__codaYear__c someYear : years) {
            FinReviewController.FilterTag someTag = new FinReviewController.FilterTag();
            someTag.identifier = someYear.Name;
            someTag.type = TYPE.YEAR.name();
            someTag.value = someYear.Name;
            results.put(someYear.Name, someTag);
        }
        return results.values();
    }
    
    @TestVisible 
    private static List<FilterTag> tags(List<c2g__codaDimension2__c> programs) {
        Map<String, FilterTag> results = new Map<String, FilterTag>();        
        for (c2g__codaDimension2__c someProgram : programs) {
            FinReviewController.FilterTag someTag = new FinReviewController.FilterTag();
            someTag.identifier = someProgram.Name;
            someTag.type = TYPE.PROGRAM.name();
            someTag.value = someProgram.c2g__ReportingCode__c;
            someTag.company = someProgram.ASHRC__c? 'ASHRC' : 'ASH';
            System.debug(someTag);
            results.put(someProgram.Name, someTag);
        }
        return results.values();
    }    
    
    @TestVisible
    private static List<FilterTag> tags(List<c2g__codaGeneralLedgerAccount__c> geeEls, TYPE type) {
        Map<String, FilterTag> results = new Map<String, FilterTag>();
        for (c2g__codaGeneralLedgerAccount__c someGeeEl : geeEls) {
            FinReviewController.FilterTag someTag = new FinReviewController.FilterTag();
            
            if (type == FinReviewController.TYPE.TRIAL_BALANCE_1) {
                someTag.identifier = someGeeEl.c2g__TrialBalance1__c;
                someTag.type = FinReviewController.TYPE.TRIAL_BALANCE_1.name(); 
                someTag.value = someGeeEl.c2g__TrialBalance1__c;
                if (someTag.value != null) {
                    results.put(someGeeEl.c2g__TrialBalance1__c, someTag);
                }
            } else {
                someTag.identifier = someGeeEl.c2g__TrialBalance3__c;
                someTag.type = FinReviewController.TYPE.TRIAL_BALANCE_3.name(); 
                someTag.value = someGeeEl.c2g__TrialBalance3__c;
                results.put(someGeeEl.c2g__TrialBalance3__c, someTag);
            }
        }
        return results.values();
    }
    
    @AuraEnabled(cacheable=false)
    public static Map<String,String> defaults() {
        Financial_Review__mdt settings = Financial_Review__mdt.getInstance('Default');
        Map<String,String> defaults = new Map<String,String>();
        defaults.put('Company', settings.Company__c);
        defaults.put('Year', settings.Year__c);
        String year = settings.Year__c;
        String company = settings.Company__c;
        
        String includedPeriods = '';    
        List<c2g__codaPeriod__c> periods = [SELECT Id, PerPost__c FROM c2g__codaPeriod__c 
                                            WHERE Fiscal_Year_Text__c = :year AND 
                                           	Trial_Balance_Ready__c = true AND 
                                            c2g__OwnerCompany__r.Key__c = :company 
                                            ORDER BY PerPost__c ASC];
        for(c2g__codaPeriod__c somePeriod : periods) {
            includedPeriods += somePeriod.PerPost__c + ', ';
        }
        defaults.put('Periods', includedPeriods.removeEnd(', '));
        
		return defaults;
    }      
    
    @AuraEnabled(cacheable=false)
    public static Id insertComment(String company, String key, String content, String assigneeId) {

        id doesNotMatter = resolveComment( company, key, 'Reassigned' );

        Comment__c c = new Comment__c(Key__c = key, Company__c = company, Content__c = content, 
			Assignee__c = assigneeId, Status__c = 'Open');
        insert c;
        return c.Id;
    }

    @AuraEnabled(cacheable=false)
    public static Id respondComment(String company, String key, String content, String assigneeId) {

        Comment__c c = new Comment__c(Key__c = key, Company__c = company, Content__c = content, 
        Assignee__c = assigneeId);
        insert c;
        return c.Id;
    }

    @AuraEnabled(cacheable=false)
    public static Id resolveComment(String company, String key, String status) {

        id response;

        List<Comment__c> opens = [SELECT Id, Content__c, Assignee__r.Name, Status__c FROM Comment__c WHERE 
                                Company__c = :company AND Key__c = :key AND Status__c = 'Open'];
        for(Comment__c o : opens ) {
            // o.Status__c = 'Resolved';
            o.Status__c = status;
        }                                   
        if( !opens.isEmpty() ) { 
            update opens;
            response = opens.get(0).id;
        }

        return response; 
    }

    @AuraEnabled(cacheable=false)    
    public static List<Comment__c> comments(String company, String key, boolean archived ) {
        List<Comment__c> results;
        
        if( archived ) {
            results = [SELECT Id, Content__c, Assignee__r.Name, Status__c,CreatedDate, LastModifiedBy.Name, Archived__c, CreatedBy.Name  FROM Comment__c WHERE 
                                       Company__c = :company AND Key__c = :key ORDER BY CreatedDate DESC];
        } else {
            results = [SELECT Id, Content__c, Assignee__r.Name, Status__c,CreatedDate, LastModifiedBy.Name, Archived__c, CreatedBy.Name  FROM Comment__c WHERE 
                                   Company__c = :company AND Key__c = :key AND Archived__c = :archived ORDER BY CreatedDate DESC];
        } 
        return results;
    }

    @AuraEnabled(cacheable=false)
    public static boolean archiveComment( string commentID, boolean archived ) {
        List<Comment__c> comments = [SELECT Archived__c FROM Comment__c WHERE id = :commentID];
        if( !comments.isEmpty() ) {
            comments.get(0).Archived__c = archived;
            update comments;
            return true;
        }
        return false;
    }
    
    @AuraEnabled(cacheable=false)
    public static boolean archiveAllComments( string company, string key ) {
        List<Comment__c> comments = [SELECT Archived__c FROM Comment__c WHERE Company__c = :company AND Key__c = :key];
        if( !comments.isEmpty() ) {
            for(Comment__c c : comments  ) {
                c.Archived__c = true;
            }
            update comments;
            return true;
        }
        return false;
    }

    @AuraEnabled(cacheable=true)
    public static List<UserOption> getAssignableUsers() {
        List<UserOption> options = new List<UserOption>();

        //if (Schema.sObjectType.Profile.isAccessible()) {
            for(User usr : [SELECT FirstName, LastName FROM User WHERE IsActive = true AND FirstName != null AND Profile.Name LIKE '%Finance%' ORDER BY FirstName]) {
                options.add(new UserOption(usr.Id, usr.FirstName + ' ' + usr.LastName));
            }
        //} else {
        //    for(User usr : [SELECT FirstName, LastName FROM User WHERE IsActive = true AND FirstName != null ORDER BY FirstName]) {
        //        options.add(new UserOption(usr.Id, usr.FirstName + ' ' + usr.LastName));
        //    }
        //}
        
        return options;
    }
    
    // key value is account-subaccount, i.e. 7020-112-359-000-00.
    static String getKey(AggregateResult result) {
        return result.get('geeElAccount') + '-' + result.get('department') + '-' + result.get('program') + '-' + 
				result.get('project') + '-' + result.get('other');
    }
    
    static FinReviewController.Income incomeFactory(String key, AggregateResult result) {
        
        FinReviewController.Income someIncome = new FinReviewController.Income();
        someIncome.name = (String) result.get('geeElName');
        someIncome.programName = (String) result.get('programName');
        someIncome.accountSubaccount = key;
        someIncome.trialBalance1 = (String) result.get('trialBalance1');
        someIncome.trialBalance3 = (String) result.get('trialBalance3');
        if(someIncome.trialBalance1 == 'Income') { someIncome.category = 'Income'; } 
        else if( someIncome.trialBalance1 == 'Expense' && someIncome.trialBalance3 == 'Expense' && key.right(2) != '25' && key.right(2) != '85') {
            someIncome.category = 'Program Expense';
        }
        else if( someIncome.trialBalance1 == 'Expense' && ( key.right(2) == '25' || key.right(2) == '85' || 
			someIncome.trialBalance3.indexOf('Salary and Benefits') >= 0)) {
			someIncome.category = 'Salary & Overhead';
        }
        else { 
            someIncome.category = 'Not Applicable';
        }
        return someIncome;
    }

    @AuraEnabled(cacheable=true)
    public static string baseURL() {
        return URL.getOrgDomainURL().toExternalForm();
    }

    public class UserOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public UserOption(String value, String label) {
            this.label = label;
            this.value = value;
        }
    }
    
    public class FilterTag {
        @AuraEnabled public String identifier;
        @AuraEnabled public String type;
        @AuraEnabled public String value;
        @AuraEnabled public String company;

        public void setType(TYPE enumType) {
            this.type = enumType.name(); 
        }
        
        public override String toString() {
            return company + ' - ' + identifier + ' - ' + type + ' - ' + value;
        }        
    }
    
    public class Balance {
        @AuraEnabled public String name;
        @AuraEnabled public String accountSubaccount;
        @AuraEnabled public String trialBalance1;
        @AuraEnabled public String trialBalance3;
        @AuraEnabled public Decimal balance;
        @AuraEnabled public String hasOpenComments;
        @AuraEnabled public String assignee;
        
        public override String toString() {
            return name + ' - ' + accountSubaccount + ' - ' + trialBalance1 + ' - ' + trialBalance3 + 
                ' - ' + balance + ' - ' + hasOpenComments + ' - ' + assignee;
        }
    }  
    
    public class Income {
        @AuraEnabled public String name;
        @AuraEnabled public String accountSubaccount;
        @AuraEnabled public String trialBalance1;
        @AuraEnabled public String trialBalance3;
        @AuraEnabled public String programName;
        @AuraEnabled public Decimal periodTotal = 0.00;
        @AuraEnabled public Decimal ytdTotal = 0.00;
        @AuraEnabled public Decimal budgetedTotal = 0.00;
        @AuraEnabled public Decimal budgetedYtdTotal = 0.00;        
        @AuraEnabled public Decimal projectedTotal = 0.00;
        @AuraEnabled public String hasOpenComments;
        @AuraEnabled public String assignee;
        @AuraEnabled public String category;
        
        public override String toString() {
            //return accountSubaccount + ' - ' + category + ' - ' + trialBalance1 + ' - ' + trialBalance3 + ' - ' + programName + ' - ' + name 
            //    + ' - ' + periodTotal + ' - ' + ytdTotal + ' - ' + budgetedTotal + ' - ' + projectedTotal;
            return accountSubaccount + ' - ' + programName + ' - ' + name + ' - Period: ' + periodTotal + ' - YTD Actuals: ' + 
                ytdTotal + ' - Budgeted YTD: ' + budgetedYtdTotal + ' - Budgeted: ' + budgetedTotal + ' - Projected: ' + projectedTotal;
        }
    }      
    
    public class TransactionRow {
        @AuraEnabled public String document;
        @AuraEnabled public String accountSubaccount;
        @AuraEnabled public String period;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Date transactionDate;
        @AuraEnabled public String account;
        @AuraEnabled public String generalLedgerAccount;
        @AuraEnabled public String description;
        
        public override String toString() {
            return document + '-' + period + '-' + transactionDate + '-' + generalLedgerAccount + 
                '-' + accountSubaccount + '-' + description + '-' + amount;
        }
    }      
}