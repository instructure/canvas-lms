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

import {fetchFolders} from '../folders'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('folders', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => server.resetHandlers())

  describe('fetchFolders', () => {
    const folderId = '235'
    const expectedPath = `/api/v1/folders/${folderId}/folders`

    it('should request page 1 when no page param is provided', async () => {
      let requestParams: URLSearchParams | undefined
      server.use(
        http.get(expectedPath, ({request}) => {
          requestParams = new URL(request.url).searchParams
          return HttpResponse.json([{id: '123', name: 'Test Folder'}], {
            headers: {
              Link: `<${expectedPath}?page=2>; rel="next"`,
            },
          })
        }),
      )

      await fetchFolders(folderId, null)
      expect(requestParams!.get('page')).toBe('1')
      expect(requestParams!.get('per_page')).toBe('25')
    })

    it('should request the specified page when page param is provided', async () => {
      let requestParams: URLSearchParams | undefined
      server.use(
        http.get(expectedPath, ({request}) => {
          requestParams = new URL(request.url).searchParams
          return HttpResponse.json([{id: '123', name: 'Test Folder'}], {
            headers: {
              Link: `<${expectedPath}?page=3>; rel="next"`,
            },
          })
        }),
      )

      await fetchFolders(folderId, '2')
      expect(requestParams!.get('page')).toBe('2')
      expect(requestParams!.get('per_page')).toBe('25')
    })

    it('should return the transformed response with next page', async () => {
      server.use(
        http.get(expectedPath, () =>
          HttpResponse.json([{id: '123', name: 'Test Folder'}], {
            headers: {
              Link: `<${expectedPath}?page=2>; rel="next"`,
            },
          }),
        ),
      )

      const result = await fetchFolders(folderId, null)
      expect(result).toEqual({
        json: [{id: '123', name: 'Test Folder'}],
        nextPage: '2',
      })
    })
  })
})
