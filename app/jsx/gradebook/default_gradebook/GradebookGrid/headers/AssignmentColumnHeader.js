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

import React from 'react'
import {arrayOf, bool, func, instanceOf, number, shape, string} from 'prop-types'
import {IconMoreSolid, IconOffLine, IconOffSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-layout'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-elements'
import 'message_students'
import I18n from 'i18n!gradebook'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {isPostable} from '../../../../grading/helpers/SubmissionHelper'
import MessageStudentsWhoHelper from '../../../shared/helpers/messageStudentsWhoHelper'
import ColumnHeader from './ColumnHeader'

function SecondaryDetailLine(props) {
  const anonymous = props.assignment.anonymizeStudents
  const unpublished = !props.assignment.published

  if (anonymous || unpublished) {
    return (
      <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
        <Text color="error" size="x-small" transform="uppercase" weight="bold">
          {unpublished ? I18n.t('Unpublished') : I18n.t('Anonymous')}
        </Text>
      </span>
    )
  }

  const pointsPossible = I18n.n(props.assignment.pointsPossible || 0)

  return (
    <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
      <span className="assignment-points-possible">
        <Text weight="normal" fontStyle="normal" size="x-small">
          {I18n.t('Out of %{pointsPossible}', {pointsPossible})}
        </Text>
      </span>

      {props.postPoliciesEnabled &&
        props.newPostPolicyIconsEnabled &&
        props.assignment.postManually && (
          <span>
            &nbsp;
            <Text size="x-small" transform="uppercase" weight="bold">
              {I18n.t('Manual')}
            </Text>
          </span>
        )}

      {!props.postPoliciesEnabled && props.assignment.muted && (
        <span>
          &nbsp;
          <Text size="x-small" transform="uppercase" weight="bold">
            {I18n.t('Muted')}
          </Text>
        </span>
      )}
    </span>
  )
}

SecondaryDetailLine.propTypes = {
  assignment: shape({
    anonymizeStudents: bool.isRequired,
    muted: bool.isRequired,
    pointsPossible: number,
    published: bool.isRequired
  }).isRequired,
  newPostPolicyIconsEnabled: bool.isRequired,
  postPoliciesEnabled: bool.isRequired
}

function labelForPostGradesAction(postGradesAction) {
  if (postGradesAction.hasGradesOrCommentsToPost) {
    return I18n.t('Post grades')
  } else if (postGradesAction.hasGradesOrPostableComments) {
    return I18n.t('All grades posted')
  }

  return I18n.t('No grades to post')
}

function labelForHideGradesAction(hideGradesAction) {
  if (hideGradesAction.hasGradesOrCommentsToHide) {
    return I18n.t('Hide grades')
  } else if (hideGradesAction.hasGradesOrPostableComments) {
    return I18n.t('All grades hidden')
  }

  return I18n.t('No grades to hide')
}

function speedGraderUrl(assignment) {
  return encodeURI(
    `/courses/${assignment.courseId}/gradebook/speed_grader?assignment_id=${assignment.id}`
  )
}

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
      postManually: bool.isRequired,
      published: bool.isRequired,
      submissionTypes: arrayOf(string).isRequired
    }).isRequired,

    curveGradesAction: shape({
      isDisabled: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    hideGradesAction: shape({
      hasGradesOrCommentsToHide: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    includeSpeedGraderMenuItem: bool.isRequired,

    postGradesAction: shape({
      featureEnabled: bool.isRequired,
      hasGradesOrPostableComments: bool.isRequired,
      hasGradesOrCommentsToPost: bool.isRequired,
      newIconsEnabled: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    showGradePostingPolicyAction: shape({
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

    students: arrayOf(
      shape({
        id: string.isRequired,
        isInactive: bool.isRequired,
        isTestStudent: bool.isRequired,
        name: string.isRequired,
        sortableName: string.isRequired,
        submission: shape({
          excused: bool.isRequired,
          latePolicyStatus: string,
          postedAt: instanceOf(Date),
          score: number,
          submittedAt: instanceOf(Date),
          workflowState: string.isRequired
        }).isRequired
      })
    ).isRequired,

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

    onMenuDismiss: func.isRequired,
    showUnpostedMenuItem: bool.isRequired
  }

  static defaultProps = {
    ...ColumnHeader.defaultProps
  }

  bindAssignmentLink = ref => {
    this.assignmentLink = ref
  }

  bindEnterGradesAsMenuContent = ref => {
    this.enterGradesAsMenuContent = ref
  }

  curveGrades = () => {
    this.invokeAndSkipFocus(this.props.curveGradesAction)
  }

  hideGrades = () => {
    this.invokeAndSkipFocus(this.props.hideGradesAction)
  }

  postGrades = () => {
    this.invokeAndSkipFocus(this.props.postGradesAction)
  }

  setDefaultGrades = () => {
    this.invokeAndSkipFocus(this.props.setDefaultGradeAction)
  }

  downloadSubmissions = () => {
    this.invokeAndSkipFocus(this.props.downloadSubmissionsAction)
  }

  reuploadSubmissions = () => {
    this.invokeAndSkipFocus(this.props.reuploadSubmissionsAction)
  }

  showGradePostingPolicy = () => {
    this.invokeAndSkipFocus(this.props.showGradePostingPolicyAction)
  }

  invokeAndSkipFocus(action) {
    // this is because the onToggle handler in ColumnHeader.js is going to get
    // called synchronously, before the SetState takes effect, and it needs to
    // know to skipFocusOnClose
    this.state.skipFocusOnClose = true

    this.setState({skipFocusOnClose: true}, () => action.onSelect(this.focusAtEnd))
  }

  focusAtStart = () => {
    this.assignmentLink.focus()
  }

  handleKeyDown = event => {
    if (event.which === 9) {
      if (this.assignmentLink.focused && !event.shiftKey) {
        event.preventDefault()
        this.optionsMenuTrigger.focus()
        return false // prevent Grid behavior
      }

      if (document.activeElement === this.optionsMenuTrigger && event.shiftKey) {
        event.preventDefault()
        this.assignmentLink.focus()
        return false // prevent Grid behavior
      }
    }

    return ColumnHeader.prototype.handleKeyDown.call(this, event)
  }

  onEnterGradesAsSettingSelect = (_event, values) => {
    this.props.enterGradesAsSetting.onSelect(values[0])
  }

  showMessageStudentsWhoDialog = () => {
    this.state.skipFocusOnClose = true
    this.setState({skipFocusOnClose: true})
    const settings = MessageStudentsWhoHelper.settings(
      this.props.assignment,
      this.activeStudentDetails()
    )
    settings.onClose = this.focusAtEnd
    window.messageStudents(settings)
  }

  activeStudentDetails() {
    const activeStudents = this.props.students.filter(
      student => !student.isInactive && !student.isTestStudent
    )
    return activeStudents.map(student => {
      const {excused, latePolicyStatus, score, submittedAt} = student.submission
      return {
        excused,
        id: student.id,
        latePolicyStatus,
        name: student.name,
        score,
        sortableName: student.sortableName,
        submittedAt
      }
    })
  }

  renderAssignmentLink() {
    const assignment = this.props.assignment

    return (
      <Button
        size="small"
        variant="link"
        theme={{smallPadding: '0', smallFontSize: '0.75rem', smallHeight: '1rem'}}
        ref={this.bindAssignmentLink}
        href={assignment.htmlUrl}
      >
        <span className="assignment-name">{assignment.name}</span>
      </Button>
    )
  }

  renderTrigger() {
    const optionsTitle = I18n.t('%{name} Options', {name: this.props.assignment.name})

    return (
      <Button
        buttonRef={ref => (this.optionsMenuTrigger = ref)}
        size="small"
        variant="icon"
        icon={IconMoreSolid}
      >
        <ScreenReaderContent>{optionsTitle}</ScreenReaderContent>
      </Button>
    )
  }

  renderMenu() {
    if (!this.props.assignment.published) {
      return null
    }

    const {sortBySetting} = this.props
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey

    return (
      <Menu
        contentRef={this.bindOptionsMenuContent}
        shouldFocusTriggerOnClose={false}
        trigger={this.renderTrigger()}
        onToggle={this.onToggle}
        onDismiss={this.props.onMenuDismiss}
      >
        <Menu contentRef={this.bindSortByMenuContent} label={I18n.t('Sort by')}>
          <Menu.Group label={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}>
            <Menu.Item
              selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'ascending'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByGradeAscending}
            >
              {I18n.t('Grade - Low to High')}
            </Menu.Item>

            <Menu.Item
              selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'descending'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByGradeDescending}
            >
              {I18n.t('Grade - High to Low')}
            </Menu.Item>

            <Menu.Item
              selected={selectedSortSetting === 'missing'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByMissing}
            >
              {I18n.t('Missing')}
            </Menu.Item>

            <Menu.Item
              selected={selectedSortSetting === 'late'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByLate}
            >
              {I18n.t('Late')}
            </Menu.Item>

            {this.props.showUnpostedMenuItem && (
              <Menu.Item
                selected={selectedSortSetting === 'unposted'}
                disabled={sortBySetting.disabled}
                onSelect={sortBySetting.onSortByUnposted}
              >
                {I18n.t('Unposted')}
              </Menu.Item>
            )}
          </Menu.Group>
        </Menu>

        {this.props.includeSpeedGraderMenuItem && (
          <Menu.Item href={speedGraderUrl(this.props.assignment)}>
            {I18n.t('SpeedGrader')}
          </Menu.Item>
        )}

        <Menu.Item
          disabled={!this.props.submissionsLoaded || this.props.assignment.anonymizeStudents}
          onSelect={this.showMessageStudentsWhoDialog}
        >
          <span data-menu-item-id="message-students-who">{I18n.t('Message Students Who')}</span>
        </Menu.Item>

        <Menu.Item disabled={this.props.curveGradesAction.isDisabled} onSelect={this.curveGrades}>
          <span data-menu-item-id="curve-grades">{I18n.t('Curve Grades')}</span>
        </Menu.Item>

        <Menu.Item
          disabled={this.props.setDefaultGradeAction.disabled}
          onSelect={this.setDefaultGrades}
        >
          <span data-menu-item-id="set-default-grade">{I18n.t('Set Default Grade')}</span>
        </Menu.Item>

        <Menu.Item
          disabled={!this.props.postGradesAction.hasGradesOrCommentsToPost}
          onSelect={this.postGrades}
        >
          {labelForPostGradesAction(this.props.postGradesAction)}
        </Menu.Item>

        {this.props.postGradesAction.featureEnabled && (
          <Menu.Item
            disabled={!this.props.hideGradesAction.hasGradesOrCommentsToHide}
            onSelect={this.hideGrades}
          >
            {labelForHideGradesAction(this.props.hideGradesAction)}
          </Menu.Item>
        )}

        {!this.props.enterGradesAsSetting.hidden && <Menu.Separator />}

        {!this.props.enterGradesAsSetting.hidden && (
          <Menu contentRef={this.bindEnterGradesAsMenuContent} label={I18n.t('Enter Grades as')}>
            <Menu.Group
              label={<ScreenReaderContent>{I18n.t('Enter Grades as')}</ScreenReaderContent>}
              onSelect={this.onEnterGradesAsSettingSelect}
              selected={[this.props.enterGradesAsSetting.selected]}
            >
              <Menu.Item value="points">{I18n.t('Points')}</Menu.Item>

              <Menu.Item value="percent">{I18n.t('Percentage')}</Menu.Item>

              {this.props.enterGradesAsSetting.showGradingSchemeOption && (
                <Menu.Item value="gradingScheme">{I18n.t('Grading Scheme')}</Menu.Item>
              )}
            </Menu.Group>
          </Menu>
        )}

        {!(
          this.props.downloadSubmissionsAction.hidden && this.props.reuploadSubmissionsAction.hidden
        ) && <Menu.Separator />}

        {!this.props.downloadSubmissionsAction.hidden && (
          <Menu.Item onSelect={this.downloadSubmissions}>
            <span data-menu-item-id="download-submissions">{I18n.t('Download Submissions')}</span>
          </Menu.Item>
        )}

        {!this.props.reuploadSubmissionsAction.hidden && (
          <Menu.Item onSelect={this.reuploadSubmissions}>
            <span data-menu-item-id="reupload-submissions">{I18n.t('Re-Upload Submissions')}</span>
          </Menu.Item>
        )}

        {this.props.postGradesAction.featureEnabled && <Menu.Separator />}

        {this.props.postGradesAction.featureEnabled && (
          <Menu.Item onSelect={this.showGradePostingPolicy}>
            {I18n.t('Grade Posting Policy')}
          </Menu.Item>
        )}
      </Menu>
    )
  }

  renderUnpostedSubmissionsIcon(newIconsEnabled) {
    if (!this.props.submissionsLoaded) {
      return null
    }

    const submissions = this.props.students.map(student => student.submission)
    const postableSubmissionsPresent = submissions.some(isPostable)

    if (newIconsEnabled) {
      // Assignment has at least one hidden submission that can be posted
      // and "new icons" are enabled so use the line version of the icon
      if (postableSubmissionsPresent) {
        return <IconOffLine size="x-small" />
      }
    } else {
      // Assignment is manually-posted and has no graded-but-unposted submissions
      // (i.e., no unposted submissions that are in a suitable state to post)
      if (this.props.assignment.postManually && !postableSubmissionsPresent) {
        return <IconOffLine size="x-small" />
      }

      // Assignment has at least one hidden submission that can be posted
      // (regardless of whether it's manually or automatically posted)
      if (postableSubmissionsPresent) {
        return <IconOffSolid color="warning" size="x-small" />
      }
    }

    return null
  }

  render() {
    const classes = `Gradebook__ColumnHeaderAction ${this.state.menuShown ? 'menuShown' : ''}`
    const newPostPolicyIconsEnabled = this.props.postGradesAction.newIconsEnabled
    const postPoliciesEnabled = this.props.postGradesAction.featureEnabled

    return (
      <div
        className={`Gradebook__ColumnHeaderContent ${this.state.hasFocus ? 'focused' : ''}`}
        onBlur={this.handleBlur}
        onFocus={this.handleFocus}
      >
        <div style={{flex: 1, minWidth: '1px'}}>
          <Grid colSpacing="none" hAlign="space-between" vAlign="middle">
            <Grid.Row>
              <Grid.Col textAlign="center" width="auto" vAlign="top">
                <div className="Gradebook__ColumnHeaderIndicators">
                  {postPoliciesEnabled &&
                    this.renderUnpostedSubmissionsIcon(newPostPolicyIconsEnabled)}
                </div>
              </Grid.Col>

              <Grid.Col textAlign="center">
                <span className="Gradebook__ColumnHeaderDetail">
                  <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--primary">
                    {this.renderAssignmentLink()}
                  </span>

                  <SecondaryDetailLine
                    assignment={this.props.assignment}
                    newPostPolicyIconsEnabled={newPostPolicyIconsEnabled}
                    postPoliciesEnabled={postPoliciesEnabled}
                  />
                </span>
              </Grid.Col>

              <Grid.Col textAlign="center" width="auto">
                <div className={classes}>{this.renderMenu()}</div>
              </Grid.Col>
            </Grid.Row>
          </Grid>
        </div>
      </div>
    )
  }
}
