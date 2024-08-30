/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {bool, func} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {sendMessageStudentsWho} from '../api'
import {hasSubmitted, hasSubmission, hasGraded} from '@canvas/grading/messageStudentsWhoHelper'
import {TeacherAssignmentShape} from '../assignmentData'
import ConfirmDialog from './ConfirmDialog'
import MessageStudentsWhoForm from './MessageStudentsWhoForm'
import {captureException} from '@sentry/browser'

const I18n = useI18nScope('assignments_2')

export default class MessageStudentsWhoDialog extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape,
    open: bool.isRequired,
    onClose: func.isRequired,
  }

  constructor(...args) {
    super(...args)
    this.state = {
      sendingMessagesNow: false,
      selectedFilter: hasSubmission(this.props.assignment) ? 'not-submitted' : 'not-graded',
      pointsThreshold: null,
      subject: '',
      body: '',
      selectedStudents: [],
    }
  }

  componentDidMount() {
    // using componentDidMount is not ideal, but its an easy way to share the code.
    this.handleFilterChange(this.state.selectedFilter)
  }

  messageStudentsWhoButtonProps = () => [
    {
      children: I18n.t('Cancel'),
      onClick: this.props.onClose,
    },
    {
      children: I18n.t('Send'),
      variant: 'primary',
      onClick: this.handleSend,
      disabled:
        this.state.subject.length === 0 ||
        this.state.body.length === 0 ||
        this.state.selectedStudents.length === 0,
    },
  ]

  findStudentsWith(submissionSelector) {
    const selectedSubmissions = this.props.assignment.submissions.nodes.filter(submissionSelector)
    return selectedSubmissions.map(submission => submission.user.lid)
  }

  handleFilterChange = selectedFilter => {
    this.setState({selectedFilter})
    if (selectedFilter === 'not-submitted') this.handleNotSubmitted()
    else if (selectedFilter === 'not-graded') this.handleNotGraded()
    else if (selectedFilter === 'less-than') this.handleLessThan()
    else if (selectedFilter === 'more-than') this.handleMoreThan()
    else {
      const errorMessage = 'MessageStudentsWhoDialog error: unrecognized filter'
      // eslint-disable-next-line no-console
      console.error(errorMessage, selectedFilter)
      captureException(new Error(errorMessage))
    }
  }

  handlePointsChange = newPointsThreshold => {
    // important to set pointsThreshold first so the filter handlers will see the updated value
    this.setState({pointsThreshold: newPointsThreshold})
    this.handleFilterChange(this.state.selectedFilter)
  }

  handleNotSubmitted() {
    this.setState({
      subject: I18n.t('No submission for %{assignmentTitle}', {
        assignmentTitle: this.props.assignment.name,
      }),
      selectedStudents: this.findStudentsWith(submission => !hasSubmitted(submission)),
    })
  }

  handleNotGraded() {
    this.setState({
      subject: I18n.t('No grade for %{assignmentTitle}', {
        assignmentTitle: this.props.assignment.name,
      }),
      selectedStudents: this.findStudentsWith(submission => !hasGraded(submission)),
    })
  }

  handleLessThan() {
    this.setState(state => ({
      subject: I18n.t('Scored less than %{score} on %{assignmentTitle}', {
        score: state.pointsThreshold ? state.pointsThreshold.toString() : 0,
        assignmentTitle: this.props.assignment.name,
      }),
      selectedStudents: this.findStudentsWith(
        submission => submission.score != null && submission.score < state.pointsThreshold
      ),
    }))
  }

  handleMoreThan() {
    this.setState(state => ({
      subject: I18n.t('Scored more than %{score} on %{assignmentTitle}', {
        score: state.pointsThreshold ? state.pointsThreshold.toString() : 0,
        assignmentTitle: this.props.assignment.name,
      }),
      selectedStudents: this.findStudentsWith(
        submission => submission.score != null && submission.score > state.pointsThreshold
      ),
    }))
  }

  shouldShowPointsThreshold() {
    return ['less-than', 'more-than'].includes(this.state.selectedFilter)
  }

  handleSubjectChange = newSubjectValue => {
    this.setState({subject: newSubjectValue})
  }

  handleBodyChange = newBodyValue => {
    this.setState({body: newBodyValue})
  }

  handleSelectedStudentsChange = newStudentSelection => {
    this.setState({selectedStudents: newStudentSelection})
  }

  handleSend = () => {
    this.setState({sendingMessagesNow: true})
    showFlashAlert({message: I18n.t('Sending messages'), srOnly: true})
    sendMessageStudentsWho({
      recipientLids: this.state.selectedStudents,
      subject: this.state.subject,
      body: this.state.body,
      contextCode: `course_${this.props.assignment.course.lid}`,
    })
      .then(() => {
        showFlashAlert({message: I18n.t('Messages sent'), type: 'success'})
        this.setState({sendingMessagesNow: false})
        this.props.onClose()
      })
      .catch(() => {
        showFlashAlert({message: I18n.t('Error sending messages'), type: 'error'})
        this.setState({sendingMessagesNow: false})
      })
  }

  renderThresholdValue() {
    return this.state.points === null ? '' : this.state.pointsThreshold.toString()
  }

  renderMessageStudentsWhoForm = () => (
    <MessageStudentsWhoForm
      assignment={this.props.assignment}
      pointsThreshold={this.state.pointsThreshold}
      selectedFilter={this.state.selectedFilter}
      subject={this.state.subject}
      body={this.state.body}
      selectedStudents={this.state.selectedStudents}
      showPointsThreshold={this.shouldShowPointsThreshold()}
      onFilterChange={this.handleFilterChange}
      onPointsThresholdChange={this.handlePointsChange}
      onSubjectChange={this.handleSubjectChange}
      onBodyChange={this.handleBodyChange}
      onSelectedStudentsChange={this.handleSelectedStudentsChange}
    />
  )

  render() {
    return (
      <ConfirmDialog
        open={this.props.open}
        working={this.state.sendingMessagesNow}
        disabled={this.state.sendingMessagesNow}
        heading={I18n.t('Message Students Who...')}
        body={this.renderMessageStudentsWhoForm}
        buttons={this.messageStudentsWhoButtonProps}
        onDismiss={this.props.onClose}
        modalProps={{size: 'medium'}}
        spinnerLabel={I18n.t('sending messages...')}
      />
    )
  }
}
