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
import * as uploadFileModule from '../../../../shared/upload_file'
import {DEFAULT_ICON} from '../../../../shared/helpers/mimeClassIconHelper'
import FileUpload from '../FileUpload'
import {fireEvent, render, wait} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '../../mocks'
import {MockedProvider} from 'react-apollo/test-utils'
import React from 'react'
import {SubmissionMocks} from '../../graphqlData/Submission'

async function makeProps(overrides) {
  const assignmentAndSubmission = await mockAssignmentAndSubmission(overrides)
  const props = {
    ...assignmentAndSubmission,
    createSubmission: jest.fn(),
    createSubmissionDraft: jest.fn(),
    updateSubmissionState: jest.fn(),
    updateUploadState: jest.fn()
  }

  // Make these return a promise that will resolve
  props.createSubmission.mockResolvedValue({})
  props.createSubmissionDraft.mockResolvedValue({})
  return props
}

beforeAll(() => {
  $('body').append('<div role="alert" id="flash_screenreader_holder" />')
})

beforeEach(() => {
  window.URL.createObjectURL = jest.fn().mockReturnValue('perry_preview')
  uploadFileModule.uploadFiles = jest.fn()
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
    const {container, getByTestId, getByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toContainElement(getByText('Upload File'))
    expect(emptyRender).toContainElement(
      container.querySelector(`svg[name=${DEFAULT_ICON.type.displayName}]`)
    )
  })

  it('renders the submission draft files if there are any', async () => {
    const props = await makeProps({
      Submission: () => SubmissionMocks.draftWithAttachment,
      File: () => ({displayName: 'foobarbaz'})
    })

    const {getByTestId, getAllByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const uploadRender = getByTestId('non-empty-upload')
    expect(uploadRender).toContainElement(getAllByText('foobarbaz')[0])
  })

  it('renders in an img tag if the file type is an image', async () => {
    const props = await makeProps({
      Submission: () => SubmissionMocks.draftWithAttachment,
      File: () => ({displayName: 'foobarbaz', mimeClass: 'image'})
    })
    const {container, getByTestId} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const uploadRender = getByTestId('non-empty-upload')
    expect(uploadRender).toContainElement(container.querySelector('img[alt="foobarbaz preview"]'))
  })

  it('renders an icon if a non-image file is uploaded', async () => {
    const props = await makeProps({
      Submission: () => SubmissionMocks.draftWithAttachment,
      File: () => ({displayName: 'foobarbaz', mimeClass: 'pdf'})
    })

    const {container, getByTestId} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(container.querySelector('svg[name="IconPdf"]'))
    expect(container.querySelector('img[alt="foobarbaz preview"]')).toBeNull()
  })

  it('allows uploading multiple files at a time', async () => {
    const props = await makeProps()

    const {container, getByTestId, getByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
    const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file, file2])

    const filesRender = getByTestId('upload-pane')

    expect(filesRender).toContainElement(getByText('Loading'))
  })

  it('creates a submission draft with the attempt one larger then the current submisison', async () => {
    const props = await makeProps({
      Submission: () => ({attempt: 0})
    })
    uploadFileModule.uploadFiles.mockResolvedValue([{id: '1', name: 'file1.jpg'}])

    const {container} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
    uploadFiles(fileInput, [file])

    await wait(() => {
      expect(props.createSubmissionDraft).toHaveBeenCalledWith({
        variables: {
          id: '1',
          attempt: 1,
          fileIds: ['1']
        }
      })
    })
  })

  it('renders a button to remove the file', async () => {
    const props = await makeProps({
      Submission: () => SubmissionMocks.draftWithAttachment,
      File: () => ({_id: '1', displayName: 'foobarbaz'})
    })

    const {container, getByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
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
      Submission: () => ({
        submissionDraft: {attachments: attachmentOverrides}
      })
    })

    const {container, getByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )

    attachmentOverrides.forEach(attachment => {
      const button = container.querySelector(`button[id="${attachment._id}"]`)
      expect(button).toContainElement(getByText(`Remove ${attachment.displayName}`))
    })
  })

  it('ellides filenames for files greater than 21 characters', async () => {
    const props = await makeProps({
      Submission: () => SubmissionMocks.draftWithAttachment,
      File: () => ({displayName: 'c'.repeat(22)})
    })

    const {getByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )

    expect(getByText(/^c+\.{3}c+$/)).toBeInTheDocument()
  })

  it('does not ellide filenames for files less than or equal to 21 characters', async () => {
    const filename = 'c'.repeat(21)
    const props = await makeProps({
      Submission: () => SubmissionMocks.draftWithAttachment,
      File: () => ({displayName: filename})
    })

    const {getAllByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )

    expect(getAllByText(filename)[0]).toBeInTheDocument()
  })

  it('displays the more options button in the upload box', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByTestId, getByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toContainElement(getByText('More Options'))
  })

  it('displays allowed extensions in the upload box', async () => {
    const props = await makeProps({
      Assignment: () => ({allowedExtensions: ['jpg, png']})
    })
    const {getByTestId, getByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toContainElement(getByText('File permitted: JPG, PNG'))
  })

  it('does not display any allowed extensions if there are none', async () => {
    const props = await makeProps()
    const {getByTestId, queryByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).not.toContainElement(queryByText('File permitted'))
  })

  it('renders an error when adding a file that is not an allowed extension', async () => {
    const props = await makeProps({
      Assignment: () => ({allowedExtensions: ['jpg']})
    })
    const {container, getByText, queryByTestId} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file])

    expect(getByText('Invalid file type')).toBeInTheDocument()
    expect(queryByTestId('non-empty-upload')).toBeNull()
  })

  it('does not render an error when adding a file that is an allowed extension', async () => {
    const props = await makeProps({
      Assignment: () => ({allowedExtensions: ['jpg']})
    })
    const {container, queryByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})

    uploadFiles(fileInput, [file])

    expect(queryByText('Invalid file type')).toBeNull()
  })

  it('does not render a submit button when a file has not been uploaded', async () => {
    const props = await makeProps()
    const {getByTestId, queryByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).not.toContainElement(queryByText('Submit'))
  })

  it('renders a submit button when a file has been uploaded', async () => {
    const props = await makeProps({
      Submission: () => SubmissionMocks.draftWithAttachment
    })
    const {getByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )

    expect(getByText('Submit')).toBeInTheDocument()
  })

  it('renders a loading indicator when a file is being uploaded', async () => {
    const props = await makeProps()
    const {container, getByTestId, getByText, queryByText} = render(
      <MockedProvider>
        <FileUpload {...props} />
      </MockedProvider>
    )

    const uploadedFilesRender = getByTestId('upload-pane')
    expect(uploadedFilesRender).not.toContainElement(queryByText('Loading'))

    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})

    uploadFiles(fileInput, [file])

    const uploadingFilesRender = getByTestId('upload-pane')
    expect(uploadingFilesRender).toContainElement(getByText('Loading'))
  })
})
