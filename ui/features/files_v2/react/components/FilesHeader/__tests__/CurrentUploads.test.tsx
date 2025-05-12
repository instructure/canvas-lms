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
import CurrentUploads from '../CurrentUploads'
import FileUploader from '@canvas/files/react/modules/FileUploader'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'

function makeUploader(name: string, error?: object) {
  const uploader = new FileUploader({file: new File(['foo'], name, {type: 'text/plain'})})
  uploader.error = error
  return uploader
}

// Mock the UploadQueue module
jest.mock('@canvas/files/react/modules/UploadQueue')

// Define mock implementation types
const mockAddChangeListener = jest.fn()
const mockRemoveChangeListener = jest.fn()
const mockGetAllUploaders = jest.fn()

// Setup mock implementations
beforeEach(() => {
  // Reset all mocks
  jest.resetAllMocks()

  // Setup default mock implementations
  mockAddChangeListener.mockImplementation((callback: () => void) => {
    // Call the callback immediately to trigger state update
    callback()
  })

  // Assign mocks to the module
  UploadQueue.addChangeListener = mockAddChangeListener
  UploadQueue.removeChangeListener = mockRemoveChangeListener
  UploadQueue.getAllUploaders = mockGetAllUploaders

  // Default to returning one uploader
  mockGetAllUploaders.mockReturnValue([makeUploader('foo.txt')])
})

describe('CurrentUploads', () => {
  it('renders', () => {
    render(<CurrentUploads />)
    expect(screen.getByTestId('current-uploads')).toBeInTheDocument()
  })

  it("doesn't render", () => {
    // Return empty array for this test
    mockGetAllUploaders.mockReturnValue([])
    render(<CurrentUploads />)
    expect(screen.queryByTestId('current-uploads')).not.toBeInTheDocument()
  })

  it('catches file conflicts and shows rename form', () => {
    const error = {response: {status: 409}}
    // Return uploader with error for this test
    mockGetAllUploaders.mockReturnValue([makeUploader('foo.txt', error)])
    render(<CurrentUploads />)
    expect(screen.getByText('File failed to upload. Please try again.')).toBeInTheDocument()
    expect(screen.getByTestId('rename-replace-button')).toBeInTheDocument()
    expect(screen.getByTestId('rename-skip-button')).toBeInTheDocument()
    expect(screen.getByTestId('rename-change-button')).toBeInTheDocument()
  })
})
