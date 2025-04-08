/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import {render, fireEvent, act} from '@testing-library/react'
import * as mediaUtils from '../../util/mediaUtils'
import Attachment from '../Attachment'

jest.mock('../../util/mediaUtils', () => ({
  hasMediaFeature: jest.fn().mockReturnValue(true),
  getUserMedia: jest.fn(() => Promise.resolve())
}))

jest.useFakeTimers()

describe('Attachment', () => {
  const getProps = (override = {}) => {
    return {
      index: 0,
      setBlob: jest.fn(),
      validFileTypes: [],
      getShouldShowFileRequiredError: jest.fn(),
      setShouldShowFileRequiredError: jest.fn(),
      ...override,
    }
  }

  it('only displays LegacyFileUpload when hasMediaFeature is false', () => {
    mediaUtils.hasMediaFeature.mockImplementation(() => false)
    const {queryByText, queryByTestId} = render(<Attachment {...getProps()} />)
    expect(queryByText('Use Webcam')).not.toBeInTheDocument()
    expect(queryByTestId('file-upload-0')).toBeInTheDocument()
    // Restore the original mock behavior after the test
    mediaUtils.hasMediaFeature.mockImplementation(() => true)
  })

  it('shows both upload options', () => {
    const {getByText} = render(<Attachment {...getProps()} />)
    expect(getByText('Choose a file to upload')).toBeInTheDocument()
    expect(getByText('Use Webcam')).toBeInTheDocument()
  })

  test('displays a tag for a file when uploading a file', () => {
    const {getByTestId} = render(<Attachment {...getProps()} />)
    const fileInput = getByTestId('file-upload-0')
    const file = new File(['file content'], 'example.txt', { type: 'text/plain' })
    fireEvent.change(fileInput, { target: { files: [file] } })
    expect(getByTestId('submission_file_tag_0')).toBeInTheDocument()
  })

  test('removes uploaded file when clearing the input', async () => {
    const {getByTestId, queryByTestId} = render(<Attachment {...getProps()} />)
    const fileInput = getByTestId('file-upload-0')
    const file = new File(['file content'], 'example.txt', { type: 'text/plain' })

    fireEvent.change(fileInput, { target: { files: [file] } })
    expect(getByTestId('submission_file_tag_0')).toBeInTheDocument()

    fireEvent.change(fileInput, { target: { files: [] } })
    expect(queryByTestId('submission_file_tag_0')).not.toBeInTheDocument()
  })

  test('displays an error if an empty file is uploaded', () => {
    const {getByTestId, getByText} = render(<Attachment {...getProps()} />)
    const fileInput = getByTestId('file-upload-0')
    const emptyFile = new File([], 'empty.txt', { type: 'text/plain' })
    fireEvent.change(fileInput, { target: { files: [emptyFile] } })
    expect(getByText('Attached files must be greater than 0 bytes.')).toBeInTheDocument()
  })

  test('displays an error if an invalid file is uploaded', () => {
    const {getByTestId, getByText} = render(<Attachment {...getProps({validFileTypes: ['pdf']})} />)
    const fileInput = getByTestId('file-upload-0')
    const file = new File(['file content'], 'example.txt', { type: 'text/plain' })
    fireEvent.change(fileInput, { target: { files: [file] } })
    expect(getByText('This file type is not allowed. Accepted file types are: pdf.')).toBeInTheDocument()
  })

  test('displays an error on focus if getShouldShowFileRequiredError returns true', () => {
    const {getByTestId, getByText} = render(<Attachment {...getProps({getShouldShowFileRequiredError: jest.fn().mockReturnValue(true)})} />)
    const fileInput = getByTestId('file-upload-0')
    fireEvent.focus(fileInput)
    expect(getByText('A file is required to make a submission.')).toBeInTheDocument()
  })

  it('displays WebcamModal when click on Use Webcam', async () => {
    const {getByLabelText, getByText} = render(<Attachment {...getProps()} />)
    fireEvent.click(getByText('Use Webcam'))
    expect(getByLabelText('Webcam')).toBeInTheDocument()
    await act(() => mediaUtils.getUserMedia())
  })

  it('displays picture when user take and select picture and calls setBlob with blob', async () => {
    const mockedBlob = jest.mock()
    jest
      .spyOn(HTMLCanvasElement.prototype, 'toBlob')
      .mockImplementationOnce(callback => callback(mockedBlob))
    const props = getProps()
    const {getByText, getByAltText} = render(<Attachment {...props} />)
    fireEvent.click(getByText('Use Webcam'))
    await act(() => mediaUtils.getUserMedia())
    fireEvent.click(getByText('Take Photo'))
    fireEvent.click(getByText('Use This Photo'))
    expect(getByAltText('Captured Image')).toBeInTheDocument()
    expect(props.setBlob).toHaveBeenCalledWith(mockedBlob)
  })

  it('does not render webcam button when png is not a valid file type', () => {
    const {queryByLabelText} = render(<Attachment {...getProps({validFileTypes: ['pdf', 'txt']})} />)
    expect(queryByLabelText('Use Webcam')).not.toBeInTheDocument()
  })
})
