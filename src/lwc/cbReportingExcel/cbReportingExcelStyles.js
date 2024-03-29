const HEADER_FILL = {
	type: "pattern",
	pattern: "solid",
	fgColor: {argb: 'EFEFEF'}
};

const RC_FILL = {
	type: "pattern",
	pattern: "solid",
	fgColor: {argb: 'FDEDD9'}
};

const PROGRAM_PROJECT_SUB_LINE_FILL = {
	type: "pattern",
	pattern: "solid",
	fgColor: {argb: 'B7B7B7'}
};

const PROGRAM_SUB_LINE_FILL = {
	type: "pattern",
	pattern: "solid",
	fgColor: {argb: '434343'}
};

const TOTAL_NET_LINE_FILL = {
	type: "pattern",
	pattern: "solid",
	fgColor: {argb: '333399'}
};

const PROGRAM_SUB_LINE_FONT = {
	size: 11,
	color: {argb: 'FFFFFF'},
	name: 'Calibri',
};

const HEADER_FONT = {
	size: 11,
	bold: true,
	name: 'Calibri',
};

const SIMPLE_BORDERS = {
	top: {style: 'thin'},
	left: {style: 'thin'},
	bottom: {style: 'thin'},
	right: {style: 'thin'}
};

const CURRENCY_FMT = '$#,##0.00;[Red]($#,##0.00)';
const PERCENT_FMT = '#,#0.00"%"';

export {
	HEADER_FILL,
	RC_FILL,
	HEADER_FONT,
	PROGRAM_PROJECT_SUB_LINE_FILL,
	PROGRAM_SUB_LINE_FILL,
	PROGRAM_SUB_LINE_FONT,
	TOTAL_NET_LINE_FILL,
	SIMPLE_BORDERS,
	CURRENCY_FMT,
	PERCENT_FMT
}