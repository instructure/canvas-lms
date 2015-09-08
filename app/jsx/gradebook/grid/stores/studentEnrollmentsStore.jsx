define([
  'bower/reflux/dist/reflux',
  'underscore',
  '../actions/studentEnrollmentsActions'
], function (Reflux, _, StudentEnrollmentsActions) {
  var StudentEnrollmentsStore = Reflux.createStore({
    listenables: [StudentEnrollmentsActions],

    init() {
      this.state = {
        data: null,
        error: null,
        all: null
      }
    },

    getInitialState() {
      return this.state;
    },

    onLoadFailed(error) {
      this.state.error = error;
      this.trigger(this.studentEnrollments);
    },

    onLoadCompleted(studentEnrollmentData) {
      this.state.all = studentEnrollmentData;
      this.state.data = studentEnrollmentData;
      this.trigger(this.state);
    },

    onSearch(searchTerm) {
      var pattern = new RegExp(searchTerm.toLowerCase()), predicate = function(enrollment) {
        var user = enrollment.user;
        return (user.name && user.name.toLowerCase().match(pattern)) ||
          (user.sis_login_id && user.sis_login_id.toLowerCase().match(pattern)) ||
          (user.login_id && user.login_id.toLowerCase().match(pattern));
      };

      this.state.data = _.filter(this.state.all, predicate);
      this.trigger(this.state);
    }
  });

  return StudentEnrollmentsStore;
});
