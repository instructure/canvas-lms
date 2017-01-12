define([
  'bower/reflux/dist/reflux',
  'underscore',
  '../actions/assignmentGroupsActions',
  'jsx/shared/helpers/dateHelper',
  '../constants'
], function (Reflux, _, AssignmentGroupsActions, DateHelper, GradebookConstants) {
  var AssignmentGroupsStore = Reflux.createStore({
    listenables: [AssignmentGroupsActions],

    init() {
      this.state = {
        data: null,
        error: null
      };
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

    onLoadCompleted(json) {
      var assignmentGroups;
      this.setNoPointsWarning(json);
      assignmentGroups = this.formatAssignmentGroups(json);
      this.state.data = assignmentGroups;
      this.trigger(this.state);
    },

    onReplaceAssignmentGroups(updatedAssignmentGroups) {
      this.state.data = updatedAssignmentGroups;
      this.trigger(this.state);
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
      var assignments = _.flatten(_.pluck(this.state.data, 'assignments')),
        assignment = _.find(assignments, assignment => updatedAssignment.id === assignment.id);

      assignment.muted = updatedAssignment.muted;
      this.trigger(this.state);
    },

    formatAssignmentGroups(groups) {
      return _.map(groups, (group) => {
        group.assignments = _.chain(group.assignments)
          .reject(assignment => _.contains(assignment.submission_types, 'not_graded'))
          .map(assignment => this.formatAssignment(assignment, group))
          .value();

        return group;
      });
    },

    formatAssignment(assignment, assignmentGroup) {
      assignment = DateHelper.parseDates(assignment, GradebookConstants.ASSIGNMENT_DATES);
      assignment.assignment_group_position = assignmentGroup.position;
      assignment.speedgrader_url = GradebookConstants.context_url + '/gradebook/speed_grader?assignment_id=' + assignment.id;
      assignment.submissions_downloads = 0;
      assignment.shouldShowNoPointsWarning = assignmentGroup.shouldShowNoPointsWarning;

      if (assignment.has_overrides) {
        assignment.overrides = _.map(
          assignment.overrides,
          override => DateHelper.parseDates(override, GradebookConstants.OVERRIDE_DATES)
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

      assignmentGroups = this.state.data;
      allAssignments = _.map(assignmentGroups, group => group.assignments);
      allAssignments = _.flatten(allAssignments);

      assignments = _.map(assignmentIds, assignmentId =>
                          _.find(allAssignments, assignment =>
                                 assignment.id === assignmentId));

      assignments = _.reject(assignments, assignment => assignment === undefined);
      return assignments;
    }
  });

  return AssignmentGroupsStore;
});
