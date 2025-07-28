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

import {
  addDownloadListener,
  removeDownloadListener,
  downloadZip,
  performRequest,
} from '../downloadUtils'
import {waitFor} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {FAKE_FILES, FAKE_FOLDERS} from '../../fixtures/fakeData'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn(() => jest.fn()),
}))
jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

describe('addDownloadListener', () => {
  it('adds event listener for custom event', () => {
    const mockListener = jest.fn()
    addDownloadListener(mockListener)
    window.dispatchEvent(new CustomEvent('download_utils_event'))
    expect(mockListener).toHaveBeenCalled()
    removeDownloadListener(mockListener)
  })
})

describe('removeDownloadListener', () => {
  it('removes event listener for custom event', () => {
    const mockListener = jest.fn()
    addDownloadListener(mockListener)
    removeDownloadListener(mockListener)
    window.dispatchEvent(new CustomEvent('download_utils_event'))
    expect(mockListener).not.toHaveBeenCalled()
  })
})

describe('downloadZip', () => {
  it('dispatches custom event with items detail', () => {
    const items = new Set(['file1', 'file2'])
    const mockListener = jest.fn()
    addDownloadListener(mockListener)
    downloadZip(items)
    expect(mockListener).toHaveBeenCalledWith(expect.objectContaining({detail: {items}}))
    removeDownloadListener(mockListener)
  })
})

describe('performRequest', () => {
  const mockItems = new Set(['folder-46', 'file-178'])
  const mockContextType = 'courses'
  const mockContextId = '1'
  const mockOnProgress = jest.fn()
  const mockOnComplete = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('makes API call and handles progress and completion', async () => {
    const mockResponse = {
      json: {
        workflow_state: 'exported',
        progress_url: '/progress',
        attachment: {url: 'http://example.com/file.zip'},
      },
    }
    const mockPoolResponse = {
      json: {
        workflow_state: 'completed',
        completion: 100,
        context_id: '1',
      },
    }
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce(mockResponse)
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce(mockPoolResponse)
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce(mockResponse)

    await performRequest({
      items: mockItems,
      rows: [FAKE_FILES[0], FAKE_FOLDERS[0]],
      contextType: mockContextType,
      contextId: mockContextId,
      onProgress: mockOnProgress,
      onComplete: mockOnComplete,
    })

    expect(doFetchApi).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        path: `/api/v1/${mockContextType}/${mockContextId}/content_exports`,
        method: 'POST',
        body: 'export_type=zip&select%5Bfiles%5D%5B%5D=178&select%5Bfolders%5D%5B%5D=46',
      }),
    )

    await waitFor(() =>
      expect(doFetchApi).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({
          path: mockResponse.json.progress_url,
        }),
      ),
    )
  })
})
