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
import I18n from 'i18n!assignments_2'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {bool, func} from 'prop-types'
import {TeacherAssignmentShape, UserShape} from '../../assignmentData'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Heading} from '@instructure/ui-heading'
import {Avatar} from '@instructure/ui-avatar'
import {Tray} from '@instructure/ui-tray'
/* import {DateTimeInput} from '@instructure/ui-forms' */
import OverrideAttempts from '../Overrides/OverrideAttempts'
import {
  IconArrowOpenEndLine,
  IconArrowOpenStartLine,
  IconEmailLine,
  IconSpeedGraderLine,
  IconUploadLine
} from '@instructure/ui-icons'
import MessageStudents from '@canvas/message-students-modal'

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
    onNextStudent: func
  }

  constructor(props) {
    super(props)
    this.state = {
      messageFormOpen: false,
      allowedAttempts: this.props.assignment.allowedAttempts
    }
  }

  renderTrayCloseButton() {
    return (
      <CloseButton placement="start" variant="icon" onClick={this.props.onHideTray}>
        {I18n.t('Close student details')}
      </CloseButton>
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
          <Avatar size="x-large" name={name} src={this.props.student.avatarUrl} data-fs-exclude />
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
      <Button
        href={speedgraderLink}
        margin="xx-small auto xx-small auto"
        icon={IconSpeedGraderLine}
        target="_blank"
        variant="link"
      >
        <Text transform="uppercase" size="small" lineHeight="fit">
          {I18n.t('SpeedGrader')}
        </Text>
      </Button>
    )
  }

  handleSubmitForStudent = () => {
    window.confirm('Submit for Student is not implemented yet')
  }

  handleMessageButtonClick = e => {
    e.preventDefault()
    this.setState({
      messageFormOpen: true
    })
  }

  handleMessageFormClose = e => {
    e.preventDefault()
    this.setState(
      {
        messageFormOpen: false
      },
      () => {
        this.messageStudentsButton.focus()
      }
    )
  }

  onChangeDueAt = (_event, newValue) => {
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
        <View display="block" margin="x-small none">
          <Button
            variant="link"
            icon={IconEmailLine}
            buttonRef={b => (this.messageStudentsButton = b)}
            onClick={this.handleMessageButtonClick}
            theme={{mediumPadding: '0', mediumHeight: '1.5rem'}}
          >
            {I18n.t('Message Student')}
          </Button>
        </View>
        <Button
          variant="link"
          icon={IconUploadLine}
          onClick={this.handleSubmitForStudent}
          theme={{mediumPadding: '0', mediumHeight: '1.5rem'}}
        >
          {I18n.t('Submit for Student')}
        </Button>
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
            stacked
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
      possible_points: this.props.assignment.pointsPossible
    })

    return (
      <Flex>
        <Flex.Item grow textAlign="center">
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
              <Flex.Item shrink textAlign="start">
                <Button
                  size="small"
                  variant="icon"
                  icon={IconArrowOpenStartLine}
                  onClick={this.props.onPreviousStudent}
                >
                  <ScreenReaderContent>{I18n.t('Previous student')}</ScreenReaderContent>
                </Button>
              </Flex.Item>
              <Flex.Item grow textAlign="center">
                <Heading level="h3" as="h2">
                  <Button
                    size="large"
                    href={studentProfileUrl}
                    aria-label={I18n.t("Go to %{name}'s profile", {name: student.shortName})}
                    target="_blank"
                    variant="link"
                    theme={{largePadding: '0.75rem', largeHeight: 'normal'}}
                  >
                    {student.shortName}
                  </Button>
                </Heading>
              </Flex.Item>
              <Flex.Item shrink textAlign="end">
                <Button
                  size="small"
                  variant="icon"
                  icon={IconArrowOpenEndLine}
                  onClick={this.props.onNextStudent}
                >
                  <ScreenReaderContent>{I18n.t('Next student')}</ScreenReaderContent>
                </Button>
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
                displayName: this.props.student.shortName
              }
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
