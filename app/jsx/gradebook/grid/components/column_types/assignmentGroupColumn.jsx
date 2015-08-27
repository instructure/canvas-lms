/** @jsx React.DOM */
define([
  'bower/reflux/dist/reflux',
  'react',
  'compiled/grade_calculator',
  'compiled/gradebook2/gradeFormatter',
  '../../stores/gradebookToolbarStore',
  '../../stores/submissionsStore',
  '../../helpers/currentOrFinal',
  'underscore'
], function (Reflux, React, GradeCalculator, GradeFormatter,
             GradebookToolbarStore, SubmissionsStore, currentOrFinal, _) {
  var AssignmentGroupColumn = React.createClass({

    propTypes: {
      cellData: React.PropTypes.any.isRequired,
      rowData: React.PropTypes.object.isRequired
    },

    mixins: [
      Reflux.connect(GradebookToolbarStore, 'toolbarOptions')
    ],

    render() {
      var assignmentGroupsIndex, submissions, assignmentGroups,
      assignmentGroupGradeData, assignmentGroup, gradeFormatter, toolbarOptions,
      groupSums, relevantAssignmentGroups, currentAssignmentGroup;

      submissions = this.props.rowData.submissions;
      submissions = SubmissionsStore.submissionsInCurrentPeriod(submissions);

      assignmentGroupsIndex = this.props.cellData;
      assignmentGroups = this.props.rowData.assignmentGroups;
      currentAssignmentGroup = assignmentGroups[assignmentGroupsIndex];
      relevantAssignmentGroups = SubmissionsStore.assignmentGroupsForSubmissions(submissions, assignmentGroups);

      toolbarOptions = this.state.toolbarOptions;

      if (this.groupIsInCurrentPeriod(currentAssignmentGroup, relevantAssignmentGroups)) {
        assignmentGroupGradeData = GradeCalculator.calculate(submissions, assignmentGroups);
        groupSums = assignmentGroupGradeData.group_sums[assignmentGroupsIndex];
        assignmentGroup = groupSums[currentOrFinal(toolbarOptions)];
      } else {
        assignmentGroup = {score: 0, possible: 0};
      }

      gradeFormatter = new GradeFormatter(assignmentGroup.score, assignmentGroup.possible, false);

      return (
        <div className='gradebook-cell' ref='cell'>
          { gradeFormatter.toString() }
        </div>
      );
    },

    groupIsInCurrentPeriod(assignmentGroup, relevantAssignmentGroups) {
      return _.contains(relevantAssignmentGroups, assignmentGroup);
    }
  });

  return AssignmentGroupColumn;
});
