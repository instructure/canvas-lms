/** @jsx React.DOM */
define([
  'react',
  'underscore',
  './assignmentGradeCell'
], function (React, _, AssignmentGradeCell) {

  const GRADEBOOK_CELL_CLASS = 'gradebook-cell',
        ACTIVE_CLASS = ' active',
        LATE_CLASS = ' late',
        RESUBMIITED_CLASS = ' resubmitted';

  var GridCell = React.createClass({
    propTypes: {
      activeCell: React.PropTypes.number.isRequired,
      cellIndex: React.PropTypes.number.isRequired,
      rowData: React.PropTypes.object.isRequired,
      renderer: React.PropTypes.func.isRequired,
      cellData: React.PropTypes.any
    },

    getInitialState() {
      return {
        cellIndex: this.props.cellIndex
      };
    },

    handleClick() {
      this.props.setActiveCell(this.state.cellIndex);
    },

    getSubmissionForAssignment() {
      var assignmentId = this.props.cellData.id;
      return _.find(this.props.rowData.submissions, (s) => s.assignment_id === assignmentId);
    },

    getClassName(isActiveCell, submission) {
      var className = GRADEBOOK_CELL_CLASS;

      if (isActiveCell) {
        className += ACTIVE_CLASS;
      }

      if (submission) {
        if (submission.late) {
          className += LATE_CLASS;
        } else if (!submission.grade_matches_current_submission) {
          className += RESUBMIITED_CLASS;
        }
      }

      return className;
    },

    renderAssignmentCell(Renderer, isActiveCell, submission) {
       return (<AssignmentGradeCell
                   submission={submission}
                   renderer={Renderer}
                   activeCell={isActiveCell}
                   cellData={this.props.cellData}
                   rowData={this.props.rowData} />);
    },

    renderGenericCell(Renderer, isActiveCell) {
      return (<Renderer isActiveCell={isActiveCell}
                        cellData={this.props.cellData}
                        rowData={this.props.rowData} />);
    },

    render() {
      var Renderer = this.props.renderer,
          className = GRADEBOOK_CELL_CLASS,
          isAssignmentCell = this.props.cellData,
          isActiveCell = this.props.activeCell === this.state.cellIndex,
          renderCell = (isAssignmentCell) ? this.renderAssignmentCell : this.renderGenericCell,
          submission = (isAssignmentCell) ? this.getSubmissionForAssignment() : null;

      return (
        <div className={this.getClassName(isActiveCell, submission)}
             onKeyDown={this.handleKeyPress}
             onClick={this.handleClick}>
          {renderCell(Renderer, isActiveCell, submission)}
        </div>
      );
    }
  });

  return GridCell;
});
