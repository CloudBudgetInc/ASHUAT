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

export {sumReportLines, subtractReportLines, calculateDifference, round}