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
import { bool, shape } from 'prop-types';
import I18n from 'i18n!gradebook';
import Container from '@instructure/ui-core/lib/components/Container';
import Pill from '@instructure/ui-core/lib/components/Pill';
import Message from './SubmissionStatus/Message'

export default class SubmissionStatus extends React.Component {
  static defaultProps = {
    submission: {
      drop: false
    }
  };

  static propTypes = {
    assignment: shape({
      muted: bool.isRequired,
      published: bool.isRequired
    }).isRequired,
    isConcluded: bool.isRequired,
    isInClosedGradingPeriod: bool.isRequired,
    isInNoGradingPeriod: bool.isRequired,
    isInOtherGradingPeriod: bool.isRequired,
    isNotCountedForScore: bool.isRequired,
    submission: shape({
      drop: bool,
      excused: bool
    }).isRequired
  };

  getStatusPills () {
    const { assignment, submission } = this.props;
    const statusPillComponents = [];

    if (assignment.muted) {
      statusPillComponents.push(
        <Pill key="muted-assignment" variant="default" text={I18n.t('Muted')} margin="0 0 x-small" />
      );
    }

    if (!assignment.published) {
      statusPillComponents.push(
        <Pill key="unpublished-assignment" variant="danger" text={I18n.t('Unpublished')} margin="0 0 x-small" />
      );
    }

    if (submission.drop) {
      statusPillComponents.push(
        <Pill key="dropped-submission" variant="default" text={I18n.t('Dropped')} margin="0 0 x-small" />
      );
    }

    if (submission.excused) {
      statusPillComponents.push(
        <Pill key="excused-assignment" variant="default" text={I18n.t('Excused')} margin="0 0 x-small" />
      );
    }

    return statusPillComponents;
  }

  getStatusNotifications () {
    const statusNotificationComponents = [];
    const statusNotificationContainerStyle = {
      display: 'flex'
    };

    if (this.props.isConcluded) {
      const concludedEnrollmentStatusMessage = I18n.t("This student's enrollment has been concluded")

      statusNotificationComponents.push(
        <div key="concluded-enrollment-status" style={statusNotificationContainerStyle}>
          <Message variant="warning" message={concludedEnrollmentStatusMessage} />
        </div>
      );
    }

    const gradingPeriodStatusMessage = this.gradingPeriodStatusMessage();
    if (gradingPeriodStatusMessage) {
      statusNotificationComponents.push(
        <div key="grading-period-status" style={statusNotificationContainerStyle}>
          <Message variant="warning" message={gradingPeriodStatusMessage} />
        </div>
      );
    }

    if (this.props.isNotCountedForScore) {
      const isNotCountedForScoreMessage = I18n.t('Not calculated in final grade')

      statusNotificationComponents.push(
        <div key="is-not-counted-for-score-status" style={statusNotificationContainerStyle}>
          <Message variant="info" message={isNotCountedForScoreMessage} />
        </div>
      );
    }

    return statusNotificationComponents;
  }

  gradingPeriodStatusMessage () {
    const { isInOtherGradingPeriod, isInClosedGradingPeriod, isInNoGradingPeriod } = this.props;
    let message;

    if (isInOtherGradingPeriod) {
      message = I18n.t('This submission is in another grading period')
    } else if (isInClosedGradingPeriod) {
      message = I18n.t('This submission is in a closed grading period')
    } else if (isInNoGradingPeriod) {
      message = I18n.t('This submission is not in any grading period')
    }

    return message;
  }

  render () {
    const statusPillComponents = this.getStatusPills();
    const statusNotificationComponents = this.getStatusNotifications();
    const statusContainerStyle = {
      display: 'flex',
      justifyContent: 'left'
    };

    return (
      <Container as="div" padding="0 0 small 0">
        <div key="status-icons" style={statusContainerStyle}>
          {statusPillComponents}
        </div>

        {statusNotificationComponents}
      </Container>
    );
  }
};
