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
import {DEFAULT_ICON} from '../../../../shared/helpers/mimeClassIconHelper'
import FileUpload from '../FileUpload'
import {fireEvent, render} from 'react-testing-library'
import {
  mockAssignment,
  mockSubmission,
  mockSubmissionDraft,
  singleAttachment
} from '../../test-utils'
import {MockedProvider} from 'react-apollo/test-utils'
import React from 'react'

let mockedSubmission

beforeAll(() => {
  $('body').append('<div role="alert" id="flash_screenreader_holder" />')
})

beforeEach(() => {
  mockedSubmission = mockSubmission({
    submissionDraft: mockSubmissionDraft()
  })
  window.URL.createObjectURL = jest.fn().mockReturnValue('perry_preview')
})

describe('FileUpload', () => {
  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files
      }
    })
  }

  it('renders the empty upload tab by default', async () => {
    const {container, getByTestId, getByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockSubmission()} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('empty-upload')

    expect(emptyRender).toContainElement(getByText('Upload File'))
    expect(emptyRender).toContainElement(
      container.querySelector(`svg[name=${DEFAULT_ICON.type.displayName}]`)
    )
  })

  it('renders the submission draft files if there are any', async () => {
    const {getByTestId, getByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockedSubmission} />
      </MockedProvider>
    )
    const uploadRender = getByTestId('non-empty-upload')

    mockedSubmission.submissionDraft.attachments.forEach(function(attachment) {
      expect(uploadRender).toContainElement(getByText(attachment.displayName))
    })
  })

  it('renders in an img tag if the file type is an image', async () => {
    const mockedAttachment = singleAttachment({
      mimeClass: 'image'
    })
    mockedSubmission.submissionDraft.attachments = [mockedAttachment]
    const {container, getByTestId} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockedSubmission} />
      </MockedProvider>
    )
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(
      container.querySelector(`img[alt="${mockedAttachment.displayName} preview"]`)
    )
  })

  it('renders an icon if a non-image file is uploaded', async () => {
    const {container, getByTestId} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockedSubmission} />
      </MockedProvider>
    )
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(container.querySelector('svg[name="IconPdf"]'))
    mockedSubmission.submissionDraft.attachments.forEach(function(attachment) {
      expect(container.querySelector(`img[alt="${attachment.displayName} preview"]`)).toBeNull()
    })
  })

  it('allows uploading multiple files at a time', async () => {
    const {container, getByTestId, getByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockSubmission()} />
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
    const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file, file2])

    const filesRender = getByTestId('non-empty-upload')

    expect(filesRender).toContainElement(getByText('Loading'))
  })

  it('renders a button to remove the file', async () => {
    const {container, getByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockedSubmission} />
      </MockedProvider>
    )
    const button = container.querySelector(
      `button[id="${mockedSubmission.submissionDraft.attachments[0]._id}"]`
    )

    mockedSubmission.submissionDraft.attachments.forEach(function(attachment) {
      expect(button).toContainElement(getByText(`Remove ${attachment.displayName}`))
    })
    expect(button).toContainElement(container.querySelector('svg[name="IconTrash"]'))
  })

  it('renders a remove button for each uploaded file', async () => {
    const {container, getByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockedSubmission} />
      </MockedProvider>
    )

    mockedSubmission.submissionDraft.attachments.forEach(function(attachment) {
      const button = container.querySelector(`button[id="${attachment._id}"]`)
      expect(button).toContainElement(getByText(`Remove ${attachment.displayName}`))
    })
  })

  it('ellides filenames for files greater than 21 characters', async () => {
    mockedSubmission.submissionDraft.attachments[0].displayName = 'c'.repeat(22)
    const {getByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockedSubmission} />
      </MockedProvider>
    )

    expect(getByText(/^c+\.{3}c+$/)).toBeInTheDocument()
  })

  it('does not ellide filenames for files less than or equal to 21 characters', async () => {
    const filename = 'c'.repeat(21)
    mockedSubmission.submissionDraft.attachments[0].displayName = filename
    const {getByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockedSubmission} />
      </MockedProvider>
    )

    expect(getByText(filename)).toBeInTheDocument()
  })

  it('displays allowed extensions in the upload box', async () => {
    const mockedAssignment = mockAssignment({allowedExtensions: ['jpg, png']})
    const {getByTestId, getByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockedAssignment} submission={mockSubmission()} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('empty-upload')

    expect(emptyRender).toContainElement(getByText('File permitted: JPG, PNG'))
  })

  it('does not display any allowed extensions if there are none', async () => {
    const {getByTestId, queryByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockSubmission()} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('empty-upload')

    expect(emptyRender).not.toContainElement(queryByText('File permitted'))
  })

  it('renders an error when adding a file that is not an allowed extension', async () => {
    const mockedAssignment = mockAssignment({allowedExtensions: ['jpg']})
    const {container, getByText, queryByTestId} = render(
      <MockedProvider>
        <FileUpload assignment={mockedAssignment} submission={mockSubmission()} />
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file])

    expect(getByText('Invalid file type')).toBeInTheDocument()
    expect(queryByTestId('non-empty-upload')).toBeNull()
  })

  it('does not render an error when adding a file that is an allowed extension', async () => {
    const mockedAssignment = mockAssignment({allowedExtensions: ['jpg']})
    const {container, queryByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockedAssignment} submission={mockSubmission()} />
      </MockedProvider>
    )
    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})

    uploadFiles(fileInput, [file])

    expect(queryByText('Invalid file type')).toBeNull()
  })

  it('does not render a submit button when a file has not been uploaded', async () => {
    const {getByTestId, queryByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockSubmission()} />
      </MockedProvider>
    )
    const emptyRender = getByTestId('empty-upload')

    expect(emptyRender).not.toContainElement(queryByText('Submit'))
  })

  it('renders a submit button when a file has been uploaded', async () => {
    const {getByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockedSubmission} />
      </MockedProvider>
    )

    expect(getByText('Submit')).toBeInTheDocument()
  })

  it('renders a loading indicator when a file is being uploaded', async () => {
    const {container, getByTestId, getByText, queryByText} = render(
      <MockedProvider>
        <FileUpload assignment={mockAssignment()} submission={mockSubmission()} />
      </MockedProvider>
    )

    const emptyRender = getByTestId('empty-upload')
    expect(emptyRender).not.toContainElement(queryByText('Loading'))

    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})

    uploadFiles(fileInput, [file])

    const filesRender = getByTestId('non-empty-upload')
    expect(filesRender).toContainElement(getByText('Loading'))
  })
})
