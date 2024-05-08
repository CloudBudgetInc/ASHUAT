import {
	CURRENCY_FMT,
	HEADER_FILL,
	HEADER_FONT,
	PERCENT_FMT,
	PROGRAM_SUB_LINE_FILL,
	PROGRAM_SUB_LINE_FONT,
	RC_FILL,
	SIMPLE_BORDERS,
	TOTAL_NET_LINE_FILL
} from "./cbReportingExcelStyles"
import {_getCopy, _message, _parseServerError, _prompt, _setCell} from 'c/cbUtils';
import {calculateDifference, subtractReportLines, sumReportLines} from "./cbReportingExcelUtils";
import getReportDataServer from "@salesforce/apex/CBExcelReport.getReportDataServer";


let _this;
const setTreasuryContext = (context) => _this = context;
let separatedReportingBalances = {};// reporting balances separated by Dimension 2, key is Dim2 Name
const FIRST_SHEET_NAME = 'Summary';
let FILE_NAME = "Exec. Committee Report";
const SEPARATE_RC_DIM2 = ['Data Hub', 'Clinical Trials']; // dim2 that may go to the second level of grouping
const SEPARATE_RC_ACC_SUBACC = ['325-392', '320-395']; // account-subaccount (project) that may go to the second level of grouping
const SPACE = '     ';

/**
 * REQUIREMENT
>>>Change Clinical News Magazine to ASH Clinical News
>>>Change LLC to ASH Headquarters
>>>Change Publications to Blood Journal
>>>Change Wallace Coulter to Wallace Coulter Grant
>>>Change ASH Found Department to ASH Foundation Department Expenses
>>>Change ASH Foundation to ASH Foundation Distributions
>>>Change Award & Diversity to Awards & Diversity Department
>>>Change MRHP Award to Minority Resident Hematology Award
>>>Change Default under Awards to Miscellaneous Awards
>>>Change Committee to Committees
 */
const TITLE_MAPPING = {
	'Clinical News Magazine': 'ASH Clinical News',
	'LLC': 'ASH Headquarters',
	'Publications': 'Blood Journal',
	'Wallace Coulter': 'Blood Journal',
	'ASH Found Department': 'ASH Foundation Department Expenses',
	'ASH Foundation': 'ASH Foundation Distributions',
	'Award & Diversity': 'Awards & Diversity Department',
	'MRHP Award': 'Minority Resident Hematology Award',
	'Default': 'Miscellaneous Awards',
	'Committee': 'Committees',
};

const SHEET_MAPPING = {
	'Annual Meeting (353)': 'Annual Meeting',
	'Publications (366)': 'Blood',
	'Blood Advances (384)': 'Pubs',
	'Blood Neoplasia (385)': 'Pubs',
	'Blood VTH (387)': 'Pubs',
	'Clinical News Magazine (376)': 'Pubs',
	'How I Treat (149)': 'Pubs',
	'Self Assessment Program (354)': 'Pubs',
	'LLC (363)': 'HDQ',

	'Highlights of ASH (355)': 'Small Meetings',
	'Meeting on Genomic Editing (382)': 'Small Meetings',
	'Meeting on Hematologic Malignancies (378)': 'Small Meetings',
	'Meeting on Lymphoma Biology (234)': 'Small Meetings',
	'ASH Summit on Emerging Immunotherapies (399)': 'Small Meetings',

	'Awards (352)': 'Awards',
	'ASHRC Data Hub (395)': 'Data Hub',
	'ASHRC SCD Clinical Trials Network (392)': 'Clinical Trials',
};

/**
 * Common by Default if key is null
 */
const SHEET_TYPE = {
	'Summary': 'summary',
	'Small Meetings': 'pairs',
	'Pubs': 'pairs'
};

const manageDataAndGenerateTreasuryFile = async () => {
	try {
		const anotherCompanyName = _this.companySO.find(comSO => comSO.value !== _this.selectedCompany).label;
		if (anotherCompanyName === 'ASH Research Collaborative') {
			const anotherCompanyId = _this.companySO.find(comSO => comSO.value !== _this.selectedCompany).value;
			await getRCCompanyData(anotherCompanyId, _this.selectedBY);
		}
		createDataSetsSeparatedBySheets(); // separating reporting balances by sheets
		convertReportingBalancesToReportLines();
		generateExcelFile();
	} catch (e) {
		_message('error', 'Manage Data of Treasury Report Error ' + e);
	}
};

