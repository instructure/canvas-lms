define([
  'react',
  'instructure-icons/react/Solid/IconMoreSolid',
  'instructure-icons/react/Solid/IconMutedSolid',
  'instructure-icons/react/Solid/IconWarningSolid',
  'instructure-ui/Link',
  'instructure-ui/Menu',
  'instructure-ui/PopoverMenu',
  'instructure-ui/Typography',
  'i18n!gradebook'
], (
  React, { default: IconMoreSolid }, { default: IconMutedSolid }, { default: IconWarningSolid },
  { default: Link }, { MenuItem }, { default: PopoverMenu }, { default: Typography }, I18n
) => {
  // TODO: remove this rule when this component begins using internal state
  /* eslint-disable react/prefer-stateless-function */

  class AssignmentColumnHeader extends React.Component {
    static propTypes = {
      assignment: React.PropTypes.shape({
        htmlUrl: React.PropTypes.string,
        id: React.PropTypes.string,
        invalid: React.PropTypes.bool,
        muted: React.PropTypes.bool,
        name: React.PropTypes.string,
        omitFromFinalGrade: React.PropTypes.bool,
        pointsPossible: React.PropTypes.number
      })
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
          { I18n.t('Out of %{pointsPossible}', { pointsPossible: assignment.pointsPossible }) }
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
            <MenuItem>{`Assignment ${this.props.assignment.id} Item 1`}</MenuItem>
            <MenuItem>{`Assignment ${this.props.assignment.id} Item 2`}</MenuItem>
            <MenuItem>{`Assignment ${this.props.assignment.id} Item 3`}</MenuItem>
          </PopoverMenu>
        </div>
      );
    }
  }

  return AssignmentColumnHeader;
});
