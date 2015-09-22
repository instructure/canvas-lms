/** @jsx React.DOM */

define([
  'react',
  './actions/ModerationActions',
  './constants'
], function (React, ModerationActions, Constants) {

  return React.createClass({

    propTypes: {
      students: React.PropTypes.arrayOf(React.PropTypes.object).isRequired,
      assignment: React.PropTypes.object.isRequired,
      handleCheckbox: React.PropTypes.func.isRequired,
      includeModerationSetColumns: React.PropTypes.bool
    },

    renderStudentMark (student, mark_number) {
      if (student.provisional_grades && student.provisional_grades[mark_number]) {
          if (this.props.includeModerationSetColumns){
            return (
              <div className='AssignmentList__Mark'>
                  <input
                     type='radio'
                     name={`mark_${student.id}`}
                     disabled={this.props.assignment.published}
                    />
                <a href={student.provisional_grades[mark_number].speedgrader_url}>{student.provisional_grades[mark_number].score}</a>
              </div>
            );
          }else{
            return(
              <div className='AssignmentList__Mark'>
                <span>{student.provisional_grades[mark_number].score}</span>
              </div>
            );
          }
      } else {
        return (
          <div className='AssignmentList__Mark'>
            <a href={this.generateSpeedgraderUrl(this.props.urls.assignment_speedgrader_url, student)}>Speed Grader</a>
          </div>
        );
      }
    },

    generateSpeedgraderUrl (baseSpeedgraderUrl, student) {
      return(baseSpeedgraderUrl + "&student_id=" + student.id);
    },

    renderFinalGrade (submission) {
      if (submission.grade) {
        return (
          <span className='AssignmentList_Grade'>
            {submission.score}
          </span>
        );
      } else {
        return (
          <span className='AssignmentList_Grade'>
            -
          </span>
        );
      }
    },

    renderStudentMarkColumns (student) {
      if(this.props.includeModerationSetColumns){
        return (
          <div className="AssignmentList__ItemGroup">
            {this.renderStudentMark(student, Constants.markColumn.MARK_ONE)}
            {this.renderStudentMark(student, Constants.markColumn.MARK_TWO)}
            {this.renderStudentMark(student, Constants.markColumn.MARK_THREE)}
            {this.renderFinalGrade(student)}
          </div>
        );
      }else
      {
        return(
          <div className="AssignmentList__ItemGroup">
            {this.renderStudentMark(student, Constants.markColumn.MARK_ONE)}
          </div>
        );
      }
    },
    render () {
      return (
        <ul className='AssignmentList'>
          {
            this.props.students.map((student) => {
              return (
                <li className='AssignmentList__Item'>
                  <div className='AssignmentList__StudentInfo'>
                    <input
                      checked={student.in_moderation_set || student.isChecked}
                      disabled={student.in_moderation_set || this.props.assignment.published}
                      type='checkbox'
                      onChange={this.props.handleCheckbox.bind(this, student)}
                    />
                    <img className='img-circle AssignmentList_StudentPhoto' src={student.avatar_image_url} />
                    <span>{student.display_name}</span>
                  </div>
                  {this.renderStudentMarkColumns(student)}
                </li>
                );
            })
          }
        </ul>
      );
    }
  });

});