const getRCCompanyData = async (anotherCompanyId, selectedBY) => {
	let anotherCompanyReportLines = [];
	await getReportDataServer({selectedBY: parseInt(selectedBY), selectedCompany: anotherCompanyId})
		.then(RBs => {
			RBs.forEach(rb => rb.company = 'RC');
			_this.reportingBalancesRaw = [..._this.reportingBalancesRaw, ...RBs];
		})
		.catch(e => _parseServerError('Get Extra Data Error ', e));
	return anotherCompanyReportLines;
};

/**
 * Method separates reporting balances by Dimension 2 Name and put extra lines to default list
 */
const createDataSetsSeparatedBySheets = () => {
	try {
		const firstSheetName = FIRST_SHEET_NAME;
		const logArray = []; // log on the page
		const listOfTitleKeys = Object.keys(TITLE_MAPPING);
		_this.reportingBalancesRaw.forEach(row => { // raw FF reporting balances
			if (row.c2g__Type__c === 'Actual') logArray.push({ // log calculations
				d2: row.c2g__Dimension2__r?.Name,
				d3: row.c2g__Dimension3__r?.Name
			});
			if (row.c2g__Dimension2__r?.Name) { // rename some titles and delete numbers
				if (row.c2g__Dimension2__r.Name.includes('355')) {
					if (row.c2g__Dimension3__r.Name.includes('210')) {
						row.c2g__Dimension2__r.Name = 'HOA North America';
						row.c2g__Dimension2__c = 'HOANorthAmerica';
					} else {
						row.c2g__Dimension2__r.Name = 'HOA International';
						row.c2g__Dimension2__c = 'HOAInternational';
					}
				}
				const mapKey = listOfTitleKeys.find(key => row.c2g__Dimension2__r.Name.includes(key));
				if (mapKey) row.c2g__Dimension2__r.Name = TITLE_MAPPING[mapKey]; // requirement to replace the titles from 3/15/2024
				if (row.c2g__Dimension2__r.Name.includes('410')) row.c2g__Dimension2__r.Name = 'Business Development (415)'; // 29 04 2024 merge everything under program Resource Development (410) into Business Development (415)
				if (row.Income_Statement_Group__c === 'Income') { // 29 04 2024 Please split all revenue in Program 362 as follows, as per the following GL codes:
					if (row.c2g__GeneralLedgerAccount__r.Name.includes('3530')) row.c2g__Dimension2__r.Name = 'Interest on Operations';
					if (row.c2g__GeneralLedgerAccount__r.Name.includes('3020') || row.c2g__GeneralLedgerAccount__r.Name.includes('3030')) row.c2g__Dimension2__r.Name = 'Membership Dues';
				}
				if (row.c2g__Dimension3__r?.Name && row.c2g__Dimension3__r.Name.includes('Default')) row.c2g__Dimension3__r.Name = 'Miscellaneous Awards';
			}
		});
		// result is object where key is future sheet name, and value is list of reporting balances
		separatedReportingBalances = _this.reportingBalancesRaw.reduce((result, rb) => {
			try {
				let mainSheetList = result[firstSheetName]; // FF RB to the first summary sheet
				if (!mainSheetList) {
					mainSheetList = [];
					result[firstSheetName] = mainSheetList;
				}
				mainSheetList.push(rb);
				return result;
			} catch (e) {
				_message('error', 'Separate Treasury Data by Sheets Iterating Error: ' + e);
			}
		}, {});
	} catch (e) {
		_message('error', 'Separate Treasury Data by Sheets Error: ' + e);
	}
};

