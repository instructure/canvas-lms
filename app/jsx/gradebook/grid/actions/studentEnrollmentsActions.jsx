define([
  'bower/reflux/dist/reflux',
  'compiled/userSettings',
  'jsx/gradebook/grid/constants',
  'jsx/gradebook/grid/helpers/enrollmentsUrlHelper',
  'jsx/gradebook/grid/helpers/depaginator',
], function (Reflux, UserSettings, GradebookConstants, EnrollmentsUrlHelper, depaginate) {

  var StudentEnrollmentsActions = Reflux.createActions({
    load: { asyncResult: true },
    search: { asyncResult: false }
  });

  function showConcluded() {
    return UserSettings.contextGet('showConcludedEnrollments') ||
      GradebookConstants.course_is_concluded;
  }

  function showInactive() {
    return UserSettings.contextGet('showInactiveEnrollments');
  }

  StudentEnrollmentsActions.load.listen(function() {
    var self = this,
      urlKey = EnrollmentsUrlHelper({
        showConcluded: showConcluded(),
        showInactive: showInactive()
      });

    depaginate(GradebookConstants[urlKey])
      .then(self.completed)
      .fail((jqxhr, textStatus, error) => self.failed(error));
  });

  return StudentEnrollmentsActions;
});
