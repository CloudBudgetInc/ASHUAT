import {_message} from 'c/cbUtils';

const sumReportLines = (baseRL, currentRL, takeIntoAccountIncomeIsNegative, log) => {
	try {
		if (!baseRL) throw Error('Base line is null');
		if (!currentRL) throw Error('Current line is null');
		if (takeIntoAccountIncomeIsNegative && currentRL.incomeStatementGroup !== 'Income') {
			baseRL.actual -= parseFloat(currentRL.actual);
			baseRL.actualYTD -= parseFloat(currentRL.actualYTD);
			baseRL.approvedBudget -= parseFloat(currentRL.approvedBudget);
			baseRL.projectedBudget -= parseFloat(currentRL.projectedBudget);
			baseRL.processedBudget -= parseFloat(currentRL.processedBudget);
		} else {
			baseRL.actual += parseFloat(currentRL.actual);
			baseRL.actualYTD += parseFloat(currentRL.actualYTD);
			baseRL.approvedBudget += parseFloat(currentRL.approvedBudget);
			baseRL.projectedBudget += parseFloat(currentRL.projectedBudget);
			baseRL.processedBudget += parseFloat(currentRL.processedBudget);
		}
		normalizeRL(baseRL);
	} catch (e) {
		_message('error', 'Sum Report Lines Error : baseLine: ' + JSON.stringify(baseRL) + ' : currentLine: ' + JSON.stringify(currentRL) + ' => ' + e);
		console.error('SUM: base = ' + JSON.stringify(baseRL));
		console.error('SUM: currentRL = ' + JSON.stringify(currentRL));
		console.error('SUM: log = ' + log);
	}
};

const subtractReportLines = (baseRL, currentRL, log) => {
	try {
		baseRL.actual -= parseFloat(currentRL.actual);
		baseRL.approvedBudget -= parseFloat(currentRL.approvedBudget);
		baseRL.processedBudget -= parseFloat(currentRL.processedBudget);
		normalizeRL(baseRL);
	} catch (e) {
		_message('error', 'Subtract Report Lines Error : ' + e);
		console.error('BASE:' + JSON.stringify(baseRL));
		console.error('CURRENT:' + JSON.stringify(currentRL));
		console.error('LOG:' + log);
	}
};

const normalizeRL = (rl) => {
	try {
		rl.actual = round(rl.actual);
		rl.approvedBudget = round(rl.approvedBudget);
		rl.processedBudget = round(rl.processedBudget);
	} catch (e) {
		_message('error', 'Normalize RL Error ' + e);
	}
};

const calculateDifference = (reportLines) => {
	try {
		reportLines.forEach(rl => {
			try {
				if (!rl) return null;
				rl.processedVsApproved = rl.processedBudget - rl.approvedBudget;
				rl.processedVsApprovedPercent = rl.approvedBudget === 0 ? 0 : (rl.processedVsApproved / rl.approvedBudget) * 100;
			} catch (e) {
				_message('error', 'Calculate Difference Error ' + e);
			}
		});
		return reportLines;
	} catch (e) {
		_message('error', 'Calculate Difference Error ' + e);
	}
};

const roundToTwoDecimals = (num) => {
	return Math.round(num * 100) / 100;
};

const round = (n) => Number(n.toFixed(2));

/**
 * Report Line wrapper
 */
class ReportLine {
	/**
	 * Constructor for tho types of parameter
	 * @param labelOrBR may be RB or label
	 */
	constructor(labelOrBR, typeOrKey, lineType, dim2Name, dim3Name, index) {
		if (typeof labelOrBR === 'string') {
			this.label = labelOrBR;
			this.type = typeOrKey;
			this.lineType = lineType;
			this.dim2Name = dim2Name;
			this.dim3Name = dim3Name;
			this.index = index;
		} else {
			this.id = labelOrBR.Id;
			this.lineKey = typeOrKey;
			this.lineType = labelOrBR.Income_Statement_Group__c;
			this.accountSubAccount = labelOrBR.Account_Subaccount__c;
			this.dim2Name = labelOrBR.c2g__Dimension2__r?.Name;
			this.dim3Name = labelOrBR.c2g__Dimension3__r?.Name;
			this.accName = labelOrBR.c2g__GeneralLedgerAccount__r?.Name;
			this.company = labelOrBR.company;
			this.label = '';
		}
	}

	actual = 0;
	approvedBudget = 0;
	processedBudget = 0;
	processedVsApproved = 0;
	processedVsApprovedPercent = 0;
	accountSubAccount;
	company;
	id;
	lineKey;
	label;
	type;
	lineType;
	index;
	dim2Name;
	dim3Name;
	isSubline = false;
}

export {sumReportLines, subtractReportLines, calculateDifference, round, ReportLine}