const convertReportingBalancesToReportLines = () => {
	Object.keys(separatedReportingBalances).forEach(sheetName => { // so far only on sheet Summary
		try {
			let reportingBalances = separatedReportingBalances[sheetName]; // list of FF RB
			let reportLines = getReportLinesFromReportingBalances(reportingBalances); // convert FF RB to Report lines
			reportLines = addSummarySubTotalLines(reportLines);
			separatedReportingBalances[sheetName] = reportLines;
		} catch (e) {
			_message('error', 'Convert RB to RL Iteration Error ' + e);
		}
	});
};

const getReportLinesFromReportingBalances = (RBList) => {
	const reportLinesMap = {}; // key is dim2 Id and account Id
	RBList.forEach(rb => { // single FF RB
		try {
			if (!rb.c2g__Dimension2__c) return null; // invalid data
			if ((rb.c2g__Type__c === 'Actual' && rb.Year__c === _this.selectedBY) || rb.c2g__Type__c === 'Projection') return null; // used only for YTD & Projection report
			let lineKey;
			if (rb.company && SEPARATE_RC_ACC_SUBACC.some(substr => rb.Account_Subaccount__c.includes(substr))) {
				rb.c2g__Dimension2__c += ' '; // to separate data in future RC table
				rb.c2g__Dimension2__r.Name += ' ';
				console.log('RB ' + rb.company);
			}
			lineKey = rb.c2g__OwnerCompany__c + rb.c2g__Dimension2__c + rb.c2g__Dimension3__c + rb.Income_Statement_Group__c;
			let reportLine = reportLinesMap[lineKey];
			if (!reportLine) {
				reportLine = getNewReportLine(rb, lineKey);
				reportLinesMap[lineKey] = reportLine;
			}
			if (rb.c2g__Type__c === 'Actual') {
				let invertedIncomeActual = rb.c2g__HomeValue__c;
				if (rb.Income_Statement_Group__c === 'Income') {
					invertedIncomeActual *= -1;
				}
				reportLine.actual += parseFloat(invertedIncomeActual);
			} else {
				if (rb.Year__c === _this.selectedBY) {
					reportLine.approvedBudget += parseFloat(rb.c2g__HomeValue__c);
				} else {
					reportLine.processedBudget += parseFloat(rb.c2g__HomeValue__c);
				}
			}
		} catch (e) {
			_message('error', 'Get Treasury RL from RB Error : ' + e);
		}
	});
	return Object.values(reportLinesMap);
};

/**
 * @param rb source reporting balance
 * @param lineKey key of reporting line
 * @return {lineKey: *, actual: number, lightGreyBoldFont: (string|string), accountSubAccount: *, processedBudget: number, processedVsApprovedPercent: number, generalLedgerName: (string|string), lightGrey: *, processedVsApproved: number, approvedBudget: number, label: string} line for the excel table
 */
const getNewReportLine = (rb, lineKey) => {
	return {
		id: rb.Id,
		lineKey,
		lineType: rb.Income_Statement_Group__c,
		accountSubAccount: rb.Account_Subaccount__c,
		dim2Name: rb.c2g__Dimension2__r?.Name,
		dim3Name: rb.c2g__Dimension3__r?.Name,
		accName: rb.c2g__GeneralLedgerAccount__r?.Name,
		company: rb.company,
		label: '',
		actual: 0,
		approvedBudget: 0, // selected BY
		processedBudget: 0, // next BY
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
	};
};

