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
import canvas from '@instructure/canvas-theme'
import {mockSubmission} from '@canvas/assignments/graphql/studentMocks'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import SubmissionWorkflowTracker from '../SubmissionWorkflowTracker'
import * as tz from '@canvas/datetime'

const {colors} = canvas.variables

describe('when a submission is graded', () => {
  describe('when the grade is visible', () => {
    it('renders as "Review Feedback"', async () => {
      const submission = await mockSubmission({Submission: SubmissionMocks.graded})

      const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
      expect(getByTestId('submission-workflow-tracker-title')).toHaveTextContent('Review Feedback')
    })

    it('renders the time submitted in the subtitle', async () => {
      const submission = await mockSubmission({Submission: SubmissionMocks.graded})
      submission.submittedAt = tz.parse('2021-06-01T19:27:54Z')

      const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
      expect(getByTestId('submission-workflow-tracker-subtitle')).toHaveTextContent(
        'SUBMITTED: Jun 1, 2021 7:27pm'
      )
    })

    it('renders the time submitted subtitle text in success color', async () => {
      const submission = await mockSubmission({Submission: SubmissionMocks.graded})
      submission.submittedAt = tz.parse('2021-06-01T19:27:54Z')

      const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
      expect(getByTestId('submission-workflow-tracker-subtitle')).toHaveStyle(
        `color: ${colors.textSuccess}`
      )
    })

    it('does not render a subtitle if the student has not submitted', async () => {
      const submission = await mockSubmission({
        Submission: {
          ...SubmissionMocks.graded,
          attempt: 0,
        },
      })

      const {queryByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
      expect(queryByTestId('submission-workflow-tracker-subtitle')).not.toBeInTheDocument()
    })
  })

  it('renders as "Submitted" when the grade is not visible', async () => {
    const submission = await mockSubmission({
      Submission: {...SubmissionMocks.graded, gradeHidden: true},
    })

    const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
    expect(getByTestId('submission-workflow-tracker-title')).toHaveTextContent(/Submitted/i)
  })
})

it('renders as "Submitted" when the student has submitted', async () => {
  const submission = await mockSubmission({Submission: {...SubmissionMocks.submitted}})

  const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
  expect(getByTestId('submission-workflow-tracker-title')).toHaveTextContent(/Submitted/i)
})

it('renders the time submitted when the student has submitted', async () => {
  const submission = await mockSubmission({Submission: {...SubmissionMocks.submitted}})
  submission.submittedAt = tz.parse('2021-06-01T19:27:54Z')

  const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
  expect(getByTestId('submission-workflow-tracker-title')).toHaveTextContent('Jun 1, 2021 7:27pm')
})

it('renders the proxy submitter name when submission was proxy', async () => {
  const submission = await mockSubmission({Submission: {...SubmissionMocks.proxySubmitted}})
  const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
  expect(getByTestId('submission-workflow-tracker-proxy-indicator')).toHaveTextContent(
    'by Marty McFly'
  )
})

it('renders as "In Progress" when the student has not yet submitted', async () => {
  const submission = await mockSubmission({
    Submission: {...SubmissionMocks.onlineUploadReadyToSubmit},
  })

  const {getByTestId} = render(<SubmissionWorkflowTracker submission={submission} />)
  expect(getByTestId('submission-workflow-tracker-title')).toHaveTextContent('In Progress')
})
