define([
  'underscore',
], function (_) {
  let EnrollmentsHelper = {
    studentsThatCanSeeAssignment: function(enrollments, assignment) {
      let visibleStudentIds = assignment.assignment_visibility;
      let students = this.students(enrollments);
      return _.pick(students, visibleStudentIds);
    },

    students: function(enrollments) {
      let studentEnrollments = this.studentEnrollments(enrollments);
      let students = _.pluck(studentEnrollments, 'user');
      return _.indexBy(students, 'id');
    },

    studentEnrollments: function(enrollments) {
      return _.where(enrollments, { type: 'StudentEnrollment' });
    }
  };
  return EnrollmentsHelper;
});
