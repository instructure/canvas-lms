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
      submission: React.PropTypes.object
    },

    hasIconDefined() {
      var submission = this.props.submission;
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
      var assignment = this.props.cellData,
          enrollment = this.props.rowData.enrollment,
          student = enrollment.user;

      student["assignment_" + assignment.id] = this.props.submission;
      this.openDialog(assignment, student);
    },

    renderIcon() {
      var submissionType = this.props.submission.submission_type,
          className = ICON_CLASS + SUBMISSION_TYPES[submissionType];

      return <i ref="icon" className={className}/>;
    },

    renderGradeCell() {
      var Renderer = this.props.renderer;
      return <Renderer isActiveCell={this.props.activeCell}
                       cellData={this.props.cellData}
                       submission={this.props.submission}
                       rowData={this.props.rowData}/>;
    },

    render() {
      var className = "gradebook-cell-comment";

      if (this.props.activeCell) {
        className += ' active';
      }
      return (
        <div>
          <a ref="detailsDialog"
             href="#"
             onClick={this.handleSubmissionCommentClick}
             className={className}>
            <span className="gradebook-cell-comment-label">
              I18n.t('submission comments')
            </span>
          </a>
          {this.shouldRenderIcon() ? this.renderIcon() : this.renderGradeCell()}
        </div>
      );
    }
  });

  return AssignmentGradeCell;
});
