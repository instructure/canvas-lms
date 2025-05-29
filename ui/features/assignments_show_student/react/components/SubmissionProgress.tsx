/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import {Flex} from '@instructure/ui-flex'
import {ProgressCircle} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Submission} from '../../assignments_show_student'
import {WORKFLOW_STATES, SUBMISSION_STATES} from '../constants/submissionStates'

const I18n = createI18nScope('assignments_2_student_header')

export const SubmissionProgress = ({
  state,
  maxValue,
  submission,
  context,
}: {state: any; maxValue: number; submission: Submission; context: any}) => {
  const renderText = (text: Function | string) =>
    typeof text === 'function' ? text(submission) : text

  // Handle the new attempt dummy submission state
  if (submission.attempt !== context.latestSubmission.attempt) {
    state = WORKFLOW_STATES[SUBMISSION_STATES.IN_PROGRESS]
  }

  return (
    <Flex>
      <Flex.Item shouldShrink={true}>
        <ProgressCircle
          meterColor="success"
          screenReaderLabel={I18n.t('Submission Progress')}
          size="x-small"
          valueMax={maxValue}
          valueNow={state.value}
        />
      </Flex.Item>
      <Flex.Item shouldGrow={true}>
        <Text as="div" data-testid="submission-workflow-tracker-title">
          {renderText(state.title)}
        </Text>
        {submission.proxySubmitter && (
          <Text
            as="div"
            color="success"
            weight="bold"
            data-testid="submission-workflow-tracker-proxy-indicator"
          >
            {I18n.t('by %{name}', {name: submission.proxySubmitter})}
          </Text>
        )}
        {state.subtitle && (
          <Text
            as="div"
            color="success"
            weight="bold"
            data-testid="submission-workflow-tracker-subtitle"
          >
            {renderText(state.subtitle)}
          </Text>
        )}
      </Flex.Item>
    </Flex>
  )
}

SubmissionProgress.propTypes = {
  state: PropTypes.object.isRequired,
  maxValue: PropTypes.number.isRequired,
  submission: PropTypes.object.isRequired,
}
