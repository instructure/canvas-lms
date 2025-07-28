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
import $ from 'jquery'
import {createCache} from '@canvas/apollo-v3'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {
  LOGGED_OUT_STUDENT_VIEW_QUERY,
  STUDENT_VIEW_QUERY,
  STUDENT_VIEW_QUERY_WITH_REVIEWER_SUBMISSION,
  SUBMISSION_HISTORIES_QUERY,
} from '@canvas/assignments/graphql/student/Queries'
import {MockedProvider} from '@apollo/client/testing'
import {mockQuery} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import StudentViewQuery from '../components/StudentViewQuery'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('../components/AttemptSelect')

const server = setupServer()

describe('student view integration tests', () => {
  let user

  beforeAll(() => {
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    user = userEvent.setup()
    fakeENV.setup({
      FEATURES: {instui_nav: true},
      context_asset_string: 'test_1',
      ASSIGNMENT_ID: '1',
      COURSE_ID: '1',
      current_user: {display_name: 'bob', avatar_url: 'awesome.avatar.url', id: '1'},
      PREREQS: {},
      current_user_roles: ['user', 'student'],
    })
    server.use(
      http.get('*', () => {
        return HttpResponse.json([])
      }),
    )
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
    jest.restoreAllMocks()
    server.resetHandlers()
  })

  describe('logged out user on a public assignment', () => {
    async function createPublicAssignmentMocks(overrides = {}) {
      const query = LOGGED_OUT_STUDENT_VIEW_QUERY
      const variables = {assignmentLid: '1'}
      const result = await mockQuery(query, overrides, variables)
      return {
        request: {query, variables},
        result,
      }
    }

    it('renders the assignment', async () => {
      const overrides = [{Assignment: {name: 'Test Assignment', rubric: null}}]
      const mocks = [await createPublicAssignmentMocks(overrides)]
      const {findAllByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" />
        </MockedProvider>,
      )
      expect((await findAllByText('Test Assignment'))[0]).toBeInTheDocument()
    })

    it('renders the rubric panel if a rubric if present', async () => {
      const overrides = [
        {Assignment: {name: 'Test Assignment', rubric: {id: '123', criteria: []}}},
        {Rubric: {title: 'Test Rubric', id: '123'}},
      ]
      const mocks = [await createPublicAssignmentMocks(overrides)]
      const {findByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" />
        </MockedProvider>,
      )

      // Wait for the assignment to load
      await findByTestId('assignments-2-student-view')

      // Wait for the rubric tab to be visible
      const rubricTab = await findByTestId('rubric-tab')
      expect(rubricTab).toBeInTheDocument()

      // Also verify the View Rubric toggle button is present
      const rubricToggle = await findByTestId('fill-out-rubric-toggle')
      expect(rubricToggle).toBeInTheDocument()
    })

    it('does not render the rubric panel if no rubric is present', async () => {
      const overrides = [{Assignment: {name: 'Test Assignment'}}]
      const mocks = [await createPublicAssignmentMocks(overrides)]
      const {queryByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" />
        </MockedProvider>,
      )

      expect(queryByRole('button', {name: 'View Rubric'})).not.toBeInTheDocument()
    })
  })

  describe('peer reviews', () => {
    function createGraphqlMocks(reviewerOverrides = {}) {
      const mocks = [
        {
          query: STUDENT_VIEW_QUERY,
          variables: {assignmentLid: '1', submissionID: '1'},
        },
        {
          query: STUDENT_VIEW_QUERY_WITH_REVIEWER_SUBMISSION,
          variables: {assignmentLid: '1', submissionID: '1', reviewerSubmissionID: '2'},
          overrides: reviewerOverrides,
        },
        {
          query: SUBMISSION_HISTORIES_QUERY,
          variables: {submissionID: '1'},
          overrides: {
            Node: {__typename: 'Submission'},
            SubmissionHistoryConnection: {nodes: [{attempt: 3}, {attempt: 4}]},
          },
        },
      ]

      const mockResults = Promise.all(
        mocks.map(async ({query, variables, overrides}) => {
          const result = await mockQuery(query, overrides, variables)
          return {
            request: {query, variables},
            result,
          }
        }),
      )
      return mockResults
    }

    it('renders needs submission view when peer review mode is enabled and the reviewer has not submitted', async () => {
      fakeENV.setup({
        peer_review_mode_enabled: true,
        peer_review_available: true,
      })

      const mocks = await createGraphqlMocks({Submission: {state: 'unsubmitted'}})
      const {findByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" reviewerSubmissionID="2" />
        </MockedProvider>,
      )
      expect(
        await findByText('You must submit your own work before you can review your peers.'),
      ).toBeInTheDocument()
    })

    it('renders unavailible view when peer review mode is enabled and the reviewer has submitted but there are no submissions to review', async () => {
      fakeENV.setup({
        peer_review_mode_enabled: true,
        peer_review_available: false,
      })

      const mocks = await createGraphqlMocks({Submission: {state: 'submitted'}})
      const {findByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" reviewerSubmissionID="2" />
        </MockedProvider>,
      )
      expect(
        await findByText('There are no submissions available to review just yet.'),
      ).toBeInTheDocument()
    })

    it('does not render unavailible or needs submission view when peer review mode is disabled', async () => {
      fakeENV.setup({
        peer_review_mode_enabled: false,
        peer_review_available: false,
      })

      const mocks = await createGraphqlMocks()
      const {queryByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" reviewerSubmissionID="2" />
        </MockedProvider>,
      )
      expect(
        queryByText('You must submit your own work before you can review your peers.'),
      ).not.toBeInTheDocument()
      expect(
        queryByText('There are no submissions available to review just yet.'),
      ).not.toBeInTheDocument()
    })

    it('does not render unavailible or needs submission view when peer review mode is enabled and there are submissions to review', async () => {
      fakeENV.setup({
        peer_review_mode_enabled: true,
        peer_review_available: true,
      })

      const mocks = await createGraphqlMocks()
      const {queryByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" reviewerSubmissionID="2" />
        </MockedProvider>,
      )
      expect(
        queryByText('You must submit your own work before you can review your peers.'),
      ).not.toBeInTheDocument()
      expect(
        queryByText('There are no submissions available to review just yet.'),
      ).not.toBeInTheDocument()
    })
  })
})
