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

import ContentUploadTab from '../ContentUploadTab'
import {DEFAULT_ICON} from '../../../../shared/helpers/mimeClassIconHelper'
import {fireEvent, render} from 'react-testing-library'
import {mockAssignment} from '../../test-utils'
import React from 'react'

beforeEach(() => {
  window.URL.createObjectURL = jest.fn()
})

describe('ContentUploadTab', () => {
  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files
      }
    })
  }

  it('renders the empty upload tab by default', async () => {
    const {container, getByTestId, getByText} = render(
      <ContentUploadTab assignment={mockAssignment()} />
    )
    const emptyRender = getByTestId('empty-upload')

    expect(emptyRender).toContainElement(getByText('Upload File'))
    expect(emptyRender).toContainElement(
      container.querySelector(`svg[name=${DEFAULT_ICON.type.displayName}]`)
    )
  })

  it('renders the uploaded files if there are any', async () => {
    const {container, getByTestId, getByText} = render(
      <ContentUploadTab assignment={mockAssignment()} />
    )
    const emptyRender = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'awesome-test-image.png', {type: 'image/png'})

    uploadFiles(emptyRender, [file])
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(getByText('awesome-test-image.png'))
  })

  it('renders in an img tag if an image is uploaded', async () => {
    const {container, getByTestId} = render(<ContentUploadTab assignment={mockAssignment()} />)
    const emptyRender = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'awesome-test-image.png', {type: 'image/png'})

    uploadFiles(emptyRender, [file])
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(
      container.querySelector('img[alt="awesome-test-image.png preview"]')
    )
  })

  it('renders an icon if a non-image file is uploaded', async () => {
    const {container, getByTestId} = render(<ContentUploadTab assignment={mockAssignment()} />)
    const emptyRender = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'awesome-test-file.pdf', {type: 'application/pdf'})

    uploadFiles(emptyRender, [file])
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(container.querySelector('svg[name="IconPdf"]'))
    expect(container.querySelector('img[alt="awesome-test-file.pdf preview"]')).toBeNull()
  })

  it('allows uploading multiple files at a time', async () => {
    const {container, getByTestId, getByText} = render(
      <ContentUploadTab assignment={mockAssignment()} />
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
    const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file, file2])
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(getByText('file1.pdf'))
    expect(uploadRender).toContainElement(getByText('file2.pdf'))
  })

  it('concatenates separate file additions together', async () => {
    const {container, getByTestId, getByText} = render(
      <ContentUploadTab assignment={mockAssignment()} />
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
    const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file])
    uploadFiles(fileInput, [file2])
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(getByText('file1.pdf'))
    expect(uploadRender).toContainElement(getByText('file2.pdf'))
  })

  it('renders a button to remove the file', async () => {
    const {container, getByText} = render(<ContentUploadTab assignment={mockAssignment()} />)
    const emptyRender = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'awesome-test-file.pdf', {type: 'application/pdf'})

    uploadFiles(emptyRender, [file])
    const button = container.querySelector('button')

    expect(button).toContainElement(getByText('Remove awesome-test-file.pdf'))
    expect(button).toContainElement(container.querySelector('svg[name="IconTrash"]'))
  })

  it('removes the correct file when the Remove button is clicked', async () => {
    const {container, getByText, queryByText} = render(
      <ContentUploadTab assignment={mockAssignment()} />
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
    const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file, file2])
    const button = container.querySelector('button[id="1"]')
    expect(button).toContainElement(getByText('Remove file1.pdf'))
    fireEvent.click(button)

    expect(queryByText('Remove file1.pdf')).toBeNull()
    expect(getByText('Remove file2.pdf')).toBeInTheDocument()
  })

  it('ellides filenames for files greater than 21 characters', async () => {
    const {container, getByText} = render(<ContentUploadTab assignment={mockAssignment()} />)
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'c'.repeat(22), {type: 'application/pdf'})

    uploadFiles(fileInput, [file])

    expect(getByText(/^c+\.{3}c+$/)).toBeInTheDocument()
  })

  it('does not ellide filenames for files less than or equal to 21 characters', async () => {
    const filename = 'c'.repeat(21)
    const {container, getByText} = render(<ContentUploadTab assignment={mockAssignment()} />)
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], filename, {type: 'application/pdf'})

    uploadFiles(fileInput, [file])

    expect(getByText(filename)).toBeInTheDocument()
  })

  it('displays allowed extensions in the upload box', async () => {
    const mockedAssignment = mockAssignment({allowedExtensions: ['jpg, png']})
    const {getByTestId, getByText} = render(<ContentUploadTab assignment={mockedAssignment} />)
    const emptyRender = getByTestId('empty-upload')

    expect(emptyRender).toContainElement(getByText('File permitted: JPG, PNG'))
  })

  it('does not display any allowed extensions if there are none', async () => {
    const {getByTestId, queryByText} = render(<ContentUploadTab assignment={mockAssignment()} />)
    const emptyRender = getByTestId('empty-upload')

    expect(emptyRender).not.toContainElement(queryByText('File permitted'))
  })

  it('renders an error when adding a file that is not an allowed extension', async () => {
    const mockedAssignment = mockAssignment({allowedExtensions: ['jpg']})
    const {container, getByText, queryByTestId} = render(
      <ContentUploadTab assignment={mockedAssignment} />
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})

    uploadFiles(fileInput, [file])

    expect(getByText('Invalid file type')).toBeInTheDocument()
    expect(queryByTestId('non-empty-upload')).toBeNull()
  })

  it('does not render an error when adding a file that is an allowed extension', async () => {
    const mockedAssignment = mockAssignment({allowedExtensions: ['jpg']})
    const {container, getByTestId, getByText, queryByText} = render(
      <ContentUploadTab assignment={mockedAssignment} />
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})

    uploadFiles(fileInput, [file])
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(getByText('file1.jpg'))
    expect(queryByText('Invalid file type')).toBeNull()
  })

  it('renders a submit button only when a file has been uploaded', async () => {
    const {container, getByText, queryByText} = render(
      <ContentUploadTab assignment={mockAssignment()} />
    )

    expect(queryByText('Submit')).toBeNull()

    const fileInput = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    expect(getByText('Submit')).toBeInTheDocument()

    const button = container.querySelector('button[id="1"]')
    expect(button).toContainElement(getByText('Remove file1.jpg'))
    fireEvent.click(button)

    expect(queryByText('Submit')).toBeNull()
  })
})