const addSummarySubTotalLines = (reportLines) => {
	const compareFn = (a, b) => { // sorting report lines by type, then by dim2 and by dim3
		try {
			const first = a.lineType + a?.dim2Name + b?.dim3Name;
			const second = b.lineType + b?.dim2Name + b?.dim3Name;
			return first < second ? -1 : (first > second ? 1 : 0);
		} catch (e) {
			_message('error', 'Comparision Error : ' + e)
		}
	};
	reportLines.forEach(rl => rl.lineType = rl.lineType === 'Income' ? 'Income' : 'Expense');
	reportLines.sort(compareFn); // sort report lines in the current sheet
	const reportLinesGroup = {};
	const awardReportLines = {};
	const RCReportLines = {};
	reportLines.forEach(rl => { // iteration over report lines
		try {
			let key1 = rl.dim2Name + rl.lineType;
			const lineIsAward = rl.dim2Name === 'Awards (352)'; // special group of report lines with sublines
			const lineIsRC = !!rl.company;
			if (lineIsRC) {
				processRCLines(RCReportLines, rl);
				return
			}
			if (lineIsAward) {
				processAwardLines(awardReportLines, rl);
				return
			}
			rl.label = rl.dim2Name;
			let existedRL = reportLinesGroup[key1];
			if (existedRL) sumReportLines(rl, existedRL, false, 'SUM SIMILAR');
			reportLinesGroup[key1] = rl;
		} catch (e) {
			_message('error', 'Add Summary Sub Total Lines Error : ' + e);
		}
	});
	const incomeReportLines = placeSortedSimpleLinesAwardsAndRC(reportLinesGroup, awardReportLines, RCReportLines, 'Income');
	const expenseReportLines = placeSortedSimpleLinesAwardsAndRC(reportLinesGroup, awardReportLines, RCReportLines, 'Expense');

	reportLines = [...incomeReportLines, ...expenseReportLines];

	reportLines.forEach(rl => {
		if (!rl.dim2Name) {
			_message('error', 'NO dim2Name in ' + JSON.stringify(rl));
			console.error('RL ERROR ......: ' + JSON.stringify(rl));
		} else {
			//console.log('RL ......' + JSON.stringify(rl));
		}
	});


	const incomeLines = reportLines.filter(rl => rl.lineType === 'Income');

	const expenseLines = reportLines.filter(rl => {
		if (rl.lineType === 'Expense' && !rl.dim2Name.includes('Focus Fellowship Training Program')) return true;
	});

	const FFTPLines = reportLines.filter(rl => rl.dim2Name.includes('Focus Fellowship Training Program'));
	const FFTPL = FFTPLines.length > 0 ? FFTPLines[0] : undefined;
	if (FFTPL) FFTPL.lineType = 'Reserve Expenses';
	const totalIncomeRL = {
		actual: 0,
		approvedBudget: 0,
		processedBudget: 0,
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
		label: 'Total Income',
		type: 'lightGreyBoldFont'
	};
	incomeLines.forEach(rl => {
		if (!rl.isSubline) sumReportLines(totalIncomeRL, rl, null, 'Treasury Summary Income');
	});

	const totalExpenseRL = {
		actual: 0,
		approvedBudget: 0,
		processedBudget: 0,
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
		label: 'Total Expense',
		type: 'lightGreyBoldFont'
	};
	expenseLines.forEach(rl => {
		if (!rl.isSubline) sumReportLines(totalExpenseRL, rl, null, 'Treasury Summary Expenses');
	});
	const totalNetIncomeBeforeFFTP = _getCopy(totalIncomeRL);
	totalNetIncomeBeforeFFTP.label = 'Total Net Income from Operations';
	subtractReportLines(totalNetIncomeBeforeFFTP, totalExpenseRL, 'Summary 1');

	const totalExpenseAfterFFTP = _getCopy(totalExpenseRL);
	totalExpenseAfterFFTP.label = 'Total Expense from Operations and Reserves';
	if (FFTPL) sumReportLines(totalExpenseAfterFFTP, FFTPL, null, 'Treasury Summary FFTP');

	const totalNetIncomeAfterFFTP = _getCopy(totalIncomeRL);
	totalNetIncomeAfterFFTP.label = 'Total Net Income from Operations and Reserves';
	subtractReportLines(totalNetIncomeAfterFFTP, totalExpenseAfterFFTP, 'Summary 2');
	/// clean extra income statement
	incomeLines.forEach((rl, i) => rl.lineType = i ? null : rl.lineType);
	expenseLines.forEach((rl, i) => rl.lineType = i ? null : rl.lineType);

	// null is empty row
	if (FFTPL) {
		reportLines = [...incomeLines, totalIncomeRL, null, ...expenseLines, totalExpenseRL, null, totalIncomeRL, totalExpenseRL, totalNetIncomeBeforeFFTP, null,
			FFTPL, null, totalIncomeRL, totalExpenseAfterFFTP, totalNetIncomeAfterFFTP];
	} else {
		reportLines = [...incomeLines, totalIncomeRL, null, ...expenseLines, totalExpenseRL, null, totalIncomeRL, totalExpenseRL, totalNetIncomeBeforeFFTP];
	}
	reportLines = calculateDifference(reportLines);

	return reportLines;
};

