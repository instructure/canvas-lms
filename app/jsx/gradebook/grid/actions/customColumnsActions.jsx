define([
  'bower/reflux/dist/reflux',
  'jsx/gradebook/grid/constants',
  'jsx/gradebook/grid/helpers/depaginator',
  'jquery',
  'i18n!gradebook2',
  'jquery.ajaxJSON'
], function (Reflux, GradebookConstants, depaginate, $, I18n) {
  var CustomColumnsActions = Reflux.createActions({
    loadTeacherNotes: { asyncResult: true },
    updateTeacherNote: { asyncResult: false }
  })

  CustomColumnsActions.loadTeacherNotes.listen(function() {
    var self = this;

    if (!GradebookConstants.teacher_notes) {
      $.ajaxJSON(GradebookConstants.custom_columns_url, 'POST', {
        'column[title]': I18n.t('notes', 'Notes'),
        'column[position]': 1,
        'column[teacher_notes]': true
      })
        .done(function(notesData) {
          GradebookConstants.teacher_notes = notesData;
          self.completed();
        });
    } else {
      var teacherNotesUrl =
        GradebookConstants
          .custom_column_data_url
          .replace(/:id/, GradebookConstants.teacher_notes.id);

      depaginate(teacherNotesUrl, { include_hidden: true })
        .then(self.completed);
    }
  });

  return CustomColumnsActions;
});
