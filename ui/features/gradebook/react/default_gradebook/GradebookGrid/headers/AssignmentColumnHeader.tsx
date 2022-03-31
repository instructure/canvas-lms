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
import ReactDOM from 'react-dom'
import {arrayOf, bool, func, instanceOf, number, shape, string} from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {IconMoreSolid, IconOffLine} from '@instructure/ui-icons'
import {Grid} from '@instructure/ui-grid'
import {Menu} from '@instructure/ui-menu'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ApolloProvider} from 'react-apollo'
import {createClient} from '@canvas/apollo'

import {isPostable} from '@canvas/grading/SubmissionHelper'
import AsyncComponents from '../../AsyncComponents'
import ColumnHeader from './ColumnHeader'

import {Link} from '@instructure/ui-link'

const {Separator: MenuSeparator, Item: MenuItem, Group: MenuGroup} = Menu as any

const I18n = useI18nScope('gradebook')

function SecondaryDetailLine(props) {
  const anonymous = props.assignment.anonymizeStudents
  const unpublished = !props.assignment.published

  if (anonymous || unpublished) {
    return (
      <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
        <Text color="danger" size="x-small" transform="uppercase" weight="bold">
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

      {props.assignment.postManually && (
        <span>
          &nbsp;
          <Text size="x-small" transform="uppercase" weight="bold">
            {I18n.t('Manual')}
          </Text>
        </span>
      )}
    </span>
  )
}

SecondaryDetailLine.propTypes = {
  assignment: shape({
    anonymizeStudents: bool.isRequired,
    pointsPossible: number,
    published: bool.isRequired
  }).isRequired
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

type Props = {
  allStudents: any
  assignment: any
  curveGradesAction: any
  downloadSubmissionsAction: any
  enterGradesAsSetting: any
  getCurrentlyShownStudents: any
  hideGradesAction: any
  messageAttachmentUploadFolderId: string
  onMenuDismiss: any
  postGradesAction: any
  reuploadSubmissionsAction: any
  setDefaultGradeAction: any
  showGradePostingPolicyAction: any
  showMessageStudentsWithObserversDialog: any
  showUnpostedMenuItem: any
  sortBySetting: any
  submissionsLoaded: boolean
}

type State = {
  hasFocus: boolean
  isMenuFocused: boolean
  isMenuOpen: boolean
  menuShown: boolean
  skipFocusOnClose: boolean
}

export default class AssignmentColumnHeader extends ColumnHeader<Props, State> {
  assignmentLink: any

  enterGradesAsMenuContent: any

  static propTypes = {
    ...ColumnHeader.propTypes,

    allStudents: arrayOf(
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

    assignment: shape({
      anonymizeStudents: bool.isRequired,
      courseId: string.isRequired,
      htmlUrl: string.isRequired,
      gradingType: string.isRequired,
      id: string.isRequired,
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

    getCurrentlyShownStudents: func.isRequired,

    hideGradesAction: shape({
      hasGradesOrCommentsToHide: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    postGradesAction: shape({
      enabledForUser: bool.isRequired,
      hasGradesOrPostableComments: bool.isRequired,
      hasGradesOrCommentsToPost: bool.isRequired,
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
    showMessageStudentsWithObserversDialog: bool.isRequired,
    showUnpostedMenuItem: bool.isRequired,
    messageAttachmentUploadFolderId: string.isRequired
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
    // @ts-ignore
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

  // TODO(EVAL): This needs to be implemented in EVAL-2064.
  handleSendMessageStudentsWho = () => {}

  showMessageStudentsWhoDialog = async () => {
    // @ts-ignore
    this.state.skipFocusOnClose = true
    this.setState({skipFocusOnClose: true})

    const options = {
      assignment: this.props.assignment,
      students: this.activeStudentDetails()
    }

    if (this.props.showMessageStudentsWithObserversDialog) {
      const mountPoint = document.querySelector(
        "[data-component='MessageStudentsWithObserversModal']"
      )
      if (mountPoint != null) {
        const MessageStudentsWhoDialog =
          await AsyncComponents.loadMessageStudentsWithObserversDialog()

        const props = {
          ...options,
          onClose: () => {
            ReactDOM.unmountComponentAtNode(mountPoint)
            this.focusAtEnd()
          },
          onSend: this.handleSendMessageStudentsWho,
          messageAttachmentUploadFolderId: this.props.messageAttachmentUploadFolderId
        }
        ReactDOM.render(
          <ApolloProvider client={createClient()}>
            <MessageStudentsWhoDialog {...props} />
          </ApolloProvider>,
          mountPoint
        )
      }
    } else {
      const MessageStudentsWhoDialog = await AsyncComponents.loadMessageStudentsWhoDialog()

      MessageStudentsWhoDialog.show(options, this.focusAtEnd)
    }
  }

  activeStudentDetails() {
    const activeStudents = this.props
      .getCurrentlyShownStudents()
      .filter(student => !student.isInactive && !student.isTestStudent)

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
      <Link
        size="small"
        theme={{smallPaddingHorizontal: '0', smallFontSize: '0.75rem', smallHeight: '1rem'}}
        ref={this.bindAssignmentLink}
        href={assignment.htmlUrl}
        isWithinText={false}
      >
        <span className="assignment-name">{assignment.name}</span>
      </Link>
    )
  }

  renderTrigger() {
    const optionsTitle = I18n.t('%{name} Options', {name: this.props.assignment.name})

    return (
      <IconButton
        elementRef={ref => (this.optionsMenuTrigger = ref)}
        size="small"
        renderIcon={IconMoreSolid}
        withBackground={false}
        withBorder={false}
        screenReaderLabel={optionsTitle}
      />
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
          <MenuGroup label={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}>
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

            {this.props.showUnpostedMenuItem && (
              <MenuItem
                selected={selectedSortSetting === 'unposted'}
                disabled={sortBySetting.disabled}
                onSelect={sortBySetting.onSortByUnposted}
              >
                {I18n.t('Unposted')}
              </MenuItem>
            )}
          </MenuGroup>
        </Menu>

        <MenuItem href={speedGraderUrl(this.props.assignment)} target="_blank">
          {I18n.t('SpeedGrader')}
        </MenuItem>

        <MenuItem
          disabled={!this.props.submissionsLoaded || this.props.assignment.anonymizeStudents}
          onSelect={this.showMessageStudentsWhoDialog}
        >
          <span data-menu-item-id="message-students-who">{I18n.t('Message Students Who')}</span>
        </MenuItem>

        <MenuItem disabled={this.props.curveGradesAction.isDisabled} onSelect={this.curveGrades}>
          <span data-menu-item-id="curve-grades">{I18n.t('Curve Grades')}</span>
        </MenuItem>

        <MenuItem
          disabled={this.props.setDefaultGradeAction.disabled}
          onSelect={this.setDefaultGrades}
        >
          <span data-menu-item-id="set-default-grade">{I18n.t('Set Default Grade')}</span>
        </MenuItem>

        {this.props.postGradesAction.enabledForUser && (
          <MenuItem
            disabled={!this.props.postGradesAction.hasGradesOrCommentsToPost}
            onSelect={this.postGrades}
          >
            {labelForPostGradesAction(this.props.postGradesAction)}
          </MenuItem>
        )}

        {this.props.postGradesAction.enabledForUser && (
          <MenuItem
            disabled={!this.props.hideGradesAction.hasGradesOrCommentsToHide}
            onSelect={this.hideGrades}
          >
            {labelForHideGradesAction(this.props.hideGradesAction)}
          </MenuItem>
        )}

        {!this.props.enterGradesAsSetting.hidden && <MenuSeparator />}

        {!this.props.enterGradesAsSetting.hidden && (
          <Menu contentRef={this.bindEnterGradesAsMenuContent} label={I18n.t('Enter Grades as')}>
            <MenuGroup
              label={<ScreenReaderContent>{I18n.t('Enter Grades as')}</ScreenReaderContent>}
              onSelect={this.onEnterGradesAsSettingSelect}
              selected={[this.props.enterGradesAsSetting.selected]}
            >
              <MenuItem value="points">{I18n.t('Points')}</MenuItem>

              <MenuItem value="percent">{I18n.t('Percentage')}</MenuItem>

              {this.props.enterGradesAsSetting.showGradingSchemeOption && (
                <MenuItem value="gradingScheme">{I18n.t('Grading Scheme')}</MenuItem>
              )}
            </MenuGroup>
          </Menu>
        )}

        {!(
          this.props.downloadSubmissionsAction.hidden && this.props.reuploadSubmissionsAction.hidden
        ) && <MenuSeparator />}

        {!this.props.downloadSubmissionsAction.hidden && (
          <MenuItem onSelect={this.downloadSubmissions}>
            <span data-menu-item-id="download-submissions">{I18n.t('Download Submissions')}</span>
          </MenuItem>
        )}

        {!this.props.reuploadSubmissionsAction.hidden && (
          <MenuItem onSelect={this.reuploadSubmissions}>
            <span data-menu-item-id="reupload-submissions">{I18n.t('Re-Upload Submissions')}</span>
          </MenuItem>
        )}

        {this.props.postGradesAction.enabledForUser && <MenuSeparator />}

        {this.props.postGradesAction.enabledForUser && (
          <MenuItem onSelect={this.showGradePostingPolicy}>
            {I18n.t('Grade Posting Policy')}
          </MenuItem>
        )}
      </Menu>
    )
  }

  renderUnpostedSubmissionsIcon() {
    if (!this.props.submissionsLoaded) {
      return null
    }

    const submissions = this.props.allStudents.map(student => student.submission)
    const postableSubmissionsPresent = submissions.some(isPostable)

    // Assignment has at least one hidden submission that can be posted
    if (postableSubmissionsPresent) {
      return <IconOffLine size="x-small" />
    }

    return null
  }

  render() {
    const classes = `Gradebook__ColumnHeaderAction ${this.state.menuShown ? 'menuShown' : ''}`

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
                  {this.renderUnpostedSubmissionsIcon()}
                </div>
              </Grid.Col>

              <Grid.Col textAlign="center">
                <span className="Gradebook__ColumnHeaderDetail">
                  <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--primary">
                    {this.renderAssignmentLink()}
                  </span>

                  <SecondaryDetailLine assignment={this.props.assignment} />
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
