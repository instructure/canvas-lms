define([
  'react',
  'instructure-icons/react/Solid/IconMoreSolid',
  'instructure-icons/react/Solid/IconMutedSolid',
  'instructure-icons/react/Solid/IconWarningSolid',
  'instructure-ui/Link',
  'instructure-ui/Menu',
  'instructure-ui/PopoverMenu',
  'instructure-ui/Typography',
  'message_students',
  'jsx/gradezilla/shared/helpers/messageStudentsWhoHelper',
  'i18n!gradebook'
], (
  React, { default: IconMoreSolid }, { default: IconMutedSolid }, { default: IconWarningSolid },
  { default: Link }, { MenuItem }, { default: PopoverMenu }, { default: Typography },
  messageStudents, MessageStudentsWhoHelper, I18n
) => {
  const { arrayOf, bool, instanceOf, number, shape, string } = React.PropTypes;

  class AssignmentColumnHeader extends React.Component {
    static propTypes = {
      assignment: shape({
        htmlUrl: string.isRequired,
        id: string.isRequired,
        invalid: bool.isRequired,
        muted: bool.isRequired,
        name: string.isRequired,
        omitFromFinalGrade: bool.isRequired,
        pointsPossible: number,
        submissionTypes: arrayOf(string).isRequired,
        courseId: string.isRequired
      }).isRequired,
      students: arrayOf(shape({
        isInactive: bool.isRequired,
        id: string.isRequired,
        name: string.isRequired,
        submission: shape({
          score: number,
          submittedAt: instanceOf(Date)
        }).isRequired,
      })).isRequired,
      submissionsLoaded: bool.isRequired
    };

    static renderMutedIcon (screenreaderText) {
      return (
        <Typography weight="bold" style="normal" size="small" color="error">
          <IconMutedSolid title={screenreaderText} />
        </Typography>
      );
    }

    static renderWarningIcon (screenreaderText) {
      return (
        <Typography weight="bold" style="normal" size="small" color="brand">
          <IconWarningSolid title={screenreaderText} />
        </Typography>
      );
    }

    constructor (props) {
      super(props);

      this.showMessageStudentsWhoDialog = this.showMessageStudentsWhoDialog.bind(this);
    }

    activeStudentDetails () {
      const activeStudents = this.props.students.filter(student => !student.isInactive);

      return activeStudents.map((student) => {
        const { score, submittedAt } = student.submission;

        return {
          id: student.id,
          name: student.name,
          score,
          submittedAt
        };
      });
    }

    showMessageStudentsWhoDialog () {
      const settings = MessageStudentsWhoHelper.settings(this.props.assignment, this.activeStudentDetails());
      window.messageStudents(settings);
    }

    renderMessageStudentsWhoMenu () {
      return (
        <MenuItem disabled={!this.props.submissionsLoaded} onSelect={this.showMessageStudentsWhoDialog}>
          <span data-menu-item-id="message-students-who">{I18n.t('Message Students Who')}</span>
        </MenuItem>
      );
    }

    renderAssignmentLink () {
      const assignment = this.props.assignment;
      let assignmentTitle;
      let assignmentIcon;

      if (assignment.muted) {
        assignmentTitle = I18n.t('This assignment is muted');
        assignmentIcon = AssignmentColumnHeader.renderMutedIcon(assignmentTitle);
      } else if (assignment.omitFromFinalGrade) {
        assignmentTitle = I18n.t('This assignment does not count toward the final grade');
        assignmentIcon = AssignmentColumnHeader.renderWarningIcon(assignmentTitle);
      } else if (assignment.invalid) {
        assignmentTitle = I18n.t('Assignments in this group have no points possible and cannot be included in grade calculation');
        assignmentIcon = AssignmentColumnHeader.renderWarningIcon(assignmentTitle);
      }

      return (
        <span className="assignment-name">
          <Link title={assignmentTitle} href={assignment.htmlUrl}>
            {assignmentIcon}
            {assignment.name}
          </Link>
        </span>
      );
    }

    renderPointsPossible () {
      const assignment = this.props.assignment;

      if (!assignment.pointsPossible) return '';

      return (
        <div className="assignment-points-possible">
          { I18n.t('Out of %{pointsPossible}', { pointsPossible: I18n.n(assignment.pointsPossible) }) }
        </div>
      )
    }

    render () {
      const optionsTitle = I18n.t('%{name} Options', { name: this.props.assignment.name });

      return (
        <div className="Gradebook__ColumnHeaderContent">
          <span className="Gradebook__ColumnHeaderDetail">
            {this.renderAssignmentLink()}
            <Typography weight="normal" style="normal" size="x-small">
              {this.renderPointsPossible()}
            </Typography>
          </span>

          <PopoverMenu
            zIndex="9999"
            trigger={
              <span className="Gradebook__ColumnHeaderAction">
                <Typography weight="bold" style="normal" size="large" color="brand">
                  <IconMoreSolid title={optionsTitle} />
                </Typography>
              </span>
            }
          >
            {this.renderMessageStudentsWhoMenu()}
          </PopoverMenu>
        </div>
      );
    }
  }

  return AssignmentColumnHeader;
});
