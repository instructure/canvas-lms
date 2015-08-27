/** @jsx React.DOM */
define([
  'react',
  'bower/reflux/dist/reflux',
  'underscore',
  'i18n!gradebook',
  'compiled/gradebook2/SetDefaultGradeDialog',
  'jsx/gradebook/grid/components/dropdown_components/headerDropdownOption'
], function (React, Reflux, _, I18n, SetDefaultGradeDialog, HeaderDropdownOption) {

  var SetDefaultGradeOption = React.createClass({

    // TODO: make selectedSection isRequired in the ticket to filter by section
    // (or, even better, pre-filter the students we pass into SetDefaultGradeDialog
    // so we dont need to pass in a selectedSection)
    propTypes: {
      assignment: React.PropTypes.object.isRequired,
      enrollments: React.PropTypes.array.isRequired,
      contextId: React.PropTypes.string.isRequired,
      selectedSection: React.PropTypes.object
    },

    students() {
      return _.pluck(this.props.enrollments, 'user');
    },

    studentsThatCanSeeAssignment(students, assignment) {
      var studentIds = assignment.assignment_visibility;
      return _.filter(students, student => _.contains(studentIds, student.id));
    },

    openDialog() {
      var assignment = this.props.assignment,
          students   = this.studentsThatCanSeeAssignment(this.students(), assignment);
      // TODO: pass in a selectedSection once the ticket for section filtering is
      // implemented
      return new SetDefaultGradeDialog({
        assignment: assignment,
        students: students,
        selected_section: this.props.selectedSection,
        context_id: this.props.contextId
      });
    },

    render() {
      return(
        <HeaderDropdownOption
          key={'setDefaultGrade-' + this.props.assignment.id}
          handleClick={this.openDialog}
          title={I18n.t('Set Default Grade')}/>
      );
    }
  });

  return SetDefaultGradeOption;
});
