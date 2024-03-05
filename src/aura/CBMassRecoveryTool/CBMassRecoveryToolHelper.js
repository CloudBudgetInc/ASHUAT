({
	helpInitUsersData: function (cmp){
		function callback(cmp, res){
			let r = res.getReturnValue();
			cmp.set('v.selectedUsersBudgetYear', r['budgetYearId']);
			cmp.set('v.budgetYearName', r['budgetYearName']);
			cmp.set('v.budgetYearPeriodSO', r['periods']);
		}
		_CBRequest(
			cmp,
			'c.getUsersVariableServer',
			null,
			null,
			callback,
			null,
			'Failed to load Users Data',
			false
		);
	},

	helpStartDataGettingProcess: function(cmp){
		cmp.set('v.showSpinner', true);
		this.helpGetBudgets((cmp));
	},

	helpGetBudgets: function (cmp){
		const _this = this;
		function callback(cmp, res){
			let resBudgets = res.getReturnValue();
			if(resBudgets.length === 0){
				_CBMessages.fireOtherMessage('There are no any Budget Data.');
				cmp.set('v.budgetLines', []);
				cmp.set('v.budgetSubLines', []);
				cmp.set('v.showSpinner', false);
			}else{
				_this.helpGetBudgetLines(cmp);
			}
		}
		_CBRequest(
			cmp,
			'c.getBudgetsServer',
			null,
			'v.budgets',
			callback,
			null,
			'Failed to load Budgets',
			false
		);
	},

	helpGetBudgetLines: function(cmp){
		const _this = this;
		const budgets = cmp.get('v.budgets');
		let counter = 0, addCounter = 0;
		let budgetLines = [];
		let appIds = [];
		for(let i = 0; i < budgets.length; i++){
			appIds.push(budgets[i].Id);
			counter = i;
			if(i === budgets.length - 1 || appIds.length === 50){
				_CBRequest(
					cmp,
					'c.getBudgetLinesServer',
					{
						'appIds' : appIds
					},
					null,
					callback,
					null,
					'Failed to load Budget Lines',
					false
				);
				appIds = [];
			}
		}
		function callback(cmp, res){
			addCounter += 50;
			let bLines = res.getReturnValue();
			budgetLines = budgetLines.concat(bLines);
			if(addCounter >= budgets.length - 1){
				cmp.set('v.budgetLines', budgetLines);
				_this.helpGetBudgetSubLines(cmp);
			}
		}
	},

	helpGetBudgetSubLines: function (cmp){
		const _this = this;
		const budgets = cmp.get('v.budgets');
		let counter = 0, addCounter = 0;
		let budgetSubLines = [];
		let appIds = [];
		for(let i = 0; i < budgets.length; i++){
			appIds.push(budgets[i].Id);
			counter = i;
			if(i === budgets.length - 1 || appIds.length === 50){
				_CBRequest(
					cmp,
					'c.getBudgetSubLinesServer',
					{
						'appIds' : appIds
					},
					null,
					callback,
					'Budgets Data Info updated.',
					'Failed to load Budget SubLines',
					false
				);
				appIds = [];
			}
		}
		function callback(cmp, res){
			addCounter += 50;
			let bsLines = res.getReturnValue();
			budgetSubLines = budgetSubLines.concat(bsLines);
			if(addCounter >= budgets.length - 1){
				cmp.set('v.budgetSubLines', budgetSubLines);
				console.clear();
				console.log(JSON.parse(JSON.stringify(cmp.get('v.budgets'))));
				console.log(JSON.parse(JSON.stringify(cmp.get('v.budgetLines'))));
				console.log(JSON.parse(JSON.stringify(budgetSubLines)));
				cmp.set('v.showSpinner', false);
			}
		}
	},

	helpGetSO: function (cmp){
		cmp.set('v.showSpinner', true);
		function callback(cmp, res){
			let rMap = res.getReturnValue();
			cmp.set('v.budgetYearSO', rMap['budgetYears']);
			cmp.set('v.showSpinner', false);
		}
		_CBRequest(
			cmp,
			'c.getSOServer',
			null,
			null,
			callback,
			null,
			'Failed to load CB SO Data',
			false
		);
	},

	helpDownloadExcel: function (cmp){
		try {

			//--> PREPARATION

			let exStyle = this.getExcelStyle(); // styles
			// excel bColumns map
			let abc = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'AA', 'AB', 'AC', 'AD', 'AE', 'AF', 'AG', 'AH'];

			//--> data
			let budgets = cmp.get('v.budgets');
			this.helpFormatData(budgets);
			let budgetLines = cmp.get('v.budgetLines');
			this.helpFormatData(budgetLines);
			let budgetSubLines = cmp.get('v.budgetSubLines');
			this.helpFormatData(budgetSubLines);

			let workbook = new ExcelJS.Workbook();

			/**
			 * APPS MAIN LIST SHEET
			 */

			let budgetSheet = workbook.addWorksheet('Budget Templates', {
				views: [
					{state: 'frozen', ySplit: 1, xSplit: 0}
				],
				properties: {showGridLines: true, tabColor: {argb: 'ffffb3'}}
			});
			let budgetLineSheet = workbook.addWorksheet('Budget Lines', {
				views: [
					{state: 'frozen', ySplit: 1, xSplit: 0}
				],
				properties: {showGridLines: true, tabColor: {argb: 'ffffb3'}}
			});
			let budgetSubLineSheet = workbook.addWorksheet('Budget SubLines', {
				views: [
					{state: 'frozen', ySplit: 1, xSplit: 0}
				],
				properties: {showGridLines: true, tabColor: {argb: 'ffffb3'}}
			});

			//--> HEADER

			let bColumns = [];
			bColumns.push({header: 'Budget Id',                 key: 'Id'                        , width: 25});
			bColumns.push({header: 'Budget Name',               key: 'Name'                      , width: 40});
			bColumns.push({header: 'CB Dimension Id',           key: 'cb4__Dimension__c'         , width: 25});
			bColumns.push({header: 'CB Dimension Name',         key: 'cb4__DimensionName__c'     , width: 20});
			bColumns.push({header: 'Status',                    key: 'cb4__Status__c'            , width: 20});
			bColumns.push({header: 'Last Approved/Rejected By', key: 'cb4__Text4__c'             , width: 20});
			bColumns.push({header: 'Next Approver',             key: 'HasAccessToChangeStatus__c', width: 25});
			bColumns.push({header: 'Next Status',               key: 'NextStatus__c'             , width: 20});
			bColumns.push({header: 'Description',               key: 'cb4__Text3__c'             , width: 40});
			bColumns.push({header: 'Budget is Locked',          key: 'cb4__Boolean1__c'          , width: 15});
			bColumns.push({header: 'Locked by',                 key: 'cb4__User__c'              , width: 25});
			bColumns.push({header: 'Is Personnel Budget',       key: 'cb4__Boolean2__c'          , width: 15});
			bColumns.push({header: 'Parent Budget Id',          key: 'cb4__Tag1__c'              , width: 25});
			bColumns.push({header: 'Parent Budget Name',        key: 'cb4__Tag1Name__c'          , width: 40});
			bColumns.push({header: 'Budget Template Id',        key: 'cb4__Tag2__c'              , width: 25});
			bColumns.push({header: 'Budget Template Name',      key: 'cb4__Tag2Name__c'          , width: 40});
			bColumns.push({header: 'Locked (Final Status)',     key: 'cb4__isLocked__c'          , width: 15});
			bColumns.push({header: 'Budget Year Id',            key: 'cb4__Tag3__c'              , width: 25});
			bColumns.push({header: 'Budget Year Name',          key: 'cb4__Tag3Name__c'          , width: 20});
			bColumns.push({header: 'Company Id',                key: 'cb4__Tag4__c'              , width: 25});
			bColumns.push({header: 'Company Name',              key: 'cb4__Tag4Name__c'          , width: 40});
			bColumns.push({header: 'CB_FF1 Id',                 key: 'cb4__Tag6__c'              , width: 25});
			bColumns.push({header: 'CB_FF1 Name',               key: 'cb4__Tag6Name__c'          , width: 40});
			bColumns.push({header: 'CB_FF2 Id',                 key: 'cb4__Tag7__c'              , width: 25});
			bColumns.push({header: 'CB_FF2 Name',               key: 'cb4__Tag7Name__c'          , width: 40});
			bColumns.push({header: 'Income Amount',             key: 'cb4__Decimal1__c'          , width: 15});
			bColumns.push({header: 'Expense Amount',            key: 'cb4__Decimal2__c'          , width: 15});
			bColumns.push({header: 'Total Amount',              key: 'cb4__Decimal3__c'          , width: 15});
			bColumns.push({header: 'Budget Locker Value',       key: 'cb4__Decimal6__c'          , width: 15});
			bColumns.push({header: 'Index',                     key: 'cb4__Index__c'             , width: 15});
			bColumns.push({header: 'Order Number',              key: 'cb4__OrderNumber__c'       , width: 15});
			bColumns.push({header: 'External Id',               key: 'cb4__ExtId__c'             , width: 25});
			bColumns.push({header: 'Owner Id',                  key: 'OwnerId'                   , width: 25});
			bColumns.push({header: 'Owner Name',                key: 'OwnerName'                 , width: 40});
			budgetSheet.columns = bColumns;
			budgetSheet.getColumn(budgetSheet.actualColumnCount).font = exStyle.totalFont; // total column style (.actualColumnCount is number of bColumns in the row)

			let blColumns = [];
			blColumns.push({header: 'BL Id',              key: 'Id'                    , width: 25});
			blColumns.push({header: 'CB Dimension Id',    key: 'cb4__Dimension__c'     , width: 25});
			blColumns.push({header: 'CB Dimension Name',  key: 'cb4__DimensionName__c' , width: 20});
			blColumns.push({header: 'Section',            key: 'cb4__Text1__c'         , width: 20});
			blColumns.push({header: 'Type',               key: 'cb4__Text2__c'         , width: 20});
			blColumns.push({header: 'Title',              key: 'cb4__Text3__c'         , width: 25});
			blColumns.push({header: 'Description',        key: 'cb4__Text4__c'         , width: 20});
			blColumns.push({header: 'Style Class',        key: 'cb4__Text5__c'         , width: 40});
			blColumns.push({header: 'Comment',            key: 'cb4__Text6__c'         , width: 40});
			blColumns.push({header: 'Budget Id',          key: 'cb4__Tag1__c'          , width: 15});
			blColumns.push({header: 'Budget Name',        key: 'cb4__Tag1Name__c'      , width: 25});
			blColumns.push({header: 'Account Id',         key: 'cb4__Tag2__c'          , width: 15});
			blColumns.push({header: 'Account Name',       key: 'cb4__Tag2Name__c'      , width: 25});
			blColumns.push({header: 'Period Id',          key: 'cb4__Tag3__c'          , width: 40});
			blColumns.push({header: 'Period Name',        key: 'cb4__Tag3Name__c'      , width: 25});
			blColumns.push({header: 'SubAccount Code Id', key: 'cb4__Tag5__c'          , width: 40});
			blColumns.push({header: 'SubAccount Code',    key: 'cb4__Tag5Name__c'      , width: 15});
			blColumns.push({header: 'CB_FF1 Id',          key: 'cb4__Tag6__c'          , width: 25});
			blColumns.push({header: 'CB_FF1 Name',        key: 'cb4__Tag6Name__c'      , width: 20});
			blColumns.push({header: 'CB_FF2 Id',          key: 'cb4__Tag7__c'          , width: 25});
			blColumns.push({header: 'CB_FF2 Name',        key: 'cb4__Tag7Name__c'      , width: 40});
			blColumns.push({header: 'CB_FF3 Id',          key: 'cb4__Tag8__c'          , width: 25});
			blColumns.push({header: 'CB_FF3 Name',        key: 'cb4__Tag8Name__c'      , width: 40});
			blColumns.push({header: 'CB_FF4 Id',          key: 'cb4__Tag9__c'          , width: 25});
			blColumns.push({header: 'CB_FF4 Name',        key: 'cb4__Tag9Name__c'      , width: 40});
			blColumns.push({header: 'Flag',               key: 'cb4__Boolean1__c'      , width: 15});
			blColumns.push({header: 'Value',              key: 'cb4__Decimal1__c'      , width: 15});
			blColumns.push({header: 'PBB Id',             key: 'cb4__ExtId__c'         , width: 15});
			blColumns.push({header: 'Owner Id',           key: 'OwnerId'               , width: 15});
			blColumns.push({header: 'Owner Name',         key: 'OwnerName'             , width: 15});
			budgetLineSheet.columns = blColumns;
			budgetLineSheet.getColumn(budgetLineSheet.actualColumnCount).font = exStyle.totalFont; // total column style (.actualColumnCount is number of bColumns in the row)

			let bslColumns = [];
			bslColumns.push({header: 'BL Id',              key: 'Id'                    , width: 25});
			bslColumns.push({header: 'CB Dimension Id',    key: 'cb4__Dimension__c'     , width: 25});
			bslColumns.push({header: 'CB Dimension Name',  key: 'cb4__DimensionName__c' , width: 20});
			bslColumns.push({header: 'Section',            key: 'cb4__Text1__c'         , width: 20});
			bslColumns.push({header: 'Type',               key: 'cb4__Text2__c'         , width: 20});
			bslColumns.push({header: 'Title',              key: 'cb4__Text3__c'         , width: 25});
			bslColumns.push({header: 'Description',        key: 'cb4__Text4__c'         , width: 20});
			bslColumns.push({header: 'Style Class',        key: 'cb4__Text5__c'         , width: 40});
			bslColumns.push({header: 'Key',                key: 'cb4__Text10__c'        , width: 40});
			bslColumns.push({header: 'Budget Id',          key: 'cb4__Tag1__c'          , width: 15});
			bslColumns.push({header: 'Budget Name',        key: 'cb4__Tag1Name__c'      , width: 25});
			bslColumns.push({header: 'Account Id',         key: 'cb4__Tag2__c'          , width: 15});
			bslColumns.push({header: 'Account Name',       key: 'cb4__Tag2Name__c'      , width: 25});
			bslColumns.push({header: 'Period Id',          key: 'cb4__Tag3__c'          , width: 40});
			bslColumns.push({header: 'Period Name',        key: 'cb4__Tag3Name__c'      , width: 25});
			bslColumns.push({header: 'SubAccount Code Id', key: 'cb4__Tag5__c'          , width: 40});
			bslColumns.push({header: 'SubAccount Code',    key: 'cb4__Tag5Name__c'      , width: 15});
			bslColumns.push({header: 'CB_FF1 Id',          key: 'cb4__Tag6__c'          , width: 25});
			bslColumns.push({header: 'CB_FF1 Name',        key: 'cb4__Tag6Name__c'      , width: 20});
			bslColumns.push({header: 'CB_FF2 Id',          key: 'cb4__Tag7__c'          , width: 25});
			bslColumns.push({header: 'CB_FF2 Name',        key: 'cb4__Tag7Name__c'      , width: 40});
			bslColumns.push({header: 'CB_FF3 Id',          key: 'cb4__Tag8__c'          , width: 25});
			bslColumns.push({header: 'CB_FF3 Name',        key: 'cb4__Tag8Name__c'      , width: 40});
			bslColumns.push({header: 'CB_FF4 Id',          key: 'cb4__Tag9__c'          , width: 25});
			bslColumns.push({header: 'CB_FF4 Name',        key: 'cb4__Tag9Name__c'      , width: 40});
			bslColumns.push({header: 'Flag',               key: 'cb4__Boolean1__c'      , width: 15});
			bslColumns.push({header: 'Value',              key: 'cb4__Decimal1__c'      , width: 15});
			bslColumns.push({header: 'PBB Id',             key: 'cb4__ExtId__c'         , width: 15});
			bslColumns.push({header: 'Owner Id',           key: 'OwnerId'               , width: 15});
			bslColumns.push({header: 'Owner Name',         key: 'OwnerName'             , width: 15});
			budgetSubLineSheet.columns = bslColumns;
			budgetSubLineSheet.getColumn(budgetSubLineSheet.actualColumnCount).font = exStyle.totalFont; // total column style (.actualColumnCount is number of bColumns in the row)

			//--> HEADER STYLE
			budgetSheet.getRow(1).height = exStyle.headerHeight;
			budgetSheet.getRow(1).eachCell({includeEmpty: false}, function (cell) { // header
				cell.font = exStyle.headerFont;
				cell.alignment = exStyle.headerAlignment;
				cell.fill = exStyle.headerFill;
				cell.border = exStyle.simpleGreyBorders;
			});
			budgetLineSheet.getRow(1).height = exStyle.headerHeight;
			budgetLineSheet.getRow(1).eachCell({includeEmpty: false}, function (cell) { // header
				cell.font = exStyle.headerFont;
				cell.alignment = exStyle.headerAlignment;
				cell.fill = exStyle.headerFill;
				cell.border = exStyle.simpleGreyBorders;
			});
			budgetSubLineSheet.getRow(1).height = exStyle.headerHeight;
			budgetSubLineSheet.getRow(1).eachCell({includeEmpty: false}, function (cell) { // header
				cell.font = exStyle.headerFont;
				cell.alignment = exStyle.headerAlignment;
				cell.fill = exStyle.headerFill;
				cell.border = exStyle.simpleGreyBorders;
			});

			//--> Columns DATA
			budgetSheet.addRows(budgets);
			budgetLineSheet.addRows(budgetLines);
			budgetSubLineSheet.addRows(budgetSubLines);

			workbook.xlsx.writeBuffer().then(buffer => saveAs(new Blob([buffer]), 'Budget Data Backup ' + budgets[0].cb4__Tag3Name__c + ' ' + new Date().today() + ' ' + new Date().timeNow() + '.xlsx')).catch(err => alert('Error writing excel export: ' + err));
		} catch
			(e) {
			alert(e)
		}
	},

	getExcelStyle: function () {
		return {
			headerFill : {type: 'pattern', pattern: 'solid', fgColor: {argb: '142952'}},
			headerFont : {bold: true, color: {argb: 'FFFFFF'}},
			headerHeight : 18,
			headerAlignment : {vertical: 'middle', horizontal: 'center'},
			simpleGreyBorders : {top: {style: 'thin', color: {argb: 'bfbfbf'}}, left: {style: 'thin', color: {argb: 'bfbfbf'}}, bottom: {style: 'thin', color: {argb: 'bfbfbf'}}, right: {style: 'thin', color: {argb: 'bfbfbf'}}},
			numFormat : '$ #,##0.00;[Red]($ #,##0.00)'
		}
	},

	helpFormatData: function (arr){
		for(let i = 0; i < arr.length; i++){
			arr[i].OwnerName = arr[i].Owner.Name;
		}
	},

	helpApplyExcelFile: function (cmp, workbook){
		let mObj = cmp.get('v.mObject');
		mObj = mObj === null ? {} : mObj;
		mObj.periods = [];
		let bIds = cmp.get('v.bIds');
		let budgets        = cmp.get('v.loadedBudgets');
		let budgetLines    = cmp.get('v.loadedBudgetLines');
		let budgetSubLines = cmp.get('v.loadedBudgetSubLines');
		let byName = null;
		let excelPeriodsSO = [];

		let bSheet   = workbook.getWorksheet(1);
		let blSheet  = workbook.getWorksheet(2);
		let bslSheet = workbook.getWorksheet(3);

		let curColumn= 1;
		bSheet.getColumn(curColumn++).key = 'Id'                        ;
		bSheet.getColumn(curColumn++).key = 'Name'                      ;
		bSheet.getColumn(curColumn++).key = 'cb4__Dimension__c'         ;
		bSheet.getColumn(curColumn++).key = 'cb4__DimensionName__c'     ;
		bSheet.getColumn(curColumn++).key = 'cb4__Status__c'            ;
		bSheet.getColumn(curColumn++).key = 'cb4__Text4__c'             ;
		bSheet.getColumn(curColumn++).key = 'HasAccessToChangeStatus__c';
		bSheet.getColumn(curColumn++).key = 'NextStatus__c'             ;
		bSheet.getColumn(curColumn++).key = 'cb4__Text3__c'             ;
		bSheet.getColumn(curColumn++).key = 'cb4__Boolean1__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__User__c'              ;
		bSheet.getColumn(curColumn++).key = 'cb4__Boolean2__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag1__c'              ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag1Name__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag2__c'              ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag2Name__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__isLocked__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag3__c'              ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag3Name__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag4__c'              ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag4Name__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag6__c'              ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag6Name__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag7__c'              ;
		bSheet.getColumn(curColumn++).key = 'cb4__Tag7Name__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Decimal1__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Decimal2__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Decimal3__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Decimal6__c'          ;
		bSheet.getColumn(curColumn++).key = 'cb4__Index__c'             ;
		bSheet.getColumn(curColumn++).key = 'cb4__OrderNumber__c'       ;
		bSheet.getColumn(curColumn++).key = 'cb4__ExtId__c'             ;
		bSheet.getColumn(curColumn++).key = 'OwnerId'                   ;
		bSheet.getColumn(curColumn++).key = 'OwnerName'                 ;

		curColumn = 1;
		blSheet.getColumn(curColumn++).key = 'Id'                   ;
		blSheet.getColumn(curColumn++).key = 'cb4__Dimension__c'    ;
		blSheet.getColumn(curColumn++).key = 'cb4__DimensionName__c';
		blSheet.getColumn(curColumn++).key = 'cb4__Text1__c'        ;
		blSheet.getColumn(curColumn++).key = 'cb4__Text2__c'        ;
		blSheet.getColumn(curColumn++).key = 'cb4__Text3__c'        ;
		blSheet.getColumn(curColumn++).key = 'cb4__Text4__c'        ;
		blSheet.getColumn(curColumn++).key = 'cb4__Text5__c'        ;
		blSheet.getColumn(curColumn++).key = 'cb4__Text6__c'        ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag1__c'         ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag1Name__c'     ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag2__c'         ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag2Name__c'     ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag3__c'         ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag3Name__c'     ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag5__c'         ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag5Name__c'     ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag6__c'         ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag6Name__c'     ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag7__c'         ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag7Name__c'     ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag8__c'         ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag8Name__c'     ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag9__c'         ;
		blSheet.getColumn(curColumn++).key = 'cb4__Tag9Name__c'     ;
		blSheet.getColumn(curColumn++).key = 'cb4__Boolean1__c'     ;
		blSheet.getColumn(curColumn++).key = 'cb4__Decimal1__c'     ;
		blSheet.getColumn(curColumn++).key = 'cb4__ExtId__c'        ;
		blSheet.getColumn(curColumn++).key = 'OwnerId'              ;
		blSheet.getColumn(curColumn++).key = 'OwnerName'            ;

		curColumn = 1;
		bslSheet.getColumn(curColumn++).key = 'Id'                   ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Dimension__c'    ;
		bslSheet.getColumn(curColumn++).key = 'cb4__DimensionName__c';
		bslSheet.getColumn(curColumn++).key = 'cb4__Text1__c'        ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Text2__c'        ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Text3__c'        ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Text4__c'        ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Text5__c'        ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Text10__c'       ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag1__c'         ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag1Name__c'     ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag2__c'         ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag2Name__c'     ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag3__c'         ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag3Name__c'     ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag5__c'         ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag5Name__c'     ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag6__c'         ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag6Name__c'     ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag7__c'         ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag7Name__c'     ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag8__c'         ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag8Name__c'     ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag9__c'         ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Tag9Name__c'     ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Boolean1__c'     ;
		bslSheet.getColumn(curColumn++).key = 'cb4__Decimal1__c'     ;
		bslSheet.getColumn(curColumn++).key = 'cb4__ExtId__c'        ;
		bslSheet.getColumn(curColumn++).key = 'OwnerId'              ;
		bslSheet.getColumn(curColumn++).key = 'OwnerName'            ;

		bSheet.eachRow(function (bRow, rowNumber){
			if(rowNumber > 1){
				bIds.push(bRow.getCell('Id').value);
				byName = byName === null ? bRow.getCell('cb4__Tag3Name__c').value : byName;

				let newBudget = {};
				newBudget.Name                       = bRow.getCell('Name'                      ).value;
				newBudget.cb4__Dimension__c          = bRow.getCell('cb4__Dimension__c'         ).value;
				newBudget.cb4__Status__c             = bRow.getCell('cb4__Status__c'            ).value;
				newBudget.cb4__Text4__c              = bRow.getCell('cb4__Text4__c'             ).value;
				newBudget.HasAccessToChangeStatus__c = bRow.getCell('HasAccessToChangeStatus__c').value;
				newBudget.NextStatus__c              = bRow.getCell('NextStatus__c'             ).value;
				newBudget.cb4__Text3__c              = bRow.getCell('cb4__Text3__c'             ).value;
				newBudget.cb4__Boolean1__c           = bRow.getCell('cb4__Boolean1__c'          ).value;
				newBudget.cb4__User__c               = bRow.getCell('cb4__User__c'              ).value;
				newBudget.cb4__Boolean2__c           = bRow.getCell('cb4__Boolean2__c'          ).value;
				newBudget.cb4__Tag1__c               = bRow.getCell('cb4__Tag1__c'              ).value;
				newBudget.cb4__Tag2__c               = bRow.getCell('cb4__Tag2__c'              ).value;
				newBudget.cb4__isLocked__c           = bRow.getCell('cb4__isLocked__c'          ).value;
				newBudget.cb4__Tag3__c               = bRow.getCell('cb4__Tag3__c'              ).value;
				newBudget.cb4__Tag4__c               = bRow.getCell('cb4__Tag4__c'              ).value;
				newBudget.cb4__Tag6__c               = bRow.getCell('cb4__Tag6__c'              ).value;
				newBudget.cb4__Tag7__c               = bRow.getCell('cb4__Tag7__c'              ).value;
				newBudget.cb4__Decimal1__c           = bRow.getCell('cb4__Decimal1__c'          ).value;
				newBudget.cb4__Decimal2__c           = bRow.getCell('cb4__Decimal2__c'          ).value;
				newBudget.cb4__Decimal3__c           = bRow.getCell('cb4__Decimal3__c'          ).value;
				newBudget.cb4__Decimal6__c           = bRow.getCell('cb4__Decimal6__c'          ).value;
				newBudget.cb4__Index__c              = bRow.getCell('cb4__Index__c'             ).value;
				newBudget.cb4__OrderNumber__c        = bRow.getCell('cb4__OrderNumber__c'       ).value;
				newBudget.cb4__ExtId__c              = bRow.getCell('cb4__ExtId__c'             ).value;
				newBudget.OwnerId                    = bRow.getCell('OwnerId'                   ).value;

				budgets.push(newBudget);
			}
		});
		let perSet = new Set();
		blSheet.eachRow(function (blRow, rowNumber){
			if(rowNumber > 1 && blRow.getCell('cb4__Text1__c').value !== 'total'){
				if(!perSet.has(blRow.getCell('cb4__Tag3__c').value)){
					excelPeriodsSO.push({
						value : blRow.getCell('cb4__Tag3__c').value,
						title : blRow.getCell('cb4__Tag3Name__c').value
					});
				}
				perSet.add(blRow.getCell('cb4__Tag3__c').value);
				let newBudgetLine = {};
				newBudgetLine.cb4__Dimension__c = blRow.getCell('cb4__Dimension__c').value;
				newBudgetLine.cb4__Text1__c     = blRow.getCell('cb4__Text1__c'    ).value;
				newBudgetLine.cb4__Text2__c     = blRow.getCell('cb4__Text2__c'    ).value;
				newBudgetLine.cb4__Text3__c     = blRow.getCell('cb4__Text3__c'    ).value;
				newBudgetLine.cb4__Text4__c     = blRow.getCell('cb4__Text4__c'    ).value;
				newBudgetLine.cb4__Text5__c     = blRow.getCell('cb4__Text5__c'    ).value;
				newBudgetLine.cb4__Text6__c     = blRow.getCell('cb4__Text6__c'    ).value;
				newBudgetLine.cb4__Tag1__c      = blRow.getCell('cb4__Tag1__c'     ).value;
				newBudgetLine.cb4__Tag2__c      = blRow.getCell('cb4__Tag2__c'     ).value;
				newBudgetLine.cb4__Tag3__c      = blRow.getCell('cb4__Tag3__c'     ).value;
				newBudgetLine.cb4__Tag5__c      = blRow.getCell('cb4__Tag5__c'     ).value;
				newBudgetLine.cb4__Tag6__c      = blRow.getCell('cb4__Tag6__c'     ).value;
				newBudgetLine.cb4__Tag7__c      = blRow.getCell('cb4__Tag7__c'     ).value;
				newBudgetLine.cb4__Tag8__c      = blRow.getCell('cb4__Tag8__c'     ).value;
				newBudgetLine.cb4__Tag9__c      = blRow.getCell('cb4__Tag9__c'     ).value;
				newBudgetLine.cb4__Boolean1__c  = blRow.getCell('cb4__Boolean1__c' ).value;
				newBudgetLine.cb4__Decimal1__c  = blRow.getCell('cb4__Decimal1__c' ).value;
				newBudgetLine.cb4__ExtId__c     = blRow.getCell('cb4__ExtId__c'    ).value;
				newBudgetLine.OwnerId           = blRow.getCell('OwnerId'          ).value;

				budgetLines.push(newBudgetLine);
			}
		});
		bslSheet.eachRow(function (bslRow, rowNumber){
			if(rowNumber > 1){
				let newBudgetSubLine = {};
				newBudgetSubLine.cb4__Dimension__c = bslRow.getCell('cb4__Dimension__c').value;
				newBudgetSubLine.cb4__Text1__c     = bslRow.getCell('cb4__Text1__c'    ).value;
				newBudgetSubLine.cb4__Text2__c     = bslRow.getCell('cb4__Text2__c'    ).value;
				newBudgetSubLine.cb4__Text3__c     = bslRow.getCell('cb4__Text3__c'    ).value;
				newBudgetSubLine.cb4__Text4__c     = bslRow.getCell('cb4__Text4__c'    ).value;
				newBudgetSubLine.cb4__Text5__c     = bslRow.getCell('cb4__Text5__c'    ).value;
				newBudgetSubLine.cb4__Text10__c    = bslRow.getCell('cb4__Text10__c'   ).value;
				newBudgetSubLine.cb4__Tag1__c      = bslRow.getCell('cb4__Tag1__c'     ).value;
				newBudgetSubLine.cb4__Tag2__c      = bslRow.getCell('cb4__Tag2__c'     ).value;
				newBudgetSubLine.cb4__Tag3__c      = bslRow.getCell('cb4__Tag3__c'     ).value;
				newBudgetSubLine.cb4__Tag5__c      = bslRow.getCell('cb4__Tag5__c'     ).value;
				newBudgetSubLine.cb4__Tag6__c      = bslRow.getCell('cb4__Tag6__c'     ).value;
				newBudgetSubLine.cb4__Tag7__c      = bslRow.getCell('cb4__Tag7__c'     ).value;
				newBudgetSubLine.cb4__Tag8__c      = bslRow.getCell('cb4__Tag8__c'     ).value;
				newBudgetSubLine.cb4__Tag9__c      = bslRow.getCell('cb4__Tag9__c'     ).value;
				newBudgetSubLine.cb4__Boolean1__c  = bslRow.getCell('cb4__Boolean1__c' ).value;
				newBudgetSubLine.cb4__Decimal1__c  = bslRow.getCell('cb4__Decimal1__c' ).value;
				newBudgetSubLine.cb4__ExtId__c     = bslRow.getCell('cb4__ExtId__c'    ).value;
				newBudgetSubLine.OwnerId           = bslRow.getCell('OwnerId'          ).value;

				budgetSubLines.push(newBudgetSubLine);
			}
		});

		cmp.set('v.loadedBudgets', budgets);
		cmp.set('v.loadedBudgetLines', budgetLines);
		cmp.set('v.loadedBudgetSubLines', budgetSubLines);
		cmp.set('v.bIds', bIds);
		cmp.set('v.selectedExcelBudgetYear', budgets[0].cb4__Tag3__c);
		cmp.set('v.excelBudgetYearName',byName );
		cmp.set('v.excelPeriodSO', excelPeriodsSO);

		_CBMessages.fireSuccessMessage('Excel Data has been successfully uploaded.');
		cmp.set('v.showSpinner', false);
	},

	helpRunFullRestoreProcess: function (cmp){
		cmp.set('v.showSpinner', true);
		let loadedBudgets = cmp.get('v.loadedBudgets');
		let budgetYearFromExcel = cmp.get('v.selectedExcelBudgetYear');
		let budgetYearFromUser  = cmp.get('v.selectedUsersBudgetYear');
		if(budgetYearFromExcel !== budgetYearFromUser){
			for(let i = 0; i < loadedBudgets.length; i++){
				loadedBudgets[i].cb4__Tag1__c = null;
				loadedBudgets[i].cb4__Tag3__c = budgetYearFromUser;
			}
		}else{
			for(let i = 0; i < loadedBudgets.length; i++){
				loadedBudgets[i].cb4__Tag1__c = null;
			}
		}
		cmp.set('v.loadedBudgets', loadedBudgets);
		cmp.set('v.showSpinner', false);
	},

	helpDeleteBudgets: function (cmp){
		cmp.set('v.showSpinner', true);
		let _this = this;
		let usersBYId = cmp.get('v.selectedUsersBudgetYear');
		_CBRequest(
			cmp,
			'c.deleteBudgetDataServer',
			{
				'byId'   : usersBYId
			},
			null,
			callback,
			'Budget Data deleted',
			'Failed to delete Budget Data',
			false
		);
		function callback(cmp, res){
			if(res.getState() === 'SUCCESS'){
				cmp.set('v.showSpinner', false);
				//_this.helpStartDataGettingProcess(cmp);
			}
		}
	},

	helpCreateTags: function (cmp, tags , attr, dataName, nextStep, nextActionName){
		cmp.set('v.showSpinner', true);
		let uploadCounter = cmp.get('v.up'+attr);
		let newTags = [];
		for(let i = uploadCounter; i < tags.length; i++) {
			newTags.push(tags[i]);
			if(i === uploadCounter + 3000 || i === tags.length - 1){
				uploadCounter = i + 1;
				break;
			}
		}

		_CBRequest(
			cmp,
			'c.createCBTagServer',
			{
				'tags' : newTags
			},
			null,
			callback,
			uploadCounter + ' of ' + tags.length + ' ' + dataName + ' created',
			'Failed to create ' + dataName + ' Data',
			false
		);

		function callback(cmp, res){
			if(res.getState() === 'SUCCESS'){
				cmp.set('v.up' + attr, uploadCounter);
				if(uploadCounter === tags.length){
					cmp.set('v.step', nextStep);
					if(nextActionName !== null) $A.enqueueAction(cmp.get('c.' + nextActionName));
				}else{
					$A.enqueueAction(cmp.get('c.' + attr.replace('loaded', 'create')));
				}
			}
			cmp.set('v.showSpinner', false);
		}
	}
});