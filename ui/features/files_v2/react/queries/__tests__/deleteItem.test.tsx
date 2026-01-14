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
import {FAKE_FILES, FAKE_FOLDERS} from '../../../fixtures/fakeData'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('deleteItem', () => {
  const mockFile = FAKE_FILES[0]
  const mockFolder = FAKE_FOLDERS[0]

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    server.use(
      http.delete(`/api/v1/files/${mockFile.id}`, () => new HttpResponse(null, {status: 200})),
      http.delete(`/api/v1/folders/${mockFolder.id}`, () => new HttpResponse(null, {status: 200})),
    )
  })

  afterEach(() => {
    server.resetHandlers()
  })

  describe('successful deletion', () => {
    it('should make DELETE request with correct path for a file', async () => {
      let requestMade = false
      let requestUrl = ''
      server.use(
        http.delete(`/api/v1/files/${mockFile.id}`, ({request}) => {
          requestMade = true
          requestUrl = new URL(request.url).pathname + new URL(request.url).search
          return new HttpResponse(null, {status: 200})
        }),
      )

      await deleteItem(mockFile)

      expect(requestMade).toBe(true)
      expect(requestUrl).toBe(`/api/v1/files/${mockFile.id}?force=true`)
    })

    it('should make DELETE request with correct path for a folder', async () => {
      let requestMade = false
      let requestUrl = ''
      server.use(
        http.delete(`/api/v1/folders/${mockFolder.id}`, ({request}) => {
          requestMade = true
          requestUrl = new URL(request.url).pathname + new URL(request.url).search
          return new HttpResponse(null, {status: 200})
        }),
      )

      await deleteItem(mockFolder)

      expect(requestMade).toBe(true)
      expect(requestUrl).toBe(`/api/v1/folders/${mockFolder.id}?force=true`)
    })
  })

  describe('error handling', () => {
    it('should throw an error when request fails', async () => {
      server.use(
        http.delete(`/api/v1/files/${mockFile.id}`, () => new HttpResponse(null, {status: 500})),
      )

      await expect(deleteItem(mockFile)).rejects.toThrow()
    })
  })
})
