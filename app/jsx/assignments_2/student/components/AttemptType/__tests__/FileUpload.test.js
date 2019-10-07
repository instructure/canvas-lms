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
import * as uploadFileModule from '../../../../../shared/upload_file'
import {AlertManagerContext} from '../../../../../shared/components/AlertManager'
import {DEFAULT_ICON} from '../../../../../shared/helpers/mimeClassIconHelper'
import FileUpload from '../FileUpload'
import {fireEvent, render, wait} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '../../../mocks'
import React from 'react'
import {SubmissionMocks} from '../../../graphqlData/Submission'

async function makeProps(overrides) {
  const assignmentAndSubmission = await mockAssignmentAndSubmission(overrides)
  const props = {
    ...assignmentAndSubmission,

    // Make these return a promise that will resolve
    createSubmissionDraft: jest.fn().mockResolvedValue({}),
    updateUploadingFiles: jest.fn().mockResolvedValue({}),
    uploadingFiles: false
  }
  return props
}

beforeAll(() => {
  $('body').append('<div role="alert" id="flash_screenreader_holder" />')
})

beforeEach(() => {
  window.URL.createObjectURL = jest.fn().mockReturnValue('perry_preview')
  uploadFileModule.uploadFiles = jest.fn().mockResolvedValue([])
})