const placeSortedSimpleLinesAwardsAndRC = (reportLinesGroup, awardReportLines, RCReportLines, type) => {
	let awardNeeded = true;
	let RCNeeded = true;
	const filteredReportLines = Object.values(reportLinesGroup).filter(rl => rl.lineType === type);
	return filteredReportLines.reduce((res, rl) => {
		if (rl.label > 'Awards' && awardNeeded) {
			res = [...res, ...Object.values(awardReportLines).filter(rl => rl.lineType === type)];
			awardNeeded = false;
		}
		if (rl.label > 'ASH Research Collaborative' && RCNeeded) {
			let RCLines = Object.values(RCReportLines).filter(rl => rl.lineType === type);
			RCLines.sort((a, b) => a.index < b.index ? -1 : a.index > b.index ? 1 : 0);
			res = [...res, ...RCLines];
			RCNeeded = false;
		}
		res.push(rl);
		return res;
	}, []);
};
/**
 * Method generates Award section of report
 */
const processAwardLines = (awardReportLines, rl) => {
	try {
		const rlKey = rl.dim2Name + rl.dim3Name + rl.lineType;
		const totalAwardKey = 'awardTotal' + rl.lineType;
		rl.isSubline = true;
		rl.type = 'lightGrey';
		rl.label = SPACE + rl.dim3Name;
		let awardTotalLine = awardReportLines[totalAwardKey];
		if (!awardTotalLine) {
			awardTotalLine = {
				actual: 0,
				dim2Name: rl.dim2Name,
				dim3Name: rl.dim3Name,
				approvedBudget: 0,
				processedBudget: 0,
				processedVsApproved: 0,
				processedVsApprovedPercent: 0,
				label: 'Awards TOTAL',
				type: 'lightGreyBoldFont',
				lineType: rl.lineType
			};
			awardReportLines[totalAwardKey] = awardTotalLine;
		}
		let awardLine = awardReportLines[rlKey];
		if (awardLine) {
			sumReportLines(awardLine, rl, null, 'Summary Award Simple Lines Grouping');
		} else {
			awardReportLines[rlKey] = rl;
		}
		sumReportLines(awardTotalLine, rl, null, 'Summary Award Grouping'); // calculate total
	} catch (e) {
		_message('error', 'Process Award Report Line Error ' + e);
	}
};

/**
 * Method generates RC section of the report
 */
const processRCLines = (RCReportLines, rl) => {
	try {
		const rlKey = rl.dim2Name + rl.lineType;
		const totalRCKey = 'RCTotal' + rl.lineType;
		const otherRCKey = 'RCOther' + rl.lineType;
		const isSeparateRCLine = SEPARATE_RC_DIM2.some(substr => rl.dim2Name.includes(substr)) && SEPARATE_RC_ACC_SUBACC.some(substr => rl.accountSubAccount.includes(substr));
		rl.isSubline = true;
		rl.type = 'lightYellowBoldFont';
		rl.label = (isSeparateRCLine ? SPACE : SPACE + SPACE) + rl.dim2Name;
		rl.index = isSeparateRCLine ? 1 : 3;
		let RCTotalLine = RCReportLines[totalRCKey];
		let RCOtherLine = RCReportLines[otherRCKey];
		if (!RCTotalLine) {
			RCTotalLine = {
				actual: 0,
				dim2Name: rl.dim2Name,
				dim3Name: rl.dim3Name,
				approvedBudget: 0,
				processedBudget: 0,
				processedVsApproved: 0,
				processedVsApprovedPercent: 0,
				label: 'ASH Research Collaborative TOTAL',
				type: 'lightYellowBoldFont',
				lineType: rl.lineType,
				index: 0
			};
			RCReportLines[totalRCKey] = RCTotalLine;
		}
		if (!RCOtherLine) {
			RCOtherLine = {
				actual: 0,
				dim2Name: rl.dim2Name,
				dim3Name: rl.dim3Name,
				approvedBudget: 0,
				processedBudget: 0,
				processedVsApproved: 0,
				processedVsApprovedPercent: 0,
				label: SPACE + 'Misc Programs',
				type: 'lightYellowBoldFont',
				lineType: rl.lineType,
				index: 2,
				isSubline: true
			};
			RCReportLines[otherRCKey] = RCOtherLine;
		}
		let RCLine = RCReportLines[rlKey];
		if (RCLine) {
			sumReportLines(RCLine, rl, null, 'RC Simple Lines Grouping');
		} else {
			RCReportLines[rlKey] = rl;
		}
		sumReportLines(RCTotalLine, rl, null, 'RC Grouping'); // calculate total
		if (!isSeparateRCLine) sumReportLines(RCOtherLine, rl, null, 'RC Other Grouping'); // calculate total
	} catch (e) {
		_message('error', 'Process Award Report Line Error ' + e);
	}
};

