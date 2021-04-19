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
import {render} from '@testing-library/react'

import {mockSubmission} from '@canvas/assignments/graphql/studentMocks'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import SubmissionWorkflowTracker from '../SubmissionWorkflowTracker'

describe('when a submission is graded', () => {
  it('renders as "Review Feedback" when the grade is visible', async () => {
    const submission = await mockSubmission({Submission: SubmissionMocks.graded})

    const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
    expect(getByTestId('submission-workflow-tracker-title')).toHaveTextContent('Review Feedback')
  })

  it('renders as "Submitted" when the grade is not visible', async () => {
    const submission = await mockSubmission({
      Submission: {...SubmissionMocks.graded, gradeHidden: true}
    })

    const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
    expect(getByTestId('submission-workflow-tracker-title')).toHaveTextContent('Submitted')
  })
})

it('renders as "Submitted" when the student has submitted', async () => {
  const submission = await mockSubmission({Submission: {...SubmissionMocks.submitted}})

  const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
  expect(getByTestId('submission-workflow-tracker-title')).toHaveTextContent('Submitted')
})

it('renders as "In Progress" when the student has not yet submitted', async () => {
  const submission = await mockSubmission({
    Submission: {...SubmissionMocks.onlineUploadReadyToSubmit}
  })

  const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
  expect(getByTestId('submission-workflow-tracker-title')).toHaveTextContent('In Progress')
})
