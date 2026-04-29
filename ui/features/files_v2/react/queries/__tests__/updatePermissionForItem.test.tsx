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
import {FAKE_FILES, FAKE_FOLDERS} from '../../../fixtures/fakeData'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('updatePermissionForItem', () => {
  const mockFile = FAKE_FILES[0]
  const mockFolder = FAKE_FOLDERS[0]

  const permissionData: UpdatePermissionBody = {
    hidden: false,
    locked: false,
    unlock_at: '',
    lock_at: '',
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    server.use(
      http.put(`/api/v1/files/${mockFile.id}`, () => new HttpResponse(null, {status: 200})),
      http.put(`/api/v1/folders/${mockFolder.id}`, () => new HttpResponse(null, {status: 200})),
    )
  })

  afterEach(() => {
    server.resetHandlers()
  })

  describe('successful permission update', () => {
    it('should make PUT request with correct path and body for a file', async () => {
      let requestMade = false
      let requestBody: any = null
      server.use(
        http.put(`/api/v1/files/${mockFile.id}`, async ({request}) => {
          requestMade = true
          requestBody = await request.json()
          return new HttpResponse(null, {status: 200})
        }),
      )

      await updatePermissionForItem(mockFile, permissionData)

      expect(requestMade).toBe(true)
      expect(requestBody).toEqual(permissionData)
    })
  })

  it('should make PUT request with correct path and body for a folder', async () => {
    let requestMade = false
    let requestBody: any = null
    server.use(
      http.put(`/api/v1/folders/${mockFolder.id}`, async ({request}) => {
        requestMade = true
        requestBody = await request.json()
        return new HttpResponse(null, {status: 200})
      }),
    )

    await updatePermissionForItem(mockFolder, permissionData)

    expect(requestMade).toBe(true)
    expect(requestBody).toEqual(permissionData)
  })

  describe('error handling', () => {
    it('should throw an error when request fails', async () => {
      server.use(
        http.put(`/api/v1/files/${mockFile.id}`, () => new HttpResponse(null, {status: 500})),
      )

      await expect(updatePermissionForItem(mockFile, permissionData)).rejects.toThrow()
    })
  })
})
