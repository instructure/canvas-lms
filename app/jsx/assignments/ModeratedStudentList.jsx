/** @jsx React.DOM */

define([
  'react'
], function (React) {

  var MARK_ONE = 0;
  var MARK_TWO = 1;
  var MARK_THREE = 2;

  return React.createClass({

    propTypes: {
      students: React.PropTypes.arrayOf(React.PropTypes.object).isRequired
    },

    renderSubmissionMark (submission, mark_number) {
      if (submission.provisional_grades && submission.provisional_grades[mark_number]) {
        return (
          <div className='AssignmentList__Mark'>
            <input type='radio' name={`mark_${submission.id}`} />
            <span>{submission.provisional_grades[mark_number].score}</span>
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
            this.props.students.map((submission) => {
              return (
                <li className='AssignmentList__Item'>
                  <div className='AssignmentList__StudentInfo'>
                    <input checked={submission.isSelected} type='checkbox' />
                    <img className='img-circle AssignmentList_StudentPhoto' src={submission.avatar_image_url} />
                    <span>{submission.display_name}</span>
                  </div>
                  {this.renderSubmissionMark(submission, MARK_ONE)}
                  {this.renderSubmissionMark(submission, MARK_TWO)}
                  {this.renderSubmissionMark(submission, MARK_THREE)}
                  {this.renderFinalGrade(submission)}
                </li>
                );
            })
          }
        </ul>
      );
    }
  });

});
