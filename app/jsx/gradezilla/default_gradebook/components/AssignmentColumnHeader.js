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

import React from 'react'
import IconMoreSolid from 'instructure-icons/react/Solid/IconMoreSolid'
import IconMutedSolid from 'instructure-icons/react/Solid/IconMutedSolid'
import IconWarningSolid from 'instructure-icons/react/Solid/IconWarningSolid'
import Link from 'instructure-ui/lib/components/Link'
import { MenuItem, MenuItemGroup, MenuItemSeparator } from 'instructure-ui/lib/components/Menu'
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu'
import Typography from 'instructure-ui/lib/components/Typography'
import 'message_students'
import MessageStudentsWhoHelper from 'jsx/gradezilla/shared/helpers/messageStudentsWhoHelper'
import I18n from 'i18n!gradebook'

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
    sortBySetting: shape({
      direction: string.isRequired,
      disabled: bool.isRequired,
      isSortColumn: bool.isRequired,
      onSortByGradeAscending: func.isRequired,
      onSortByGradeDescending: func.isRequired,
      onSortByLate: func.isRequired,
      onSortByMissing: func.isRequired,
      onSortByUnposted: func.isRequired,
      settingKey: string.isRequired
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
    }).isRequired,
    downloadSubmissionsAction: shape({
      hidden: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,
    reuploadSubmissionsAction: shape({
      hidden: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,
    muteAssignmentAction: shape({
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

    this.bindOptionsMenuContent = (ref) => { this.optionsMenuContent = ref };
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
        <Typography weight="bold" fontStyle="normal" size="large" color="brand">
          <IconMoreSolid title={optionsTitle} />
        </Typography>
      </span>
    );
  }

  render () {
    const { sortBySetting } = this.props;
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey;

    return (
      <div className="Gradebook__ColumnHeaderContent">
        <span className="Gradebook__ColumnHeaderDetail">
          {this.renderAssignmentLink()}
          <Typography weight="normal" fontStyle="normal" size="x-small">
            {this.renderPointsPossible()}
          </Typography>
        </span>

        <PopoverMenu
          contentRef={this.bindOptionsMenuContent}
          focusTriggerOnClose={false}
          trigger={this.renderTrigger()}
        >
          <MenuItemGroup label={I18n.t('Sort by')}>
            <MenuItem
              selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'ascending'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByGradeAscending}
            >
              <span>{I18n.t('Grade - Low to High')}</span>
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'descending'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByGradeDescending}
            >
              <span>{I18n.t('Grade - High to Low')}</span>
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'missing'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByMissing}
            >
              <span data-menu-item-id="sort-by-missing">{I18n.t('Missing')}</span>
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'late'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByLate}
            >
              <span data-menu-item-id="sort-by-late">{I18n.t('Late')}</span>
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'unposted'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByUnposted}
            >
              <span>{I18n.t('Unposted')}</span>
            </MenuItem>
          </MenuItemGroup>

          <MenuItemSeparator />

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

          {
            !this.props.downloadSubmissionsAction.hidden &&
            <MenuItem onSelect={this.props.downloadSubmissionsAction.onSelect}>
              <span data-menu-item-id="download-submissions">{I18n.t('Download Submissions')}</span>
            </MenuItem>
          }

          {
            !this.props.reuploadSubmissionsAction.hidden &&
            <MenuItem onSelect={this.props.reuploadSubmissionsAction.onSelect}>
              <span data-menu-item-id="reupload-submissions">{I18n.t('Re-Upload Submissions')}</span>
            </MenuItem>
          }

          <MenuItem
            disabled={this.props.muteAssignmentAction.disabled}
            onSelect={this.props.muteAssignmentAction.onSelect}
          >
            <span data-menu-item-id="assignment-muter">
              {this.props.assignment.muted ? I18n.t('Unmute Assignment') : I18n.t('Mute Assignment')}
            </span>
          </MenuItem>
        </PopoverMenu>
      </div>
    );
  }
}

export default AssignmentColumnHeader
