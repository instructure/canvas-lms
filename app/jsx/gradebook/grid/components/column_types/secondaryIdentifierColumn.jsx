/** @jsx React.DOM */

define([
  'react',
  'i18n!gradebook2',
  'bower/reflux/dist/reflux',
  '../../stores/gradebookToolbarStore'
], function(React, I18n, Reflux, GradebookToolbarStore) {

  var SecondaryIdentifierColumn = React.createClass({
    mixins: [Reflux.connect(GradebookToolbarStore, "toolbarOptions")],
    render() {
      var hideStudentNames = this.state.toolbarOptions.hideStudentNames;
      var user = this.props.rowData.enrollment.user;
      var displayText = hideStudentNames ? I18n.t('Hidden') : (user.sis_login_id || user.login_id);
      return <span>{displayText}</span>;
    }
  });

  return SecondaryIdentifierColumn;
});
