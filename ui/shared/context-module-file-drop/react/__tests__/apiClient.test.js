/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {http, HttpResponse} from 'msw'
import {mswServer} from '../../../msw/mswServer'
import {getCourseRootFolder, getFolderFiles} from '../apiClient'

const server = mswServer([])

beforeAll(() => {
  server.listen()
})

beforeEach(() => {
  // Reset handlers for each test
})

afterEach(() => {
  server.resetHandlers()
  jest.clearAllMocks()
})

afterAll(() => {
  server.close()
})

it('fetches course root folder', async () => {
  server.use(
    http.get('*/api/v1/courses/1/folders/root', () => {
      return new HttpResponse(JSON.stringify({files: []}), {
        status: 200,
        headers: {'Content-Type': 'application/json'},
      })
    }),
  )
  const rootFolder = await getCourseRootFolder('1')
  expect(rootFolder).toEqual({files: []})
})

it('fetches folder files across pages', async () => {
  server.use(
    http.get('*/api/v1/folders/1/files', ({request}) => {
      const url = new URL(request.url)
      if (url.searchParams.get('page') === '2') {
        return new HttpResponse(JSON.stringify([{display_name: 'b.txt'}]), {
          status: 200,
          headers: {'Content-Type': 'application/json'},
        })
      }
      return new HttpResponse(JSON.stringify([{display_name: 'a.txt'}]), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          link: '<http://canvas.example.com/api/v1/folders/1/files?only[]=names&page=2>; rel="next"',
        },
      })
    }),
  )
  const files = await getFolderFiles('1')
  expect(files.map(f => f.get('display_name'))).toEqual(['a.txt', 'b.txt'])
})
