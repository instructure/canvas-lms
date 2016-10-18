define([
  'reflux',
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

    formatTitle(assignmentGroupScore) {
      return assignmentGroupScore.score + " / " + assignmentGroupScore.possible;
    },

    render() {
      var assignmentGroupsIndex, submissions, assignmentGroups,
      assignmentGroupGradeData, assignmentGroup, gradeFormatter, toolbarOptions,
      groupSums, relevantAssignmentGroups, currentAssignmentGroup, assignmentGroupScore;

      submissions = this.props.cellData.submissions;
      submissions = _.flatten(_.values(submissions));
      submissions = SubmissionsStore.submissionsInCurrentPeriod(submissions);

      let assignmentGroupColumnId = this.props.cellData.columnId;
      assignmentGroups = this.props.rowData.assignmentGroups;
      currentAssignmentGroup = this.props.cellData.assignmentGroup;
      relevantAssignmentGroups = SubmissionsStore.assignmentGroupsForSubmissions(submissions, assignmentGroups);

      toolbarOptions = this.state.toolbarOptions;

      if (this.groupIsInCurrentPeriod(currentAssignmentGroup, relevantAssignmentGroups)) {
        assignmentGroupGradeData = GradeCalculator.calculate(submissions, assignmentGroups);
        groupSums = assignmentGroupGradeData.group_sums;
        groupSums = _.find(groupSums, sum => sum.group.columnId === assignmentGroupColumnId);
        assignmentGroupScore = groupSums[currentOrFinal(toolbarOptions)];
      } else {
        assignmentGroupScore = {score: 0, possible: 0};
      }

      gradeFormatter = new GradeFormatter(assignmentGroupScore.score, assignmentGroupScore.possible, false);

      return (
        <div className='assignment-group-grade' title={this.formatTitle(assignmentGroupScore)} ref='cell'>
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
