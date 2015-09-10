define([
  'bower/reflux/dist/reflux',
  'jquery',
  'underscore',
  'i18n!gradebook2',
  'compiled/userSettings'
], function (Reflux, $, _, I18n, userSettings) {
  var GradebookToolbarActions = Reflux.createActions([
    'toggleStudentNames',
    'toggleNotesColumn',
    'toggleTreatUngradedAsZero',
    'toggleShowAttendanceColumns',
    'toggleTotalColumnInFront',
    'arrangeColumnsBy'
  ]);

  GradebookToolbarActions.toggleStudentNames.preEmit = (hideStudentNames) => {
    userSettings.contextSet('hideStudentNames', hideStudentNames);
  };

  GradebookToolbarActions.toggleNotesColumn.preEmit = (hideNotesColumn) => {
    var options = ENV.GRADEBOOK_OPTIONS;
    if (!options.teacher_notes) {
      $.ajaxJSON(options.custom_columns_url, 'POST', {
        'column[title]': I18n.t('notes', 'Notes'),
        'column[position]': 1,
        'column[teacher_notes]': true
      });
    } else {
      var url = options.custom_column_url.replace(/:id/, options.teacher_notes.id);
      $.ajaxJSON(url, 'PUT', { 'column[hidden]': hideNotesColumn } );
    }
  };

  GradebookToolbarActions.toggleTreatUngradedAsZero.preEmit = (treatUngradedAsZero) => {
    userSettings.contextSet('treatUngradedAsZero', treatUngradedAsZero);
  };

  GradebookToolbarActions.toggleShowAttendanceColumns.preEmit = (showAttendanceColumns) => {
    userSettings.contextSet('showAttendanceColumns', showAttendanceColumns);
  };

  GradebookToolbarActions.toggleTotalColumnInFront.preEmit = (totalColumnInFront) => {
    userSettings.contextSet('total_column_in_front', totalColumnInFront);
  };

  GradebookToolbarActions.arrangeColumnsBy.preEmit = (criteria) => {
    var columnOrderUrl = ENV.GRADEBOOK_OPTIONS.gradebook_column_order_settings_url;
    var arrangeColumnsData = { column_order: { sortType: criteria } };
    $.ajaxJSON(columnOrderUrl, 'POST', arrangeColumnsData);
  };

  return GradebookToolbarActions;
});
