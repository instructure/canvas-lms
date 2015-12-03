define([
  'bower/reflux/dist/reflux',
  'underscore',
  'jsx/gradebook/grid/actions/studentEnrollmentsActions',
  'jsx/gradebook/grid/stores/sectionsStore'
], function (Reflux, _, StudentEnrollmentsActions, SectionsStore) {
  var StudentEnrollmentsStore = Reflux.createStore({
    listenables: [
      StudentEnrollmentsActions
    ],

    init() {
      this.listenTo(SectionsStore, this.onSectionSelected);
      this.state = {
        data: null,
        error: null,
        all: null
      }
    },

    getInitialState() {
      if (this.state === undefined) {
        this.init();
      }

      return this.state;
    },

    onLoadFailed(error) {
      this.state.error = error;
      this.trigger(this.state);
    },

    onLoadCompleted(studentEnrollmentData) {
      this.state.all = studentEnrollmentData;
      this.state.inCurrentSection = this.studentsInSection(SectionsStore.selected());
      this.state.data = this.state.inCurrentSection;

      this.trigger(this.state);
    },

    onSearch(searchTerm) {
      this.applySearch(searchTerm);
      this.trigger(this.state);
    },

    onSectionSelected() {
      var selectedSection, studentsInSection;

      selectedSection = SectionsStore.selected();
      studentsInSection = this.studentsInSection(selectedSection);

      if (studentsInSection === null || studentsInSection === undefined) {
        return;
      }

      this.state.inCurrentSection = studentsInSection;
      this.state.data = studentsInSection;
      this.applySearch(this.state.searchTerm);
      this.trigger(this.state);
    },

    applySearch(searchTerm) {
      if (searchTerm !== null && searchTerm !== undefined) {
        var pattern = new RegExp(searchTerm.toLowerCase()), predicate = function(enrollment) {
          var user = enrollment.user;
          return (user.name && user.name.toLowerCase().match(pattern)) ||
            (user.sis_login_id && user.sis_login_id.toLowerCase().match(pattern)) ||
            (user.login_id && user.login_id.toLowerCase().match(pattern));
        };

        this.state.searchTerm = searchTerm;
        this.state.data = _.filter(this.state.inCurrentSection, predicate);
      }
    },

    studentsInSection(selectedSection) {
      var students, filteredStudents;

      students = this.state.all;

      if (_.isUndefined(students)) {
        return undefined;
      } else if (_.isUndefined(selectedSection) || selectedSection.id === '0'){
        return students;
      }

      filteredStudents = _.filter(students, student => student.course_section_id === selectedSection.id);

      return filteredStudents;
    }
  });

  return StudentEnrollmentsStore;
});
