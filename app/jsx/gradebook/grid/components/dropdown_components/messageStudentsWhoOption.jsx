define([
  'react',
  'underscore',
  'jsx/gradebook/grid/components/dropdown_components/headerDropdownOption',
  'jsx/gradebook/grid/helpers/submissionsHelper',
  'jsx/gradebook/grid/helpers/enrollmentsHelper',
  'timezone',
  'jsx/gradebook/grid/helpers/messageStudentsWhoHelper',
  'message_students'
], function (React, _, HeaderDropdownOption, SubmissionsHelper, EnrollmentsHelper, tz, MessageStudentsWhoHelper) {

  let MessageStudentsWhoOption = React.createClass({
    propTypes: {
      title: React.PropTypes.string.isRequired,
      assignment: React.PropTypes.object.isRequired,
      enrollments: React.PropTypes.array.isRequired,
      submissions: React.PropTypes.object.isRequired
    },

    openDialog() {
      let studentsForAssignment = EnrollmentsHelper.studentsThatCanSeeAssignment(this.props.enrollments, this.props.assignment);
      let students = this.combineStudentsWithScores(studentsForAssignment);
      let settings = MessageStudentsWhoHelper.settings(this.props.assignment, students);
      messageStudents(settings);
    },

    combineStudentsWithScores(students) {
      let submissions = SubmissionsHelper.submissionsForAssignment(this.props.submissions, this.props.assignment);
      return _.map(students, function(student, studentId) {
        let studentWithScore = _.extend({ score: null, submitted_at: null }, student);
        let submission = submissions[studentId];
        if (submission) {
          studentWithScore.score = submission.score;
          studentWithScore.submitted_at = tz.parse(submission.submitted_at);
        }
        return studentWithScore;
      });
    },

    render() {
      return(
        <HeaderDropdownOption
          handleClick={this.openDialog}
          key={'messageStudentsWho' + this.props.assignment.id}
          title={this.props.title}/>
      );
    }
  });

  return MessageStudentsWhoOption;
});
