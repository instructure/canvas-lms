define([
  'bower/reflux/dist/reflux',
  'compiled/userSettings',
  '../constants',
  '../helpers/depaginator',
  'jquery',
  'jquery.ajaxJSON'
], function (Reflux, UserSettings, GradebookConstants, depaginate, $) {
  var StudentEnrollmentsActions = Reflux.createActions({
    load: { asyncResult: true },
    search: { asyncResult: false }
  })

  StudentEnrollmentsActions.load.listen(function() {
    var showConcludedEnrollments = UserSettings.contextGet('show_concluded_enrollments'),
      self = this,
      studentsUrl;

    if (showConcludedEnrollments) {
      studentsUrl = ENV.GRADEBOOK_OPTIONS.students_url_with_concluded_enrollments;
    } else {
      studentsUrl = ENV.GRADEBOOK_OPTIONS.students_url;
    }

    depaginate(studentsUrl)
      .then(self.completed)
      .fail((jqxhr, textStatus, error) => self.failed(error));
  });

  return StudentEnrollmentsActions;
});
