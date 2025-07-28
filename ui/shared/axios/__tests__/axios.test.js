/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import axios from '../index'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const ok = value => expect(value).toBeTruthy()

const server = setupServer()

describe('Custom Axios Tests', () => {
  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  test('Accept headers request stringified ids', async () => {
    let capturedRequest
    server.use(
      http.get('*/some/url', ({request}) => {
        capturedRequest = request
        return new HttpResponse('hello', {
          status: 200,
        })
      }),
    )

    await axios.get('/some/url')
    ok(capturedRequest.headers.get('Accept').includes('application/json+canvas-string-ids'))
  })

  test('passes X-Requested-With header', async () => {
    let capturedRequest
    server.use(
      http.get('*/some/url', ({request}) => {
        capturedRequest = request
        return new HttpResponse('hello', {
          status: 200,
        })
      }),
    )

    await axios.get('/some/url')
    ok(capturedRequest.headers.get('X-Requested-With') === 'XMLHttpRequest')
  })
})
