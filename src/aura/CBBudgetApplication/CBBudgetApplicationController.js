({
	doInit: function (cmp, event, helper) {

		_getCurrentUserSettings(cmp);
		document.title = _TEXT.APPS.MODULE_HEADER;
		_showSpinner(cmp);
		helper.helpSetAdminAccessVariable(cmp);
		window.setTimeout(
			$A.getCallback(function () {
				try {
					const recordId = cmp.get("v.recordId");
					if (recordId != null) {
						cmp.set("v.mode", 'single');
						cmp.set("v.app.Id", recordId);
						cmp.set("v.recordId", null);
					}

					let mode = cmp.get("v.mode");

					helper.helpGetBudgetAppDimension(cmp);
					helper.helpGetBudgetAppAmountDimension(cmp);
					if (mode === 'table') {
						helper.helpSetTableHeight(cmp);
						cmp.set("v.headerTitle", 'Budget Templates');
						helper.helpGetNeededSO(cmp);
						helper.helpGetMainAppSO(cmp);
						helper.helpGetAppList(cmp);
						helper.helpSetAdminAccessVariable(cmp);
					} else {
						if(recordId != null){
							helper.helpSetEditDisabledVariable(cmp, cmp.get('v.app'));
							helper.helpSetUserHasNoAccessToApprove(cmp, cmp.get('v.app'));
						}
						helper.helpRefreshSingleApp(cmp);
					}
				} catch (e) {
					alert('Init wizard error: ' + e);
				}
			}), 10
		);

		$(window).scroll(function () {
			let the_top = $(document).scrollTop();
			let inpMode = cmp.get("v.inputMode");
			if (the_top > 1000 && (!inpMode)) {
				$('#nav').addClass('fixed');
			} else {
				$('#nav').removeClass('fixed');
			}
		});

	},

	saveApp: function (cmp, event, helper) {
		function callback(){
			$A.get("e.force:refreshView").fire();
			//window.location.href = window.location.href;
		}
		helper.helpSaveApp(cmp, callback());
	},
	createApp: function (cmp, event, helper) {
		helper.helpCreateApp(cmp);
	},
	cloneApp: function (cmp, event, helper) {
		helper.helpCloneApp(cmp);
	},
	applyTitleRule: function (cmp, event, helper) {
		helper.helpApplyTitleRule(cmp);
	},
	deleteApp: function (cmp, event, helper) {
		helper.helpDeleteApp(cmp);
	},
	updateApp: function (cmp, event, helper) {
		_showSpinner(cmp);
		helper.helpGetAppList(cmp);
	},
	recalculateAllApps: function (cmp, event, helper) {
		_showSpinner(cmp);
		helper.helpRecalculateTotals(cmp);
	},

	valueChangeResponse: function (cmp, event, helper) {
		cmp.set("v.needSave", true);
		const row = event.getSource().get('v.name');
		const type = event.getSource().get('v.label');
		helper.helpCalculateRow(cmp, row, type);
		helper.helpCalculateTotalRows(cmp, type);
		helper.helpCalculateMarginRow(cmp);
		helper.helpCalculateTargetTotalRows(cmp, type);
	},

	addLine: function (cmp, event, helper) {
		const type = event.getSource().get('v.name');
		_CBMessages.fireWarningMessage('To save the added items, save the budget.', null);
		helper.helpAddLine(cmp, type, undefined, false);
	},

	calculateDialogTotals: function (cmp, event, helper) {
		helper.helpCalculateDialogTotals(cmp);
	},

	handleRowAction: function (cmp, event, helper) {
		helper.helpHandleTableButtons(cmp, event);
	},

	redirectToApp: function (cmp, event, helper) {
		_CBRedirect.toSObject(event.getSource().get('v.value'));
	},

	redirectToAppSheet: function (cmp, event, helper) {
		helper.helpRedirectToAppSheet(cmp);
	},
	/**
	 * Simple line title was clicked
	 */
	showDetails: function (cmp, event, helper) {
		let rowShrinkId = event.getSource().get('v.value');
		helper.helpShowDetails(cmp, rowShrinkId);
	},
	applyDetails: function (cmp, event, helper) {
		//let row = JSON.parse(JSON.stringify(cmp.get('v.row')));
		_showSpinner(cmp);
		let blCmp = cmp.find('blcomponent');
		if(blCmp.saveSubRows() === 't'){
			helper.helpApplyDetails(cmp);
			blCmp.resetOldRow();
		}
		helper.helpSaveAppTotals(cmp);
		cmp.set('v.disableDeleteSublines', false);
		cmp.set('v.disableCloseButton', false);
		//helper.helpValidateByCombinationRules(cmp, row);
	},

	closeDetails: function (cmp, event, helper) {
		helper.helpCloseDetails(cmp);
		cmp.find('blcomponent').resetOldRow();
		cmp.set('v.disableDeleteSublines', false);
	},

	turnDetailMode: function (cmp, event, helper) {
		_showSpinner(cmp);
		setTimeout(function () {
			const on = event.getSource().get('v.checked'); // TODO Toggle value!
			if (on) {
				cmp.set("v.showMode", true);
			} else {
				cmp.set("v.showMode", false);
			}
			_hideSpinner(cmp);
		}, 10);
	},
	deleteRow: function (cmp, event, helper) {
		if (!confirm(_TEXT.APPS.DELETE_ROW_CONFIRM)) return;
		let rowId = event.getSource().get('v.value');
		helper.helpDeleteRow(cmp, rowId);
		//_CBMessages.fireWarningMessage('To apply changes save the budget.', null); // Changed to deleting on the flow
	},

	/**
	 * The method converts calculation rule line to simple line
	 */
	convertToSimpleRow: function (cmp, event, helper) {
		let rowId = event.getSource().get('v.value');
		helper.helpConvertToSimpleRow(cmp, rowId);
		helper.helpCloseDetails(cmp);
	},
	updateAppLineTitle: function (cmp, event, helper) {
		cmp.set("v.needSave", true);
		helper.helpUpdateAppLineTitle(cmp, event.getSource().get("v.accesskey"));
		cmp.set('v.disableDeleteSublines', true);
	},
	applySinglePageFilter: function (cmp, event, helper) {
		helper.helpApplyPageFilters(cmp);
	},
	backToMainTable: function (cmp, event, helper) {
		helper.helpBackToMainTable(cmp);
	},

	/** EXCEL */
	showExcelPanel: function (cmp, event, helper) {
		helper.helpShowExcelPanel(cmp);
	},
	downloadExcel: function (cmp, event, helper) {
		helper.helpDownloadExcel(cmp, 'ExcelFile');
		helper.helpShowExcelPanel(cmp);
	},

	handleFilesChange: function (cmp, event, helper) {
		_showSpinner(cmp);
		helper.helpShowExcelPanel(cmp);
		let file = event.getSource().get("v.files")[0];

		let workbook = new ExcelJS.Workbook();
		let blob = new Blob([file, {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}]);

		let fileReader = new FileReader();
		fileReader.onload = function (event) {
			workbook.xlsx.load(event.target.result).then(function () {
				setTimeout(function () {
					helper.helpApplyExcelFile(cmp, workbook);
				}, 100);
			}).catch(err => _cl('Error writing excel import' + err, 'red'));

		};
		fileReader.readAsArrayBuffer(blob);
	},
	/** EXCEL */

	refreshCalcRules: function (cmp, evt, helper) {
		helper.helpRefreshCalcRules(cmp);

	},

	// BACKUP //
	refreshBackupList: function (cmp, event, helper) {
		helper.helpGetBackupList(cmp);
	},
	showBackup: function (cmp, event, helper) {
		$A.util.removeClass(cmp.find("backupDiv"), "slds-hide");
		$A.util.removeClass(cmp.find("modalBackGround"), "slds-hide");
		helper.helpGetBackupList(cmp);
	},
	applyBackup: function (cmp, event, helper) {
		let backupId = event.getSource().get('v.value');
		helper.helpApplyBackup(cmp, backupId);
		$A.util.addClass(cmp.find("backupDiv"), "slds-hide");
		$A.util.addClass(cmp.find("modalBackGround"), "slds-hide");
	},
	hideBackup: function (cmp, event, helper) {
		cmp.set("v.backupList", []);
		$A.util.addClass(cmp.find("backupDiv"), "slds-hide");
		$A.util.addClass(cmp.find("modalBackGround"), "slds-hide");
	},
	// BACKUP //

	/**
	 * This method will be invoked from the additional Budget App Component
	 */
	applyAdditionalComponent: function (cmp, event, helper) {
		let childCMP = cmp.get("v.additionalCMP");
		if(childCMP!== undefined && cmp.get('v.additionalComponent').length > 0) {
			cmp.set("v.app", childCMP.get("v.app"));
			cmp.set("v.template", childCMP.get("v.template"));
			cmp.set("v.row", childCMP.get("v.row"));
		}

		if(cmp.get('v.additionalBudgetLineComponent') !== undefined && cmp.get('v.additionalBudgetLineComponent').length > 0) {
			function setParentParams() {
				let param = event.getParam('row');
				if (!_isInvalid(param)) {
					cmp.set('v.row', param);
				}
			}

			window.setTimeout(
				$A.getCallback(function () {
					setParentParams();
				}), 10
			);
		}
	},

	sendIncomeData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(null, cmp.get('v.incomeData'));
				}catch (e){}
			}
		}
	},

	sendIncomeDownUpSubData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.incomeDownUpSubData'));
				}catch (e){}
			}
		}
	},

	sendIncomeTopDownSubData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.incomeTopDownSubData'));
				}catch (e){}
			}
		}
	},

	sendExpenseData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(null, cmp.get('v.expenseData'));
				}catch (e){}
			}
		}
	},

	sendExpenseDownUpSubData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.expenseDownUpSubData'));
				}catch (e){}
			}
		}
	},

	sendExpenseTopDownSubData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.expenseTopDownSubData'));
				}catch (e){}
			}
		}
	},

	sendTotalData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.totalData'));
				}catch (e){}
			}
		}
	},

	sendTargetTotalData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.targetTotalData'));
				}catch (e){}
			}
		}
	},

	sendRowDataToBLComponent: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalBudgetLineComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalBudgetLineComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.row'));
				}catch (e){}
			}
		}
	},

	onHideLevelChanges: function (cmp, event, helper) {
		_showSpinner(cmp);
		window.setTimeout(
			$A.getCallback(function () {
				helper.helpFoldUnfoldList(cmp);
			}), 10
		);
	},

	onStatusFilterChanges: function(cmp, evt, h) {
		_showSpinner(cmp);
		window.setTimeout(
			$A.getCallback(function () {
				h.helpGetAppList(cmp);
			}), 10
		);
	},

	hideNotification: function (cmp, evt, h){
		$A.util.addClass(cmp.find("cbnotification"), "slds-hide");
		if(evt.getSource().get("v.value") === true) window.localStorage.setItem('resolutionNotify', 'false');
		else window.localStorage.setItem('resolutionNotify', 'true');
	},

	handleUploadFinished: function (cmp, evt, h){
		h.getAttachedDocuments(cmp);
	},

	handleChildEvent: function (cmp, event, helper) {
		event.getParam("param");
	},

	changeLockStatusBudget: function(cmp, evt, h) {
		function callback(cmp, res){
			h.helpSetEditDisabledVariable(cmp, cmp.get('v.app'));
			h.helpSetAdminAccessVariable(cmp);
			let response = res.getReturnValue();
			if(response.cb4__Boolean1__c){
				_CBMessages.fireSuccessMessage('Budget has been locked', null);
			}else{
				_CBMessages.fireSuccessMessage('Budget has been unlocked', null);
			}
		}
		_CBRequest(
			cmp,
			'c.changeLockStatusBudgetServer',
			{
				'app' : cmp.get('v.app')
			},
			'v.app',
			callback,
			null,
			'Failed to lock Budget',
			false
		);
	},

	rejectBudget: function(cmp, evt, h) {
		h.helpInitDataFlow(cmp, true);
		$A.util.addClass(cmp.find("approveModalDiv"), "slds-hide");
		$A.util.addClass(cmp.find("modalBackGround"), "slds-hide");
	},

	initDataFlow: function (cmp, evt, h) {
		h.helpInitDataFlow(cmp, false);
		$A.util.addClass(cmp.find("approveModalDiv"), "slds-hide");
		$A.util.addClass(cmp.find("modalBackGround"), "slds-hide");
	},

	handleStatusChange: function (cmp, evt, h) {
		let outputVariables = evt.getParam("outputVariables");
		let resultStatus = outputVariables[0].value.cb4__Status__c;
		_CBMessages.fireSuccessMessage("Budget was " + (resultStatus === 'Open' ? 'Opened' : resultStatus) + ".");
		if(resultStatus === 'Open'){
			let appId = cmp.get("v.app.Id");
			function redirect(cmp, response) {
				const cmpName = response.getReturnValue();
				let param = {
					recordId : null,
					mode     : 'table'
				};
				_CBRedirect.toComponent(cmpName, param);
			}
			_CBRequest(
				cmp,
				"c.getProperlyCmpNameServer",
				{
					"recordId": appId,
					"dimensionId": null,
					"createNewTag": false
				},
				null,
				redirect,
				null,
				'Redirect Error'
			);
		}else{
			$A.get("e.force:refreshView").fire();
		}
	},

	showCommentModal: function(cmp, evt, h) {
		if(cmp.get('v.app.NextStatus__c') == 'Reject'){
			cmp.set('v.rejectBtnPressed', true);
		}else{
			cmp.set('v.rejectBtnPressed', false);
		}
		h.showCModal(cmp);
	},

	showRejectCommentModal: function(cmp, evt, h){
		cmp.set('v.rejectBtnPressed', true);
		h.showCModal(cmp);
	},

	hideCommentModal: function(cmp, evt, h) {
		$A.util.addClass(cmp.find("approveModalDiv"), "slds-hide");
		$A.util.addClass(cmp.find("modalBackGround"), "slds-hide");
		cmp.set('v.rejectBtnPressed', false);
	},

	historyTabInit: function(cmp, evt, h) {

		function getFormattedDate(ldate){
			let year = ldate.toLocaleString("default", { year: "numeric" });
			let month = ldate.toLocaleString("default", { month: "2-digit" });
			let day = ldate.toLocaleString("default", { day: "2-digit" });
			return year + "-" + month + "-" + day;
		}
		let date = new Date();
		date.setDate(date.getDate() + 1);
		cmp.set('v.endHistoryDate', getFormattedDate(date));
		date.setDate(date.getDate() - 8);
		cmp.set('v.startHistoryDate', getFormattedDate(date));

		h.helpGetHistory(cmp);
	},

	applyHistoryFilter: function(cmp, evt, h) {
		h.helpGetHistory(cmp);
	},

	lockSublineDeletion: function(cmp, evt, h) {
		cmp.set('v.disableDeleteSublines', true);
	}
});