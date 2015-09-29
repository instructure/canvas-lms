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
      var submission = this.state.submission;
      return (submission && submission.grade) ? submission.grade : '-';
    },

    isSubmissionGradedAsNull() {
      return this.state.submission && _.isNull(this.state.submission.grade);
    },

    sendSubmission() {
      var submission = {
        userId: this.props.rowData.enrollment.user_id,
        assignmentId: this.props.cellData.id,
        postedGrade: this.state.gradeToPost
      };

      SubmissionsActions.updateGrade(submission);
      this.setState({gradeToPost: null});
    },
  };

  return GradeCellMixin;
});
