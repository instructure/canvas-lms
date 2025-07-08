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

import {deleteItem} from '../deleteItem'
import {UnauthorizedError} from '../../../utils/apiUtils'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../fixtures/fakeData'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn(),
}))

const mockDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

describe('deleteItem', () => {
  const mockFile = FAKE_FILES[0]
  const mockFolder = FAKE_FOLDERS[0]

  beforeEach(() => {
    mockDoFetchApi.mockResolvedValue({
      text: '',
      response: {
        ok: true,
        status: 200,
        text: () => Promise.resolve(''),
      } as Response,
    })
  })

  afterEach(() => {
    mockDoFetchApi.mockReset()
  })

  describe('successful deletion', () => {
    it('should call doFetchApi with correct path and options for a file', async () => {
      await deleteItem(mockFile)

      expect(mockDoFetchApi).toHaveBeenCalledWith({
        path: `/api/v1/files/${mockFile.id}?force=true`,
        method: 'DELETE',
        headers: {'Content-Type': 'application/json'},
      })
    })

    it('should call doFetchApi with correct path and options for a folder', async () => {
      await deleteItem(mockFolder)

      expect(mockDoFetchApi).toHaveBeenCalledWith({
        path: `/api/v1/folders/${mockFolder.id}?force=true`,
        method: 'DELETE',
        headers: {'Content-Type': 'application/json'},
      })
    })
  })

  describe('error handling', () => {
    it('should throw UnauthorizedError when response status is 401', async () => {
      mockDoFetchApi.mockResolvedValueOnce({
        text: '',
        response: {
          ok: false,
          status: 401,
          text: () => Promise.resolve('Unauthorized'),
        } as Response,
      })

      await expect(deleteItem(mockFile)).rejects.toThrow(UnauthorizedError)
    })

    it('should throw an error when response is not ok', async () => {
      mockDoFetchApi.mockResolvedValueOnce({
        text: '',
        response: {
          ok: false,
          status: 500,
          text: () => Promise.resolve('Internal Server Error'),
        } as Response,
      })

      await expect(deleteItem(mockFile)).rejects.toThrow(
        `Failed to delete ${mockFile.id}: 500 - Internal Server Error`,
      )
    })

    it('should throw an error when doFetchApi rejects', async () => {
      mockDoFetchApi.mockRejectedValueOnce(new Error('Network error'))

      await expect(deleteItem(mockFile)).rejects.toThrow('Network error')
    })
  })

  describe('doFetchApi spy assertions', () => {
    it('should verify doFetchApi was called exactly once', async () => {
      await deleteItem(mockFile)

      expect(mockDoFetchApi).toHaveBeenCalledTimes(1)
    })

    it('should verify doFetchApi was never called when function is not invoked', () => {
      expect(mockDoFetchApi).not.toHaveBeenCalled()
    })
  })
})
