/** @jsx React.DOM */
define([
  'react',
  '../../mixins/gradeCellMixin',
  '../../mixins/standardGradeInputMixin',
  '../../mixins/standardCellFocusMixin',
  '../../mixins/standardRenderMixin'
], function (
  React,
  GradeCellMixin,
  StandardGradeInputMixin,
  StandardCellFocusMixin,
  StandardRenderMixin
) {

  var AssignmentLetterGrade = React.createClass({
    mixins: [
      GradeCellMixin,
      StandardGradeInputMixin,
      StandardCellFocusMixin,
      StandardRenderMixin
    ],

    renderViewGrade() {
      var submission = this.state.submission;
      if (submission && submission.grade) {
        var gradingType = this.props.cellData.grading_type;
            score = (gradingType == 'letter_grade') ? submission.score : ''
        return (
          <div ref="grade">
            {submission.grade}
            <span className="letter-grade-points">
              {score}
            </span>
          </div>
        );
      } else {
        return <div ref="grade">-</div>;
      }
    }
  });

  return AssignmentLetterGrade;

});
