define([
  'bower/reflux/dist/reflux',
  'underscore',
  'jquery',
  '../actions/submissionsActions',
  '../stores/assignmentGroupsStore',
  '../stores/gradingPeriodsStore',
  'compiled/gradebook2/GRADEBOOK_TRANSLATIONS',
  'compiled/jquery.rails_flash_notifications'
], function (Reflux, _, $, SubmissionsActions, AssignmentGroupsStore,
             GradingPeriodsStore, GRADEBOOK_TRANSLATIONS) {

  var SubmissionsStore = Reflux.createStore({
    listenables: [SubmissionsActions],

    getInitialState() {
      this.submissions = {
        data: null,
        error: null,
        selected: null
      };
      return this.submissions;
    },

    onUpdateGradeCompleted(postedGrade, response) {
      var userSubmissions =
        _.find(this.submissions.data, (s) => s.user_id === postedGrade.userId)
        .submissions;

      var submission = _.find(userSubmissions, (s) => s.id === response.id);

      if (submission) {
        var submissionIndex = _.indexOf(_.pluck(userSubmissions, 'id'), response.id);
        userSubmissions[submissionIndex] = response;
      } else {
        userSubmissions.push(response);
      }

      this.trigger(this.submissions);
    },

    onUpdateGradeFailed() {
      $.flashError(GRADEBOOK_TRANSLATIONS.submission_update_error);
    },

    onLoadFailed(error) {
      this.submissions.error = error;
      this.trigger(this.submissions);
    },

    onLoadCompleted(submissions) {
      this.submissions.data = submissions;
      this.trigger(this.submissions);
    },

    updateSubmissions(currentSubs, updatedSubs) {
      var mergedSubmissions = _.extend(
        _.indexBy(currentSubs, 'id'),
        _.indexBy(updatedSubs, 'id')
      );
      return _.values(mergedSubmissions);
    },

    onUpdatedSubmissionsReceived(updatedSubs) {
      var subIds, updatedSubsForGroup;

      this.submissions.data = _.map(this.submissions.data, (submissionGroup) => {
        subIds = _.pluck(submissionGroup.submissions, 'id');
        updatedSubsForGroup = _.filter(updatedSubs, sub => _.contains(subIds, sub.id));
        submissionGroup.submissions = this.updateSubmissions(submissionGroup.submissions, updatedSubsForGroup);
        return submissionGroup;
      });

      this.trigger(this.submissions);
    },

    /*
       ([Submission], [Assignment]) -> [Submission]
       Given a list of submissions and a list of assignments, filters out the
       submissions which don't belong to an assignment in the list of
       assignments
    */
    filterSubmissions(submissions, assignments) {
      var assignmentIds, filteredSubmissions;

      assignmentIds = _.map(assignments, assignment => assignment.id);
      filteredSubmissions = _.filter(submissions, submission =>
        _.contains(assignmentIds, submission.assignment_id));

      return filteredSubmissions;
    },

    /*
       ([Submission], [AssignmentGroup]) -> [AssignmentGroup]
       Given a list of submissions and assignment groups, Returns the assignment
       groups which have a submission in the list.
    */
    assignmentGroupsForSubmissions(submissions, assignmentGroups) {
      var assignmentIds, relevantGroups;

      assignmentIds = _.map(submissions, s => s.assignment_id);
      relevantGroups = _.filter(assignmentGroups, assignmentGroup =>
        _.filter(assignmentGroup.assignments, a =>
          _.contains(assignmentIds, a.id)).length > 0
      );

      return relevantGroups;
    },

    /*
       [Submission] -> [Assignment]
       Given a list of submissions, returns a list of assignments which those
       submissions belong to. Assignments are not guaranteed to be unique. If
       uniqueness is required, use `_.uniq` on the result.
    */
    assignmentsForSubmissions(submissions) {
      var assignmentIds, allAssignments;
      assignmentIds = _.map(submissions, submission => submission.assignment_id);
      allAssignments = AssignmentGroupsStore.assignments(assignmentIds);

      return allAssignments;
    },

    /*
       ([Submission], GradingPeriod) -> [Submission]
       Takes a list of submissions and returns the submissions in that list
       which are in the given grading period
    */
    submissionsInPeriod(submissions, period) {
      var periodAssignments, periodSubmissions, assignments;

      assignments = this.assignmentsForSubmissions(submissions);
      periodAssignments = GradingPeriodsStore.assignmentsInPeriod(assignments, period);
      periodSubmissions = this.filterSubmissions(submissions, periodAssignments);

      return periodSubmissions;
    },

    /*
       [Submission] -> [Submission]
       Takes a list of submissions and returns the submissions in that list
       which are in the current grading period
    */
    submissionsInCurrentPeriod(submissions) {
      var currentPeriod = GradingPeriodsStore.selected();

      return this.submissionsInPeriod(submissions, currentPeriod);
    }
  });

  return SubmissionsStore;
});
