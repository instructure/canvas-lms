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

import React from 'react'
import {useSubmissionWorkflow} from '../hooks/useSubmissionWorkflow'
import {SubmissionProgress} from './SubmissionProgress'
import {useSubmission} from '../context/SubmissionContext'
import StudentViewContext from './Context'

const SubmissionWorkflowTracker = () => {
  const {assignmentId, submissionId} = useSubmission()
  const {loading, submission, currentState, maxValue} = useSubmissionWorkflow(
    assignmentId,
    submissionId,
  )

  if (loading) return null

  return (
    <StudentViewContext.Consumer>
      {context => (
        <div
          className="assignment-student-submission-tracker"
          data-testid="submission-workflow-tracker"
        >
          {submission && currentState && (
            <SubmissionProgress
              state={currentState}
              maxValue={maxValue}
              submission={submission}
              context={context}
            />
          )}
        </div>
      )}
    </StudentViewContext.Consumer>
  )
}

export default SubmissionWorkflowTracker