/**
 * SIMPLE LINES
 */
const addSimpleSubTotalLines = (reportLines) => {
	const compareFn = (a, b) => {
		const first = a.lineType + a?.accName;
		const second = b.lineType + b?.accName;
		return first < second ? -1 : (first > second ? 1 : 0);
	};
	reportLines.sort(compareFn);
	const reportLinesGroup = {};
	reportLines.forEach(rl => {
		try {
			if (rl.lineType !== 'Income') rl.lineType = 'Expense';
			let key1 = rl.lineType + rl.accName; // key of simple line
			rl.label = rl.accName.replace(/^\d+\s*-\s*/, ''); // delete account number and a dash
			const awardGroupRL = reportLinesGroup[key1];
			if (!awardGroupRL) {
				reportLinesGroup[key1] = rl;
			} else {
				sumReportLines(awardGroupRL, rl, null, 'Treasury Simple Grouping');
			}
		} catch (e) {
			_message('error', 'Add Simple Sub Total Lines Error : ' + e);
		}
	});

	reportLines = Object.values(reportLinesGroup);
	const incomeLines = reportLines.filter(rl => rl.lineType === 'Income');
	const expenseLines = reportLines.filter(rl => rl.lineType !== 'Income');
	const totalIncomeRL = {
		actual: 0,
		approvedBudget: 0,
		processedBudget: 0,
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
		label: 'Total Income',
		type: 'lightGreyBoldFont'
	};
	incomeLines.forEach(rl => sumReportLines(totalIncomeRL, rl, null, 'Treasury Simple Income'));

	const totalExpenseRL = {
		actual: 0,
		approvedBudget: 0,
		processedBudget: 0,
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
		label: 'Total Expense',
		type: 'lightGreyBoldFont'
	};
	expenseLines.forEach(rl => sumReportLines(totalExpenseRL, rl, null, 'Treasury Simple Expense'));
	const totalNetIncome = _getCopy(totalIncomeRL);
	totalNetIncome.label = 'Total Net Income from Operations';
	subtractReportLines(totalNetIncome, totalExpenseRL, 'Simple 1');

	/// clean extra income statement
	incomeLines.forEach((rl, i) => rl.lineType = i ? null : rl.lineType);
	expenseLines.forEach((rl, i) => rl.lineType = i ? null : rl.lineType);

	// null is empty row
	reportLines = [...incomeLines, totalIncomeRL, null, ...expenseLines, totalExpenseRL, null, totalIncomeRL, totalExpenseRL, totalNetIncome];
	reportLines = calculateDifference(reportLines);
	return reportLines;
};

/**
 * PAIR LINES
 */
