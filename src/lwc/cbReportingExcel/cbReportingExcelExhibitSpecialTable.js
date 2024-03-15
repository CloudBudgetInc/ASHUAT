import {CURRENCY_FMT, PERCENT_FMT, PROGRAM_SUB_LINE_FONT, TOTAL_NET_LINE_FILL} from "./cbReportingExcelStyles"
import {_message, _parseServerError, _setCell} from 'c/cbUtils';
import getReportDataServer from "@salesforce/apex/CBExcelReport.getReportDataServer";
import {calculateDifference, subtractReportLines, sumReportLines} from "./cbReportingExcelUtils"

/**
 * Specially for the Main sheet Hematology-Focus Fellowship Training Program (460) lines must be moved to the bottom of the list
 */
const moveHFFTPtoBottom = (reportLines) => {
	try {
		let updatedReportLines = [];
		let HFFTPReportLines = [];
		reportLines.forEach(rl => {
			if (rl.label === 'Total Net Income') return null;
			if (rl.programProject && rl.programProject.includes('(460)')) {
				rl.isHFFTP = true;
				HFFTPReportLines.push(rl);
			} else {
				updatedReportLines.push(rl);
			}
		});
		return [...updatedReportLines, ...HFFTPReportLines];
	} catch (e) {
		_message('error', 'Move HFFTP lines to bottom error ' + e);
	}
};

const addSpecialTableToMainSheet = async (sheet, reportLines, anotherCompanyId, selectedBY) => {
	if (anotherCompanyId === 'ASH Research Collaborative') {
		const RCCompanyReportLines = await getRCCompanyData(anotherCompanyId, selectedBY);
		addSpecialTableLinesIncludedAnotherCompany(sheet, reportLines, RCCompanyReportLines[0], RCCompanyReportLines[1]);
	} else {
		addSpecialTableLines(sheet, reportLines);
	}
};

const getRCCompanyData = async (anotherCompanyId, selectedBY) => {
	let anotherCompanyReportLines = [];
	await getReportDataServer({selectedBY: parseInt(selectedBY), selectedCompany: anotherCompanyId})
		.then(RBs => {
			const anotherCompanyIncome = {
				label: 'Income',
				company: 'ASH RC',
				actual: 0,
				approvedBudget: 0, // selected BY
				processedBudget: 0, // next BY
				processedVsApproved: 0,
				processedVsApprovedPercent: 0,
			};
			const anotherCompanyExpense = {
				label: 'Expense',
				company: 'ASH RC',
				actual: 0,
				approvedBudget: 0, // selected BY
				processedBudget: 0, // next BY
				processedVsApproved: 0,
				processedVsApprovedPercent: 0,
			};
			anotherCompanyReportLines = [anotherCompanyIncome, anotherCompanyExpense];
			RBs.forEach(rb => {
				if ((rb.c2g__Type__c === 'Actual' && rb.Year__c === selectedBY) || rb.c2g__Type__c === 'Projection') return null; // used only for YTD & Projection report
				const reportLine = rb.Income_Statement_Group__c === 'Income' ? anotherCompanyIncome : anotherCompanyExpense;
				if (rb.c2g__Type__c === 'Actual') {
					let invertedIncomeActual = rb.c2g__HomeValue__c;
					if (rb.Income_Statement_Group__c === 'Income') {
						invertedIncomeActual *= -1;
					}
					reportLine.actual += parseFloat(invertedIncomeActual);
				} else {
					if (rb.Year__c === selectedBY) {
						reportLine.approvedBudget += parseFloat(rb.c2g__HomeValue__c);
					} else {
						reportLine.processedBudget += parseFloat(rb.c2g__HomeValue__c);
					}
				}
			});
		})
		.catch(e => _parseServerError('Get Extra Data Error ', e));

	anotherCompanyReportLines.forEach(rl => console.log('ANOTHER: ' + JSON.stringify(rl)));
	return anotherCompanyReportLines;
};


