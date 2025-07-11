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

import {updatePermissionForItem, UpdatePermissionBody} from '../updatePermissionForItem'
import {doFetchApiWithAuthCheck} from '../../../utils/apiUtils'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../fixtures/fakeData'

jest.mock('../../../utils/apiUtils', () => ({
  ...jest.requireActual('../../../utils/apiUtils'),
  doFetchApiWithAuthCheck: jest.fn(),
}))

const mockDoFetchApiWithAuthCheck = doFetchApiWithAuthCheck as jest.MockedFunction<
  typeof doFetchApiWithAuthCheck
>

describe('updatePermissionForItem', () => {
  const mockFile = FAKE_FILES[0]
  const mockFolder = FAKE_FOLDERS[0]

  const permissionData: UpdatePermissionBody = {
    hidden: false,
    locked: false,
    unlock_at: '',
    lock_at: '',
  }

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

  describe('successful permission update', () => {
    it('should call doFetchApiWithAuthCheck with correct path and options for a file', async () => {
      await updatePermissionForItem(mockFile, permissionData)

      expect(mockDoFetchApiWithAuthCheck).toHaveBeenCalledWith({
        path: `/api/v1/files/${mockFile.id}`,
        method: 'PUT',
        headers: {'Content-Type': 'application/json'},
        body: permissionData,
      })
    })
  })

  it('should call doFetchApiWithAuthCheck with correct path and options for a folder', async () => {
    await updatePermissionForItem(mockFolder, permissionData)

    expect(mockDoFetchApiWithAuthCheck).toHaveBeenCalledWith({
      path: `/api/v1/folders/${mockFolder.id}`,
      method: 'PUT',
      headers: {'Content-Type': 'application/json'},
      body: permissionData,
    })
  })

  describe('error handling', () => {
    it('should throw the same error which doFetchApiWithAuthCheck throws', async () => {
      const error = new Error('Network error')
      mockDoFetchApiWithAuthCheck.mockRejectedValueOnce(error)

      await expect(updatePermissionForItem(mockFile, permissionData)).rejects.toThrow(error)
    })
  })
})