const addPairSubTotalLines = (reportLines) => {

	reportLines.forEach(rl => {
		if (rl.dim3Name === 'Default (000)') rl.dim3Name = rl.dim2Name;
	});

	const compareFn = (a, b) => {
		const first = a.lineType + a?.dim3Name;
		const second = b.lineType + b?.dim3Name;
		return first < second ? -1 : (first > second ? 1 : 0);
	};
	reportLines.sort(compareFn);
	const getLabel = (dim3Name, isg) => dim3Name.replace(/(\d+|\([^)]*\))/g, '').trim() + (isg === 'Income' ? ' Revenue' : ' Expense');
	const reportLinesGroup = {};
	reportLines.forEach(rl => {
		try {
			if (rl.lineType !== 'Income') rl.lineType = 'Expense';
			let key1 = rl.lineType + rl.dim3Name; // key of simple line
			rl.label = getLabel(rl.dim3Name, rl.lineType);
			const awardGroupRL = reportLinesGroup[key1];
			if (!awardGroupRL) {
				reportLinesGroup[key1] = rl;
			} else {
				sumReportLines(awardGroupRL, rl, null, 'Treasury Pairs Grouping');
			}
		} catch (e) {
			_message('error', 'Add Simple Sub Total Lines Error : ' + e);
		}
	});
	reportLines = Object.values(reportLinesGroup);
	const incomeLines = reportLines.filter(rl => rl.lineType === 'Income');
	const expenseLines = reportLines.filter(rl => rl.lineType !== 'Income');
	const totalIncomeRL = {
		actual: 0,
		approvedBudget: 0,
		processedBudget: 0,
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
		label: 'Total Income',
		type: 'lightGrey'
	};
	incomeLines.forEach(rl => sumReportLines(totalIncomeRL, rl, null, 'Treasury Pairs Income'));

	const totalExpenseRL = {
		actual: 0,
		approvedBudget: 0,
		processedBudget: 0,
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
		label: 'Total Expense',
		type: 'lightGrey'
	};
	expenseLines.forEach(rl => sumReportLines(totalExpenseRL, rl, null, 'Treasury Simple Expense'));
	const totalNetIncome = _getCopy(totalIncomeRL);
	totalNetIncome.type = 'lightGreyBoldFont';
	totalNetIncome.label = 'Total Net Income from Operations';
	subtractReportLines(totalNetIncome, totalExpenseRL, 'Pair st 1');

	const pairsMap = {};
	reportLines.forEach(rl => {
		let pair = pairsMap[rl.dim3Name];
		if (!pair) {
			pair = [];
			pairsMap[rl.dim3Name] = pair;
		}
		pair.push(rl);
	});
	let simpleLines = [];
	Object.values(pairsMap).forEach(pair => {
		const subTotal = {
			actual: 0,
			approvedBudget: 0,
			processedBudget: 0,
			processedVsApproved: 0,
			processedVsApprovedPercent: 0,
			label: 'Subtotal',
			type: 'lightGrey'
		};

		if (pair.length === 2) {
			sumReportLines(subTotal, pair[0], null, 'Pair Subtotal 2');
			subtractReportLines(subTotal, pair[1], 'Pair st 2');
			simpleLines = [...simpleLines, pair[0], pair[1], subTotal, null];
		} else {
			subtractReportLines(subTotal, pair[0], 'Pair st 3');
			simpleLines = [...simpleLines, pair[0], subTotal, null];
		}
	});


	// null is empty row
	reportLines = [...simpleLines, totalIncomeRL, totalExpenseRL, totalNetIncome];
	reportLines = calculateDifference(reportLines);
	return reportLines;
};

/**
 * The main method to generate na Excel file
 */
const generateExcelFile = async () => {
	try {
		_this.showSpinner = true;
		let fileName = `${FILE_NAME} (${_this.selectedCompany} ${+_this.selectedBY + 1})`;  // Rich requirement from 18.04.2024 Selected budget year must be in column H
		fileName = await _prompt("Type the file name", fileName, 'File Name');
		if (!fileName || fileName.length < 1) {
			_this.showSpinner = false;
			return;
		}
		let workbook = new ExcelJS.Workbook();

		Object.keys(separatedReportingBalances).forEach(sheetName => {
			if (sheetName !== 'Summary') return null; // requirement to leave just the Summary sheet form 15/03/2024
			const lines = separatedReportingBalances[sheetName];
			let sheetType = SHEET_TYPE[sheetName];
			let excelSheet = workbook.addWorksheet(sheetName, {views: [{state: "frozen", ySplit: 1, xSplit: 0}]});
			addSummaryHeaderAndSetColumnWidth(excelSheet);
			addSummaryReportLines(excelSheet, lines);
			if (sheetType === 'pairs') excelSheet.getColumn(1).hidden = true;
		});

		let data = await workbook.xlsx.writeBuffer();
		const blob = new Blob([data], {type: "application/octet-stream"});
		let downloadLink = document.createElement("a");
		downloadLink.href = window.URL.createObjectURL(blob);
		downloadLink.target = "_blank";
		downloadLink.download = fileName + ".xlsx";
		downloadLink.click();
		_this.showSpinner = false;
	} catch (e) {
		_message("error", "Reporting Excel generateExcelFile error: " + e);
		_this.showSpinner = false;
	}
};

