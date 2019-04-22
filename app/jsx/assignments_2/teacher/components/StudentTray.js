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

import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

import {bool, func} from 'prop-types'
import {TeacherAssignmentShape, UserShape} from '../assignmentData'

import {Flex, FlexItem, View} from '@instructure/ui-layout'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Avatar, Heading, Link, Text} from '@instructure/ui-elements'
import {Tray} from '@instructure/ui-overlays'
import {
  IconArrowOpenEndLine,
  IconArrowOpenStartLine,
  IconEmailLine,
  IconSpeedGraderLine,
  IconUploadLine
} from '@instructure/ui-icons'
import MessageStudents from 'jsx/shared/MessageStudents'

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
      messageFormOpen: false
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
          <Avatar size="x-large" name={name} src={this.props.student.avatarUrl} />
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
        margin="xx-small auto xx-small auto"
        icon={<IconSpeedGraderLine />}
        iconPlacement="start"
        target="_blank"
      >
        <Text transform="uppercase" size="small" lineHeight="fit">
          {I18n.t('SpeedGrader')}
        </Text>
      </Link>
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

  renderActionLinks() {
    return (
      <React.Fragment>
        <Link
          icon={<IconEmailLine />}
          iconPlacement="start"
          linkRef={b => (this.messageStudentsButton = b)}
          onClick={this.handleMessageButtonClick}
          margin="small auto auto auto"
        >
          <Text color="primary">{I18n.t('Message Student')}</Text>
        </Link>

        <Link
          icon={<IconUploadLine />}
          iconPlacement="start"
          onClick={this.handleSubmitForStudent}
          margin="small auto auto auto"
        >
          <Text color="primary">{I18n.t('Submit for Student')}</Text>
        </Link>
      </React.Fragment>
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
        <FlexItem grow textAlign="center">
          <Text as="p" weight="bold" lineHeight="fit">
            {this.props.assignment.name}
          </Text>
          <Text as="p" lineHeight="fit">
            {displayString}
          </Text>
          {this.renderSpeedgraderLink()}
        </FlexItem>
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
              <FlexItem shrink textAlign="start">
                <Button
                  size="small"
                  variant="icon"
                  icon={IconArrowOpenStartLine}
                  onClick={this.props.onPreviousStudent}
                >
                  <ScreenReaderContent>{I18n.t('Previous student')}</ScreenReaderContent>
                </Button>
              </FlexItem>
              <FlexItem grow textAlign="center">
                <Heading level="h3" as="h2">
                  <Link
                    href={studentProfileUrl}
                    aria-label={I18n.t("Go to %{name}'s profile", {name: student.shortName})}
                    target="_blank"
                  >
                    {student.shortName}
                  </Link>
                </Heading>
              </FlexItem>
              <FlexItem shrink textAlign="end">
                <Button
                  size="small"
                  variant="icon"
                  icon={IconArrowOpenEndLine}
                  onClick={this.props.onNextStudent}
                >
                  <ScreenReaderContent>{I18n.t('Next student')}</ScreenReaderContent>
                </Button>
              </FlexItem>
            </Flex>
          </div>

          <View as="div" borderWidth="small 0" margin="small 0">
            {this.renderStudentSummary()}
          </View>
        </header>

        <Heading level="h4" as="h3" margin="medium auto auto auto">
          {I18n.t('Actions')}
        </Heading>
        {this.renderActionLinks()}
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
