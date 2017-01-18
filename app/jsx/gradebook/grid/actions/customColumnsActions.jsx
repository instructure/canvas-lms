define([
  'bower/reflux/dist/reflux',
  'underscore',
  'jsx/gradebook/grid/constants',
  'jsx/gradebook/grid/helpers/depaginator',
  'jquery',
  'i18n!gradebook2',
  'jquery.ajaxJSON'
], function(Reflux, _, GradebookConstants, depaginate, $, I18n) {
  let CustomColumnsActions = Reflux.createActions({
    load:              { asyncResult: true },
    loadColumnData:    { asyncResult: true },
    loadTeacherNotes:  { asyncResult: true }
  });

  let onTeacherNotesCompleted = function(notesData) {
    GradebookConstants.teacher_notes = notesData;
    this.completed();
  };

  let loadTeacherNotesFromServer = function() {
    let data, method, onComplete, url;

    url = GradebookConstants.custom_columns_url;
    method = 'POST';
    data = {
      'column[title]': I18n.t('notes', 'Notes'),
      'column[position]': 1,
      'column[teacher_notes]': true
    };

    $.ajaxJSON(url, method, data)
      .done(onTeacherNotesCompleted.bind(this));
  };

  let loadTeacherNotesFromENV = function() {
    let teacherNotesUrl =
      GradebookConstants
        .custom_column_data_url
        .replace(/:id/, GradebookConstants.teacher_notes.id);

    depaginate(teacherNotesUrl, { include_hidden: true })
      .then(this.completed);
  };

  let loadColumnsData = function(columns) {
    _.each(columns, function(column) {
      if (!column.hidden) {
        CustomColumnsActions.loadColumnData(column.id);
      }

      this.completed(columns);
    }.bind(this));
  };

  CustomColumnsActions.loadTeacherNotes.listen(function() {
    if (!GradebookConstants.teacher_notes) {
      (loadTeacherNotesFromServer.bind(this))();
    } else {
      (loadTeacherNotesFromENV.bind(this))();
    }
  });

  CustomColumnsActions.load.listen(function() {
    $.getJSON(GradebookConstants.custom_columns_url)
      .done(loadColumnsData.bind(this))
      .fail(this.failed);
  });

  CustomColumnsActions.loadColumnData.listen(function(columnId) {
    let url;

    url = GradebookConstants.custom_column_data_url.replace(/:id/, columnId);

    $.getJSON(url)
      .done(data => this.completed(data, columnId))
      .fail((jqxhr, textStatus, error) => this.failed(error));
  });

  return CustomColumnsActions;
});
