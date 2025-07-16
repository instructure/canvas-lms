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
import {doFetchApiWithAuthCheck} from '../../../utils/apiUtils'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../fixtures/fakeData'

jest.mock('../../../utils/apiUtils', () => ({
  ...jest.requireActual('../../../utils/apiUtils'),
  doFetchApiWithAuthCheck: jest.fn(),
}))

const mockDoFetchApiWithAuthCheck = doFetchApiWithAuthCheck as jest.MockedFunction<
  typeof doFetchApiWithAuthCheck
>

describe('deleteItem', () => {
  const mockFile = FAKE_FILES[0]
  const mockFolder = FAKE_FOLDERS[0]

  beforeEach(() => {
    mockDoFetchApiWithAuthCheck.mockResolvedValue({
      text: '',
      response: {
        ok: true,
        status: 200,
        text: () => Promise.resolve(''),
      } as Response,
    })
  })

  afterEach(() => {
    mockDoFetchApiWithAuthCheck.mockReset()
  })

  describe('successful deletion', () => {
    it('should call doFetchApiWithAuthCheck with correct path and options for a file', async () => {
      await deleteItem(mockFile)

      expect(mockDoFetchApiWithAuthCheck).toHaveBeenCalledWith({
        path: `/api/v1/files/${mockFile.id}?force=true`,
        method: 'DELETE',
        headers: {'Content-Type': 'application/json'},
      })
    })

    it('should call doFetchApiWithAuthCheck with correct path and options for a folder', async () => {
      await deleteItem(mockFolder)

      expect(mockDoFetchApiWithAuthCheck).toHaveBeenCalledWith({
        path: `/api/v1/folders/${mockFolder.id}?force=true`,
        method: 'DELETE',
        headers: {'Content-Type': 'application/json'},
      })
    })
  })

  describe('error handling', () => {
    it('should throw the same error which doFetchApiWithAuthCheck throws', async () => {
      const error = new Error('Network error')
      mockDoFetchApiWithAuthCheck.mockRejectedValueOnce(error)

      await expect(deleteItem(mockFile)).rejects.toThrow(error)
    })
  })
})
