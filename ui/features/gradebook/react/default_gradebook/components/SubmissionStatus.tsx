// @ts-nocheck
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
import {bool, instanceOf, number, shape, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Pill} from '@instructure/ui-pill'
import Message from './SubmissionStatus/Message'
import {isPostable} from '@canvas/grading/SubmissionHelper'

const I18n = useI18nScope('gradebook')

export default class SubmissionStatus extends React.Component {
  static defaultProps = {
    submission: {
      drop: false,
    },
  }

  static propTypes = {
    assignment: shape({
      anonymizeStudents: bool.isRequired,
      postManually: bool.isRequired,
      published: bool.isRequired,
    }).isRequired,
    isConcluded: bool.isRequired,
    isInClosedGradingPeriod: bool.isRequired,
    isInNoGradingPeriod: bool.isRequired,
    isInOtherGradingPeriod: bool.isRequired,
    isNotCountedForScore: bool.isRequired,
    submission: shape({
      drop: bool,
      excused: bool,
      hasPostableComments: bool,
      postedAt: instanceOf(Date),
      score: number,
      workflowState: string.isRequired,
    }).isRequired,
  }

  getStatusPills() {
    const {assignment, submission} = this.props
    const statusPillComponents = []

    if (!assignment.published) {
      statusPillComponents.push(
        <Pill key="unpublished-assignment" color="danger" margin="0 0 x-small">
          {I18n.t('Unpublished')}
        </Pill>
      )
    }

    // If students are anonymized we don't want to leak any information about the submission
    if (assignment.anonymizeStudents) {
      return statusPillComponents
    }

    if (isPostable(submission)) {
      statusPillComponents.push(
        <Pill key="hidden-submission" color="warning" margin="0 0 x-small">
          {I18n.t('Hidden')}
        </Pill>
      )
    }

    if (submission.drop) {
      statusPillComponents.push(
        <Pill key="dropped-submission" color="primary" margin="0 0 x-small">
          {I18n.t('Dropped')}
        </Pill>
      )
    }

    if (submission.excused) {
      statusPillComponents.push(
        <Pill key="excused-assignment" color="primary" margin="0 0 x-small">
          {I18n.t('Excused')}
        </Pill>
      )
    }

    return statusPillComponents
  }

  getStatusNotifications() {
    const statusNotificationComponents = []
    const statusNotificationContainerStyle = {
      display: 'flex',
    }

    if (this.props.isConcluded) {
      const concludedEnrollmentStatusMessage = I18n.t(
        "This student's enrollment has been concluded"
      )

      statusNotificationComponents.push(
        <div key="concluded-enrollment-status" style={statusNotificationContainerStyle}>
          <Message variant="warning" message={concludedEnrollmentStatusMessage} />
        </div>
      )
    }

    const gradingPeriodStatusMessage = this.gradingPeriodStatusMessage()
    if (gradingPeriodStatusMessage) {
      statusNotificationComponents.push(
        <div key="grading-period-status" style={statusNotificationContainerStyle}>
          <Message variant="warning" message={gradingPeriodStatusMessage} />
        </div>
      )
    }

    if (this.props.isNotCountedForScore) {
      const isNotCountedForScoreMessage = I18n.t('Not calculated in final grade')

      statusNotificationComponents.push(
        <div key="is-not-counted-for-score-status" style={statusNotificationContainerStyle}>
          <Message variant="info" message={isNotCountedForScoreMessage} />
        </div>
      )
    }

    return statusNotificationComponents
  }

  gradingPeriodStatusMessage() {
    const {isInOtherGradingPeriod, isInClosedGradingPeriod, isInNoGradingPeriod} = this.props
    let message

    if (isInOtherGradingPeriod) {
      message = I18n.t('This submission is in another grading period')
    } else if (isInClosedGradingPeriod) {
      message = I18n.t('This submission is in a closed grading period')
    } else if (isInNoGradingPeriod) {
      message = I18n.t('This submission is not in any grading period')
    }

    return message
  }

  render() {
    const statusPillComponents = this.getStatusPills()
    const statusNotificationComponents = this.getStatusNotifications()
    const statusContainerStyle = {
      display: 'flex',
      justifyContent: 'left',
    }

    return (
      <View as="div" padding="0 0 small 0">
        <div key="status-icons" style={statusContainerStyle}>
          {statusPillComponents}
        </div>

        {statusNotificationComponents}
      </View>
    )
  }
}
