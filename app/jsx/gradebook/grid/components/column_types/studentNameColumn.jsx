/** @jsx React.DOM */

define([
  'react',
  'i18n!gradebook2',
  'bower/reflux/dist/reflux',
  '../../stores/gradebookToolbarStore',
  '../../constants'
], function(React, I18n, Reflux, GradebookToolbarStore, GradebookConstants) {

  var StudentNameColumn = React.createClass({
    mixins: [Reflux.connect(GradebookToolbarStore, "toolbarOptions")],
    render() {
      var hideStudentNames = this.state.toolbarOptions.hideStudentNames;
      if (hideStudentNames) {
        return <span>{I18n.t('Hidden')}</span>;
      } else {
        var enrollment = this.props.rowData.enrollment;
        var displayName = GradebookConstants.list_students_by_sortable_name_enabled ?
          enrollment.user.sortable_name : enrollment.user.name;
        return <a href={enrollment.html_url}>{displayName}</a>;
      }
    }
  });

  return StudentNameColumn;
});
