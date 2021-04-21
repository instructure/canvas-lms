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
import I18n from 'i18n!assignments_2_student_header'
import {ProgressCircle} from '@instructure/ui-progress'
import React from 'react'
import {Submission} from '../graphqlData/Submission'
import {Text} from '@instructure/ui-elements'

const possibleStates = {
  inProgress: {
    value: 1,
    title: I18n.t('In Progress'),
    subtitle: I18n.t('Next Up: Submit Assignment')
  },
  submitted: {value: 2, title: I18n.t('Submitted'), subtitle: I18n.t('Next Up: Review Feedback')},
  completed: {
    value: 3,
    title: I18n.t('Review Feedback'),
    subtitle: I18n.t('This assignment is complete!')
  }
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

export default function SubmissionWorkflowTracker({submission}) {
  if (!submission) {
    return null
  }

  const {state, valueMax} = currentWorkflowState({submission})
  return (
    <div
      className="assignment-student-submission-tracker"
      data-testid="submission-workflow-tracker"
    >
      <Flex>
        <Flex.Item shouldShrink>
          <ProgressCircle
            meterColor="success"
            screenReaderLabel={I18n.t('Submission Progress')}
            size="x-small"
            valueMax={valueMax}
            valueNow={state.value}
          />
        </Flex.Item>
        <Flex.Item shouldGrow>
          {state.title && (
            <Text
              as="div"
              color="success"
              data-testid="submission-workflow-tracker-title"
              transform="uppercase"
              weight="bold"
            >
              {state.title}
            </Text>
          )}
          {state.subtitle && <Text as="div">{state.subtitle}</Text>}
        </Flex.Item>
      </Flex>
    </div>
  )
}

SubmissionWorkflowTracker.propTypes = {
  submission: Submission.shape.isRequired
}
