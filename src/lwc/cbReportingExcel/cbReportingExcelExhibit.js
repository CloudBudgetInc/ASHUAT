import {
	CURRENCY_FMT,
	HEADER_FILL,
	HEADER_FONT,
	PERCENT_FMT,
	PROGRAM_PROJECT_SUB_LINE_FILL,
	PROGRAM_SUB_LINE_FILL,
	PROGRAM_SUB_LINE_FONT,
	SIMPLE_BORDERS,
	TOTAL_NET_LINE_FILL
} from "./cbReportingExcelStyles"
import {_message, _prompt, _setCell} from 'c/cbUtils';
import {calculateDifference, sumReportLines} from "./cbReportingExcelUtils"
import {addSpecialTableToMainSheet, moveHFFTPtoBottom} from "./cbReportingExcelExhibitSpecialTable";


let _this;
const setContext = (context) => _this = context;
let separatedReportingBalances = {};// reporting balances separated by Dimension 2, key is Dim2 Name
const FIRST_SHEET_NAME = 'Main';
let FILE_NAME = "Budget Exhibit";

const manageDataAndGenerateFile = () => {
	HEADER_PARAMS = undefined;
	createDataSetsSeparatedByDimension1();
	convertReportingBalancesToReportLines();
	generateExcelFile();
};

/**
 * Method separates reporting balances by Dimension 2 Name and put extra lines to default list
 */
const createDataSetsSeparatedByDimension1 = () => {
	try {
		const firstSheetName = FIRST_SHEET_NAME;
		const RBWithoutDimension2SheetName = 'Default';
		separatedReportingBalances = _this.reportingBalancesRaw.reduce((result, rb) => {
			try {
				let mainSheetList = result[firstSheetName];
				if (!mainSheetList) {
					mainSheetList = [];
					result[firstSheetName] = mainSheetList;
				}

				let dim2Name = rb.c2g__Dimension1__r?.Name;
				if (!dim2Name) dim2Name = RBWithoutDimension2SheetName;
				let dim2List = result[dim2Name];
				if (!dim2List) {
					dim2List = [];
					result[dim2Name] = dim2List;
				}

				mainSheetList.push(rb);
				dim2List.push(rb);
				return result;
			} catch (e) {
				_message('error', 'Separate Data by Dimension 2 Iterating Error: ' + e);
			}
		}, {});
	} catch (e) {
		_message('error', 'Separate Data by Dimension 2 Error: ' + e);
	}
};

const convertReportingBalancesToReportLines = () => {
	Object.keys(separatedReportingBalances).forEach(key => {
		let reportingBalances = separatedReportingBalances[key];
		let reportLines = getReportLinesFromReportingBalances(reportingBalances);
		reportLines = addSubTotalLines(reportLines);
		if (key === FIRST_SHEET_NAME) reportLines = moveHFFTPtoBottom(reportLines);
		reportLines = calculateDifference(reportLines);
		separatedReportingBalances[key] = reportLines;
	});
};

const getReportLinesFromReportingBalances = (RBList) => {
	const reportLinesMap = {}; // key is dim2 Id and account Id
	RBList.forEach(rb => {
		try {
			if ((rb.c2g__Type__c === 'Actual' && rb.Year__c === _this.selectedBY) || rb.c2g__Type__c === 'Projection') return null; // used only for YTD & Projection report
			const lineKey = rb.c2g__Dimension2__c + rb.c2g__Dimension3__c + rb.Income_Statement_Group__c + rb.c2g__GeneralLedgerAccount__c + rb.Account_Subaccount__c;
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
			_message('error', 'Get RL from RB Error : ' + e);
		}
	});
	return Object.values(reportLinesMap);
};

/**
 *
 * @param rb source reporting balance
 * @param lineKey key of reporting line
 * @return {lineKey: *, actual: number, programProject: (string|string), accountSubAccount: *, processedBudget: number, processedVsApprovedPercent: number, generalLedgerName: (string|string), incomeStatementGroup: *, processedVsApproved: number, approvedBudget: number, label: string} line for the excel table
 */
const getNewReportLine = (rb, lineKey) => {
	return {
		lineKey,
		program: rb.c2g__Dimension2__r?.Name,
		programProject: rb.c2g__Dimension2__r?.Name + '-' + rb.c2g__Dimension3__r?.Name,
		incomeStatementGroup: rb.Income_Statement_Group__c,
		generalLedgerName: rb.c2g__GeneralLedgerAccount__r?.Name,
		accountSubAccount: rb.Account_Subaccount__c,
		label: '',
		actual: 0,
		approvedBudget: 0, // selected BY
		processedBudget: 0, // next BY
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
	};
};

