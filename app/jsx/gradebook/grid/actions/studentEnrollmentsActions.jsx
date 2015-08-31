define([
  'bower/reflux/dist/reflux',
  'compiled/userSettings',
  'jsx/gradebook/grid/constants',
  'jsx/gradebook/grid/helpers/depaginator'
], function (Reflux, UserSettings, GradebookConstants, depaginate) {
  var StudentEnrollmentsActions = Reflux.createActions({
    load: { asyncResult: true },
    search: { asyncResult: false }
  })

  StudentEnrollmentsActions.load.listen(function() {
    var showConcludedEnrollments = UserSettings.contextGet('show_concluded_enrollments'),
      self = this,
      studentsUrl;

    studentsUrl = showConcludedEnrollments ?
      GradebookConstants.students_url_with_concluded_enrollments :
      GradebookConstants.students_url;

    depaginate(studentsUrl)
      .then(self.completed)
      .fail((jqxhr, textStatus, error) => self.failed(error));
  });

  return StudentEnrollmentsActions;
});
