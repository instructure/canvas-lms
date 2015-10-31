/** @jsx React.DOM */
define([
  'react',
  '../../mixins/gradeCellMixin',
  '../../mixins/standardRenderMixin',
  '../../mixins/standardGradeInputMixin',
  '../../mixins/standardCellFocusMixin'
], function (React, GradeCellMixin, StandardRenderMixin, StandardGradeInputMixin,
             StandardCellFocusMixin) {
  var AssignmentPoints = React.createClass({
    mixins: [
      GradeCellMixin,
      StandardRenderMixin,
      StandardCellFocusMixin
    ],

    handleOnChange(event) {
      this.setState({gradeToPost: event.target.value});
    },

    renderEditGrade() {
      return (
        <div className="points-input">
          <div className="out-of-float">
            <input
              type="text"
              onChange={this.handleOnChange}
              className="grade out-of-grade"
              ref="gradeInput"
              value={this.state.gradeToPost || this.getDisplayGrade()}/>
          </div>
          <div className="out-of-float out-of-points">
            <span className="divider">/</span>
            <span ref="pointsPossible">
              {this.props.columnData.assignment.points_possible}
            </span>
          </div>
        </div>
      );
    },

    renderViewGrade() {
      return (
        <div ref="grade">
          {this.getDisplayGrade()}
        </div>
      );
    }

  });

  return AssignmentPoints;
});
