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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {fetchItemTitles} from '../fetchItemTitles'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
}))

const server = setupServer(
  http.get('/api/v1/courses/:courseId/modules/:moduleId/items', ({params}) => {
    if (params.courseId === '17') {
      return HttpResponse.json({error: 'Not found'}, {status: 404})
    }
    return HttpResponse.json([
      {id: '1', title: 'Item 1'},
      {id: '2', title: 'Item 2'},
    ])
  }),
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

describe('fetchItemTitles', () => {
  it('should fetch item titles', async () => {
    const response = await fetchItemTitles('1', '2')
    expect(response).toEqual([
      {id: '1', title: 'Item 1'},
      {id: '2', title: 'Item 2'},
    ])
  })

  it('should handle API errors', async () => {
    await expect(fetchItemTitles('17', '2')).rejects.toThrow()
    expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Failed loading module items',
        type: 'error',
      }),
    )
  })
})