const addSubTotalLines = (reportLines) => {
	try {
		const updatedReportLines = [];
		let incomeStatementGroup; // light total
		let incomeStatementSubLine;

		let programProject; // medium total
		let programProjectSubLine;

		let program; // hard total
		let programSubLine;

		const totalNetLine = {
			type: 'totalNet',
			actual: 0,
			approvedBudget: 0,
			processedBudget: 0,
			processedVsApproved: 0,
			processedVsApprovedPercent: 0,
			label: 'Total Net Income'
		};

		reportLines.forEach((rl, i) => {
			try {
				if (i === 0) { // first line

					incomeStatementGroup = rl.incomeStatementGroup + rl.programProject; // key
					incomeStatementSubLine = getNewIncomeStatementSubLine(rl);

					programProject = rl.programProject;
					programProjectSubLine = getNewProgramProjectSubLine(rl);

					program = rl.program;
					programSubLine = getNewProgramSubLine(rl);

					sumReportLines(incomeStatementSubLine, rl);
					sumReportLines(programProjectSubLine, rl, true);
					sumReportLines(programSubLine, rl, true);
					sumReportLines(totalNetLine, rl, true);

					updatedReportLines.push(rl);
					return null;
				}
				if (incomeStatementGroup !== rl.incomeStatementGroup + rl.programProject) { //flush incomeStatementSubLine
					updatedReportLines.push(incomeStatementSubLine);
					incomeStatementGroup = rl.incomeStatementGroup + rl.programProject;
					incomeStatementSubLine = getNewIncomeStatementSubLine(rl);
				}

				if (programProject !== rl.programProject) { //flush programProjectSubLine
					updatedReportLines.push(programProjectSubLine);
					programProject = rl.programProject;
					programProjectSubLine = getNewProgramProjectSubLine(rl);
				}

				if (program !== rl.program) { //flush programSubLine
					updatedReportLines.push(programSubLine);
					program = rl.program;
					programSubLine = getNewProgramSubLine(rl);
				}

				sumReportLines(incomeStatementSubLine, rl);
				sumReportLines(programProjectSubLine, rl, true);
				sumReportLines(programSubLine, rl, true);
				sumReportLines(totalNetLine, rl, true);

				updatedReportLines.push(rl);
			} catch (e) {
				_message('error', 'Add Subtotal Lines Error ' + e);
			}
		});
		if (incomeStatementSubLine) updatedReportLines.push(incomeStatementSubLine); // flush the last subline
		if (programProjectSubLine) updatedReportLines.push(programProjectSubLine); // flush the last programProjectSubLine
		if (programSubLine) updatedReportLines.push(programSubLine); // flush the last programProjectSubLine
		updatedReportLines.push(totalNetLine); // flush totalNetLine
		return updatedReportLines;
	} catch (e) {
		_message('error', 'Add SubtotalLines Error ' + e);
	}
};

const getNewIncomeStatementSubLine = (rl) => {
	return {
		type: 'incomeStatementGroup',
		programProject: rl.programProject,
		actual: 0,
		approvedBudget: 0,
		processedBudget: 0,
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
		label: rl.incomeStatementGroup + ' Subtotal'
	}
};

const getNewProgramProjectSubLine = (rl) => {
	return {
		type: 'programProject',
		programProject: rl.programProject,
		actual: 0,
		approvedBudget: 0,
		processedBudget: 0,
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
		label: 'Project Net Income'
	}
};

const getNewProgramSubLine = (rl) => {
	return {
		type: 'program',
		programProject: rl.program,
		actual: 0,
		approvedBudget: 0,
		processedBudget: 0,
		processedVsApproved: 0,
		processedVsApprovedPercent: 0,
		label: 'Program Net Income'
	}
};

/**
 * The main method to generate na Excel file
 */
