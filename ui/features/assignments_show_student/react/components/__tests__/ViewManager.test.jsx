/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import {mockQuery} from '@canvas/assignments/graphql/studentMocks'
import range from 'lodash/range'
import React from 'react'
import {
  STUDENT_VIEW_QUERY,
  SUBMISSION_HISTORIES_QUERY,
} from '@canvas/assignments/graphql/student/Queries'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import ViewManager from '../ViewManager'

async function mockStudentViewResult(overrides = {}) {
  const variables = {assignmentLid: '1', submissionID: '1'}
  const result = await mockQuery(STUDENT_VIEW_QUERY, overrides, variables)
  result.data.assignment.env = {
    assignmentUrl: 'mocked-assignment-url',
    courseId: '1',
    currentUser: {id: '1', display_name: 'bob', avatar_image_url: 'awesome.avatar.url'},
    modulePrereq: null,
    moduleUrl: 'mocked-module-url',
  }
  return result.data
}

async function mockSubmissionHistoriesResult(overrides = {}) {
  const variables = {submissionID: '1'}
  const allOverrides = [overrides, {Node: {__typename: 'Submission'}}]
  const result = await mockQuery(SUBMISSION_HISTORIES_QUERY, allOverrides, variables)
  return result.data
}

async function makeProps(opts = {}) {
  const currentAttempt = opts.currentAttempt
  const numSubmissionHistories =
    opts.numSubmissionHistories === undefined ? currentAttempt - 1 : opts.numSubmissionHistories
  const withDraft = !!opts.withDraft

  // Mock the current submission
  const submittedStateOverrides = currentAttempt === 0 ? {} : SubmissionMocks.submitted
  const studentViewOverrides = [
    {
      Submission: {
        ...submittedStateOverrides,
        attempt: currentAttempt,
      },
    },
  ]
  if (withDraft) {
    studentViewOverrides.push({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
    })
  }
  const studentViewResult = await mockStudentViewResult(studentViewOverrides)

  // Mock the submission histories, as needed.
  let submissionHistoriesResult = null
  if (numSubmissionHistories > 0) {
    const mockedNodeResults = range(0, numSubmissionHistories).map(attempt => ({
      ...SubmissionMocks.graded,
      attempt,
    }))

    submissionHistoriesResult = await mockSubmissionHistoriesResult({
      SubmissionHistoryConnection: {nodes: mockedNodeResults},
    })
  }

  return {
    initialQueryData: studentViewResult,
    submissionHistoriesQueryData: submissionHistoriesResult,
  }
}

describe('ViewManager', () => {
  const originalEnv = JSON.parse(JSON.stringify(window.ENV))
  beforeEach(() => {
    window.ENV = {
      FEATURES: {instui_nav: true},
      context_asset_string: 'test_1',
      COURSE_ID: '1',
      current_user: {display_name: 'bob', avatar_url: 'awesome.avatar.url'},
      enrollment_state: 'active',
      PREREQS: {},
      current_user_roles: ['user', 'student'],
    }
  })

  afterEach(() => {
    window.ENV = originalEnv
  })

  describe('New Attempt Button', () => {
    describe('behaves correctly', () => {
      it('by creating a new dummy submission when clicked', async () => {
        const props = await makeProps({currentAttempt: 1})
        const {getByDisplayValue, getByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        const newAttemptButton = getByText('New Attempt')
        fireEvent.click(newAttemptButton)
        expect(getByDisplayValue('Attempt 2')).not.toBeNull()
      })

      it('by not displaying the new attempt button on a dummy submission', async () => {
        const props = await makeProps({currentAttempt: 1})
        const {queryByText, getByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        const newAttemptButton = getByText('New Attempt')
        fireEvent.click(newAttemptButton)
        expect(queryByText('New Attempt')).toBeNull()
      })
    })

    describe('when a submission draft exists', () => {
      it('is not displayed when the draft is the selected', async () => {
        const props = await makeProps({currentAttempt: 1, withDraft: true})
        const {queryByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        expect(queryByText('New Attempt')).toBeNull()
      })
    })

    describe('when there is no submission draft', () => {
      it('is not displayed on attempt 0', async () => {
        const props = await makeProps({currentAttempt: 0})
        const {queryByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        expect(queryByText('New Attempt')).toBeNull()
      })

      it('is displayed on the latest submitted attempt', async () => {
        const props = await makeProps({currentAttempt: 1})
        const {queryByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        expect(queryByText('New Attempt')).not.toBeNull()
      })

      it('sets focus on the assignment toggle details when clicked', async () => {
        const props = await makeProps({currentAttempt: 1})
        const {getByText, getByTestId} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )

        const mockFocus = jest.fn()
        const assignmentToggle = getByTestId('assignments-2-assignment-toggle-details')
        assignmentToggle.focus = mockFocus

        const newButton = getByText('New Attempt')
        fireEvent.click(newButton)

        await waitFor(() => {
          expect(mockFocus).toHaveBeenCalled()
        })
      })

      it('is displayed if you are not on the latest submission attempt', async () => {
        const props = await makeProps({currentAttempt: 3, numSubmissionHistories: 4})
        const {queryByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        expect(queryByText('New Attempt')).not.toBeNull()
      })

      it('is not displayed if the enrollment state is something other than active', async () => {
        window.ENV.enrollment_state = 'completed'

        const props = await makeProps({currentAttempt: 1})
        const {queryByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        expect(queryByText('New Attempt')).toBeNull()
      })
    })
  })

  describe('Submission Drafts', () => {
    it('are initially displayed if they exist', async () => {
      const props = await makeProps({currentAttempt: 1, withDraft: true})
      const {getByDisplayValue} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      expect(getByDisplayValue('Attempt 2')).not.toBeNull()
    })
  })
})
