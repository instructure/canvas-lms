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

import $ from 'jquery'
import * as uploadFileModule from '@canvas/upload-file'
import AttemptTab from '../AttemptTab'
import {EXTERNAL_TOOLS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import TextEntry from '../AttemptType/TextEntry'
import {render, waitFor} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/client/testing'
import React, {createRef} from 'react'
import StudentViewContext from '../Context'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

jest.mock('@canvas/upload-file')

const defaultMocks = (result = {data: {course: {externalToolsConnection: {nodes: []}}}}) => [
  {
    request: {
      query: EXTERNAL_TOOLS_QUERY,
      variables: {courseID: '1'},
    },
    result,
  },
]
const CUSTOM_TIMEOUT_LIMIT = 1000
describe('ContentTabs', () => {
  beforeAll(() => {
    window.INST = window.INST || {}
    window.INST.editorButtons = []

    // Mock URL.createObjectURL for file handling
    URL.createObjectURL = jest.fn(blob => {
      return `blob:mock-url-${blob.name || 'unnamed'}`
    })

    // Mock Blob.prototype.slice for file handling
    if (!Blob.prototype.slice) {
      Blob.prototype.slice = jest.fn(function (start, end) {
        return this
      })
    }
  })

  const renderAttemptTab = async props => {
    const retval = render(
      <MockedProvider mocks={defaultMocks()}>
        <AttemptTab {...props} focusAttemptOnInit={false} />
      </MockedProvider>,
    )

    if (props.assignment.submissionTypes.includes('online_text_entry')) {
      await waitFor(
        () => {
          expect(tinymce.get('textentry_text')).toBeDefined()
        },
        {timeout: 4000},
      )
      return retval
    } else {
      return Promise.resolve(retval)
    }
  }

  const createSubmitButtonRef = () => {
    const submitButton = document.createElement('button')
    const ref = createRef()
    ref.current = submitButton
    return ref
  }

  describe('the assignment is locked aka passed the until date', () => {
    it('renders the availability dates if the assignment was not submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {lockInfo: {isLocked: true}},
      })
      props.submitButtonRef = createSubmitButtonRef()
      const {findByText} = render(
        <MockedProvider>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )

      expect(await findByText('Availability Dates')).toBeInTheDocument()
    })

    it('renders the last submission if the assignment was submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {lockInfo: {isLocked: true}},
        Submission: {
          ...SubmissionMocks.submitted,
          attachments: [{displayName: 'test.jpg'}],
        },
      })
      props.submitButtonRef = createSubmitButtonRef()
      const {findByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
      expect(await findByTestId('assignments_2_submission_preview')).toBeInTheDocument()
    })

    it('renders the last submission type if the assignment submissionTypes attribute has changed', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          lockInfo: {isLocked: true},
          submissionTypes: ['online_text_entry'],
        },
        Submission: {
          ...SubmissionMocks.submitted,
          attachments: [{displayName: 'test.jpg'}],
          submissionType: 'online_upload',
        },
      })
      props.submitButtonRef = createSubmitButtonRef()

      const {findByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
      expect(await findByTestId('assignments_2_submission_preview')).toBeInTheDocument()
    })

    it('renders the last submission if the assignment was submitted and marked late', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {lockInfo: {isLocked: true}},
        Submission: {
          ...SubmissionMocks.late,
          attachments: [{displayName: 'test.jpg'}],
        },
      })
      props.submitButtonRef = createSubmitButtonRef()
      const {findByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
      expect(await findByTestId('assignments_2_submission_preview')).toBeInTheDocument()
    })

    it('renders the availability dates if the assignment was not submitted and marked missing', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {lockInfo: {isLocked: true}},
        Submission: {...SubmissionMocks.missing},
      })
      props.submitButtonRef = createSubmitButtonRef()
      const {findByText} = render(
        <MockedProvider>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )

      expect(await findByText('Availability Dates')).toBeInTheDocument()
    })

    it('renders the availability dates if the assignment was not submitted and marked excused', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {lockInfo: {isLocked: true}},
        Submission: {...SubmissionMocks.excused},
      })
      props.submitButtonRef = createSubmitButtonRef()
      const {findByText} = render(
        <MockedProvider>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )

      expect(await findByText('Availability Dates')).toBeInTheDocument()
    })
  })

  describe('the submission type is online_upload', () => {
    it('renders the file upload tab when the submission is unsubmitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_upload']},
      })
      props.submitButtonRef = createSubmitButtonRef()

      const {getByTestId} = render(
        <MockedProvider mocks={defaultMocks()}>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )
      expect(await waitFor(() => getByTestId('upload-pane'))).toBeInTheDocument()
    })

    it('renders the file preview tab when the submission is submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          submissionTypes: ['online_upload'],
          courseId: '1',
        },
        Submission: {
          ...SubmissionMocks.submitted,
          attachments: [
            {
              displayName: 'test.jpg',
              submissionPreviewUrl: 'http://example.com/preview',
              mimeClass: 'image',
              _id: '1',
              id: '1',
            },
          ],
        },
      })
      props.submitButtonRef = createSubmitButtonRef()

      const mocks = [
        {
          request: {
            query: EXTERNAL_TOOLS_QUERY,
            variables: {courseID: '1'},
          },
          result: {
            data: {
              course: {
                externalToolsConnection: {
                  nodes: [],
                },
              },
            },
          },
        },
      ]

      const {findByTestId} = render(
        <MockedProvider mocks={mocks}>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )

      // First wait for the loading spinner to appear
      const spinner = await findByTestId('attempt-tab')
      expect(spinner).toBeInTheDocument()

      // Then wait for the preview to appear
      expect(await findByTestId('assignments_2_submission_preview')).toBeInTheDocument()
    })

    describe('Uploading a file', () => {
      beforeAll(() => {
        $('body').append('<div role="alert" id="flash_screenreader_holder" />')
        uploadFileModule.uploadFiles = jest.fn()
      })

      it('shows a file preview for an uploaded file', async () => {
        const props = await mockAssignmentAndSubmission({
          Submission: {
            submissionDraft: {
              attachments: [{displayName: 'test.jpg'}],
            },
          },
        })
        props.submitButtonRef = createSubmitButtonRef()

        const {getAllByText} = render(
          <MockedProvider mocks={defaultMocks()}>
            <AttemptTab {...props} focusAttemptOnInit={false} />
          </MockedProvider>,
        )
        expect(await waitFor(() => getAllByText('test.jpg')[0])).toBeInTheDocument()
      })
    })
  })
})
