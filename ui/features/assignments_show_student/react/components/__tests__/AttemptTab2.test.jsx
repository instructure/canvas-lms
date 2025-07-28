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

import 'jquery'
import * as uploadFileModule from '@canvas/upload-file'
import AttemptTab from '../AttemptTab'
import {EXTERNAL_TOOLS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {act, fireEvent, render, waitFor} from '@testing-library/react'
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
          expect(tinymce.get('textentry_text')).toBeDefined()
        },
        {timeout: 4000},
      )
      return retval
    } else {
      return Promise.resolve(retval)
    }
  }

  describe('there are multiple submission types', () => {
    describe('when no submission type is selected', () => {
      it('renders the submission type selector if the submission can be modified', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        })
        const {getByTestId} = render(
          <MockedProvider mocks={defaultMocks()}>
            <AttemptTab {...props} focusAttemptOnInit={false} />
          </MockedProvider>,
        )

        expect(getByTestId('submission-type-selector')).toBeInTheDocument()
      })

      it('shows buttons for the available submission types', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        })

        const {getAllByRole} = render(
          <MockedProvider mocks={defaultMocks()}>
            <AttemptTab {...props} focusAttemptOnInit={false} />
          </MockedProvider>,
        )

        const buttons = getAllByRole('button')
        expect(buttons).toHaveLength(2)
        expect(buttons[0]).toHaveTextContent('Text')
        expect(buttons[1]).toHaveTextContent('Upload')
      })

      it('shows disabled buttons for the available submission types for observers', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        })
        const {getAllByRole} = render(
          <MockedProvider mocks={defaultMocks()}>
            <StudentViewContext.Provider
              value={{allowChangesToSubmission: false, isObserver: true}}
            >
              <AttemptTab {...props} focusAttemptOnInit={false} />
            </StudentViewContext.Provider>
          </MockedProvider>,
        )

        const buttons = getAllByRole('button')
        expect(buttons).toHaveLength(2)
        expect(buttons[0]).toBeDisabled()
        expect(buttons[1]).toBeDisabled()
      })

      it('displays "Available submission types" for observers', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        })
        const {getByText} = render(
          <MockedProvider mocks={defaultMocks()}>
            <StudentViewContext.Provider
              value={{allowChangesToSubmission: false, isObserver: true}}
            >
              <AttemptTab {...props} focusAttemptOnInit={false} />
            </StudentViewContext.Provider>
          </MockedProvider>,
        )

        expect(getByText('Available submission types')).toBeInTheDocument()
      })

      it('displays "Choose a submission type" for students', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        })
        const {getByText} = render(
          <MockedProvider mocks={defaultMocks()}>
            <StudentViewContext.Provider value={{allowChangesToSubmission: true, observer: false}}>
              <AttemptTab {...props} focusAttemptOnInit={false} />
            </StudentViewContext.Provider>
          </MockedProvider>,
        )

        expect(getByText('Choose a submission type')).toBeInTheDocument()
      })

      it('does not render the submission type selector if the submission cannot be modified', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        })
        const {queryByTestId} = render(
          <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
            <AttemptTab {...props} focusAttemptOnInit={false} />
          </StudentViewContext.Provider>,
        )

        expect(queryByTestId('submission-type-selector')).not.toBeInTheDocument()
      })
    })

    it('updates the active type after selecting a type', async () => {
      const mockedUpdateActiveSubmissionType = jest.fn()
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
      })
      const {getByRole} = render(
        <MockedProvider mocks={defaultMocks()}>
          <AttemptTab
            {...props}
            updateActiveSubmissionType={mockedUpdateActiveSubmissionType}
            focusAttemptOnInit={false}
          />
        </MockedProvider>,
      )

      const textButton = getByRole('button', {name: /Text/})
      act(() => {
        fireEvent.click(textButton)
      })

      expect(mockedUpdateActiveSubmissionType).toHaveBeenCalledWith('online_text_entry')
    })

    it('renders the active submission type if available', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_url']},
      })
      const {findByTestId} = render(
        <MockedProvider mocks={defaultMocks()}>
          <AttemptTab {...props} activeSubmissionType="online_url" focusAttemptOnInit={false} />
        </MockedProvider>,
      )

      expect(await findByTestId('url-entry')).toBeInTheDocument()
    })

    it('does not render the selector if the submission state is submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        Submission: {
          state: 'submitted',
        },
      })
      const {queryByTestId} = render(
        <MockedProvider mocks={defaultMocks()}>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )

      expect(queryByTestId('submission-type-selector')).not.toBeInTheDocument()
    })

    it('does not render the selector if the student is graded post-submission', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        Submission: {
          state: 'graded',
          attempt: 1,
        },
      })
      const {queryByTestId} = render(
        <MockedProvider mocks={defaultMocks()}>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )

      expect(queryByTestId('submission-type-selector')).not.toBeInTheDocument()
    })

    it('renders the selector if the student is graded pre-submission', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        Submission: {
          state: 'graded',
          attempt: 0,
        },
      })
      const {queryByTestId} = render(
        <MockedProvider mocks={defaultMocks()}>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )

      expect(queryByTestId('submission-type-selector')).toBeInTheDocument()
    })

    it('does not render the selector if the context indicates the submission cannot be modified', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
      })

      const {queryByTestId} = render(
        <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </StudentViewContext.Provider>,
      )

      expect(queryByTestId('submission-type-selector')).not.toBeInTheDocument()
    })
  })

  describe('group assignments', () => {
    const groupMatcher = /this submission will count for everyone in your sample-group-set group/

    it('shows a reminder for a group assignment that does not grade students individually and is not yet submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          gradeGroupStudentsIndividually: false,
          groupSet: {
            _id: '1',
            name: 'sample-group-set',
          },
          submissionTypes: ['online_text_entry', 'online_upload'],
        },
        Submission: {
          ...SubmissionMocks.onlineUploadReadyToSubmit,
        },
      })

      const {getByText} = render(
        <MockedProvider mocks={defaultMocks()}>
          <StudentViewContext.Provider value={{allowChangesToSubmission: true}}>
            <AttemptTab {...props} focusAttemptOnInit={false} />
          </StudentViewContext.Provider>
        </MockedProvider>,
      )

      expect(getByText(groupMatcher)).toBeInTheDocument()
    })

    it('does not show a reminder for a non-group assignment', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          submissionTypes: ['online_text_entry', 'online_upload'],
        },
        Submission: {
          ...SubmissionMocks.onlineUploadReadyToSubmit,
        },
      })

      const {queryByText} = render(
        <MockedProvider mocks={defaultMocks()}>
          <StudentViewContext.Provider value={{allowChangesToSubmission: true}}>
            <AttemptTab {...props} focusAttemptOnInit={false} />
          </StudentViewContext.Provider>
        </MockedProvider>,
      )

      expect(queryByText(groupMatcher)).not.toBeInTheDocument()
    })

    it('does not show a reminder for a group assignment that grades students individually', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          gradeGroupStudentsIndividually: true,
          groupSet: {
            _id: '1',
            name: 'sample-group-set',
          },
          submissionTypes: ['online_text_entry', 'online_upload'],
        },
        Submission: {
          ...SubmissionMocks.onlineUploadReadyToSubmit,
        },
      })

      const {queryByText} = render(
        <MockedProvider mocks={defaultMocks()}>
          <StudentViewContext.Provider value={{allowChangesToSubmission: true}}>
            <AttemptTab {...props} focusAttemptOnInit={false} />
          </StudentViewContext.Provider>
        </MockedProvider>,
      )

      expect(queryByText(groupMatcher)).not.toBeInTheDocument()
    })

    it('does not show a reminder for a group assignment if the selected attempt is submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          gradeGroupStudentsIndividually: true,
          groupSet: {
            _id: '1',
            name: 'sample-group-set',
          },
          submissionTypes: ['online_text_entry', 'online_upload'],
        },
        Submission: {
          ...SubmissionMocks.submitted,
        },
      })

      const {queryByText} = render(
        <StudentViewContext.Provider value={{allowChangesToSubmission: true}}>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </StudentViewContext.Provider>,
      )

      expect(queryByText(groupMatcher)).not.toBeInTheDocument()
    })

    it('does not show a reminder if changes to the submission are not allowed', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          gradeGroupStudentsIndividually: false,
          groupSet: {
            _id: '1',
            name: 'sample-group-set',
          },
          submissionTypes: ['online_text_entry', 'online_upload'],
        },
        Submission: {
          ...SubmissionMocks.onlineUploadReadyToSubmit,
        },
      })

      const {queryByText} = render(
        <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </StudentViewContext.Provider>,
      )

      expect(queryByText(groupMatcher)).not.toBeInTheDocument()
    })
  })

  describe('file upload handling', () => {
    let uploadedFileCount

    beforeEach(() => {
      uploadedFileCount = 0
      uploadFileModule.uploadFile.mockImplementation(_file => {
        uploadedFileCount += 1
        return {id: `${uploadedFileCount}`}
      })
    })

    afterEach(() => {
      uploadFileModule.uploadFile.mockReset()
    })

    async function submitFiles(container, files) {
      await waitFor(() => expect(container.querySelector('input[type="file"]')).toBeInTheDocument())
      const fileInput = container.querySelector('input[type="file"]')
      fireEvent.change(fileInput, {target: {files}})
    }

    async function generatePropsWithAttempt(attempt) {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_upload']},
        Submission: {attempt},
      })
      props.focusAttemptOnInit = true
      props.updateUploadingFiles = jest.fn()
      props.createSubmissionDraft = jest.fn()
      return props
    }

    function renderWithProps(props) {
      return render(
        <MockedProvider>
          <AttemptTab {...props} />
        </MockedProvider>,
      )
    }

    it('calls uploadFile once for each file received that needs uploading', async () => {
      const props = await generatePropsWithAttempt(2)
      const {container} = renderWithProps(props)

      const file = new Blob(['foo'], {type: 'application/pdf'})
      file.name = 'file1.pdf'
      const file2 = new Blob(['foo'], {type: 'application/pdf'})
      file2.name = 'file2.pdf'

      await submitFiles(container, [file, file2])

      const {calls} = uploadFileModule.uploadFile.mock
      expect(calls).toHaveLength(2)
      expect(calls[0][1]).toEqual({
        content_type: 'application/pdf',
        name: 'file1.pdf',
        submit_assignment: true,
      })
      expect(calls[1][1]).toEqual({
        content_type: 'application/pdf',
        name: 'file2.pdf',
        submit_assignment: true,
      })
    })

    it('calls uploadFile with the URL pointing to the assignments api endpoint', async () => {
      const props = await generatePropsWithAttempt(2)
      props.assignment.groupSet = null
      const {container} = renderWithProps(props)

      const file = new Blob(['foo'], {type: 'application/pdf'})
      file.name = 'file1.pdf'
      await submitFiles(container, [file])
      const {calls} = uploadFileModule.uploadFile.mock
      expect(calls[0][0]).toEqual(
        `/api/v1/courses/1/assignments/${props.assignment._id}/submissions/1/files`,
      )
    })

    it('calls uploadFile with the URL pointing to the groups api endpoint', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_upload']},
        Submission: {attempt: 2},
      })
      props.focusAttemptOnInit = true
      props.updateUploadingFiles = jest.fn()
      props.createSubmissionDraft = jest.fn()

      const {container} = renderWithProps(props)

      const file = new Blob(['foo'], {type: 'application/pdf'})
      file.name = 'file1.pdf'
      await submitFiles(container, [file])
      const {calls} = uploadFileModule.uploadFile.mock
      expect(calls[0][0]).toEqual(
        `/api/v1/groups/${props.assignment.groupSet.currentGroup._id}/files`,
      )
    })

    // Byproduct of how the dummy submissions are being handled. Check out ViewManager
    // for some context around this
    it('creates a submission draft for the current attempt when not on attempt 0', async () => {
      const props = await generatePropsWithAttempt(2)
      const {container} = renderWithProps(props)

      const file = new Blob(['foo'], {type: 'application/pdf'})
      file.name = 'file1.pdf'
      await submitFiles(container, [file])

      await waitFor(() => {
        expect(props.createSubmissionDraft).toHaveBeenCalledWith({
          variables: {
            id: '1',
            activeSubmissionType: 'online_upload',
            attempt: 2,
            fileIds: ['1'],
          },
        })
      })
    })

    it('creates a submission draft for attempt 1 when on attempt 0', async () => {
      const props = await generatePropsWithAttempt(0)
      const {container} = renderWithProps(props)

      const file = new Blob(['foo'], {type: 'application/pdf'})
      file.name = 'file1.pdf'
      await submitFiles(container, [file])

      await waitFor(() => {
        expect(props.createSubmissionDraft).toHaveBeenCalledWith({
          variables: {
            id: '1',
            activeSubmissionType: 'online_upload',
            attempt: 1,
            fileIds: ['1'],
          },
        })
      })
    })

    it('renders a progress bar with the name of each file being uploaded', async () => {
      const progressHandlers = []

      uploadFileModule.uploadFile.mockReset()
      uploadFileModule.uploadFile
        .mockImplementationOnce((url, data, file, ajaxLib, onProgress) => {
          progressHandlers.push(onProgress)
          return Promise.resolve({id: '1', name: 'file1.pdf'})
        })
        .mockImplementationOnce((url, data, file, ajaxLib, onProgress) => {
          progressHandlers.push(onProgress)
          return Promise.resolve({id: '2', name: 'file2.pdf'})
        })

      const props = await generatePropsWithAttempt(0)
      const {container, findAllByRole} = renderWithProps(props)
      const file = new Blob(['foo'], {type: 'application/pdf'})
      file.name = 'file1.pdf'
      const file2 = new Blob(['foo'], {type: 'application/pdf'})
      file2.name = 'file2.pdf'
      await submitFiles(container, [file, file2])

      progressHandlers[0]({loaded: 10, total: 100})
      progressHandlers[1]({loaded: 50, total: 250})

      const progressBars = await findAllByRole('progressbar')
      expect(progressBars).toHaveLength(2)

      expect(progressBars[0]).toHaveAttribute('aria-valuetext', '10 percent')
      expect(progressBars[1]).toHaveAttribute('aria-valuetext', '20 percent')
    })

    function fireEventWithContentItem(contentItem) {
      fireEvent(
        window,
        new MessageEvent('message', {
          data: {
            subject: 'LtiDeepLinkingResponse',
            content_items: [contentItem],
          },
        }),
      )
    }

    it('shows the URL of a file being uploaded if no name is present', async () => {
      const progressHandlers = []

      uploadFileModule.uploadFile.mockReset()
      uploadFileModule.uploadFile.mockImplementationOnce((url, data, file, ajaxLib, onProgress) => {
        progressHandlers.push(onProgress)
        return Promise.resolve({id: '1', name: 'file1.pdf'})
      })

      const props = await generatePropsWithAttempt(0)
      const {container, findAllByRole} = renderWithProps(props)

      // It seems to be necessary to wait for something if the test is run in isolation
      await waitFor(() => expect(container.querySelector('input[type="file"]')).toBeInTheDocument())

      fireEventWithContentItem({url: 'http://localhost/some-lti-file', mediaType: 'plain/txt'})

      progressHandlers[0]({loaded: 10, total: 100})

      const progressBars = await findAllByRole('progressbar')
      expect(progressBars).toHaveLength(1)

      expect(progressBars[0]).toHaveAttribute('aria-valuetext', '10 percent')
    })

    it('uses "text" of the LTI content item as the file name for display and API calls', async () => {
      const progressHandlers = []

      uploadFileModule.uploadFile.mockReset()
      uploadFileModule.uploadFile.mockImplementationOnce((url, data, file, ajaxLib, onProgress) => {
        progressHandlers.push(onProgress)
        return Promise.resolve({id: '1', name: 'file1.pdf'})
      })

      const props = await generatePropsWithAttempt(0)
      const {container, findAllByRole} = renderWithProps(props)

      // It seems to be necessary to wait for something if the test is run in isolation
      await waitFor(() => expect(container.querySelector('input[type="file"]')).toBeInTheDocument())

      fireEventWithContentItem({
        url: 'http://localhost/some-lti-file',
        text: 'x.pdf',
        mediaType: 'plain/txt',
      })

      progressHandlers[0]({loaded: 10, total: 100})

      const progressBars = await findAllByRole('progressbar')
      expect(progressBars[0]).toHaveAttribute('aria-valuetext', '10 percent')

      expect(uploadFileModule.uploadFile.mock.calls[0][1]).toEqual({
        url: 'http://localhost/some-lti-file',
        name: 'x.pdf',
        content_type: 'plain/txt',
        submit_assignment: false,
      })
    })
  })
})
