/** @jsx React.DOM */
define([
  'underscore',
  '../actions/submissionsActions'
], function (_, SubmissionsActions) {
  var GradeCellMixin = {
    getInitialState() {
      return {
        submission: this.props.submission,
      };
    },

    componentWillReceiveProps(nextProps) {
      this.setState({submission: nextProps.submission});
    },

    getDisplayGrade() {
      var submission = this.props.cellData;
      return (submission && submission.grade) ? submission.grade : '-';
    },

    isSubmissionGradedAsNull() {
      return this.props.cellData && _.isNull(this.props.cellData.grade);
    },

    sendSubmission() {
      var submission = {
        userId: this.props.rowData.student.id,
        assignmentId: this.props.columnData.assignment.id,
        postedGrade: this.state.gradeToPost
      };

      SubmissionsActions.updateGrade(submission);
      this.setState({gradeToPost: null});
    },
  };

  return GradeCellMixin;
});