const generateExcelFile = async () => {
	try {

		_this.showSpinner = true;
		let fileName = `${FILE_NAME} (${_this.selectedCompany} ${_this.selectedBY})`;
		fileName = await _prompt("Type the file name", fileName, 'File Name');
		if (!fileName || fileName.length < 1) {
			_this.showSpinner = false;
			return;
		}
		let workbook = new ExcelJS.Workbook();

		//Object.keys(this.separatedReportingBalances).forEach(name => console.log('SHEET NAME : ' + name));
		Object.keys(separatedReportingBalances).forEach(sheetName => {
			const lines = separatedReportingBalances[sheetName];
			let dim1Sheet = workbook.addWorksheet(sheetName, {views: [{state: "frozen", ySplit: 1, xSplit: 0}]});
			addHeaderAndSetColumnWidth(dim1Sheet);
			addReportLines(dim1Sheet, lines);
		});

		const anotherCompanyId = _this.companySO.find(comSO => comSO.value !== _this.selectedCompany).value;
		await addSpecialTableToMainSheet(workbook.getWorksheet(FIRST_SHEET_NAME), separatedReportingBalances[FIRST_SHEET_NAME], anotherCompanyId, _this.selectedBY);

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

let HEADER_PARAMS;
const getHeaderParams = () => {
	if (!HEADER_PARAMS) {
		const previousBY = _this.selectedBY - 1;
		const nextBY = +_this.selectedBY + 1;
		HEADER_PARAMS = [
			{title: 'Program-Project', width: 50},
			{title: 'Income Statement Group', width: 35},
			{title: 'General Ledger Name', width: 35},
			{title: 'Account-Subaccount', width: 20},
			{title: 'Label', width: 47},
			{title: `${previousBY} Actual`, width: 15},
			{title: `${_this.selectedBY} Approved Budgeted`, width: 22},
			{title: `${nextBY} Proposed Budgeted`, width: 22},
			{title: `Proposed FY${nextBY} vs Approved FY${_this.selectedBY} ($)`, width: 32},
			{title: `Proposed FY${nextBY} vs Approved FY${_this.selectedBY} (%)`, width: 32}
		];
	}
	return HEADER_PARAMS;
};

const addHeaderAndSetColumnWidth = (sheet) => {
	try {
		const headerRow = sheet.getRow(1);
		getHeaderParams().forEach((h, i) => {
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

const FIELD_ORDER = ['programProject', 'incomeStatementGroup', 'generalLedgerName', 'accountSubAccount', 'label', 'actual', 'approvedBudget', 'processedBudget', 'processedVsApproved', 'processedVsApprovedPercent'];

/**
 * Method gets prepared report lines and put them to an Excel sheet
 * @param sheet
 * @param lines
 */
const addReportLines = (sheet, lines) => {
	try {
		let rowPosition = 2;
		let rowFill, rowFont, previousLineWasProgramSubtotal, previousLineWasSimple;
		const numberFields = ['actual', 'approvedBudget', 'processedBudget', 'processedVsApproved'];
		lines = lines.filter(line => numberFields.some(fn => line[fn] !== 0)); // remove completely empty lines
		let insertSpecialLine = true;
		lines.forEach(line => {
			if (previousLineWasProgramSubtotal) rowPosition++;
			if (insertSpecialLine && line.programProject?.includes('460')) {
				insertSpecialLine = false;
				const cell = sheet.getRow(rowPosition++).getCell(1);
				cell.value = 'Reserves';
				cell.font = {bold: true, size: 14};
				return null;
			}
			const excelRow = sheet.getRow(rowPosition++);
			rowFill = getReportLineFill(line.type);
			rowFont = getReportLineFont(line.type);
			if (previousLineWasSimple) line.programProject = line.incomeStatementGroup = undefined;
			FIELD_ORDER.forEach((f, i) => {
				const cell = excelRow.getCell(i + 1);
				_setCell(cell, line[f], rowFill, rowFont, null, null, SIMPLE_BORDERS);
				if (numberFields.includes(f)) cell.numFmt = CURRENCY_FMT;
				if (f === 'processedVsApprovedPercent') cell.numFmt = PERCENT_FMT;
			});
			previousLineWasProgramSubtotal = line.type === 'program';
			previousLineWasSimple = line.type === undefined;
		})
	} catch (e) {
		_message('error', 'Add Report Lines Error ' + e);
	}
};

const getReportLineFill = (type) => {
	switch (type) {
		case 'incomeStatementGroup':
			return HEADER_FILL;
		case 'programProject':
			return PROGRAM_PROJECT_SUB_LINE_FILL;
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
		case 'program':
			return PROGRAM_SUB_LINE_FONT;
		case 'totalNet':
			return PROGRAM_SUB_LINE_FONT;
		default:
			return undefined;
	}
};

export {setContext, manageDataAndGenerateFile}