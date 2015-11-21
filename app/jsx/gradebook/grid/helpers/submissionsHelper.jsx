define([
  'underscore',
], function (_) {
  var SubmissionsHelper = {
    submissionsForAssignment: function(submissionGroups, assignmentId) {
      var submissions = this.extractSubmissions(submissionGroups);
      return _.filter(
        submissions,
        submission => submission.assignment_id.toString() === assignmentId.toString()
      );
    },

    extractSubmissions: function(submissionGroups) {
      return _.chain(submissionGroups)
        .values()
        .flatten()
        .pluck('submissions')
        .flatten()
        .value();
    }
  };
  return SubmissionsHelper;
});