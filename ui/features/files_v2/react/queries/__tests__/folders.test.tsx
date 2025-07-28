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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {fetchFolders} from '../folders'

jest.mock('@canvas/do-fetch-api-effect', () => {
  return jest.fn(() => ({
    json: [{id: '123', name: 'Test Folder'}],
    link: {next: {page: '2'}},
  }))
})

describe('folders', () => {
  describe('fetchFolders', () => {
    const folderId = '235'
    const expectedFolderPerPage = '25'
    const expectedPath = `/api/v1/folders/${folderId}/folders`
    const expectedHttpMethod = 'GET'

    beforeEach(() => {
      ;(doFetchApi as jest.Mock).mockClear()
    })

    it('should call the doFetchApi with page 1 when no page param is provided', async () => {
      await fetchFolders(folderId, null)
      expect(doFetchApi).toHaveBeenCalledWith({
        path: expectedPath,
        method: expectedHttpMethod,
        params: {per_page: expectedFolderPerPage, page: '1'},
      })
    })

    it('should call the doFetchApi with page param when is provided', async () => {
      await fetchFolders(folderId, '2')
      expect(doFetchApi).toHaveBeenCalledWith({
        path: expectedPath,
        method: expectedHttpMethod,
        params: {per_page: expectedFolderPerPage, page: '2'},
      })
    })

    it('should return the transformed response from doFetchApi response', async () => {
      const result = await fetchFolders(folderId, null)
      expect(result).toEqual({
        json: [{id: '123', name: 'Test Folder'}],
        nextPage: '2',
      })
    })
  })
})
