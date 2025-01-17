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
import React from 'react'
import StudentViewContext from '../Context'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

jest.mock('@canvas/upload-file')

const defaultMocks = (result = {data: {}}) => [
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
          expect(tinymce?.editors[0]).toBeDefined()
        },
        {timeout: 4000},
      )
      return retval
    } else {
      return Promise.resolve(retval)
    }
  }

  describe('the assignment is locked aka passed the until date', () => {
    it('renders the availability dates if the assignment was not submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {lockInfo: {isLocked: true}},
      })
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

      const {getByTestId} = render(
        <MockedProvider mocks={defaultMocks()}>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )
      expect(await waitFor(() => getByTestId('upload-pane'))).toBeInTheDocument()
    })

    it('renders the file preview tab when the submission is submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_upload']},
        Submission: {
          ...SubmissionMocks.submitted,
          attachments: [{}],
        },
      })

      const {findByTestId} = render(<AttemptTab {...props} focusAttemptOnInit={false} />)
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

        const {getAllByText} = render(
          <MockedProvider mocks={defaultMocks()}>
            <AttemptTab {...props} focusAttemptOnInit={false} />
          </MockedProvider>,
        )
        expect(await waitFor(() => getAllByText('test.jpg')[0])).toBeInTheDocument()
      })
    })
  })

  describe('the submission type is student_annotation', () => {
    it('renders the canvadocs iframe', async () => {
      const assignmentAndSubmission = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['student_annotation']},
      })
      const props = {
        ...assignmentAndSubmission,
        createSubmissionDraft: jest.fn().mockResolvedValue({}),
      }

      const {getByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
      expect(await waitFor(() => getByTestId('canvadocs-pane'))).toBeInTheDocument()
    })
  })

  describe('the submission type is online_text_entry', () => {
    beforeAll(async () => {
      $('body').append('<div role="alert" id="flash_screenreader_holder" />')
      uploadFileModule.uploadFiles = jest.fn()

      // This gets the lazy loaded components loaded before our specs.
      // otherwise, the first one (at least) will fail.
      const {unmount} = render(
        <TextEntry focusOnInit={false} submission={{id: '1', _id: '1', state: 'unsubmitted'}} />,
      )
      await waitFor(() => {
        expect(tinymce.editors[0]).toBeDefined()
      })
      unmount()
    })

    describe('uploading a text draft', () => {
      it('renders the text entry tab', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry']},
        })

        const {findByTestId} = await renderAttemptTab(props)
        expect(await findByTestId('text-editor')).toBeInTheDocument()
      })

      // The following tests don't match how the text editor actually works.
      // The RCE doesn't play nicely with our test environment, so we stub it
      // out and instead test for the read-only property (and possibly others
      // eventually) on the TextEntry component's placeholder text-area. This
      // does not mirror real-world usage but at least lets us verify that our
      // props are being passed through and correctly on the initial render.
      describe('text area', () => {
        it('renders as read-only if the submission has been submitted', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'submitted',
            },
          })

          const {findByTestId} = await renderAttemptTab(props)
          expect(await findByTestId('read-only-content')).toBeInTheDocument()
        })

        it('does not render as read-only if the submission has been graded pre-submission', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'graded',
              attempt: 0,
            },
          })

          const {queryByTestId} = await renderAttemptTab(props)
          expect(queryByTestId('read-only-content')).not.toBeInTheDocument()
        })

        it('renders as read-only if the submission has been graded post-submission', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'graded',
              attempt: 1,
            },
          })

          const {findByTestId} = await renderAttemptTab(props)
          expect(await findByTestId('read-only-content')).toBeInTheDocument()
        })

        it('renders as read-only if changes are not allowed to the submission', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'unsubmitted',
            },
          })

          const {findByTestId} = render(
            <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
              <AttemptTab {...props} focusAttemptOnInit={false} />
            </StudentViewContext.Provider>,
          )

          expect(await findByTestId('read-only-content')).toBeInTheDocument()
        })

        it('does not render as read-only if changes are allowed and the submission is not submitted', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'unsubmitted',
            },
          })

          const {queryByTestId} = await renderAttemptTab(props)
          expect(queryByTestId('read-only-content')).not.toBeInTheDocument()
        })
      })
    })
  })
})
