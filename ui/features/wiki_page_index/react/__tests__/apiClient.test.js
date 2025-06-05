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
import {mswServer} from '../../../../shared/msw/mswServer'
import {deletePages} from '../apiClient'

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

it('deletes pages', async () => {
  server.use(
    http.delete('*/api/v1/courses/1/pages/my_page', () => {
      return new HttpResponse(JSON.stringify({}), {
        status: 200,
        headers: {'Content-Type': 'application/json'},
      })
    }),
  )
  const response = await deletePages('courses', '1', ['my_page'])
  expect(response.failures).toEqual([])
  expect(response.successes[0].data).toEqual('my_page')
})
