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
import IconMoreSolid from '@instructure/ui-icons/lib/Solid/IconMore';
import Button from '@instructure/ui-buttons/lib/components/Button';
import Grid, { GridCol, GridRow } from '@instructure/ui-layout/lib/components/Grid';
import Link from '@instructure/ui-elements/lib/components/Link';
import Menu, {
  MenuItem,
  MenuItemGroup,
  MenuItemSeparator
} from '@instructure/ui-menu/lib/components/Menu';
import Text from '@instructure/ui-elements/lib/components/Text';
import 'message_students';
import I18n from 'i18n!gradebook';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import MessageStudentsWhoHelper from '../../../shared/helpers/messageStudentsWhoHelper'
import ColumnHeader from './ColumnHeader'

function SecondaryDetailLine (props) {
  const anonymous = props.assignment.anonymizeStudents;
  const unpublished = !props.assignment.published;

  if (anonymous || unpublished) {
    return (
      <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
        <Text color="error" size="x-small" transform="uppercase" weight="bold">
          { unpublished ? I18n.t('Unpublished') : I18n.t('Anonymous') }
        </Text>
      </span>
    );
  }

  const pointsPossible = I18n.n(props.assignment.pointsPossible || 0);

  return (
    <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
      <span className="assignment-points-possible">
        <Text weight="normal" fontStyle="normal" size="x-small">
          { I18n.t('Out of %{pointsPossible}', { pointsPossible }) }
        </Text>
      </span>

      {
        props.assignment.muted && (
          <span>
            &nbsp;
            <Text size="x-small" transform="uppercase" weight="bold">
              { I18n.t('Muted') }
            </Text>
          </span>
        )
      }
    </span>
  );
}

SecondaryDetailLine.propTypes = {
  assignment: shape({
    anonymizeStudents: bool.isRequired,
    muted: bool.isRequired,
    pointsPossible: number,
    published: bool.isRequired
  }).isRequired
};

