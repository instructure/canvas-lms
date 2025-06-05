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
import {createCache} from '@canvas/apollo-v3'
import {fireEvent, render, waitFor, act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {
  STUDENT_VIEW_QUERY,
  SUBMISSION_HISTORIES_QUERY,
  USER_GROUPS_QUERY,
} from '@canvas/assignments/graphql/student/Queries'
import {MockedProvider} from '@apollo/client/testing'
import {mockQuery} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import StudentViewQuery from '../components/StudentViewQuery'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('../components/AttemptSelect')

describe('student view integration tests', () => {
  let user

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
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
  })

  describe('StudentViewQuery', () => {
    async function createGraphqlMocks(createSubmissionDraftOverrides = {}) {
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

      return Promise.all(
        mocks.map(async ({query, variables, overrides}) => {
          const result = await mockQuery(query, overrides, variables)
          return {
            request: {query, variables},
            result,
          }
        }),
      )
    }

    it('renders normally', async () => {
      const mocks = await createGraphqlMocks()
      const {findByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" />
        </MockedProvider>,
      )

      await act(async () => {
        const element = await findByTestId('assignments-2-student-view')
        expect(element).toBeInTheDocument()
      })
    })

    it('renders error state correctly', async () => {
      const mocks = await createGraphqlMocks()
      mocks[0].error = new Error('aw shucks')
      const {findByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" />
        </MockedProvider>,
      )

      await act(async () => {
        const errorElement = await findByText('Sorry, Something Broke')
        expect(errorElement).toBeInTheDocument()
      })
    })

    it('handles file upload successfully', async () => {
      const mockFile = new File(['test content'], 'test.jpg', {type: 'image/jpeg'})
      const mocks = await createGraphqlMocks({
        CreateSubmissionDraftPayload: {
          submissionDraft: {
            attachments: [{displayName: 'test.jpg', _id: '1'}],
            submissionAttempt: 1,
          },
        },
      })

      const {findByTestId, getByTestId} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks} cache={createCache()}>
            <StudentViewQuery assignmentLid="1" submissionID="1" />
          </MockedProvider>
        </AlertManagerContext.Provider>,
      )

      const fileInput = await findByTestId('input-file-drop')

      await act(async () => {
        await user.upload(fileInput, mockFile)
      })

      // Wait for the file upload and GraphQL mutation to complete
      await waitFor(
        () => {
          expect(getByTestId('upload-box')).toBeInTheDocument()
        },
        {timeout: 3000},
      )
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
        </AlertManagerContext.Provider>,
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
        </AlertManagerContext.Provider>,
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
})
