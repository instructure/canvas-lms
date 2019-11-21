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
import * as uploadFileModule from '../../../shared/upload_file'
import {AlertManagerContext} from '../../../shared/components/AlertManager'
import {CREATE_SUBMISSION_DRAFT} from '../graphqlData/Mutations'
import {createCache} from '../../../canvas-apollo'
import {fireEvent, render, waitForElement} from '@testing-library/react'
import {
  LOGGED_OUT_STUDENT_VIEW_QUERY,
  STUDENT_VIEW_QUERY,
  SUBMISSION_HISTORIES_QUERY
} from '../graphqlData/Queries'
import {MockedProvider} from '@apollo/react-testing'
import {mockQuery} from '../mocks'
import React from 'react'
import StudentViewQuery from '../components/StudentViewQuery'
import {SubmissionMocks} from '../graphqlData/Submission'

jest.setTimeout(10000) // TODO: figure out why these tests are so slow
jest.mock('../components/Attempt')

describe('student view integration tests', () => {
  beforeEach(() => {
    window.ENV = {
      context_asset_string: 'test_1',
      COURSE_ID: '1',
      current_user: {display_name: 'bob', avatar_url: 'awesome.avatar.url'},
      PREREQS: {}
    }
  })

  describe('StudentViewQuery', () => {
    function createGraphqlMocks(overrides = {}) {
      const mocks = [
        {
          query: STUDENT_VIEW_QUERY,
          variables: {assignmentLid: '1', submissionID: '1'}
        },
        {
          query: CREATE_SUBMISSION_DRAFT,
          variables: {id: '1', activeSubmissionType: 'online_upload', attempt: 1, fileIds: ['1']}
        }
      ]

      const mockResults = Promise.all(
        mocks.map(async ({query, variables}) => {
          const result = await mockQuery(query, overrides, variables)
          return {
            request: {query, variables},
            result
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
    })

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

      expect(await waitForElement(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
    })

    // This cannot be tested at the <AttemptTab> because the new file being
    // displayed happens as a result of a cache write and these higher level
    // components re-rendering
    it('displays the new file after it has been uploaded', async () => {
      window.URL.createObjectURL = jest.fn()
      uploadFileModule.uploadFiles = jest.fn()
      uploadFileModule.uploadFiles.mockReturnValueOnce([{id: '1', name: 'file1.jpg'}])
      $('body').append('<div role="alert" id="flash_screenreader_holder" />')

      const mocks = await createGraphqlMocks({
        CreateSubmissionDraftPayload: {
          submissionDraft: {attachments: [{displayName: 'test.jpg'}]}
        }
      })

      const {container, findByText, findAllByText} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks} cache={createCache()}>
            <StudentViewQuery assignmentLid="1" submissionID="1" />
          </MockedProvider>
        </AlertManagerContext.Provider>
      )

      const files = [new File(['foo'], 'file1.jpg', {type: 'image/jpg'})]
      const fileInput = await waitForElement(() =>
        container.querySelector('input[id="inputFileDrop"]')
      )
      fireEvent.change(fileInput, {target: {files}})
      await findByText('Loading')
      expect((await findAllByText('test.jpg'))[0]).toBeInTheDocument()
    })

    it('displays a loading indicator for each new file being uploaded', async () => {
      window.URL.createObjectURL = jest.fn()
      uploadFileModule.uploadFiles = jest.fn()
      uploadFileModule.uploadFiles.mockReturnValueOnce([
        {id: '1', name: 'file1.jpg'},
        {id: '2', name: 'file2.jpg'}
      ])
      $('body').append('<div role="alert" id="flash_screenreader_holder" />')

      const mocks = await createGraphqlMocks({
        CreateSubmissionDraftPayload: {
          submissionDraft: {attachments: [{}, {}]}
        }
      })

      const {container, findAllByText} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks} cache={createCache()}>
            <StudentViewQuery assignmentLid="1" submissionID="1" />
          </MockedProvider>
        </AlertManagerContext.Provider>
      )

      const files = [
        new File(['foo'], 'file1.jpg', {type: 'image/jpg'}),
        new File(['foo'], 'file2.pdf', {type: 'application/pdf'})
      ]
      const fileInput = await waitForElement(() =>
        container.querySelector('input[id="inputFileDrop"]')
      )
      fireEvent.change(fileInput, {target: {files}})
      const elements = await findAllByText('Loading')
      expect(elements).toHaveLength(2)
    })
  })

  describe('loading more submission histories', () => {
    function createSubmissionHistoryMocks() {
      const mocks = [
        {
          query: STUDENT_VIEW_QUERY,
          variables: {assignmentLid: '1', submissionID: '1'},
          overrides: {
            Submission: {...SubmissionMocks.graded, attempt: 5}
          }
        },
        {
          query: SUBMISSION_HISTORIES_QUERY,
          variables: {submissionID: '1'},
          overrides: {
            Node: {__typename: 'Submission'},
            PageInfo: {hasPreviousPage: true},
            SubmissionHistoryConnection: {
              nodes: [{attempt: 3}, {attempt: 4}]
            }
          }
        }
      ]

      const mockResults = Promise.all(
        mocks.map(async ({query, variables, overrides}) => {
          const result = await mockQuery(query, overrides, variables)
          return {
            request: {query, variables},
            result
          }
        })
      )
      return mockResults
    }

    it.skip('Displays the previous submission after loading more paginated histories', async () => {
      // TODO: get this to not timeout with instUI 6
      const mocks = await createSubmissionHistoryMocks()

      const {findAllByText, findByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" />
        </MockedProvider>
      )

      const prevButton = await findByText('View Previous Submission')
      fireEvent.click(prevButton)
      expect((await findAllByText('Attempt 4'))[0]).toBeInTheDocument()
    })
  })

  describe('the submission is a text entry', () => {
    function createTextMocks(overrides = {}) {
      const mocks = [
        {
          query: STUDENT_VIEW_QUERY,
          variables: {assignmentLid: '1', submissionID: '1'}
        },
        {
          query: CREATE_SUBMISSION_DRAFT,
          variables: {id: '1', attempt: 1, body: ''}
        }
      ]

      const mockResults = Promise.all(
        mocks.map(async ({query, variables}) => {
          const result = await mockQuery(query, overrides, variables)
          return {
            request: {query, variables},
            result
          }
        })
      )
      return mockResults
    }

    it.skip('opens the RCE when the Start Entry button is clicked', async () => {
      // TODO: get this to work with latest @testing-library
      const mocks = await createTextMocks({
        Assignment: {submissionTypes: ['online_text_entry']},
        SubmissionDraft: {body: ''}
      })

      const {findByTestId} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" submissionID="1" />
        </MockedProvider>
      )

      const startButton = await findByTestId('start-text-entry')
      fireEvent.click(startButton)

      expect(await findByTestId('text-editor')).toBeInTheDocument()
    })
  })

  describe('logged out user on a public assignment', () => {
    async function createPublicAssignmentMocks(overrides = {}) {
      const query = LOGGED_OUT_STUDENT_VIEW_QUERY
      const variables = {assignmentLid: '1'}
      const result = await mockQuery(query, overrides, variables)
      return {
        request: {query, variables},
        result
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

    it('renders a rubric if present', async () => {
      const overrides = [
        {Assignment: {name: 'Test Assignment', rubric: {}}},
        {Rubric: {title: 'Test Rubric'}}
      ]
      const mocks = [await createPublicAssignmentMocks(overrides)]
      const {findAllByText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <StudentViewQuery assignmentLid="1" />
        </MockedProvider>
      )
      expect((await findAllByText('Test Rubric'))[0]).toBeInTheDocument()
    })
  })
})
