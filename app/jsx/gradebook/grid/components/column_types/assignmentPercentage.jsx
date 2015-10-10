/** @jsx React.DOM */
define([
  'react',
  '../../actions/submissionsActions',
  '../../mixins/gradeCellMixin',
  '../../mixins/standardGradeInputMixin',
  '../../mixins/standardCellFocusMixin',
  '../../mixins/standardRenderMixin'
], function (
  React,
  SubmissionsActions,
  GradeCellMixin,
  StandardGradeInputMixin,
  StandardCellFocusMixin,
  StandardRenderMixin
) {

  var AssignmentPercentage = React.createClass({
    mixins: [
      GradeCellMixin,
      StandardGradeInputMixin,
      StandardCellFocusMixin,
      StandardRenderMixin
    ],

    renderViewGrade() {
      return (
        <div ref="grade">
          {this.getDisplayGrade().replace("%", "")}
        </div>
      );
    }
  });

  return AssignmentPercentage;
});
