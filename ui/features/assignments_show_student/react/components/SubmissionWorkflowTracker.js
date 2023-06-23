/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Flex} from '@instructure/ui-flex'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ProgressCircle} from '@instructure/ui-progress'
import React from 'react'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('assignments_2_student_header')

const possibleStates = {
  inProgress: {
    value: 1,
    title: <Text>{I18n.t('In Progress')}</Text>,
    subtitle: I18n.t('NEXT UP: Submit Assignment'),
  },
  submitted: {
    value: 2,
    title: submission => {
      // Hard-coding the upper-casing into the prefix is not what we'd prefer,
      // but it doesn't seem possible to transform the string using I18n
      // wrappers *and* have it play nice with the rendering in
      // FriendlyDatetime.
      return (
        <FriendlyDatetime
          dateTime={submission.submittedAt}
          format={I18n.t('#date.formats.full')}
          prefix={I18n.t('Submitted on')}
          showTime={true}
        />
      )
    },
    subtitle: I18n.t('NEXT UP: Review Feedback'),
  },
  completed: {
    value: 3,
    title: <Text>{I18n.t('Review Feedback')}</Text>,
    subtitle: submission => {
      const {attempt, submittedAt} = submission

      if (attempt === 0) {
        return null
      }

      if (submittedAt == null) {
        return I18n.t('This assignment is complete!')
      }

      return (
        <FriendlyDatetime
          dateTime={submittedAt}
          format={I18n.t('#date.formats.full')}
          prefix={I18n.t('SUBMITTED: ')}
          showTime={true}
        />
      )
    },
  },
}

function currentWorkflowState({submission}) {
  let currentState
  if (submission.state === 'graded') {
    currentState = submission.gradeHidden ? possibleStates.submitted : possibleStates.completed
  } else if (submission.state === 'submitted') {
    currentState = possibleStates.submitted
  } else {
    // Also show "In Progress" when the assignment has not been started
    currentState = possibleStates.inProgress
  }

  const valueMax = Math.max(...Object.values(possibleStates).map(state => state.value))
  return {state: currentState, valueMax}
}

const renderStateText = (submission, stateText) =>
  typeof stateText === 'function' ? stateText(submission) : stateText

export default function SubmissionWorkflowTracker({submission}) {
  if (!submission) {
    return null
  }

  const {state, valueMax} = currentWorkflowState({submission})
  const subtitle = renderStateText(submission, state.subtitle)
  return (
    <div
      className="assignment-student-submission-tracker"
      data-testid="submission-workflow-tracker"
    >
      <Flex>
        <Flex.Item shouldShrink={true}>
          <ProgressCircle
            meterColor="success"
            screenReaderLabel={I18n.t('Submission Progress')}
            size="x-small"
            valueMax={valueMax}
            valueNow={state.value}
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <Text as="div" data-testid="submission-workflow-tracker-title">
            {renderStateText(submission, state.title)}
          </Text>
          {submission.proxySubmitter && (
            <Text
              as="div"
              color="success"
              data-testid="submission-workflow-tracker-proxy-indicator"
              weight="bold"
            >
              {I18n.t('by %{name}', {name: submission.proxySubmitter})}
            </Text>
          )}
          {subtitle && (
            <Text
              as="div"
              color="success"
              weight="bold"
              data-testid="submission-workflow-tracker-subtitle"
            >
              {subtitle}
            </Text>
          )}
        </Flex.Item>
      </Flex>
    </div>
  )
}

SubmissionWorkflowTracker.propTypes = {
  submission: Submission.shape.isRequired,
}
