
/** @jsx React.DOM */
define([
  'react',
  'jquery',
  'bower/reflux/dist/reflux',
  'underscore',
  'i18n!gradebook',
  'jsx/gradebook/grid/components/dropdown_components/headerDropdownOption',
  'compiled/AssignmentMuter',
  'jsx/gradebook/grid/constants',
  'jsx/gradebook/grid/actions/assignmentGroupsActions'
], function (
  React,
  $,
  Reflux,
  _,
  I18n,
  HeaderDropdownOption,
  AssignmentMuter,
  GradebookConstants,
  AssignmentGroupsActions
) {

  const MUTE = I18n.t('Mute Assignment'),
        UNMUTE = I18n.t('Unmute Assignment'),
        MUTING_EVENT = 'assignment_muting_toggled';

  var MuteAssignmentOption = React.createClass({

    propTypes: {
      assignment: React.PropTypes.object.isRequired
    },

    openDialog() {
      var assignment = this.props.assignment,
          contextUrl = GradebookConstants.context_url,
          options = {openDialogInstantly: true},
          id = assignment.id,
          url = contextUrl + "/assignments/" + id + "/mute";

      new AssignmentMuter(null, assignment, url, null, options);

      $.subscribe(MUTING_EVENT, (assignment) => {
        AssignmentGroupsActions.replaceAssignment(assignment);
        $.unsubscribe(MUTING_EVENT);
      });
    },

    render() {
      var title = (this.props.assignment.muted) ? UNMUTE : MUTE;
      return(
        <HeaderDropdownOption
          handleClick={this.openDialog}
          key={'muteAssignment' + this.props.assignment.id}
          title={title}/>
      );
    }
  });

  return MuteAssignmentOption;
});