const addSpecialTableLinesIncludedAnotherCompany = (sheet, reportLines, RCIncome, RCExpense) => {
	try {
		const specialReportReportLines = {}; // key is 'Income Subtotal' or 'Program Expense Subtotal' or 'Salary and Overhead Subtotal'
		let HFFTPReportLine; //programProject
		reportLines.forEach(rl => {
			if (rl.type !== 'incomeStatementGroup') return null;
			if (rl.isHFFTP) {
				HFFTPReportLine = rl;
				HFFTPReportLine.company = '';
				HFFTPReportLine.leaveLabel = true;
				HFFTPReportLine.label = 'Total Expense from Reserves (HFFTP) + Operations';
			}
			let line = specialReportReportLines[rl.label];
			if (!line) {
				line = new ReportLine(rl.label, 'ASH');
				specialReportReportLines[rl.label] = line;
			}
			line.actual += +rl.actual;
			line.approvedBudget += +rl.approvedBudget;
			line.processedBudget += +rl.processedBudget;
		});

		// LINES
		const totalIncomeLine = specialReportReportLines['Income Subtotal']; // using twice
		const totalExpenseLineNOHFFTP = new ReportLine('Expense', 'ASH');
		const totalNetIncomeLineASHNOHFFTP = new ReportLine('Net Income', 'ASH');
		const totalNetIncomeLineGLOBALNOHFFTP = new ReportLine('Net Income', '');
		const totalNetIncomeLineRCNOHFFTP = new ReportLine('Net Income', 'ASH RC'); // RC net income
		const totalNetIncomeGLOBAL = new ReportLine('Net Income', ''); // last total
		totalNetIncomeGLOBAL.leaveLabel = true;
		totalNetIncomeGLOBAL.label = 'Total Net Income From Reserves + Operations';
		// TOTAL INCOME LINE IS UPPER
		const totalProgramExpenseLine = specialReportReportLines['Program Expense Subtotal'];
		const totalSalaryAndOverheadLine = specialReportReportLines['Salary and Overhead Subtotal'];
		const totalExpenseLineWithHFFTP = new ReportLine('Total Expense from Reserves (HFFTP) + Operations', 'ASH');
		const totalNetIncomeWithHFFTP = new ReportLine('Net Income From Reserves + Operations', 'ASH');

		console.log('HFFTPReportLine:' + JSON.stringify(HFFTPReportLine));
		console.log('totalIncomeLine:' + JSON.stringify(totalIncomeLine));
		console.log('totalExpenseLineNOHFFTP:' + JSON.stringify(totalExpenseLineNOHFFTP));
		console.log('totalNetIncomeLineASHNOHFFTP:' + JSON.stringify(totalNetIncomeLineASHNOHFFTP));
		console.log('totalProgramExpenseLine:' + JSON.stringify(totalProgramExpenseLine));
		console.log('totalSalaryAndOverheadLine:' + JSON.stringify(totalSalaryAndOverheadLine));
		console.log('totalExpenseLineWithHFFTP:' + JSON.stringify(totalExpenseLineWithHFFTP));
		console.log('totalNetIncomeWithHFFTP:' + JSON.stringify(totalNetIncomeWithHFFTP));

		sumReportLines(totalNetIncomeLineRCNOHFFTP, RCIncome); // RC Net Income
		subtractReportLines(totalNetIncomeLineRCNOHFFTP, RCExpense); // RC Net Income

		sumReportLines(totalExpenseLineNOHFFTP, totalProgramExpenseLine); // Expense without Reverses
		sumReportLines(totalExpenseLineNOHFFTP, totalSalaryAndOverheadLine); // Expense without Reverses
		//if (HFFTPReportLine) subtractReportLines(totalExpenseLineNOHFFTP, HFFTPReportLine);

		sumReportLines(totalNetIncomeLineASHNOHFFTP, totalIncomeLine);
		subtractReportLines(totalNetIncomeLineASHNOHFFTP, totalExpenseLineNOHFFTP);

		sumReportLines(totalExpenseLineWithHFFTP, totalProgramExpenseLine);
		sumReportLines(totalExpenseLineWithHFFTP, totalSalaryAndOverheadLine);

		sumReportLines(totalNetIncomeWithHFFTP, totalIncomeLine);
		subtractReportLines(totalNetIncomeWithHFFTP, totalExpenseLineWithHFFTP);

		sumReportLines(totalNetIncomeLineGLOBALNOHFFTP, totalNetIncomeLineASHNOHFFTP);
		sumReportLines(totalNetIncomeLineGLOBALNOHFFTP, totalNetIncomeLineRCNOHFFTP);

		sumReportLines(totalNetIncomeGLOBAL, totalNetIncomeLineGLOBALNOHFFTP);
		subtractReportLines(totalNetIncomeGLOBAL, HFFTPReportLine);

		calculateDifference([totalIncomeLine, totalExpenseLineNOHFFTP, totalNetIncomeLineRCNOHFFTP, totalNetIncomeLineASHNOHFFTP, totalNetIncomeLineGLOBALNOHFFTP, RCIncome, RCExpense, totalProgramExpenseLine, totalSalaryAndOverheadLine, totalExpenseLineWithHFFTP, totalNetIncomeWithHFFTP]);

		let startRowPosition = sheet.rowCount + 2;

		/** THE FIRST TABLE */
		[totalIncomeLine, totalExpenseLineNOHFFTP, totalNetIncomeLineASHNOHFFTP, RCIncome, RCExpense, totalNetIncomeLineRCNOHFFTP, totalNetIncomeLineGLOBALNOHFFTP].forEach(line => {
			try {
				const row = sheet.getRow(startRowPosition++);
				const labelCell = row.getCell(5);
				const actualCell = row.getCell(6);
				const approvedBudgetCell = row.getCell(7);
				const processedBudgetCell = row.getCell(8);
				const processedVsApprovedCell = row.getCell(9);
				const processedVsApprovedPercentCell = row.getCell(10);
				const processedVsApproved = line.processedBudget - line.approvedBudget;
				const processedVsApprovedPercent = line.approvedBudget === 0 ? 0 : (line.processedVsApproved / line.approvedBudget) * 100;
				const textLabel = `Total ${line.label.replace('Subtotal', '')} from ${line.company} Operations`;
				_setCell(labelCell, textLabel, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT);
				_setCell(actualCell, line.actual, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(approvedBudgetCell, line.approvedBudget, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedBudgetCell, line.processedBudget, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedVsApprovedCell, processedVsApproved, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedVsApprovedPercentCell, processedVsApprovedPercent, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, PERCENT_FMT);
			} catch (e) {
				_message('error', 'Populate Special Table Error ' + e);
			}
		});

		/** THE FIRST TABLE */
		startRowPosition++;
		/** THE SECOND TABLE */
		[totalIncomeLine, totalExpenseLineNOHFFTP, totalNetIncomeLineASHNOHFFTP, RCIncome, RCExpense, totalNetIncomeLineRCNOHFFTP, totalNetIncomeLineGLOBALNOHFFTP, HFFTPReportLine, totalNetIncomeGLOBAL].forEach(line => {
			try {
				const row = sheet.getRow(startRowPosition++);
				const labelCell = row.getCell(5);
				const actualCell = row.getCell(6);
				const approvedBudgetCell = row.getCell(7);
				const processedBudgetCell = row.getCell(8);
				const processedVsApprovedCell = row.getCell(9);
				const processedVsApprovedPercentCell = row.getCell(10);
				const processedVsApproved = line.processedBudget - line.approvedBudget;
				const processedVsApprovedPercent = line.approvedBudget === 0 ? 0 : (line.processedVsApproved / line.approvedBudget) * 100;
				const textLabel = line.leaveLabel ? line.label : `Total ${line.label.replace('Subtotal', '')} from ${line.company} Operations`;
				_setCell(labelCell, textLabel, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT);
				_setCell(actualCell, line.actual, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(approvedBudgetCell, line.approvedBudget, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedBudgetCell, line.processedBudget, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedVsApprovedCell, processedVsApproved, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedVsApprovedPercentCell, processedVsApprovedPercent, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, PERCENT_FMT);
			} catch (e) {
				_message('error', 'Populate Special Table Error ' + e);
			}
		});
		/** THE SECOND TABLE */

	} catch (e) {
		_message('error', 'Add Special Table Error ' + e);
	}

};

const ReportLine = class {
	constructor(label, company) {
		this.label = label;
		this.company = company;
	}

	actual = 0;
	approvedBudget = 0;
	processedBudget = 0;
	processedVsApproved = 0;
	processedVsApprovedPercent = 0;
};


const addSpecialTableLines = (sheet, reportLines) => {
	try {
		const specialReportReportLines = {}; // key is 'Income Subtotal' or 'Program Expense Subtotal' or 'Salary and Overhead Subtotal'
		let HFFTPReportLine; //programProject
		reportLines.forEach(rl => {
			if (rl.type !== 'incomeStatementGroup') return null;
			if (rl.isHFFTP) HFFTPReportLine = rl;
			let line = specialReportReportLines[rl.label];
			if (!line) {
				line = {
					label: rl.label,
					actual: 0,
					approvedBudget: 0,
					processedBudget: 0,
					processedVsApproved: 0,
					processedVsApprovedPercent: 0,
				};
				specialReportReportLines[rl.label] = line;
			}
			line.actual += +rl.actual;
			line.approvedBudget += +rl.approvedBudget;
			line.processedBudget += +rl.processedBudget;
		});

		// LINES
		const totalIncomeLine = specialReportReportLines['Income Subtotal']; // using twice
		const totalExpenseLineNOHFFTP = {
			label: 'Expense',
			actual: 0,
			approvedBudget: 0,
			processedBudget: 0,
			processedVsApproved: 0,
			processedVsApprovedPercent: 0,
		};
		const totalNetIncomeLineASHNOHFFTP = {
			label: 'Net Income',
			actual: 0,
			approvedBudget: 0,
			processedBudget: 0,
			processedVsApproved: 0,
			processedVsApprovedPercent: 0,
		};
		// TOTAL INCOME LINE IS UPPER
		const totalProgramExpenseLine = specialReportReportLines['Program Expense Subtotal'];
		const totalSalaryAndOverheadLine = specialReportReportLines['Salary and Overhead Subtotal'];
		const totalExpenseLineWithHFFTP = {
			label: 'Total Expense from Reserves (HFFTP) + Operations',
			actual: 0,
			approvedBudget: 0,
			processedBudget: 0,
			processedVsApproved: 0,
			processedVsApprovedPercent: 0,
		};
		const totalNetIncomeWithHFFTP = {
			label: 'Net Income From Reserves + Operations',
			actual: 0,
			approvedBudget: 0,
			processedBudget: 0,
			processedVsApproved: 0,
			processedVsApprovedPercent: 0,
		};

		console.log('HFFTPReportLine:' + JSON.stringify(HFFTPReportLine));
		console.log('totalIncomeLine:' + JSON.stringify(totalIncomeLine));
		console.log('totalExpenseLineNOHFFTP:' + JSON.stringify(totalExpenseLineNOHFFTP));
		console.log('totalNetIncomeLineASHNOHFFTP:' + JSON.stringify(totalNetIncomeLineASHNOHFFTP));
		console.log('totalProgramExpenseLine:' + JSON.stringify(totalProgramExpenseLine));
		console.log('totalSalaryAndOverheadLine:' + JSON.stringify(totalSalaryAndOverheadLine));
		console.log('totalExpenseLineWithHFFTP:' + JSON.stringify(totalExpenseLineWithHFFTP));
		console.log('totalNetIncomeWithHFFTP:' + JSON.stringify(totalNetIncomeWithHFFTP));

		sumReportLines(totalExpenseLineNOHFFTP, totalProgramExpenseLine);
		sumReportLines(totalExpenseLineNOHFFTP, totalSalaryAndOverheadLine);
		if (HFFTPReportLine) subtractReportLines(totalExpenseLineNOHFFTP, HFFTPReportLine);

		sumReportLines(totalNetIncomeLineASHNOHFFTP, totalIncomeLine);
		subtractReportLines(totalNetIncomeLineASHNOHFFTP, totalExpenseLineNOHFFTP);

		sumReportLines(totalExpenseLineWithHFFTP, totalProgramExpenseLine);
		sumReportLines(totalExpenseLineWithHFFTP, totalSalaryAndOverheadLine);

		sumReportLines(totalNetIncomeWithHFFTP, totalIncomeLine);
		subtractReportLines(totalNetIncomeWithHFFTP, totalExpenseLineWithHFFTP);

		calculateDifference([totalIncomeLine, totalExpenseLineNOHFFTP, totalNetIncomeLineASHNOHFFTP, totalProgramExpenseLine, totalSalaryAndOverheadLine, totalExpenseLineWithHFFTP, totalNetIncomeWithHFFTP]);

		let startRowPosition = sheet.rowCount + 2;

		/** THE FIRST TABLE */
		[totalIncomeLine, totalExpenseLineNOHFFTP, totalNetIncomeLineASHNOHFFTP].forEach(line => {
			try {
				const row = sheet.getRow(startRowPosition++);
				const labelCell = row.getCell(5);
				const actualCell = row.getCell(6);
				const approvedBudgetCell = row.getCell(7);
				const processedBudgetCell = row.getCell(8);
				const processedVsApprovedCell = row.getCell(9);
				const processedVsApprovedPercentCell = row.getCell(10);
				const processedVsApproved = line.processedBudget - line.approvedBudget;
				const processedVsApprovedPercent = line.approvedBudget === 0 ? 0 : (line.processedVsApproved / line.approvedBudget) * 100;
				const textLabel = 'Total ' + line.label.replace('Subtotal', '') + ' from Operations';
				_setCell(labelCell, textLabel, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT);
				_setCell(actualCell, line.actual, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(approvedBudgetCell, line.approvedBudget, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedBudgetCell, line.processedBudget, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedVsApprovedCell, processedVsApproved, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedVsApprovedPercentCell, processedVsApprovedPercent, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, PERCENT_FMT);
			} catch (e) {
				_message('error', 'Populate Special Table Error ' + e);
			}
		});
		/** THE FIRST TABLE */
		startRowPosition++;
		/** THE SECOND TABLE */
		[totalIncomeLine, totalProgramExpenseLine, totalSalaryAndOverheadLine, totalExpenseLineWithHFFTP, totalNetIncomeWithHFFTP].forEach(line => {
			try {
				const row = sheet.getRow(startRowPosition++);
				const labelCell = row.getCell(5);
				const actualCell = row.getCell(6);
				const approvedBudgetCell = row.getCell(7);
				const processedBudgetCell = row.getCell(8);
				const processedVsApprovedCell = row.getCell(9);
				const processedVsApprovedPercentCell = row.getCell(10);
				const processedVsApproved = line.processedBudget - line.approvedBudget;
				const processedVsApprovedPercent = line.approvedBudget === 0 ? 0 : (line.processedVsApproved / line.approvedBudget) * 100;
				const textLabel = 'Total ' + line.label.replace('Subtotal', '');
				_setCell(labelCell, textLabel, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT);
				_setCell(actualCell, line.actual, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(approvedBudgetCell, line.approvedBudget, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedBudgetCell, line.processedBudget, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedVsApprovedCell, processedVsApproved, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, CURRENCY_FMT);
				_setCell(processedVsApprovedPercentCell, processedVsApprovedPercent, TOTAL_NET_LINE_FILL, PROGRAM_SUB_LINE_FONT, PERCENT_FMT);
			} catch (e) {
				_message('error', 'Populate Special Table Error ' + e);
			}
		});
		/** THE SECOND TABLE */

	} catch (e) {
		_message('error', 'Add Special Table Error ' + e);
	}

};

export {addSpecialTableToMainSheet, moveHFFTPtoBottom}