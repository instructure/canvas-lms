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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CanvasCartridgeImporter from '../canvas_cartridge'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const setPreAttachmentMock = jest.fn()

jest.mock('@canvas/alerts/react/FlashAlert')

const renderComponent = (overrideProps?: any) =>
  render(
    <CanvasCartridgeImporter onSelectPreAttachmentFile={setPreAttachmentMock} {...overrideProps} />
  )

describe('CanvasCartridgeImporter', () => {
  beforeAll(() => (window.ENV.UPLOAD_LIMIT = 1024))

  afterEach(() => jest.clearAllMocks())

  it('renders hidden input', () => {
    renderComponent()
    expect(screen.getByTestId('migrationFileUpload')).toBeInTheDocument()
  })

  it('renders button input', () => {
    renderComponent()
    expect(screen.getByRole('button', {name: 'Choose File'})).toBeInTheDocument()
  })

  it('renders text if no file is chosen', () => {
    renderComponent()
    expect(screen.getByText('No file chosen')).toBeInTheDocument()
  })

  it('renders file name if file is chosen', () => {
    renderComponent()
    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    const input = screen.getByTestId('migrationFileUpload')
    userEvent.upload(input, file)
    expect(screen.getByText('my_file.zip')).toBeInTheDocument()
  })

  it('does not render file name when large file is chosen', async () => {
    renderComponent()
    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    Object.defineProperty(file, 'size', {value: 1024 + 1})
    const input = screen.getByTestId('migrationFileUpload')
    userEvent.upload(input, file)
    expect(screen.getByText('No file chosen')).toBeInTheDocument()
  })

  it('calls setPreAttachment when file is chosen', () => {
    renderComponent()
    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    const input = screen.getByTestId('migrationFileUpload')
    userEvent.upload(input, file)
    expect(setPreAttachmentMock).toHaveBeenCalledWith(file)
  })

  it('does not call setPreAttachment when large file is chosen', () => {
    renderComponent()
    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    Object.defineProperty(file, 'size', {value: 1024 + 1})
    const input = screen.getByTestId('migrationFileUpload')
    userEvent.upload(input, file)
    expect(setPreAttachmentMock).toHaveBeenCalledWith(null)
  })

  it('renders alert when large file is chosen', async () => {
    renderComponent()
    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    Object.defineProperty(file, 'size', {value: 1024 + 1})
    const input = screen.getByTestId('migrationFileUpload')
    userEvent.upload(input, file)
    expect(showFlashError).toHaveBeenCalledWith('Your migration can not exceed 1.0 KB')
  })
})
