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

import {useQuery} from '@apollo/client'
import {STUDENT_VIEW_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {WORKFLOW_STATES, SUBMISSION_STATES} from '../constants/submissionStates'
import {Submission} from '../../assignments_show_student'

interface SubmissionWorkflowResult {
  loading: boolean
  submission: Submission | null
  currentState: (typeof WORKFLOW_STATES)[keyof typeof SUBMISSION_STATES] | null
  maxValue: number
}

export const useSubmissionWorkflow = (
  assignmentId: string,
  submissionId: string,
): SubmissionWorkflowResult => {
  const {loading, data} = useQuery(STUDENT_VIEW_QUERY, {
    variables: {
      assignmentLid: assignmentId,
      submissionID: submissionId,
    },
    nextFetchPolicy: 'cache-and-network',
    pollInterval: ENV.LTI_TOOL === 'true' ? 5000 : undefined,
  })

  const getCurrentState = (submission: Submission | null) => {
    if (!submission) return null

    if (submission.state === 'graded') {
      return submission.gradeHidden
        ? WORKFLOW_STATES[SUBMISSION_STATES.SUBMITTED]
        : WORKFLOW_STATES[SUBMISSION_STATES.COMPLETED]
    }

    if (submission.state === 'submitted' || submission.state === 'pending_review') {
      return WORKFLOW_STATES[SUBMISSION_STATES.SUBMITTED]
    }

    return WORKFLOW_STATES[SUBMISSION_STATES.IN_PROGRESS]
  }

  const getMaxValue = () => Math.max(...Object.values(WORKFLOW_STATES).map(state => state.value))
  const submission = data?.submission ?? null
  const currentState = getCurrentState(submission)
  const maxValue = getMaxValue()

  return {
    loading,
    submission,
    currentState,
    maxValue,
  }
}
