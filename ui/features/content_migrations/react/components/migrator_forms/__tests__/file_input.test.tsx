/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, screen, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import MigrationFileInput from '../file_input'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn().mockReturnValue(jest.fn()),
}))

const onChange = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(<MigrationFileInput onChange={onChange} {...overrideProps} />)

describe('MigrationFileInput', () => {
  beforeAll(() => (window.ENV.UPLOAD_LIMIT = 1024))

  afterEach(() => jest.clearAllMocks())

  it('renders hidden input', () => {
    renderComponent()

    expect(screen.getByTestId('migrationFileUpload')).toBeInTheDocument()
  })

  it('renders button input', () => {
    renderComponent()

    expect(screen.getByText('Choose File')).toBeInTheDocument()
  })

  it('renders text if no file is chosen', () => {
    renderComponent()

    expect(screen.getByText('No file chosen')).toBeInTheDocument()
  })

  it('renders file name if file is chosen', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)

    expect(screen.getByText('my_file.zip')).toBeInTheDocument()
  })

  it('renders file size validation error when large file is chosen', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    Object.defineProperty(file, 'size', {value: 1024 + 1})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)

    expect(screen.getByText('Your migration can not exceed 1.0 KB')).toBeInTheDocument()
  })

  it('calls onChange with file', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)

    expect(onChange).toHaveBeenCalledWith(expect.any(File))
  })

  it('calls onChange with null and displays proper error message when wrong file type provided', async () => {
    renderComponent()

    const wrongFile = new File(['blah, blah, blah'], 'my_file.jpg', {type: 'image/jpeg'})
    const input = screen.getByTestId('migrationFileUpload')
    fireEvent.change(input, {
      target: {
        files: [wrongFile],
      },
    })
    expect(onChange).toHaveBeenCalledWith(null)
    expect(screen.getByText('Invalid file type')).toBeInTheDocument()
  })

  it('renders the progressbar with the passed progress', async () => {
    renderComponent({isSubmitting: true, fileUploadProgress: 29})
    expect(screen.getByText('29%')).toBeInTheDocument()
  })

  it('disable input while uploading', async () => {
    renderComponent({isSubmitting: true})
    expect(screen.getByTestId('migrationFileUpload')).toBeDisabled()
  })

  describe('externalFormMessage', () => {
    describe('when externalFormMessage is provided', () => {
      const text = 'External Form Message'
      const externalFormMessage = {text, type: 'hint'}

      it('renders the externalFormMessage', () => {
        renderComponent({externalFormMessage})
        expect(screen.getByText(text)).toBeInTheDocument()
      })
    })

    describe('when externalFormMessage is not provided', () => {
      it('renders the default message', () => {
        renderComponent()
        expect(screen.getByText('No file chosen')).toBeInTheDocument()
      })
    })
  })
})
