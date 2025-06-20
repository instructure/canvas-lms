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
import {render, screen} from '@testing-library/react'
import {mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import SubmissionWorkflowTracker from '../SubmissionWorkflowTracker'
import * as tz from '@instructure/moment-utils'
import canvas from '@instructure/canvas-theme'
import {MockedProvider} from '@apollo/client/testing'
import {STUDENT_VIEW_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {createCache} from '@canvas/apollo-v3'
import {withSubmissionContext} from '../../test-utils/submission-context'
import StudentViewContext, {StudentViewContextDefaults} from '../Context'

async function createGraphqlMocks(submissionData = {}) {
  const variables = {
    assignmentLid: '1',
    submissionID: '1',
  }
  const result = await mockQuery(STUDENT_VIEW_QUERY, [{Submission: submissionData}], variables)
  return [
    {
      delay: 30,
      request: {query: STUDENT_VIEW_QUERY, variables},
      result,
    },
  ]
}

async function renderWithMocks(submissionData: any) {
  const mocks = await createGraphqlMocks(submissionData)
  return render(
    <StudentViewContext.Provider
      value={{...StudentViewContextDefaults, latestSubmission: submissionData}}
    >
      <MockedProvider mocks={mocks} cache={createCache()}>
        {withSubmissionContext(<SubmissionWorkflowTracker />, {
          assignmentId: '1',
          submissionId: '1',
        })}
      </MockedProvider>
    </StudentViewContext.Provider>,
  )
}

describe('SubmissionWorkflowTracker', () => {
  beforeEach(() => {
    window.ENV = window.ENV || {}
    window.ENV.LTI_TOOL = 'false'
  })

  describe('when a submission is graded', () => {
    describe('when the grade is visible', () => {
      it('renders as "Review Feedback"', async () => {
        await renderWithMocks(SubmissionMocks.graded)
        expect(await screen.findByText(/Review Feedback/i)).toBeInTheDocument()
      })

      it('renders the time submitted in the subtitle', async () => {
        await renderWithMocks({
          ...SubmissionMocks.graded,
          submittedAt: tz.parse('2021-06-01T19:27:54Z'),
        })
        expect(await screen.findAllByText(/SUBMITTED: Jun 1, 2021 7:27pm/i)).toHaveLength(2)
      })

      it('renders the time submitted subtitle text in success color', async () => {
        await renderWithMocks({
          ...SubmissionMocks.graded,
          submittedAt: tz.parse('2021-06-01T19:27:54Z'),
        })
        expect(await screen.findByTestId('submission-workflow-tracker-subtitle')).toHaveStyle(
          `color: ${canvas.colors.contrasts.green5782}`,
        )
      })

      it('renders as Submit Assignment when not submitted', async () => {
        await renderWithMocks({
          ...SubmissionMocks.onlineUploadReadyToSubmit,
        })

        expect(await screen.findByText('NEXT UP: Submit Assignment')).toBeInTheDocument()
      })
    })

    it('renders as "Submitted" when the grade is not visible', async () => {
      await renderWithMocks({
        ...SubmissionMocks.graded,
        gradeHidden: true,
      })
      expect(await screen.findAllByText(/Submitted/i)).toHaveLength(2)
    })
  })

  it('renders as "Submitted" when the student has submitted', async () => {
    await renderWithMocks(SubmissionMocks.submitted)
    expect(await screen.findAllByText(/Submitted/i)).toHaveLength(2)
  })

  it('renders as "Submitted" when submission state is pending_review', async () => {
    await renderWithMocks(SubmissionMocks.pendingReview)
    expect(await screen.findAllByText(/Submitted/i)).toHaveLength(2)
  })

  it('renders the time submitted when the student has submitted', async () => {
    await renderWithMocks({
      ...SubmissionMocks.submitted,
      submittedAt: tz.parse('2021-06-01T19:27:54Z'),
    })
    expect(await screen.findAllByText(/Jun 1, 2021 7:27pm/i)).toHaveLength(2)
  })

  it('renders the proxy submitter name when submission was proxy', async () => {
    await renderWithMocks(SubmissionMocks.proxySubmitted)

    expect(await screen.findByText('by Marty McFly')).toBeInTheDocument()
  })

  it('renders as "In Progress" when the student has not yet submitted', async () => {
    await renderWithMocks(SubmissionMocks.onlineUploadReadyToSubmit)

    expect(await screen.findByText('In Progress')).toBeInTheDocument()
  })
})
