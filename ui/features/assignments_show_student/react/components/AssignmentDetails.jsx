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

import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {Text} from '@instructure/ui-text'
import StudentViewContext from './Context'
import SubmissionStatusPill, {
  isStatusPillPresent,
} from '@canvas/assignments/react/SubmissionStatusPill'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Pill} from '@instructure/ui-pill'
import AvailabilityDates from '@canvas/assignments/react/AvailabilityDates'
import {totalAllowedAttempts} from '../helpers/SubmissionHelpers'

const I18n = useI18nScope('assignments_2_student_header_date_title')

export function renderPipe(item) {
  return item && <View margin="0 xx-small 0 xx-small">|</View>
}

function renderAvailability(assignment) {
  return (
    <>
      <Text size="small" color="secondary">
        {(assignment.unlockAt || assignment.lockAt) && renderPipe(assignment.dueAt)}
        <AvailabilityDates assignment={assignment} formatStyle="long" />
      </Text>
    </>
  )
}

function renderAttempts(assignment) {
  return (
    <StudentViewContext.Consumer>
      {context => (
        <>
          {assignment.expectsSubmission && (
            <>
              <Pill>
                {I18n.t(
                  {
                    zero: 'Unlimited Attempts',
                    one: '1 Attempt',
                    other: '%{count} Attempts',
                  },
                  {count: totalAllowedAttempts(assignment, context.latestSubmission) || 0}
                )}
              </Pill>
            </>
          )}
        </>
      )}
    </StudentViewContext.Consumer>
  )
}

export default function AssignmentDetails({assignment, submission}) {
  return (
    <>
      <Flex direction="column">
        <div style={{lineHeight: 1.05}}>
          <Flex.Item padding={window.ENV.FEATURES.instui_nav ? '0' : 'xxx-small 0 0'}>
            {window.ENV.FEATURES.instui_nav ? (
              <Text weight="bold" size="xx-large" wrap="break-word" data-testid="title">
                {assignment.name}
              </Text>
            ) : (
              <Text size="x-large" wrap="break-word" data-testid="title" weight="light">
                {assignment.name}
              </Text>
            )}
          </Flex.Item>
        </div>
        {(assignment.dueAt ||
          assignment.lockAt ||
          assignment.unlockAt ||
          assignment.env.peerReviewModeEnabled) && (
          <Flex.Item
            margin={window.ENV.FEATURES.instui_nav ? 'small 0 0 0' : '0'}
            themeOverride={{lineHeight: 1}}
          >
            <div style={{lineHeight: 1}}>
              <Text
                size="small"
                color={window.ENV.FEATURES.instui_nav ? 'secondary' : null}
                weight={window.ENV.FEATURES.instui_nav ? null : 'bold'}
                data-testid="assignment-sub-header"
              >
                {assignment.env.peerReviewModeEnabled &&
                  `${I18n.t('Peer:')} ${assignment.env.peerDisplayName}`}
                {assignment.dueAt && (
                  <>
                    {renderPipe(assignment.env.peerReviewModeEnabled)}
                    <FriendlyDatetime
                      data-testid="due-date"
                      prefix={I18n.t('Due:')}
                      format={I18n.t('#date.formats.full_with_weekday')}
                      dateTime={assignment.dueAt}
                    />
                  </>
                )}
              </Text>
              {window.ENV.FEATURES.instui_nav &&
                !assignment.env.peerReviewModeEnabled &&
                renderAvailability(assignment)}
            </div>
          </Flex.Item>
        )}
        {window.ENV.FEATURES.instui_nav && !assignment.env.peerReviewModeEnabled && (
          <Flex margin="small 0 0 0">
            <Flex.Item>
              <SubmissionStatusPill
                submissionStatus={submission?.submissionStatus}
                customGradeStatus={submission?.customGradeStatus}
              />
            </Flex.Item>
            <Flex.Item margin={isStatusPillPresent(submission) ? '0 0 0 small' : '0'}>
              {renderAttempts(assignment)}
            </Flex.Item>
          </Flex>
        )}
      </Flex>
    </>
  )
}

AssignmentDetails.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape,
}
