define([
  'bower/reflux/dist/reflux',
  'underscore',
  '../actions/assignmentGroupsActions',
  '../helpers/datesHelper',
  '../constants'
], function (Reflux, _, AssignmentGroupsActions, DatesHelper, GradebookConstants) {
  var AssignmentGroupsStore = Reflux.createStore({
    listenables: [AssignmentGroupsActions],

    getInitialState() {
      this.assignmentGroups = {
        data: null,
        error: null
      };
      return this.assignmentGroups;
    },

    onLoadFailed(error) {
      this.assignmentGroups.error = error;
      this.trigger(this.assignmentGroups);
    },

    onLoadCompleted(json) {
      var assignmentGroups;
      this.setNoPointsWarning(json);
      assignmentGroups = this.formatAssignmentGroups(json);
      this.assignmentGroups.data = assignmentGroups;
      this.trigger(this.assignmentGroups);
    },

    onReplaceAssignmentGroups(updatedAssignmentGroups) {
      this.assignmentGroups.data = updatedAssignmentGroups;
      this.trigger(this.assignmentGroups);
    },

    setNoPointsWarning(assignmentGroups) {
      _.each(assignmentGroups, (group) => {
        var pointsPossible = _.inject(group.assignments, (sum, assignment) => {
          return sum + (assignment.points_possible || 0);
        }, 0);

        group.shouldShowNoPointsWarning = (pointsPossible === 0);
      });
    },

    onReplaceAssignment(updatedAssignment) {
      var assignmentGroups = this.assignmentGroups.data,
          assignments = _.flatten(_.pluck(assignmentGroups, 'assignments')),
          assignment = _.find(assignments, assignment => updatedAssignment.id === assignment.id);

      assignment.muted = updatedAssignment.muted;
      this.assignmentGroups.data = assignmentGroups;
      this.trigger(this.assignmentGroups);
    },

    formatAssignmentGroups(groups) {
      return _.map(groups, (group) => {
        group.assignments = _.map(
          group.assignments,
          assignment => this.formatAssignment(assignment, group)
        );

        return group;
      });
    },

    formatAssignment(assignment, assignmentGroup) {
      assignment = DatesHelper.parseDates(assignment, GradebookConstants.ASSIGNMENT_DATES);
      assignment.assignment_group_position = assignmentGroup.position;
      assignment.speedgrader_url = GradebookConstants.context_url + '/gradebook/speed_grader?assignment_id=' + assignment.id;
      assignment.submissions_downloads = 0;
      assignment.shouldShowNoPointsWarning = assignmentGroup.shouldShowNoPointsWarning;

      if (assignment.has_overrides) {
        assignment.overrides = _.map(
          assignment.overrides,
          override => DatesHelper.parseDates(override, GradebookConstants.OVERRIDE_DATES)
        );
      }
      return assignment;
    },

    /*
      ["id"] -> [Assignment]
      Given a list of assignment ids, retrieves the specified assignments
    */
    assignments(assignmentIds) {
      var assignmentGroups, assignments, allAssignments;

      assignmentGroups = this.assignmentGroups.data;
      allAssignments = _.map(assignmentGroups, group => group.assignments);
      allAssignments = _.flatten(allAssignments);

      assignments = _.map(assignmentIds, assignmentId =>
                          _.find(allAssignments, assignment =>
                                 assignment.id === assignmentId));

      return assignments;
    }
  });

  return AssignmentGroupsStore;
});