const getSummaryAndSimpleHeaderParams = () => {
	const previousBY = _this.selectedBY - 1;
	const nextBY = +_this.selectedBY + 1;
	const summaryHeaders = [
		{title: 'Type', width: 17},
		{title: 'Label', width: 50},
		{title: `${previousBY} Actual`, width: 15},
		{title: `${_this.selectedBY} Approved Budgeted`, width: 22},
		{title: `${nextBY} Proposed Budgeted`, width: 22},
		{title: `Proposed FY${nextBY} vs Approved FY${_this.selectedBY} ($)`, width: 32},
		{title: `Proposed FY${nextBY} vs Approved FY${_this.selectedBY} (%)`, width: 32}
	];
	return summaryHeaders;
};

const addSummaryHeaderAndSetColumnWidth = (sheet) => {
	try {
		const headerRow = sheet.getRow(1);
		getSummaryAndSimpleHeaderParams().forEach((h, i) => {
			try {
				const headerCell = headerRow.getCell(i + 1);
				_setCell(headerCell, h.title, HEADER_FILL, HEADER_FONT, null, null, SIMPLE_BORDERS);
				sheet.getColumn(i + 1).width = h.width;
			} catch (e) {
				_message('error', 'Add Header Row Iteration Error : ' + e);
			}
		});
	} catch (e) {
		_message('error', 'Add Header Row Error : ' + e);
	}
};

const SUMMARY_FIELD_ORDER = ['lineType', 'label', 'actual', 'approvedBudget', 'processedBudget', 'processedVsApproved', 'processedVsApprovedPercent'];

const addSummaryReportLines = (sheet, lines) => {
	try {
		let rowPosition = 2;
		let rowFill, rowFont;
		lines.forEach(line => {
			if (!line) {
				rowPosition++;
				return null;
			}
			if (line.label) line.label = line.label.replace(/\(\d+\)/g, '');
			const excelRow = sheet.getRow(rowPosition++);
			rowFill = getReportLineFill(line.type);
			rowFont = getReportLineFont(line.type);
			SUMMARY_FIELD_ORDER.forEach((f, i) => {
				const cell = excelRow.getCell(i + 1);
				_setCell(cell, line[f], rowFill, rowFont, null, null, SIMPLE_BORDERS);
				if (['actual', 'approvedBudget', 'processedBudget', 'processedVsApproved'].includes(f)) cell.numFmt = CURRENCY_FMT;
				if (f === 'processedVsApprovedPercent') cell.numFmt = PERCENT_FMT;
			});
		})
	} catch (e) {
		_message('error', 'Add Report Lines Error ' + e);
	}
};

const getReportLineFill = (type) => {
	switch (type) {
		case 'lightGrey':
			return HEADER_FILL;
		case 'lightGreyBoldFont':
			return HEADER_FILL;
		case 'lightYellowBoldFont':
			return RC_FILL;
		case 'program':
			return PROGRAM_SUB_LINE_FILL;
		case 'totalNet':
			return TOTAL_NET_LINE_FILL;
		default:
			return undefined;
	}
};
const getReportLineFont = (type) => {
	switch (type) {
		case 'lightGreyBoldFont':
			return HEADER_FONT;
		case 'totalNet':
			return PROGRAM_SUB_LINE_FONT;
		default:
			return undefined;
	}
};

export {setTreasuryContext, manageDataAndGenerateTreasuryFile}