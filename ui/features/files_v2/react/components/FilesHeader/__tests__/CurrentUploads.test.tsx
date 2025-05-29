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
import {render, screen, waitFor, act} from '@testing-library/react'
import {queryClient} from '@canvas/query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import CurrentUploads from '../CurrentUploads'
import FileUploader from '@canvas/files/react/modules/FileUploader'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'
import {FileManagementProvider} from '../../../contexts/FileManagementContext'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'

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

const error = {response: {status: 409}}
const nonDuplicateError = {response: {status: 500}}

const renderComponent = () => {
  return render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <MockedQueryClientProvider client={queryClient}>
        <CurrentUploads />
      </MockedQueryClientProvider>
    </FileManagementProvider>,
  )
}

describe('CurrentUploads', () => {
  it('renders', () => {
    renderComponent()
    expect(screen.getByTestId('current-uploads')).toBeInTheDocument()
  })

  it("doesn't render", () => {
    // Return empty array for this test
    mockGetAllUploaders.mockReturnValue([])
    renderComponent()
    expect(screen.queryByTestId('current-uploads')).not.toBeInTheDocument()
  })

  it('catches file conflicts and shows rename form', () => {
    // Return uploader with error for this test
    mockGetAllUploaders.mockReturnValue([makeUploader('foo.txt', error)])
    renderComponent()
    expect(screen.getByText('File failed to upload. Please try again.')).toBeInTheDocument()
    expect(screen.getByTestId('rename-replace-button')).toBeInTheDocument()
    expect(screen.getByTestId('rename-skip-button')).toBeInTheDocument()
    expect(screen.getByTestId('rename-change-button')).toBeInTheDocument()
  })

  // The mockGetAllUploaders implementations aren't 100% accurate but are close enough
  // The beginning and end of the process is the most important, so some intermediate updates are left out
  describe('quota and files queries', () => {
    let changeCallback: () => void

    // simulates UploadQueue.onChange
    // which triggers handleUploadQueueChange
    const executeCallbackTimes = (times: number) => {
      for (let i = 0; i < times; i++) {
        act(() => changeCallback())
      }
    }

    beforeEach(() => {
      changeCallback = () => {}
      jest.spyOn(queryClient, 'refetchQueries')

      mockAddChangeListener.mockImplementation((callback: () => void) => {
        changeCallback = callback
      })
    })

    it('are refetched once when sole upload completes', async () => {
      mockGetAllUploaders
        .mockImplementationOnce(() => [makeUploader('foo.txt')])
        // progress 0 -> 1
        .mockImplementationOnce(() => [makeUploader('foo.txt')])
        .mockImplementation(() => [])

      renderComponent()
      executeCallbackTimes(3)

      await waitFor(() => {
        expect(queryClient.refetchQueries).toHaveBeenCalledWith({
          queryKey: ['quota'],
          type: 'active',
        })
        expect(queryClient.refetchQueries).toHaveBeenCalledWith({
          queryKey: ['files'],
          type: 'active',
        })
      })
    })

    it('are refeched once when multiple uploads complete', async () => {
      mockGetAllUploaders
        .mockImplementationOnce(() => [makeUploader('foo.txt'), makeUploader('bar.txt')])
        .mockImplementationOnce(() => [makeUploader('bar.txt')])
        .mockImplementation(() => [])

      renderComponent()
      executeCallbackTimes(3)

      await waitFor(() => {
        expect(queryClient.refetchQueries).toHaveBeenCalledTimes(2)
      })
    })

    it('are refetched once when sole upload fails', async () => {
      mockGetAllUploaders
        .mockImplementationOnce(() => [makeUploader('foo.txt')])
        // progress 0 -> 1
        .mockImplementationOnce(() => [makeUploader('foo.txt')])
        .mockImplementation(() => [makeUploader('foo.txt', nonDuplicateError)])

      renderComponent()
      executeCallbackTimes(3)

      await waitFor(() => {
        expect(queryClient.refetchQueries).toHaveBeenCalledTimes(2)
      })
    })

    it('are refetched once when all uploads fail', async () => {
      mockGetAllUploaders
        .mockImplementationOnce(() => [makeUploader('foo.txt'), makeUploader('bar.txt')])
        .mockImplementationOnce(() => [
          makeUploader('foo.txt', nonDuplicateError),
          makeUploader('bar.txt'),
        ])
        .mockImplementation(() => [
          makeUploader('foo.txt', nonDuplicateError),
          makeUploader('bar.txt', nonDuplicateError),
        ])

      renderComponent()
      executeCallbackTimes(3)

      await waitFor(() => {
        expect(queryClient.refetchQueries).toHaveBeenCalledTimes(2)
      })
    })

    it('are not refetched again when failed upload is removed', async () => {
      mockGetAllUploaders
        .mockImplementationOnce(() => [makeUploader('foo.txt')])
        .mockImplementationOnce(() => [makeUploader('foo.txt', nonDuplicateError)])
        .mockImplementation(() => [])

      renderComponent()
      executeCallbackTimes(3)

      await waitFor(() => {
        expect(queryClient.refetchQueries).toHaveBeenCalledTimes(2)
      })
    })

    it('are refetched once when last upload errors', async () => {
      mockGetAllUploaders
        .mockImplementationOnce(() => [makeUploader('foo.txt'), makeUploader('bar.txt')])
        .mockImplementationOnce(() => [makeUploader('bar.txt')])
        .mockImplementationOnce(() => [makeUploader('bar.txt', nonDuplicateError)])

      renderComponent()
      executeCallbackTimes(3)

      await waitFor(() => {
        expect(queryClient.refetchQueries).toHaveBeenCalledTimes(2)
      })
    })

    it('are refetched once when first upload errors', async () => {
      mockGetAllUploaders
        .mockImplementationOnce(() => [makeUploader('foo.txt'), makeUploader('bar.txt')])
        .mockImplementationOnce(() => [
          makeUploader('foo.txt', nonDuplicateError),
          makeUploader('bar.txt'),
        ])
        .mockImplementationOnce(() => [makeUploader('foo.txt', nonDuplicateError)])

      renderComponent()
      executeCallbackTimes(3)

      await waitFor(() => {
        expect(queryClient.refetchQueries).toHaveBeenCalledTimes(2)
      })
    })

    it('are refetched once when resolving name conflicts', async () => {
      mockGetAllUploaders
        .mockImplementationOnce(() => [makeUploader('foo.txt'), makeUploader('bar.txt')])
        .mockImplementationOnce(() => [makeUploader('foo.txt', error)])
        .mockImplementationOnce(() => [
          makeUploader('foo.txt', error),
          makeUploader('bar.txt', error),
        ])
        .mockImplementationOnce(() => [makeUploader('bar.txt', error)])
        .mockImplementation(() => [])

      renderComponent()
      executeCallbackTimes(5)

      await waitFor(() => {
        expect(queryClient.refetchQueries).toHaveBeenCalledTimes(2)
      })
    })

    it('are refetched once when dealing with mixed errors', async () => {
      mockGetAllUploaders
        .mockImplementationOnce(() => [makeUploader('foo.txt'), makeUploader('bar.txt')])
        .mockImplementationOnce(() => [makeUploader('foo.txt', error)])
        .mockImplementationOnce(() => [
          makeUploader('foo.txt', error),
          makeUploader('bar.txt', nonDuplicateError),
        ])
        .mockImplementationOnce(() => [makeUploader('bar.txt', error)])
        .mockImplementation(() => [])

      renderComponent()
      executeCallbackTimes(5)

      await waitFor(() => {
        expect(queryClient.refetchQueries).toHaveBeenCalledTimes(2)
      })
    })
  })
})
