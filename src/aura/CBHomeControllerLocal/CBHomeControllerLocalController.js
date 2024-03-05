({
	runInit: function(cmp, evt, h) {
		h.helpGetInitialSO(cmp);
		h.helpApplyLockSettings(cmp);
	},
	refreshLockedPeriods: function(cmp, evt, h) {
		h.helpSetLockedPeriodSO(cmp);
	},
	refreshCurrentUpdateStatuses: function(cmp, evt, h) {
		h.helpApplyLockSettings(cmp);
	},
	lockBudgetsTill: function(cmp, evt, h) {
		h.helpLockBudgetPeriods(cmp);
	},
	handleMainMenu: function(cmp, evt, h) {
		let selectedMenuItemValue = evt.getParam("value");
		h.helpHandleBLockMenu(cmp, selectedMenuItemValue);
	},
	runBudgetDataGeneration: function(cmp, evt, h) {
		h.helpRunBudgetDataFromStagersGeneration(cmp);
	}
});