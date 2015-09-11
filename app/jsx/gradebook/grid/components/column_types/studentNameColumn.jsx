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

    renderHiddenName() {
      var hiddenText = I18n.t('Hidden');
      return <span title={hiddenText}>{hiddenText}</span>;
    },

    renderStudentName() {
      var enrollment = this.props.rowData.enrollment,
          displayName = GradebookConstants.list_students_by_sortable_name_enabled ?
                          enrollment.user.sortable_name : enrollment.user.name;

      return <a title={displayName}
                href={enrollment.html_url}>{displayName}</a>;
    },

    render() {
      var hideStudentNames = this.state.toolbarOptions.hideStudentNames;
      return (
        <div className="student-name">
          {(hideStudentNames) ? this.renderHiddenName() : this.renderStudentName()}
        </div>
      );
    }
  });

  return StudentNameColumn;
});
