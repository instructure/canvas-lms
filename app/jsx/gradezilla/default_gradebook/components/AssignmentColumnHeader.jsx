/*
 * Copyright (C) 2017 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/* eslint-disable react/style-prop-object */
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
  'i18n!gradebook',
], (React, { default: IconMoreSolid }, { default: IconMutedSolid }, { default: IconWarningSolid },
  { default: Link }, { MenuItem }, { default: PopoverMenu }, { default: Typography },
  messageStudents, MessageStudentsWhoHelper, I18n) => {
  const { arrayOf, bool, func, instanceOf, number, shape, string } = React.PropTypes;

  class AssignmentColumnHeader extends React.Component {
    static propTypes = {
      assignment: shape({
        courseId: string.isRequired,
        htmlUrl: string.isRequired,
        id: string.isRequired,
        invalid: bool,
        muted: bool.isRequired,
        name: string.isRequired,
        omitFromFinalGrade: bool.isRequired,
        pointsPossible: number,
        submissionTypes: arrayOf(string).isRequired
      }).isRequired,
      curveGradesAction: shape({
        isDisabled: bool.isRequired,
        onSelect: func.isRequired
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
      submissionsLoaded: bool.isRequired,
      assignmentDetailsAction: shape({
        disabled: bool.isRequired,
        onSelect: func.isRequired
      }).isRequired,
      setDefaultGradeAction: shape({
        disabled: bool.isRequired,
        onSelect: func.isRequired
      }).isRequired
    };

    static renderMutedIcon (screenreaderText) {
      return (
        <Typography weight="bold" fontStyle="normal" size="small" color="error">
          <IconMutedSolid title={screenreaderText} />
        </Typography>
      );
    }

    static renderWarningIcon (screenreaderText) {
      return (
        <Typography weight="bold" fontStyle="normal" size="small" color="brand">
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
        assignmentTitle = I18n.t('This assignment has no points possible and cannot be included in grade calculation');
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
      const pointsPossible = I18n.n(this.props.assignment.pointsPossible || 0);

      return (
        <div className="assignment-points-possible">
          { I18n.t('Out of %{pointsPossible}', { pointsPossible }) }
        </div>
      );
    }

    renderTrigger () {
      const optionsTitle = I18n.t('%{name} Options', { name: this.props.assignment.name });
      return (
        <span className="Gradebook__ColumnHeaderAction">
          <Typography weight="bold" style="normal" size="large" color="brand">
            <IconMoreSolid title={optionsTitle} />
          </Typography>
        </span>
      );
    }

    render () {
      return (
        <div className="Gradebook__ColumnHeaderContent">
          <span className="Gradebook__ColumnHeaderDetail">
            {this.renderAssignmentLink()}
            <Typography weight="normal" fontStyle="normal" size="x-small">
              {this.renderPointsPossible()}
            </Typography>
          </span>

          <PopoverMenu zIndex="9999" trigger={this.renderTrigger()}>
            <MenuItem
              disabled={this.props.assignmentDetailsAction.disabled}
              onSelect={this.props.assignmentDetailsAction.onSelect}
            >
              <span data-menu-item-id="show-assignment-details">{I18n.t('Assignment Details')}</span>
            </MenuItem>
            <MenuItem
              disabled={!this.props.submissionsLoaded}
              onSelect={this.showMessageStudentsWhoDialog}
            >
              <span data-menu-item-id="message-students-who">{I18n.t('Message Students Who')}</span>
            </MenuItem>
            <MenuItem
              disabled={this.props.curveGradesAction.isDisabled}
              onSelect={this.props.curveGradesAction.onSelect}
            >
              <span data-menu-item-id="curve-grades">{I18n.t('Curve Grades')}</span>
            </MenuItem>
            <MenuItem
              disabled={this.props.setDefaultGradeAction.disabled}
              onSelect={this.props.setDefaultGradeAction.onSelect}
            >
              <span data-menu-item-id="set-default-grade">{I18n.t('Set Default Grade')}</span>
            </MenuItem>
          </PopoverMenu>
        </div>
      );
    }
  }

  return AssignmentColumnHeader;
});
