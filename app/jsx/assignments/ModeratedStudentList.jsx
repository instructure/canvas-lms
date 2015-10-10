/** @jsx React.DOM */

define([
  'react'
], function (React) {

  var MARK_ONE = 0;
  var MARK_TWO = 1;
  var MARK_THREE = 2;

  return React.createClass({
    getInitialState () {
      return (
        {submissions: []}
      );
    },
    componentDidMount () {
      this.props.store.addChangeListener(this.handleStoreChange);
    },
    handleStoreChange () {
      this.setState({submissions: this.props.store.submissions});
    },
    displayName: 'ModeratedStudentList',
    selectCheckbox (submission, event) {
      // this.actions.updateSubmission(submission);
    },
    renderSubmissionMark (submission, mark_number) {
      if(submission.provisional_grades[mark_number]){
        return(
          <div className='AssignmentList__Mark'>
            <input type='radio' name={"mark_" + submission.id} />
            <span>{submission.provisional_grades[mark_number].score}</span>
          </div>
        );
      }else{
        return(
          <div className='AssignmentList__Mark'>
            <span>Speed Grader</span>
          </div>
        );
      }
    },
    renderFinalGrade (submission) {
      if (submission.grade){
        return(
          <span className='AssignmentList_Grade'>
            {submission.score}
          </span>
        );
      }else{
        return(
          <span className='AssignmentList_Grade'>
            -
          </span>
        );
      }
    },
    render () {
      return(
        <ul className='AssignmentList'>
          {
            this.state.submissions.map(function(submission) {
              return(
                <li className='AssignmentList__Item'>
                  <div className='AssignmentList__StudentInfo'>
                    <input checked={submission.isSelected} type="checkbox" onChange={this.selectCheckbox.bind(null, submission)} />
                    <img className='img-circle AssignmentList_StudentPhoto' src={submission.user.avatar_image_url} />
                    <span>{submission.user.display_name}</span>
                  </div>
                  {this.renderSubmissionMark(submission, MARK_ONE)}
                  {this.renderSubmissionMark(submission, MARK_TWO)}
                  {this.renderSubmissionMark(submission, MARK_THREE)}
                  {this.renderFinalGrade(submission)}
                </li>
                );
            }.bind(this))
          }
        </ul>
      );
    }
  });

});
