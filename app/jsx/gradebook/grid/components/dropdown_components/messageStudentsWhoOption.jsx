define([
  'react',
  'underscore',
  'jsx/gradebook/grid/components/dropdown_components/headerDropdownOption',
  'jsx/gradebook/grid/helpers/submissionsHelper',
  'timezone',
  'jsx/gradebook/grid/helpers/messageStudentsWhoHelper',
  'message_students'
], function (React, _, HeaderDropdownOption, SubmissionsHelper, tz, MessageStudentsWhoHelper) {

  var MessageStudentsWhoOption = React.createClass({
    propTypes: {
      title: React.PropTypes.string.isRequired,
      assignment: React.PropTypes.object.isRequired,
      enrollments: React.PropTypes.array.isRequired,
      submissions: React.PropTypes.object.isRequired
    },

    openDialog() {
      var submissions = SubmissionsHelper.
        submissionsForAssignment(this.props.submissions, this.props.assignment.id);
      var students = _.map(submissions, (submission) => {
        submission.submitted_at = tz.parse(submission.submitted_at);
        var enrollment = _.find(
          this.props.enrollments,
          enrollment => enrollment.user_id === submission.user_id
        );
        if(enrollment) submission.name = enrollment.user.name;
        return submission;
      });

      var settings = MessageStudentsWhoHelper.settings(this.props.assignment, students);
      messageStudents(settings);
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
