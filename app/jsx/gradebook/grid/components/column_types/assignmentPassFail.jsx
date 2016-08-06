define([
  'react',
  'underscore',
  '../../mixins/gradeCellMixin',
  '../../actions/submissionsActions'
], function (React, _, GradeCellMixin, SubmissionsActions) {

  var GRADEBOOK_CHECKBOX_CLASS = 'gradebook-checkbox';
  var NEXT_GRADE_TYPE = {
    ''          : 'complete',
    'complete'  : 'incomplete',
    'incomplete': ''
  };

  var AssignmentPassFail = React.createClass({
    mixins: [GradeCellMixin],

    getCurrentGrade() {
      var previousGrade = (this.props.cellData) ? this.props.cellData.grade : null,
          grade;

      if (this.state.gradeToPost || this.state.gradeToPost === "") {
        grade = this.state.gradeToPost;
      } else {
        grade = previousGrade;
      }

      return grade;
    },

    getClassName() {
      var className = 'grade';
      if (this.getCurrentGrade() || this.getCurrentGrade() === '' || this.props.isActiveCell) {
        className += ' ' + GRADEBOOK_CHECKBOX_CLASS + ' '
                  + GRADEBOOK_CHECKBOX_CLASS + '-'
                  + this.getCurrentGrade();
      }

      if (this.props.isActiveCell) {
        className += ' editable';
      }

      return className;
    },

    handleClick() {
      var currentGrade = this.getCurrentGrade() || '',
          isActiveCell = this.props.isActiveCell,
          gradeToPost  = (isActiveCell) ? NEXT_GRADE_TYPE[currentGrade]
                                        : currentGrade;

      this.setState({gradeToPost: gradeToPost}, this.sendSubmission);
    },

    render() {
      var cellContent = (!this.props.cellData ||  this.isSubmissionGradedAsNull()) ? '-' : '';
      return (
        <div style={{width: '100%', height: '100%'}} onClick={this.handleClick}>
          <div ref="grade" className={this.getClassName()}>
            {cellContent}
          </div>
        </div>
      );
    }
  });

  return AssignmentPassFail;
});
