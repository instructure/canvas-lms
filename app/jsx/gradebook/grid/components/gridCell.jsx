/** @jsx React.DOM */
define([
  'react',
  'underscore',
  './assignmentGradeCell'
], function (React, _, AssignmentGradeCell) {

  var GRADEBOOK_CELL_CLASS = 'gradebook-cell',
      ACTIVE_CLASS = ' active',
      LATE_CLASS = ' late',
      RESUBMIITED_CLASS = ' resubmitted',
      ASSIGNMENT_TYPES = [
        'percent',
        'pass_fail',
        'letter_grade',
        'points',
        'gpa_scale',
      ];

  var GridCell = React.createClass({
    propTypes: {
      activeCell: React.PropTypes.number.isRequired,
      cellData: React.PropTypes.any,
      cellIndex: React.PropTypes.number.isRequired,
      columnData: React.PropTypes.object,
      rowData: React.PropTypes.object.isRequired,
      renderer: React.PropTypes.func.isRequired
    },

    getInitialState() {
      return {
        cellIndex: this.props.cellIndex
      };
    },

    handleClick() {
      this.props.setActiveCell(this.state.cellIndex);
    },

    isAssignment(columnData) {
      return _.contains(ASSIGNMENT_TYPES, columnData.columnType);
    },

    getClassName(isActiveCell, cellData, isAssignment) {
      var className = GRADEBOOK_CELL_CLASS;

      if (isActiveCell) {
        className += ACTIVE_CLASS;
      }

      if (isAssignment && cellData) {
        if (cellData.late) {
          className += LATE_CLASS;
        } else if (cellData.grade_matches_current_submission !== null && !(cellData.grade_matches_current_submission)) {
          className += RESUBMIITED_CLASS;
        }
      }

      return className;
    },

    renderAssignmentCell(Renderer, isActiveCell) {
       return (<AssignmentGradeCell
                   activeCell={isActiveCell}
                   cellData={this.props.cellData}
                   columnData={this.props.columnData}
                   renderer={Renderer}
                   rowData={this.props.rowData} />);
    },

    renderGenericCell(Renderer, isActiveCell) {
      return (<Renderer isActiveCell={isActiveCell}
                        cellData={this.props.cellData}
                        columnData={this.props.columnData}
                        rowData={this.props.rowData} />);
    },

    render() {
      var Renderer = this.props.renderer,
          className = GRADEBOOK_CELL_CLASS,
          isAssignmentCell = this.isAssignment(this.props.columnData),
          isActiveCell = this.props.activeCell === this.state.cellIndex,
          renderCell = (isAssignmentCell) ? this.renderAssignmentCell : this.renderGenericCell,
          submission = this.props.cellData;

      return (
        <div className={this.getClassName(isActiveCell, submission, isAssignmentCell)}
             onKeyDown={this.handleKeyPress}
             onClick={this.handleClick}
             key='null'>
          {renderCell(Renderer, isActiveCell)}
        </div>
      );
    }
  });

  return GridCell;
});
