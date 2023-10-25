/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'

import {bool, func} from 'prop-types'
import {TeacherAssignmentShape, UserShape} from '../../assignmentData'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {CloseButton, IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Heading} from '@instructure/ui-heading'
import {Avatar} from '@instructure/ui-avatar'
import {Tray} from '@instructure/ui-tray'
import OverrideAttempts from '../Overrides/OverrideAttempts'
import {
  IconArrowOpenEndLine,
  IconArrowOpenStartLine,
  IconEmailLine,
  IconSpeedGraderLine,
  IconUploadLine,
} from '@instructure/ui-icons'
import MessageStudents from '@canvas/message-students-modal'

const I18n = useI18nScope('assignments_2')

/*
 *  CAUTION: The InstUI DateTimeInput component was deprecated in v7.
 *  Rather than perform the InstUI upgrade for this part of assignments
 *  2, we are just going to short out those components and skip the tests.
 */
const DateTimeInput = () => <div className="fake-editable-datetime" />

export default class StudentTray extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    student: UserShape.isRequired,
    trayOpen: bool.isRequired,
    onHideTray: func,
    onPreviousStudent: func,
    onNextStudent: func,
  }

  constructor(props) {
    super(props)
    this.state = {
      messageFormOpen: false,
      allowedAttempts: this.props.assignment.allowedAttempts,
    }
  }

  renderTrayCloseButton() {
    return (
      <CloseButton
        placement="start"
        onClick={this.props.onHideTray}
        screenReaderLabel={I18n.t('Close student details')}
      />
    )
  }

  renderAvatar() {
    const name = this.props.student.shortName || this.props.student.name || I18n.t('User')
    return (
      <View textAlign="center" display="block" margin="auto auto small auto">
        <Link
          href={`/courses/${this.props.assignment.course.lid}/users/${this.props.student.lid}`}
          aria-label={I18n.t("Go to %{name}'s profile", {name})}
          target="_blank"
        >
          <Avatar
            size="x-large"
            name={name}
            src={this.props.student.avatarUrl}
            data-fs-exclude={true}
          />
        </Link>
      </View>
    )
  }

  renderSpeedgraderLink() {
    const assignmentLid = this.props.assignment.lid
    const courseLid = this.props.assignment.course.lid
    const studentLid = this.props.student.lid
    const speedgraderLink = encodeURI(
      `/courses/${courseLid}/gradebook/speed_grader?assignment_id=${assignmentLid}#{"student_id":"${studentLid}"}`
    )
    return (
      <Link
        href={speedgraderLink}
        isWithinText={false}
        margin="xx-small auto xx-small auto"
        renderIcon={IconSpeedGraderLine}
        target="_blank"
      >
        <Text transform="uppercase" size="small" lineHeight="fit">
          {I18n.t('SpeedGrader')}
        </Text>
      </Link>
    )
  }

  handleSubmitForStudent = () => {
    // eslint-disable-next-line no-alert
    window.confirm('Submit for Student is not implemented yet')
  }

  handleMessageButtonClick = e => {
    e.preventDefault()
    this.setState({
      messageFormOpen: true,
    })
  }

  handleMessageFormClose = e => {
    e.preventDefault()
    this.setState(
      {
        messageFormOpen: false,
      },
      () => {
        this.messageStudentsButton.focus()
      }
    )
  }

  onChangeDueAt = (_event, newValue) => {
    // Should we be using this.state.dueAt with <DateTimeInput> below?
    // eslint-disable-next-line react/no-unused-state
    this.setState({dueAt: newValue})
  }

  onChangeAttempts = (field, newValue) => {
    this.setState({allowedAttempts: newValue})
  }

  renderActionLinks() {
    return (
      <>
        <Heading level="h4" as="h3" margin="medium auto auto auto">
          {I18n.t('Actions')}
        </Heading>
        <View display="block" margin="x-small none" padding="small">
          <Link
            as="button"
            renderIcon={IconEmailLine}
            elementRef={b => (this.messageStudentsButton = b)}
            onClick={this.handleMessageButtonClick}
            isWithinText={false}
            themeOverride={{
              iconSize: '1.25rem',
              mediumPaddingHorizontal: '0',
              mediumHeight: '1',
              iconPlusTextMargin: '.5rem',
            }}
          >
            {I18n.t('Message Student')}
          </Link>
          <Link
            as="button"
            renderIcon={IconUploadLine}
            onClick={this.handleSubmitForStudent}
            isWithinText={false}
            margin="small auto auto auto"
            themeOverride={{
              iconSize: '1.25rem',
              mediumPaddingHorizontal: '0',
              mediumHeight: '1.5rem',
              iconPlusTextMargin: '.5rem',
            }}
          >
            {I18n.t('Submit for Student')}
          </Link>
        </View>
      </>
    )
  }

  renderOverrideActions() {
    const hasDueDate = this.props.assignment.dueAt !== null
    return (
      <>
        <View as="div" margin="medium auto auto auto">
          <DateTimeInput
            description={I18n.t('Extend Due Date')}
            label={I18n.t('Extend Due Date')}
            dateLabel={I18n.t('Date')}
            datePreviousLabel={I18n.t('previous')}
            dateNextLabel={I18n.t('next')}
            timeLabel={I18n.t('Time')}
            onChange={this.onChangeDueAt}
            layout="stacked"
            value={hasDueDate ? this.props.assignment.dueAt : null}
            invalidDateTimeMessage={I18n.t('Invalid date and time')}
            messages={this.state.messages}
          />
        </View>

        <View as="div" margin="small auto auto auto">
          <OverrideAttempts
            allowedAttempts={this.state.allowedAttempts}
            variant="detail"
            stacked={true}
            onChange={this.onChangeAttempts}
          />
        </View>
      </>
    )
  }

  renderStudentSummary() {
    const submission = this.props.student.submission
    const validScore = submission.score || submission.score === 0
    const displayString = I18n.t('Score {{student_points}}/{{possible_points}}', {
      student_points: validScore ? submission.score : '\u2013',
      possible_points: this.props.assignment.pointsPossible,
    })

    return (
      <Flex>
        <Flex.Item shouldGrow={true} textAlign="center">
          <Text as="p" weight="bold" lineHeight="fit">
            {this.props.assignment.name}
          </Text>
          <Text as="p" lineHeight="fit">
            {displayString}
          </Text>
          {this.renderSpeedgraderLink()}
        </Flex.Item>
      </Flex>
    )
  }

  renderTrayBody() {
    const student = this.props.student
    const studentProfileUrl = `/courses/${this.props.assignment.course.lid}/users/${student.lid}`

    return (
      <View as="aside" padding="small medium 0">
        <header>
          {this.renderAvatar()}

          <div style={{margin: '0 auto auto -10%', width: '120%'}}>
            <Flex>
              <Flex.Item shouldShrink={true} textAlign="start">
                <IconButton
                  size="small"
                  renderIcon={IconArrowOpenStartLine}
                  withBackground={false}
                  withBorder={false}
                  onClick={this.props.onPreviousStudent}
                  screenReaderLabel={I18n.t('Previous student')}
                />
              </Flex.Item>
              <Flex.Item shouldGrow={true} textAlign="center">
                <Heading level="h3" as="h2">
                  <Link
                    size="large"
                    href={studentProfileUrl}
                    isWithinText={false}
                    aria-label={I18n.t("Go to %{name}'s profile", {name: student.shortName})}
                    target="_blank"
                    themeOverride={{largePadding: '0.75rem', largeHeight: 'normal'}}
                  >
                    {student.shortName}
                  </Link>
                </Heading>
              </Flex.Item>
              <Flex.Item shouldShrink={true} textAlign="end">
                <IconButton
                  size="small"
                  renderIcon={IconArrowOpenEndLine}
                  withBackground={false}
                  withBorder={false}
                  onClick={this.props.onNextStudent}
                  screenReaderLabel={I18n.t('Next student')}
                />
              </Flex.Item>
            </Flex>
          </div>

          <View as="div" borderWidth="small 0" margin="small 0">
            {this.renderStudentSummary()}
          </View>
        </header>

        {this.renderActionLinks()}
        {this.renderOverrideActions()}
      </View>
    )
  }

  render() {
    return (
      <div>
        {this.state.messageFormOpen ? (
          <MessageStudents
            contextCode={`course_${this.props.assignment.course.lid}`}
            onRequestClose={this.handleMessageFormClose}
            open={this.state.messageFormOpen}
            recipients={[
              {
                id: this.props.student.lid,
                displayName: this.props.student.shortName,
              },
            ]}
            title={I18n.t('Send a message')}
          />
        ) : null}

        <Tray
          label={I18n.t('Student Details')}
          open={this.props.trayOpen}
          onDismiss={this.props.onHideTray}
          placement="end"
        >
          <View as="div" padding="medium">
            {this.renderTrayCloseButton()}
            {this.renderTrayBody()}
          </View>
        </Tray>
      </div>
    )
  }
}
