define([
  'bower/reflux/dist/reflux',
  'underscore',
  '../actions/studentEnrollmentsActions'
], function (Reflux, _, StudentEnrollmentsActions) {
  var StudentEnrollmentsStore = Reflux.createStore({
    listenables: [StudentEnrollmentsActions],

    getInitialState() {
      this.studentEnrollments = {
        data: null,
        error: null,
        all: null
      };

      return this.studentEnrollments;
    },

    onLoadFailed(error) {
      this.studentEnrollments.error = error;
      this.trigger(this.studentEnrollments);
    },

    onLoadCompleted(studentEnrollmentData) {
      this.studentEnrollments.all = studentEnrollmentData;
      this.studentEnrollments.data = studentEnrollmentData;
      this.trigger(this.studentEnrollments);
    },

    onSearch(searchTerm) {
      var pattern = new RegExp(searchTerm.toLowerCase()), predicate = function(enrollment) {
        var user = enrollment.user;
        return (user.name && user.name.toLowerCase().match(pattern)) ||
          (user.sis_login_id && user.sis_login_id.toLowerCase().match(pattern)) ||
          (user.login_id && user.login_id.toLowerCase().match(pattern));
      };

      this.studentEnrollments.data = _.filter(this.studentEnrollments.all, predicate);
      this.trigger(this.studentEnrollments);
    }
  });

  return StudentEnrollmentsStore;
});
