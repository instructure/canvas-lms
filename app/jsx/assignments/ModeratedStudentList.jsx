/** @jsx React.DOM */

define([
  'react',
  './actions/ModerationActions'
], function (React, ModerationActions) {

  var MARK_ONE = 0;
  var MARK_TWO = 1;
  var MARK_THREE = 2;

  return React.createClass({

    propTypes: {
      students: React.PropTypes.arrayOf(React.PropTypes.object).isRequired,
      assignment: React.PropTypes.object.isRequired
    },

    handleCheckbox (student, event) {
      if (event.target.checked) {
        this.props.store.dispatch(ModerationActions.selectStudent(student.id));
      } else {
        this.props.store.dispatch(ModerationActions.unselectStudent(student.id));
      }
    },

    renderStudentMark (student, mark_number) {
      if (student.provisional_grades && student.provisional_grades[mark_number]) {
        return (
          <div className='AssignmentList__Mark'>
            <input
               type='radio'
               name={`mark_${student.id}`}
               disabled={this.props.assignment.published}
              />
            <span>{student.provisional_grades[mark_number].score}</span>
          </div>
        );
      } else {
        return (
          <div className='AssignmentList__Mark'>
            <span>Speed Grader</span>
          </div>
        );
      }
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
                      onChange={this.handleCheckbox.bind(this, student)}
                    />
                    <img className='img-circle AssignmentList_StudentPhoto' src={student.avatar_image_url} />
                    <span>{student.display_name}</span>
                  </div>
                  {this.renderStudentMark(student, MARK_ONE)}
                  {this.renderStudentMark(student, MARK_TWO)}
                  {this.renderStudentMark(student, MARK_THREE)}
                  {this.renderFinalGrade(student)}
                </li>
                );
            })
          }
        </ul>
      );
    }
  });

});
