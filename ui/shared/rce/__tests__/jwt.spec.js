/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import * as jwt from '../jwt'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

describe('JWT', () => {
  describe('.refreshFn() returned function', () => {
    const token = 'example'
    const newToken = 'newToken'
    const url = '/api/v1/jwts/refresh'
    const server = setupServer()

    let refreshFn

    beforeAll(() => server.listen())
    afterEach(() => server.resetHandlers())
    afterAll(() => server.close())

    beforeEach(() => {
      refreshFn = jwt.refreshFn(token)

      server.use(
        http.post(url, () => {
          return HttpResponse.json({token: newToken})
        }),
      )
    })

    test('sends an ajax request', async () => {
      let requestReceived = false
      server.use(
        http.post(url, () => {
          requestReceived = true
          return HttpResponse.json({token: newToken})
        }),
      )
      await refreshFn()
      expect(requestReceived).toBe(true)
    })

    test('sends the request to the "refresh JWT" endpoint', async () => {
      let correctUrl = false
      server.use(
        http.post(url, ({request}) => {
          correctUrl = request.url.includes(url)
          return HttpResponse.json({token: newToken})
        }),
      )
      await refreshFn()
      expect(correctUrl).toBe(true)
    })

    test('uses a POST request', async () => {
      let requestMethod = null
      server.use(
        http.all(url, ({request}) => {
          requestMethod = request.method
          return HttpResponse.json({token: newToken})
        }),
      )
      await refreshFn()
      expect(requestMethod).toBe('POST')
    })

    test('does not send multiple requests before receiving a response', async () => {
      let requestCount = 0
      server.use(
        http.post(url, async () => {
          requestCount++
          // Call refreshFn again while first request is in flight
          if (requestCount === 1) {
            refreshFn()
          }
          return HttpResponse.json({token: newToken})
        }),
      )
      await refreshFn()
      // Give time for any second request to complete
      await new Promise(resolve => setTimeout(resolve, 10))
      expect(requestCount).toBe(1)
    })

    test('returns the refreshed token with the resolved promise', async () => {
      const renewedToken = await refreshFn()
      expect(renewedToken).toBe(newToken)
    })

    test('sends the refreshed token to the given callback', async () => {
      let renewedToken
      await refreshFn(t => {
        renewedToken = t
      })
      expect(renewedToken).toBe(newToken)
    })
  })
})
