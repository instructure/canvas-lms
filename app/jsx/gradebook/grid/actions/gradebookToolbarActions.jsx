define([
  'reflux',
  'jquery',
  'underscore',
  'i18n!gradebook2',
  'compiled/userSettings',
  'jsx/gradebook/grid/constants'
], function (Reflux, $, _, I18n, userSettings, GradebookConstants) {

  var GradebookToolbarActions = Reflux.createActions({
    toggleStudentNames: { asyncResult: false },
    toggleNotesColumn: { asyncResult: false },
    toggleTreatUngradedAsZero: { asyncResult: false },
    toggleTotalColumnInFront: { asyncResult: false },
    arrangeColumnsBy: { asyncResult: false },
    showTotalGradeAsPoints: { asyncResult: false },
    hideTotalDisplayWarning: { asyncResult: false }
  });

  GradebookToolbarActions.toggleStudentNames.preEmit = (hideStudentNames) => {
    userSettings.contextSet('hideStudentNames', hideStudentNames);
  };

  GradebookToolbarActions.toggleTreatUngradedAsZero.preEmit = (treatUngradedAsZero) => {
    userSettings.contextSet('treatUngradedAsZero', treatUngradedAsZero);
  };

  GradebookToolbarActions.toggleTotalColumnInFront.preEmit = (totalColumnInFront) => {
    userSettings.contextSet('total_column_in_front', totalColumnInFront);
  };

  GradebookToolbarActions.arrangeColumnsBy.preEmit = (criteria) => {
    var columnOrderUrl = GradebookConstants.gradebook_column_order_settings_url;
    var arrangeColumnsData = { column_order: { sortType: criteria } };
    $.ajaxJSON(columnOrderUrl, 'POST', arrangeColumnsData);
  };

  GradebookToolbarActions.showTotalGradeAsPoints.preEmit = (showAsPoints) => {
    $.ajaxJSON(
      GradebookConstants.setting_update_url, "PUT",
      { show_total_grade_as_points: showAsPoints }
    );
  };

  GradebookToolbarActions.hideTotalDisplayWarning.preEmit = (hideWarning) => {
    userSettings.contextSet('warned_about_totals_display', hideWarning);
  };

  GradebookToolbarActions.toggleNotesColumn.preEmit = (hideNotesColumn) => {
    var url = GradebookConstants.custom_column_url.replace(/:id/, GradebookConstants.teacher_notes.id);
    $.ajaxJSON(url, 'PUT', { 'column[hidden]': hideNotesColumn });
  };

  return GradebookToolbarActions;
});
