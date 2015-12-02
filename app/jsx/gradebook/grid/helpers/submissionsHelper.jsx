define([
  'underscore',
], function (_) {
  let SubmissionsHelper = {
    submissionsForAssignment: function(submissionGroups, assignment) {
      let submissions = this.extractSubmissions(submissionGroups);
      let subsForAssignment = submissions[assignment.id]
      return subsForAssignment ? _.indexBy(subsForAssignment, 'user_id') : {};
    },

    extractSubmissions: function(submissionGroups) {
      return _.chain(submissionGroups)
        .values()
        .flatten()
        .pluck('submissions')
        .flatten()
        .groupBy('assignment_id')
        .value();
    }
  };
  return SubmissionsHelper;
});
