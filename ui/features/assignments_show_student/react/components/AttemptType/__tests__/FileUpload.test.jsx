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
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {EXTERNAL_TOOLS_QUERY, USER_GROUPS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import FileUpload from '../FileUpload'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import StudentViewContext from '../../Context'

async function createGraphqlMocks(overrides = {}) {
  const userGroupOverrides = [{Node: () => ({__typename: 'User'})}]
  userGroupOverrides.push(overrides)

  const externalToolsResult = await mockQuery(EXTERNAL_TOOLS_QUERY, overrides, {courseID: '1'})
  const userGroupsResult = await mockQuery(USER_GROUPS_QUERY, userGroupOverrides, {userID: '1'})
  return [
    {
      request: {
        query: EXTERNAL_TOOLS_QUERY,
        variables: {courseID: '1'},
      },
      result: externalToolsResult,
    },
    {
      request: {
        query: EXTERNAL_TOOLS_QUERY,
        variables: {courseID: '1'},
      },
      result: externalToolsResult,
    },
    {
      request: {
        query: USER_GROUPS_QUERY,
        variables: {userID: '1'},
      },
      result: userGroupsResult,
    },
  ]
}

async function makeProps(overrides) {
  const assignmentAndSubmission = await mockAssignmentAndSubmission(overrides)
  const props = {
    ...assignmentAndSubmission,

    // Make these return a promise that will resolve
    onCanvasFileRequested: jest.fn(),
    onUploadRequested: jest.fn(),
    filesToUpload: [],
    uploadingFiles: false,
    focusOnInit: false,
  }
  return props
}

// EVAL-3907 - remove or rewrite to remove spies on imports
describe.skip('FileUpload', () => {
  beforeAll(() => {
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  })

  beforeEach(() => {
    uploadFileModule.uploadFile = jest.fn().mockResolvedValue(null)
  })

  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files,
      },
    })
  }

  it('renders the upload file drop', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toHaveTextContent(/choose a file to upload/i)
  })

  it('renders an enabled upload file drop for students', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const fileDrop = getByTestId('input-file-drop')

    expect(fileDrop).not.toBeDisabled()
  })

  it('renders a disabled upload file drop for observers', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <StudentViewContext.Provider value={{allowChangesToSubmission: false, isObserver: true}}>
          <FileUpload {...props} />
        </StudentViewContext.Provider>
      </MockedProvider>
    )
    const fileDrop = getByTestId('input-file-drop')

    expect(fileDrop).toBeDisabled()
  })

  it('does not move focus to file drop box after render if focusOnInit is false', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const inputFileDrop = getByTestId('input-file-drop')

    expect(inputFileDrop).not.toHaveFocus()
  })

  it('moves focus to file drop box after render if focusOnInit is true', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    props.focusOnInit = true
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const inputFileDrop = getByTestId('input-file-drop')

    expect(inputFileDrop).toHaveFocus()
  })

  it('renders the submission draft files if there are any', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'foobarbaz'},
    })

    const {getByTestId, getAllByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const uploadRender = getByTestId('upload-pane')
    expect(uploadRender).toContainElement(getAllByText('foobarbaz')[0])
  })

  it('renders in an img tag if the file type is an image', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'foobarbaz', mimeClass: 'image'},
    })
    const {container, getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const uploadRender = getByTestId('upload-pane')
    expect(uploadRender).toContainElement(container.querySelector('img[alt="foobarbaz preview"]'))
  })

  it('renders an icon if a non-image file is uploaded', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'foobarbaz', mimeClass: 'pdf'},
    })

    const {container, getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const uploadRender = getByTestId('upload-pane')

    expect(uploadRender).toContainElement(container.querySelector('svg[name="IconPdf"]'))
    expect(container.querySelector('img[alt="foobarbaz preview"]')).toBeNull()
  })

  it('allows uploading multiple files at a time', async () => {
    const mocks = await createGraphqlMocks()
    const setOnSuccess = jest.fn()
    const props = await makeProps()
    uploadFileModule.uploadFile
      .mockResolvedValueOnce({id: '1', name: 'file1.jpg'})
      .mockResolvedValueOnce({id: '2', name: 'file2.jpg'})

    const {container} = render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
    const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file, file2])

    await waitFor(() => {
      expect(props.onUploadRequested).toHaveBeenCalledWith(
        expect.objectContaining({
          files: [
            expect.objectContaining({preview: 'http://example.com/whatever'}),
            expect.objectContaining({preview: 'http://example.com/whatever'}),
          ],
        })
      )
    })
  })

  it('creates an error alert when the API fails to upload files', async () => {
    const mocks = await createGraphqlMocks()
    const setOnFailure = jest.fn()
    const setOnSuccess = jest.fn()
    const props = await makeProps()
    props.onUploadRequested.mockImplementation(({onError}) => {
      onError(new Error('no'))
    })

    const {container} = render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file])
    await waitFor(() => {
      expect(setOnFailure).toHaveBeenCalledWith('Error updating submission draft')
    })
  })

  it('uploads files received through the LtiDeepLinkingResponse message event', async () => {
    const mocks = await createGraphqlMocks()
    const setOnSuccess = jest.fn()
    const props = await makeProps({
      Submission: {attempt: 0},
    })
    uploadFileModule.uploadFile.mockResolvedValueOnce({id: '1', name: 'LemonRules.jpg'})

    render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'LtiDeepLinkingResponse',
          content_items: [
            {
              url: 'http://lemon.com',
              title: 'LemonRules.txt',
              mediaType: 'plain/txt',
            },
          ],
        },
      })
    )

    await waitFor(() => {
      expect(props.onUploadRequested).toHaveBeenCalledWith(
        expect.objectContaining({
          files: [
            {
              mediaType: 'plain/txt',
              title: 'LemonRules.txt',
              url: 'http://lemon.com',
            },
          ],
        })
      )
    })
  })

  it('clears mediaType on files received through the A2ExternalContentReady message event', async () => {
    const mocks = await createGraphqlMocks()
    const setOnSuccess = jest.fn()
    const props = await makeProps({
      Submission: {attempt: 0},
    })
    uploadFileModule.uploadFile.mockResolvedValueOnce({id: '1', name: 'LemonRules.jpg'})

    render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'A2ExternalContentReady',
          content_items: [
            {
              url: 'http://lemon.com',
              title: 'LemonRules.txt',
              mediaType: 'application/octet-stream',
            },
          ],
        },
      })
    )

    await waitFor(() => {
      expect(props.onUploadRequested).toHaveBeenCalledWith(
        expect.objectContaining({
          files: [
            {
              mediaType: '',
              title: 'LemonRules.txt',
              url: 'http://lemon.com',
            },
          ],
        })
      )
    })
  })

  it('creates an error alert when given no file id through the Lti response', async () => {
    const mocks = await createGraphqlMocks()
    const setOnFailure = jest.fn()
    const props = await makeProps()
    render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'A2ExternalContentReady',
          content_items: [],
        },
      })
    )

    expect(setOnFailure).toHaveBeenCalledWith('Error adding files to submission draft')
  })

  it('creates an error alert when an error message is present in the Lti response', async () => {
    const mocks = await createGraphqlMocks()
    const setOnFailure = jest.fn()
    const props = await makeProps()
    render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )

    const errormsg = 'oooh eeee this is an error message'
    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'LtiDeepLinkingResponse',
          errormsg,
        },
      })
    )

    expect(setOnFailure).toHaveBeenCalledWith(errormsg)
  })

  it('does not call onUploadRequested when there is an error message present in the Lti response', async () => {
    const mocks = await createGraphqlMocks()
    const setOnFailure = jest.fn()
    const props = await makeProps()
    render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )

    const errormsg = 'oooh eeee this is an error message'
    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'LtiDeepLinkingResponse',
          content_items: [
            {
              url: 'http://lemon.com',
              title: 'LemonRules.txt',
              mediaType: 'plain/txt',
            },
          ],
          errormsg,
        },
      })
    )

    expect(props.onUploadRequested).not.toHaveBeenCalled()
  })

  it('renders a button to remove the file', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {_id: '1', displayName: 'foobarbaz'},
    })

    const {container, getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const button = container.querySelector('button[id="1"]')

    expect(button).toContainElement(getByText('Remove foobarbaz'))
    expect(button).toContainElement(container.querySelector('svg[name="IconTrash"]'))
  })

  it('renders a remove button for each uploaded file', async () => {
    const mocks = await createGraphqlMocks()
    const attachmentOverrides = [
      {_id: '1', displayName: 'foobarbaz1'},
      {_id: '2', displayName: 'foobarbaz2'},
    ]
    const props = await makeProps({
      Submission: {
        submissionDraft: {attachments: attachmentOverrides},
      },
    })

    const {container, getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )

    attachmentOverrides.forEach(attachment => {
      const button = container.querySelector(`button[id="${attachment._id}"]`)
      expect(button).toContainElement(getByText(`Remove ${attachment.displayName}`))
    })
  })

  it('elides filenames for files greater than 21 characters', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'c'.repeat(22)},
    })

    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )

    expect(getByText(/^c+\.{3}c+$/)).toBeInTheDocument()
  })

  it('does not elide filenames for files less than or equal to 21 characters', async () => {
    const mocks = await createGraphqlMocks()
    const filename = 'c'.repeat(21)
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: filename},
    })

    const {getAllByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )

    expect(getAllByText(filename)[0]).toBeInTheDocument()
  })

  it('displays a button for uploading Canvas files in the upload box', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId, findByRole} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toContainElement(await findByRole('button', {name: /Files/}))
  })

  it('displays allowed extensions in the upload box', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Assignment: {allowedExtensions: ['jpg, png']},
    })
    const {getByTestId, getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toContainElement(getByText('File permitted: JPG, PNG'))
  })

  it('does not display any allowed extensions if there are none', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId, queryByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).not.toContainElement(queryByText('File permitted'))
  })

  it('renders an error when adding a file that is not an allowed extension', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Assignment: {allowedExtensions: ['jpg']},
    })
    const {container, getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file])

    expect(getByText('Invalid file type')).toBeInTheDocument()
  })

  it('does not render an error when adding a file that is an allowed extension', async () => {
    const mocks = await createGraphqlMocks()
    const setOnSuccess = jest.fn()
    const props = await makeProps({
      Assignment: {allowedExtensions: ['jpg']},
    })
    const {container, queryByText} = render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})

    uploadFiles(fileInput, [file])

    expect(queryByText('Invalid file type')).toBeNull()
  })

  it('shows a checkmark icon for uploaded files', async () => {
    const mocks = await createGraphqlMocks()
    const setOnSuccess = jest.fn()
    const attachmentOverrides = [{_id: '1', displayName: 'just a file'}]
    const props = await makeProps({
      Submission: {
        submissionDraft: {attachments: attachmentOverrides},
      },
    })

    const {container, getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
    const uploadRender = getByTestId('upload-pane')
    expect(uploadRender).toContainElement(container.querySelector('svg[name="IconComplete"]'))
  })

  it('renders a loading indicator for each file in the process of uploading', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    props.filesToUpload = [
      {id: '1', _id: '1', name: 'file1.pdf', isLoading: true, loaded: 10, total: 100},
      {id: '2', _id: '2', name: 'file2.pdf', isLoading: true, loaded: 50, total: 250},
    ]

    const {getAllByRole} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>
    )

    const progressBars = getAllByRole('progressbar')
    expect(progressBars).toHaveLength(2)

    expect(progressBars[0]).toHaveAttribute('aria-valuenow', '10')
    expect(progressBars[0]).toHaveAttribute('aria-valuemax', '100')
    expect(progressBars[0]).toHaveAttribute('aria-valuetext', '10 percent')
    expect(progressBars[0]).toHaveAttribute(
      'aria-label',
      'Upload progress for file1.pdf 10 percent'
    )

    expect(progressBars[1]).toHaveAttribute('aria-valuenow', '50')
    expect(progressBars[1]).toHaveAttribute('aria-valuemax', '250')
    expect(progressBars[1]).toHaveAttribute('aria-valuetext', '20 percent')
    expect(progressBars[1]).toHaveAttribute(
      'aria-label',
      'Upload progress for file2.pdf 20 percent'
    )
  })

  describe('webcam photo upload', () => {
    it('is available when the assignment has no file extension restrictions', async () => {
      const mocks = await createGraphqlMocks()
      const props = await makeProps()

      const {findByRole} = render(
        <MockedProvider mocks={mocks}>
          <FileUpload {...props} />
        </MockedProvider>
      )
      fireEvent.click(await findByRole('button', {name: /Canvas Files/}))
      expect(await findByRole('button', {name: /Webcam/})).toBeInTheDocument()
    })

    it('is available when the assignment allows PNG files', async () => {
      const mocks = await createGraphqlMocks()
      const props = await makeProps({
        Assignment: {allowedExtensions: ['jpg', 'png']},
      })

      const {findByRole} = render(
        <MockedProvider mocks={mocks}>
          <FileUpload {...props} />
        </MockedProvider>
      )
      fireEvent.click(await findByRole('button', {name: /Canvas Files/}))
      expect(await findByRole('button', {name: /Webcam/})).toBeInTheDocument()
    })

    it('is not available when the assignment does not allow PNG files', async () => {
      const mocks = await createGraphqlMocks()
      const props = await makeProps({
        Assignment: {allowedExtensions: ['xls']},
      })

      const {findByRole, queryByRole} = render(
        <MockedProvider mocks={mocks}>
          <FileUpload {...props} />
        </MockedProvider>
      )
      fireEvent.click(await findByRole('button', {name: /Canvas Files/}))
      expect(queryByRole('button', {name: /Webcam/})).not.toBeInTheDocument()
    })
  })
})
