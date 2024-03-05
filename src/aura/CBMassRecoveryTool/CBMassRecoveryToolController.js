({
	doInit: function (cmp, evt, h){
		Date.prototype.today = function () {
			return ((this.getDate() < 10)?"0":"") + this.getDate() +"/"+(((this.getMonth()+1) < 10)?"0":"") + (this.getMonth()+1) +"/"+ this.getFullYear();
		}
		Date.prototype.timeNow = function () {
			return ((this.getHours() < 10)?"0":"") + this.getHours() +":"+ ((this.getMinutes() < 10)?"0":"") + this.getMinutes() +":"+ ((this.getSeconds() < 10)?"0":"") + this.getSeconds();
		}
		h.helpInitUsersData(cmp);
		h.helpStartDataGettingProcess(cmp);
	},

	downloadExcel: function (cmp, evt, h){
		setTimeout(function () {
			h.helpDownloadExcel(cmp);
		},10);
	},

	handleFileChange: function (cmp, evt, h){
		cmp.set('v.showSpinner', true);
		let file = evt.getSource().get("v.files")[0];

		let workbook = new ExcelJS.Workbook();
		let blob = new Blob([file, {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}]);

		let fileReader = new FileReader();
		fileReader.onload = function (event) {
			workbook.xlsx.load(event.target.result).then(function () {
				setTimeout(function () {
					h.helpApplyExcelFile(cmp, workbook);
				}, 100);
			}).catch(err => {
				_cl('Error writing excel import' + err, 'red');
				cmp.set('v.showSpinner', false);
			});
		};
		fileReader.readAsArrayBuffer(blob);
	},

	showMappingModal: function (cmp, evt, h){
		let yearSO = cmp.get('v.budgetYearSO');
		h.helpRunFullRestoreProcess(cmp);
		if(yearSO.length === 0) h.helpGetSO(cmp);
		cmp.set('v.showMapping', true);
		cmp.set('v.showWarning', false);
		cmp.set('v.showBackdrop', false);
		cmp.set('v.step', 1);
	},

	deleteCurrentYearBudgetData: function (cmp, evt, h){
		h.helpDeleteBudgets(cmp);
		cmp.set('v.step', 2);
	},

	createBudgets: function (cmp, evt, h){
		h.helpCreateTags(cmp, cmp.get('v.loadedBudgets'), 'loadedBudgets', 'Budgets', 3, 'createBudgetLines');
	},

	createBudgetLines: function (cmp, evt, h){
		h.helpCreateTags(cmp, cmp.get('v.loadedBudgetLines'), 'loadedBudgetLines', 'Budget Lines', 4, 'createBudgetSubLines');
	},

	createBudgetSubLines: function (cmp, evt, h){
		h.helpCreateTags(cmp, cmp.get('v.loadedBudgetSubLines'), 'loadedBudgetSubLines', 'Budget SubLines', 0, null);
	},

	showWarningModal: function (cmp, evt, h){
		cmp.set('v.showBackdrop', true);
		cmp.set('v.showWarning', true);
	},

	hideModals: function (cmp, evt, h){
		cmp.set('v.showWarning', false);
		cmp.set('v.showBackdrop', false);
	},

	debug: function (cmp, evt, h){
		console.clear();
		console.log(evt.getSource().get("v.value"));
	}
});