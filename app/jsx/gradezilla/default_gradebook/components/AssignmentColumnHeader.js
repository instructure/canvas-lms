/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react';
import { arrayOf, bool, func, instanceOf, number, shape, string } from 'prop-types';
import IconMoreSolid from 'instructure-icons/lib/Solid/IconMoreSolid';
import IconMutedSolid from 'instructure-icons/lib/Solid/IconMutedSolid';
import IconWarningSolid from 'instructure-icons/lib/Solid/IconWarningSolid';
import Link from 'instructure-ui/lib/components/Link';
import {
  MenuItem,
  MenuItemFlyout,
  MenuItemGroup,
  MenuItemSeparator
} from 'instructure-ui/lib/components/Menu';
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu';
import Typography from 'instructure-ui/lib/components/Typography';
import 'message_students';
import MessageStudentsWhoHelper from 'jsx/gradezilla/shared/helpers/messageStudentsWhoHelper';
import I18n from 'i18n!gradebook';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';
import ColumnHeader from 'jsx/gradezilla/default_gradebook/components/ColumnHeader';

class AssignmentColumnHeader extends ColumnHeader {
  static propTypes = {
    ...ColumnHeader.propTypes,
    assignment: shape({
      courseId: string.isRequired,
      htmlUrl: string.isRequired,
      id: string.isRequired,
      muted: bool.isRequired,
      name: string.isRequired,
      omitFromFinalGrade: bool.isRequired,
      pointsPossible: number,
      published: bool.isRequired,
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
    }).isRequired,
    onMenuClose: func.isRequired,
    showUnpostedMenuItem: bool.isRequired
  };

  static defaultProps = {
    ...ColumnHeader.defaultProps
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

  bindAssignmentLink = (ref) => { this.assignmentLink = ref };

  curveGrades = () => { this.invokeAndSkipFocus(this.props.curveGradesAction) };
  setDefaultGrades = () => { this.invokeAndSkipFocus(this.props.setDefaultGradeAction) };
  muteAssignment = () => { this.invokeAndSkipFocus(this.props.muteAssignmentAction) };
  downloadSubmissions = () => { this.invokeAndSkipFocus(this.props.downloadSubmissionsAction) };
  reuploadSubmissions = () => { this.invokeAndSkipFocus(this.props.reuploadSubmissionsAction) };

  invokeAndSkipFocus (action) {
    this.setState({ skipFocusOnClose: true });
    action.onSelect(this.focusAtEnd);
  }

  focusAtStart = () => { this.assignmentLink.focus() };

  handleKeyDown = (event) => {
    if (event.which === 9) {
      if (this.assignmentLink.focused && !event.shiftKey) {
        event.preventDefault();
        this.optionsMenuTrigger.focus();
        return false; // prevent Grid behavior
      }

      if (document.activeElement === this.optionsMenuTrigger && event.shiftKey) {
        event.preventDefault();
        this.assignmentLink.focus();
        return false; // prevent Grid behavior
      }
    }

    return ColumnHeader.prototype.handleKeyDown.call(this, event);
  };

  showMessageStudentsWhoDialog = () => {
    this.setState({ skipFocusOnClose: true });
    const settings = MessageStudentsWhoHelper.settings(this.props.assignment, this.activeStudentDetails());
    settings.onClose = this.focusAtEnd;
    window.messageStudents(settings);
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
    } else if (assignment.pointsPossible == null || assignment.pointsPossible === 0) {
      assignmentTitle = I18n.t('This assignment has no points possible and cannot be included in grade calculation');
      assignmentIcon = AssignmentColumnHeader.renderWarningIcon(assignmentTitle);
    }

    return (
      <span className="assignment-name">
        <Link ref={this.bindAssignmentLink} title={assignmentTitle} href={assignment.htmlUrl}>
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
    const menuShown = this.state.menuShown;
    const classes = `Gradebook__ColumnHeaderAction ${menuShown ? 'menuShown' : ''}`;

    return (
      <span ref={this.bindOptionsMenuTrigger} className={classes}>
        <Typography weight="bold" fontStyle="normal" size="large" color="brand">
          <IconMoreSolid className="rotated" title={optionsTitle} />
        </Typography>
      </span>
    );
  }

  renderMenu () {
    if (!this.props.assignment.published) { return null; }

    const { sortBySetting } = this.props;
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey;

    return (
      <PopoverMenu
        contentRef={this.bindOptionsMenuContent}
        shouldFocusTriggerOnClose={false}
        trigger={this.renderTrigger()}
        onToggle={this.onToggle}
        onClose={this.props.onMenuClose}
      >
        <MenuItemFlyout contentRef={this.bindSortByMenuContent} label={I18n.t('Sort by')}>
          <MenuItemGroup label={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}>
            <MenuItem
              selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'ascending'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByGradeAscending}
            >
              {I18n.t('Grade - Low to High')}
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'descending'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByGradeDescending}
            >
              {I18n.t('Grade - High to Low')}
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'missing'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByMissing}
            >
              {I18n.t('Missing')}
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'late'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByLate}
            >
              {I18n.t('Late')}
            </MenuItem>

            {
              this.props.showUnpostedMenuItem &&
                <MenuItem
                  selected={selectedSortSetting === 'unposted'}
                  disabled={sortBySetting.disabled}
                  onSelect={sortBySetting.onSortByUnposted}
                >
                  {I18n.t('Unposted')}
                </MenuItem>
            }
          </MenuItemGroup>
        </MenuItemFlyout>

        <MenuItem
          disabled={!this.props.submissionsLoaded}
          onSelect={this.showMessageStudentsWhoDialog}
        >
          <span data-menu-item-id="message-students-who">{I18n.t('Message Students Who')}</span>
        </MenuItem>

        <MenuItem
          disabled={this.props.curveGradesAction.isDisabled}
          onSelect={this.curveGrades}
        >
          <span data-menu-item-id="curve-grades">{I18n.t('Curve Grades')}</span>
        </MenuItem>

        <MenuItem
          disabled={this.props.setDefaultGradeAction.disabled}
          onSelect={this.setDefaultGrades}
        >
          <span data-menu-item-id="set-default-grade">{I18n.t('Set Default Grade')}</span>
        </MenuItem>

        <MenuItem
          disabled={this.props.muteAssignmentAction.disabled}
          onSelect={this.muteAssignment}
        >
          <span data-menu-item-id="assignment-muter">
            {this.props.assignment.muted ? I18n.t('Unmute Assignment') : I18n.t('Mute Assignment')}
          </span>
        </MenuItem>

        {
          !(
            this.props.downloadSubmissionsAction.hidden &&
            this.props.reuploadSubmissionsAction.hidden
          ) && <MenuItemSeparator />
        }

        {
          !this.props.downloadSubmissionsAction.hidden &&
          <MenuItem onSelect={this.downloadSubmissions}>
            <span data-menu-item-id="download-submissions">{I18n.t('Download Submissions')}</span>
          </MenuItem>
        }

        {
          !this.props.reuploadSubmissionsAction.hidden &&
          <MenuItem onSelect={this.reuploadSubmissions}>
            <span data-menu-item-id="reupload-submissions">{I18n.t('Re-Upload Submissions')}</span>
          </MenuItem>
        }
      </PopoverMenu>
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

        {this.renderMenu()}
      </div>
    );
  }
}

export default AssignmentColumnHeader;
