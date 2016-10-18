define([
  'react',
  'i18n!gradebook2',
  'reflux',
  '../../stores/gradebookToolbarStore',
  '../../constants'
], function(React, I18n, Reflux, GradebookToolbarStore, GradebookConstants) {

  let StudentNameColumn = React.createClass({
    mixins: [Reflux.connect(GradebookToolbarStore, "toolbarOptions")],

    rowData() {
      return this.props.rowData;
    },

    renderHiddenName() {
      const hiddenText = I18n.t('Hidden');
      return <span title={hiddenText}>{hiddenText}</span>;
    },

    isConcludedOrInactive() {
      return this.isConcluded() || this.isInactive();
    },

    isConcluded() {
      return this.rowData().isConcluded;
    },

    isInactive() {
      return this.rowData().isInactive;
    },

    renderEnrollmentStatus() {
      let enrollmentStatus;
      const labelTitle = I18n.t('This user is currently not able to access the course');

      if(this.isConcluded()) {
        enrollmentStatus = I18n.t('concluded');
      } else if(this.isInactive()) {
        enrollmentStatus = I18n.t('inactive');
      }

      return <span ref="enrollmentStatus" className='label'
                 title={labelTitle}>{enrollmentStatus}</span>
    },

    renderStudentName() {
      var displayName = this.rowData().studentName;

      return <a ref="gradesUrl" title={displayName}
                href={this.rowData().student.grades.html_url}>{displayName}</a>
    },

    renderHiddenOrStudentName() {
      var hideStudentNames = this.state.toolbarOptions.hideStudentNames;
      if(hideStudentNames) {
        return this.renderHiddenName();
      } else {
        return this.renderStudentName();
      }
    },

    render() {
      return (
        <div ref="studentName" className="student-name">
          {this.renderHiddenOrStudentName()} {this.isConcludedOrInactive() ? this.renderEnrollmentStatus() :  ''}
        </div>
      );
    }
  });

  return StudentNameColumn;
});
