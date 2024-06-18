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
import FakeServer from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'

describe('JWT', () => {
  describe('.refreshFn() returned function', () => {
    const token = 'example'
    const newToken = 'newToken'
    const url = '/api/v1/jwts/refresh'

    let refreshFn
    let server

    beforeEach(() => {
      server = new FakeServer()
      refreshFn = jwt.refreshFn(token)

      server.for(url).respond([{status: 200, body: {token: newToken}}])
    })

    afterEach(() => {
      server.teardown()
    })

    test('sends an ajax request', async () => {
      await refreshFn()
      expect(server.receivedRequests.length).toBe(1)
    })

    test('sends the request to the "refresh JWT" endpoint', async () => {
      await refreshFn()
      expect(server.findRequest(url)).toBeTruthy()
    })

    test('uses a POST request', async () => {
      await refreshFn()
      const request = server.findRequest('/api/v1/jwts/refresh')
      expect(request.method).toBe('POST')
    })

    test('does not send multiple requests before receiving a response', async () => {
      server.unsetResponses(url)
      server
        .for(url)
        .beforeRespond(() => {
          refreshFn()
        })
        .respond([{status: 200, body: {token: newToken}}])
      await refreshFn()
      expect(server.receivedRequests.length).toBe(1)
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
