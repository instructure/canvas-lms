/** @jsx React.DOM */
define([
  'react',
  'compiled/SubmissionDetailsDialog',
  'jsx/gradebook/grid/constants'
], function (React, SubmissionDetailsDialog, GradebookConstants) {
  const GRADED = 'graded',
        ICON_CLASS = 'icon-',
        LATE_CLASS = 'late',
        RESUBMITTED_CLASS = 'resubmiited',
        SUBMISSION_TYPES = {
          discussion_topic: 'discussion',
          online_url: 'link',
          online_text_entry: 'text',
          online_upload: 'document',
          online_quiz: 'quiz',
          media_recording: 'media'
        };

  var AssignmentGradeCell = React.createClass({
    propTypes: {
      activeCell: React.PropTypes.bool.isRequired,
      rowData: React.PropTypes.object.isRequired,
      renderer: React.PropTypes.func.isRequired,
      columnData: React.PropTypes.object
    },

    hasIconDefined() {
      var submission = this.props.cellData;

      if (!submission || submission.workflow_state === GRADED) {
        return false;
      }

      return submission.submission_type in SUBMISSION_TYPES;
    },

    shouldRenderIcon() {
      return this.hasIconDefined() && !this.props.activeCell;
    },

    openDialog(assignment, student) {
      SubmissionDetailsDialog.open(assignment, student, GradebookConstants);
    },

    handleSubmissionCommentClick(event) {
      var assignment, submission, student;

      assignment = this.props.columnData.assignment;
      student = this.props.rowData.student;
      submission = this.props.cellData;

      student["assignment_" + assignment.id] = submission;
      this.openDialog(assignment, student);
    },

    renderIcon() {
      var submissionType = this.props.cellData.submission_type,
          className = ICON_CLASS + SUBMISSION_TYPES[submissionType];

      return <i ref="icon" className={className}/>;
    },

    renderGradeCell() {
      var Renderer = this.props.renderer;
      return <Renderer isActiveCell={this.props.activeCell}
                       cellData={this.props.cellData}
                       submission={this.props.cellData}
                       columnData={this.props.columnData}
                       rowData={this.props.rowData}/>;
    },

    render() {
      var className, child;

      className = "gradebook-cell-comment";
      child = this.shouldRenderIcon() ? this.renderIcon() : this.renderGradeCell();

      if (this.props.activeCell) {
        className += ' active';
      }

      return (
        <div className="assignment-grade-cell">
          <a ref="detailsDialog"
             href="#"
             onClick={this.handleSubmissionCommentClick}
             className={className}>
            <span className="gradebook-cell-comment-label">
              I18n.t('submission comments')
            </span>
          </a>
          {child}
        </div>
      );
    }
  });

  return AssignmentGradeCell;
});