describe('FileUpload', () => {
  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files
      }
    })
  }

  it('renders the upload tab by default', async () => {
    const props = await makeProps()
    const {container, getByTestId, getByText} = render(<FileUpload {...props} />)
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toContainElement(getByText('Upload File'))
    expect(emptyRender).toContainElement(
      container.querySelector(`svg[name=${DEFAULT_ICON.type.displayName.replace('Line', '')}]`)
    )
  })

  it('renders the submission draft files if there are any', async () => {
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'foobarbaz'}
    })

    const {getByTestId, getAllByText} = render(<FileUpload {...props} />)
    const uploadRender = getByTestId('non-empty-upload')
    expect(uploadRender).toContainElement(getAllByText('foobarbaz')[0])
  })

  it('renders in an img tag if the file type is an image', async () => {
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'foobarbaz', mimeClass: 'image'}
    })
    const {container, getByTestId} = render(<FileUpload {...props} />)
    const uploadRender = getByTestId('non-empty-upload')
    expect(uploadRender).toContainElement(container.querySelector('img[alt="foobarbaz preview"]'))
  })

  it('renders an icon if a non-image file is uploaded', async () => {
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'foobarbaz', mimeClass: 'pdf'}
    })

    const {container, getByTestId} = render(<FileUpload {...props} />)
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(container.querySelector('svg[name="IconPdf"]'))
    expect(container.querySelector('img[alt="foobarbaz preview"]')).toBeNull()
  })

  it('allows uploading multiple files at a time', async () => {
    const props = await makeProps()
    uploadFileModule.uploadFiles.mockResolvedValue([
      {id: '1', name: 'file1.jpg'},
      {id: '2', name: 'file2.jpg'}
    ])

    const {container} = render(<FileUpload {...props} />)
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
    const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file, file2])

    await wait(() => {
      expect(props.createSubmissionDraft).toHaveBeenCalledWith({
        variables: {
          id: '1',
          activeSubmissionType: 'online_upload',
          attempt: 1,
          fileIds: ['1', '2']
        }
      })
    })
  })

  it('creates an error alert when the API fails to upload files', async () => {
    const setOnFailure = jest.fn()
    const props = await makeProps()
    uploadFileModule.uploadFiles.mock.results = () => {
      throw new Error('no')
    }

    const {container} = render(
      <AlertManagerContext.Provider value={{setOnFailure}}>
        <FileUpload {...props} />
      </AlertManagerContext.Provider>
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file])
    expect(setOnFailure).toHaveBeenCalledWith('Error updating submission draft')
  })

  it('uploads files received through the LtiDeepLinkingResponse message event', async () => {
    const props = await makeProps({
      Submission: {attempt: 0}
    })
    uploadFileModule.uploadFiles.mockResolvedValue([{id: '1', name: 'LemonRules.jpg'}])

    render(<FileUpload {...props} />)

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          messageType: 'LtiDeepLinkingResponse',
          content_items: [
            {
              url: 'http://lemon.com',
              title: 'LemonRules.txt',
              mediaType: 'plain/txt'
            }
          ]
        }
      })
    )

    await wait(() => {
      expect(props.createSubmissionDraft).toHaveBeenCalledWith({
        variables: {
          id: '1',
          activeSubmissionType: 'online_upload',
          attempt: 1,
          fileIds: ['1']
        }
      })
    })
  })

  it('creates an error alert when given no file id through the Lti response', async () => {
    const setOnFailure = jest.fn()
    const props = await makeProps()
    render(
      <AlertManagerContext.Provider value={{setOnFailure}}>
        <FileUpload {...props} />
      </AlertManagerContext.Provider>
    )

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          messageType: 'A2ExternalContentReady',
          content_items: []
        }
      })
    )

    expect(setOnFailure).toHaveBeenCalledWith('Error adding files to submission draft')
  })

  // Byproduct of how the dummy submissions are being handled. Check out ViewManager
  // for some context around this
  it('creates a submission draft for the current attempt when not on attempt 0', async () => {
    const props = await makeProps({
      Submission: {attempt: 2}
    })
    uploadFileModule.uploadFiles.mockResolvedValue([{id: '1', name: 'file1.jpg'}])

    const {container} = render(<FileUpload {...props} />)
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
    uploadFiles(fileInput, [file])

    await wait(() => {
      expect(props.createSubmissionDraft).toHaveBeenCalledWith({
        variables: {
          id: '1',
          activeSubmissionType: 'online_upload',
          attempt: 2,
          fileIds: ['1']
        }
      })
    })
  })

  it('creates a submission draft for attempt one when on attempt 0', async () => {
    const props = await makeProps({
      Submission: {attempt: 0}
    })
    uploadFileModule.uploadFiles.mockResolvedValue([{id: '1', name: 'file1.jpg'}])

    const {container} = render(<FileUpload {...props} />)
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
    uploadFiles(fileInput, [file])

    await wait(() => {
      expect(props.createSubmissionDraft).toHaveBeenCalledWith({
        variables: {
          id: '1',
          activeSubmissionType: 'online_upload',
          attempt: 1,
          fileIds: ['1']
        }
      })
    })
  })

  it('renders a button to remove the file', async () => {
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {_id: '1', displayName: 'foobarbaz'}
    })

    const {container, getByText} = render(<FileUpload {...props} />)
    const button = container.querySelector('button[id="1"]')

    expect(button).toContainElement(getByText('Remove foobarbaz'))
    expect(button).toContainElement(container.querySelector('svg[name="IconTrash"]'))
  })

  it('renders a remove button for each uploaded file', async () => {
    const attachmentOverrides = [
      {_id: '1', displayName: 'foobarbaz1'},
      {_id: '2', displayName: 'foobarbaz2'}
    ]
    const props = await makeProps({
      Submission: {
        submissionDraft: {attachments: attachmentOverrides}
      }
    })

    const {container, getByText} = render(<FileUpload {...props} />)

    attachmentOverrides.forEach(attachment => {
      const button = container.querySelector(`button[id="${attachment._id}"]`)
      expect(button).toContainElement(getByText(`Remove ${attachment.displayName}`))
    })
  })

  it('elides filenames for files greater than 21 characters', async () => {
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'c'.repeat(22)}
    })

    const {getByText} = render(<FileUpload {...props} />)

    expect(getByText(/^c+\.{3}c+$/)).toBeInTheDocument()
  })

  it('does not elide filenames for files less than or equal to 21 characters', async () => {
    const filename = 'c'.repeat(21)
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: filename}
    })

    const {getAllByText} = render(<FileUpload {...props} />)

    expect(getAllByText(filename)[0]).toBeInTheDocument()
  })

  it('displays the more options button in the upload box', async () => {
    const props = await makeProps()
    const {getByTestId, getByText} = render(<FileUpload {...props} />)
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toContainElement(getByText('More Options'))
  })

  it('displays allowed extensions in the upload box', async () => {
    const props = await makeProps({
      Assignment: {allowedExtensions: ['jpg, png']}
    })
    const {getByTestId, getByText} = render(<FileUpload {...props} />)
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toContainElement(getByText('File permitted: JPG, PNG'))
  })

  it('does not display any allowed extensions if there are none', async () => {
    const props = await makeProps()
    const {getByTestId, queryByText} = render(<FileUpload {...props} />)
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).not.toContainElement(queryByText('File permitted'))
  })

  it('renders an error when adding a file that is not an allowed extension', async () => {
    const props = await makeProps({
      Assignment: {allowedExtensions: ['jpg']}
    })
    const {container, getByText, queryByTestId} = render(<FileUpload {...props} />)
    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file])

    expect(getByText('Invalid file type')).toBeInTheDocument()
    expect(queryByTestId('non-empty-upload')).toBeNull()
  })

  it('does not render an error when adding a file that is an allowed extension', async () => {
    const props = await makeProps({
      Assignment: {allowedExtensions: ['jpg']}
    })
    const {container, queryByText} = render(<FileUpload {...props} />)
    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})

    uploadFiles(fileInput, [file])

    expect(queryByText('Invalid file type')).toBeNull()
  })

  it('renders a loading indicator when a file is being uploaded', async () => {
    const props = await makeProps()
    props.uploadingFiles = true
    const {getByTestId, getByText} = render(<FileUpload {...props} />)

    const uploadingFilesRender = getByTestId('upload-pane')
    expect(uploadingFilesRender).toContainElement(getByText('Loading'))
  })
})
