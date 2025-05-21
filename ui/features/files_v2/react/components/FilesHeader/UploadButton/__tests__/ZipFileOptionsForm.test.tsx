/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import ZipFileOptionsForm from '../ZipFileOptionsForm'

// Mock jQuery for flashError function
jest.mock('jquery', () => {
  return {
    __esModule: true,
    default: {
      flashError: jest.fn(),
    },
  }
})

const zipFile = new File(['foo'], 'foo.zip', {type: 'application/zip'})

const defaultProps = {
  open: true,
  onClose: jest.fn(),
  fileOptions: {
    name: 'foo.zip',
    file: zipFile,
    cannotOverwrite: false,
    expandZip: false,
  },
  onZipOptionsResolved: jest.fn(),
}
const renderComponent = (props = {}) => render(<ZipFileOptionsForm {...defaultProps} {...props} />)

describe('ZipFileOptionsForm', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    // Reset all mocks before each test
    jest.resetModules()
  })

  it('renders header', () => {
    renderComponent()
    expect(screen.getByText('Zip file options')).toBeInTheDocument()
  })

  it('renders body', () => {
    renderComponent()
    expect(
      screen.getByText(
        'Would you like to expand the contents of "foo.zip" into the current folder, or upload the zip file as is?',
      ),
    ).toBeInTheDocument()
  })

  it('renders footer', () => {
    renderComponent()
    expect(screen.getByTestId('zip-expand-button')).toBeInTheDocument()
    expect(screen.getByTestId('zip-upload-button')).toBeInTheDocument()
  })

  describe('calls onZipOptionsResolved', () => {
    it('when expands', async () => {
      const user = userEvent.setup()
      renderComponent()
      await user.click(screen.getByTestId('zip-expand-button'))

      expect(defaultProps.onZipOptionsResolved).toHaveBeenCalledWith({
        expandZip: true,
        file: zipFile,
      })
    })

    it('when uploads', async () => {
      const user = userEvent.setup()
      renderComponent()
      await user.click(screen.getByTestId('zip-upload-button'))

      expect(defaultProps.onZipOptionsResolved).toHaveBeenCalledWith({
        expandZip: false,
        file: zipFile,
      })
    })
  })
})