export default class AssignmentColumnHeader extends ColumnHeader {
  static propTypes = {
    ...ColumnHeader.propTypes,
    assignment: shape({
      anonymizeStudents: bool.isRequired,
      courseId: string.isRequired,
      htmlUrl: string.isRequired,
      id: string.isRequired,
      muted: bool.isRequired,
      name: string.isRequired,
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
        excused: bool.isRequired,
        latePolicyStatus: string,
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
    onMenuDismiss: func.isRequired,
    showUnpostedMenuItem: bool.isRequired
  };

  static defaultProps = {
    ...ColumnHeader.defaultProps
  };

  bindAssignmentLink = (ref) => { this.assignmentLink = ref };
  bindEnterGradesAsMenuContent = (ref) => { this.enterGradesAsMenuContent = ref };

  curveGrades = () => { this.invokeAndSkipFocus(this.props.curveGradesAction) };
  setDefaultGrades = () => { this.invokeAndSkipFocus(this.props.setDefaultGradeAction) };
  muteAssignment = () => { this.invokeAndSkipFocus(this.props.muteAssignmentAction) };
  downloadSubmissions = () => { this.invokeAndSkipFocus(this.props.downloadSubmissionsAction) };
  reuploadSubmissions = () => { this.invokeAndSkipFocus(this.props.reuploadSubmissionsAction) };

  invokeAndSkipFocus (action) {
    // this is because the onToggle handler in ColumnHeader.js is going to get
    // called synchronously, before the SetState takes effect, and it needs to
    // know to skipFocusOnClose
    this.state.skipFocusOnClose = true

    this.setState({ skipFocusOnClose: true }, () =>
      action.onSelect(this.focusAtEnd)
    );
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

  onEnterGradesAsSettingSelect = (_event, values) => {
    this.props.enterGradesAsSetting.onSelect(values[0]);
  }

  showMessageStudentsWhoDialog = () => {
    this.state.skipFocusOnClose = true
    this.setState({ skipFocusOnClose: true });
    const settings = MessageStudentsWhoHelper.settings(this.props.assignment, this.activeStudentDetails());
    settings.onClose = this.focusAtEnd;
    window.messageStudents(settings);
  }

  activeStudentDetails () {
    const activeStudents = this.props.students.filter(student => !student.isInactive);
    return activeStudents.map((student) => {
      const { excused, latePolicyStatus, score, submittedAt } = student.submission;
      return {
        excused,
        id: student.id,
        latePolicyStatus,
        name: student.name,
        score,
        submittedAt
      };
    });
  }

  renderAssignmentLink () {
    const assignment = this.props.assignment;

    return (
      <span className="assignment-name">
        <Link ref={this.bindAssignmentLink} href={assignment.htmlUrl}>
          {assignment.name}
        </Link>
      </span>
    );
  }

  renderTrigger () {
    const optionsTitle = I18n.t('%{name} Options', { name: this.props.assignment.name });

    return (
      <Button buttonRef={ref => this.optionsMenuTrigger = ref} size="small" variant="icon" icon={IconMoreSolid}>
        <ScreenReaderContent>{optionsTitle}</ScreenReaderContent>
      </Button>
    );
  }

  renderMenu () {
    if (!this.props.assignment.published) { return null; }

    const { sortBySetting } = this.props;
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey;

    return (
      <Menu
        contentRef={this.bindOptionsMenuContent}
        shouldFocusTriggerOnClose={false}
        trigger={this.renderTrigger()}
        onToggle={this.onToggle}
        onDismiss={this.props.onMenuDismiss}
      >
        <Menu contentRef={this.bindSortByMenuContent} label={I18n.t('Sort by')}>
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
        </Menu>

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

        { !this.props.enterGradesAsSetting.hidden && <MenuItemSeparator /> }

        {
          !this.props.enterGradesAsSetting.hidden && (
            <Menu contentRef={this.bindEnterGradesAsMenuContent} label={I18n.t('Enter Grades as')}>
              <MenuItemGroup
                label={<ScreenReaderContent>{I18n.t('Enter Grades as')}</ScreenReaderContent>}
                onSelect={this.onEnterGradesAsSettingSelect}
                selected={[this.props.enterGradesAsSetting.selected]}
              >
                <MenuItem value="points">
                  { I18n.t('Points') }
                </MenuItem>

                <MenuItem value="percent">
                  { I18n.t('Percentage') }
                </MenuItem>

                {
                  this.props.enterGradesAsSetting.showGradingSchemeOption && (
                    <MenuItem value="gradingScheme">
                      { I18n.t('Grading Scheme') }
                    </MenuItem>
                  )
                }
              </MenuItemGroup>
            </Menu>
          )
        }

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
      </Menu>
    );
  }

  render () {
    const classes = `Gradebook__ColumnHeaderAction ${this.state.menuShown ? 'menuShown' : ''}`;

    return (
      <div
        className={`Gradebook__ColumnHeaderContent ${this.state.hasFocus ? 'focused' : ''}`}
        onBlur={this.handleBlur}
        onFocus={this.handleFocus}
      >
        <div style={{ flex: 1, minWidth: '1px' }}>
          <Grid colSpacing="none" hAlign="space-between" vAlign="middle">
            <GridRow>
              <GridCol textAlign="center" width="auto">
                <div className="Gradebook__ColumnHeaderIndicators" />
              </GridCol>

              <GridCol textAlign="center">
                <span className="Gradebook__ColumnHeaderDetail">
                  <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--primary">
                    { this.renderAssignmentLink() }
                  </span>

                  <SecondaryDetailLine assignment={this.props.assignment} />
                </span>
              </GridCol>

              <GridCol textAlign="center" width="auto">
                <div className={classes}>
                  {this.renderMenu()}
                </div>
              </GridCol>
            </GridRow>
          </Grid>
        </div>
      </div>
    );
  }
}
