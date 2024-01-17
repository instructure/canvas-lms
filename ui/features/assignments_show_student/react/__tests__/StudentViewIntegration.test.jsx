/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import * as uploadFileModule from '@canvas/upload-file'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {CREATE_SUBMISSION_DRAFT} from '@canvas/assignments/graphql/student/Mutations'
import {createCache} from '@canvas/apollo'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {
  LOGGED_OUT_STUDENT_VIEW_QUERY,
  STUDENT_VIEW_QUERY,
  STUDENT_VIEW_QUERY_WITH_REVIEWER_SUBMISSION,
  SUBMISSION_HISTORIES_QUERY,
  USER_GROUPS_QUERY,
} from '@canvas/assignments/graphql/student/Queries'
import {MockedProvider} from '@apollo/react-testing'
import {mockQuery} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import StudentViewQuery from '../components/StudentViewQuery'

jest.mock('../components/AttemptSelect')

describe('student view integration tests', () => {
  const oldENV = window.ENV

  beforeEach(() => {
    window.ENV = {
      FEATURES: {instui_nav: true},
      context_asset_string: 'test_1',
      ASSIGNMENT_ID: '1',
      COURSE_ID: '1',
      current_user: {display_name: 'bob', avatar_url: 'awesome.avatar.url', id: '1'},
      PREREQS: {},
      current_user_roles: ['user', 'student'],
    }
  })

  afterEach(() => {
    window.ENV = oldENV
  })

  describe('StudentViewQuery', () => {
    function createGraphqlMocks(createSubmissionDraftOverrides = {}) {
      const mocks = [
        {
          query: STUDENT_VIEW_QUERY,
          variables: {assignmentLid: '1', submissionID: '1'},
        },
        {
          query: CREATE_SUBMISSION_DRAFT,
          variables: {id: '1', activeSubmissionType: 'online_upload', attempt: 1, fileIds: ['1']},
          overrides: createSubmissionDraftOverrides,
        },
        {
          query: SUBMISSION_HISTORIES_QUERY,
          variables: {submissionID: '1'},
          overrides: {
            Node: {__typename: 'Submission'},
            SubmissionHistoryConnection: {nodes: [{attempt: 3}, {attempt: 4}]},
          },
        },
        {
          query: USER_GROUPS_QUERY,
          variables: {userID: '1'},
          overrides: {
            Node: {__typename: 'User'},
            User: {groups: []},
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
        })
      )
      return mockResults
    }

    // TODO: These three tests could be moved to the StudentViewQuery unit test file
    it('renders normally', async () => {
      const mocks = await createGraphqlMocks()
      const {findByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" />
        </MockedProvider>
      )
      expect(await findByTestId('assignments-2-student-view')).toBeInTheDocument()
    }, 10000)

    it('renders loading', async () => {
      const mocks = await createGraphqlMocks()
      const {getByTitle} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" />
        </MockedProvider>
      )

      expect(getByTitle('Loading')).toBeInTheDocument()
    })

    it('renders error', async () => {
      const mocks = await createGraphqlMocks()
      mocks[0].error = new Error('aw shucks')
      const {getByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" />
        </MockedProvider>
      )

      expect(await waitFor(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
    })

    // This cannot be tested at the <AttemptTab> because the new file being
    // displayed happens as a result of a cache write and these higher level
    // components re-rendering
    // EVAL-3907 - remove or rewrite to remove spies on imports
    it.skip('displays the new file after it has been uploaded', async () => {
      uploadFileModule.uploadFile = jest.fn()
      uploadFileModule.uploadFile.mockReturnValueOnce({id: '1', name: 'test.jpg'})
      $('body').append('<div role="alert" id="flash_screenreader_holder" />')

      const mocks = await createGraphqlMocks({
        CreateSubmissionDraftPayload: {
          submissionDraft: {attachments: [{displayName: 'test.jpg'}]},
        },
      })

      const {findAllByRole, findByRole, findByTestId} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks} cache={createCache()}>
            <StudentViewQuery assignmentLid="1" submissionID="1" />
          </MockedProvider>
        </AlertManagerContext.Provider>
      )

      const files = [new File(['foo'], 'test.jpg', {type: 'image/jpg'})]
      const fileInput = await findByTestId('input-file-drop')
      fireEvent.change(fileInput, {target: {files}})
      await findByRole('progressbar', {name: /Upload progress/})
      const allCells = await findAllByRole('cell')
      const targetCell = allCells.find(cell => {
        return cell.textContent.includes('test.jpg')
      })
      expect(targetCell).toBeTruthy()
    })

    // EVAL-3907 - remove or rewrite to remove spies on imports
    it.skip('displays a progress bar for each new file being uploaded', async () => {
      uploadFileModule.uploadFiles = jest.fn()
      uploadFileModule.uploadFiles.mockReturnValueOnce([
        {id: '1', name: 'file1.jpg'},
        {id: '2', name: 'file2.jpg'},
      ])
      $('body').append('<div role="alert" id="flash_screenreader_holder" />')

      const mocks = await createGraphqlMocks({
        CreateSubmissionDraftPayload: {
          submissionDraft: {attachments: [{}, {}]},
        },
      })

      const {findByTestId, findAllByRole} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks} cache={createCache()}>
            <StudentViewQuery assignmentLid="1" submissionID="1" />
          </MockedProvider>
        </AlertManagerContext.Provider>
      )

      const files = [
        new File(['foo'], 'file1.jpg', {type: 'image/jpg'}),
        new File(['foo'], 'file2.pdf', {type: 'application/pdf'}),
      ]
      const fileInput = await findByTestId('input-file-drop')
      fireEvent.change(fileInput, {target: {files}})
      const elements = await findAllByRole('progressbar', {name: /Upload progress/})
      expect(elements).toHaveLength(2)
    })
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
        </MockedProvider>
      )
      expect((await findAllByText('Test Assignment'))[0]).toBeInTheDocument()
    })

    it('renders the rubric panel if a rubric if present', async () => {
      const overrides = [
        {Assignment: {name: 'Test Assignment', rubric: {id: '123', criteria: []}}},
        {Rubric: {title: 'Test Rubric', id: '123'}},
      ]
      const mocks = [await createPublicAssignmentMocks(overrides)]
      const {findByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" />
        </MockedProvider>
      )

      expect(await findByRole('button', {name: 'View Rubric'})).toBeInTheDocument()
    })

    it('does not render the rubric panel if no rubric is present', async () => {
      const overrides = [{Assignment: {name: 'Test Assignment'}}]
      const mocks = [await createPublicAssignmentMocks(overrides)]
      const {queryByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" />
        </MockedProvider>
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
        })
      )
      return mockResults
    }

    it('renders needs submission view when peer review mode is enabled and the reviewer has not submitted', async () => {
      window.ENV.peer_review_mode_enabled = true
      window.ENV.peer_review_available = true

      const mocks = await createGraphqlMocks({Submission: {state: 'unsubmitted'}})
      const {findByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" reviewerSubmissionID="2" />
        </MockedProvider>
      )
      expect(
        await findByText('You must submit your own work before you can review your peers.')
      ).toBeInTheDocument()
    })

    it('renders unavailible view when peer review mode is enabled and the reviewer has submitted but there are no submissions to review', async () => {
      window.ENV.peer_review_mode_enabled = true
      window.ENV.peer_review_available = false

      const mocks = await createGraphqlMocks({Submission: {state: 'submitted'}})
      const {findByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" reviewerSubmissionID="2" />
        </MockedProvider>
      )
      expect(
        await findByText('There are no submissions available to review just yet.')
      ).toBeInTheDocument()
    })

    it('does not render unavailible or needs submission view when peer review mode is disabled', async () => {
      window.ENV.peer_review_mode_enabled = false
      window.ENV.peer_review_available = false

      const mocks = await createGraphqlMocks()
      const {queryByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" reviewerSubmissionID="2" />
        </MockedProvider>
      )
      expect(
        queryByText('You must submit your own work before you can review your peers.')
      ).not.toBeInTheDocument()
      expect(
        queryByText('There are no submissions available to review just yet.')
      ).not.toBeInTheDocument()
    })

    it('does not render unavailible or needs submission view when peer review mode is enabled and there are submissions to review', async () => {
      window.ENV.peer_review_mode_enabled = true
      window.ENV.peer_review_available = true

      const mocks = await createGraphqlMocks()
      const {queryByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" reviewerSubmissionID="2" />
        </MockedProvider>
      )
      expect(
        queryByText('You must submit your own work before you can review your peers.')
      ).not.toBeInTheDocument()
      expect(
        queryByText('There are no submissions available to review just yet.')
      ).not.toBeInTheDocument()
    })
  })
})
