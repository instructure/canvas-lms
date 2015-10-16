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
      var displayName, enrollment;
      displayName = this.props.rowData.studentName;
      enrollment = this.props.rowData.student;

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
