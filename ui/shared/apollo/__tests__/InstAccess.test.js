/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import fetchMock from 'fetch-mock'
import InstAccess from '../InstAccess'

const mockGetCookie = cookieName => {
  if (cookieName === '_csrf_token') {
    return 'myVerySafeCsrfToken'
  }
  return null
}

describe('InstAccess', () => {
  beforeEach(() => {
    jest.mock('@instructure/get-cookie', () => ({
      __esModule: true,
      default: jest.fn().mockImplementation(mockGetCookie),
    }))
    fetchMock.reset()
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('initialization', () => {
    it('initializes with no token', () => {
      const ia = new InstAccess()
      expect(ia.instAccessToken).toBeNull()
    })

    it('can be provided a token if we have one available', () => {
      const ia = new InstAccess({token: 'veryFakeToken'})
      expect(ia.instAccessToken).toEqual('veryFakeToken')
    })
  })

  describe('token fetching', () => {
    it('will use a provided token if available', async () => {
      fetchMock.mock('http://fake-gateway/graphql', {
        status: 200,
        headers: {Authorization: 'Bearer veryFakeToken'},
      })

      const ia = new InstAccess({
        token: 'veryFakeToken',
        preferredFetch: fetchMock.fetchHandler,
      })

      await ia.gatewayAuthenticatedFetch('http://fake-gateway/graphql', {})
      expect(fetchMock.calls('http://fake-gateway/graphql').length).toEqual(1)
    })

    it('fetches a token (with CSRF protection) when it needs one', async () => {
      fetchMock.mock('/api/v1/inst_access_tokens', {
        status: 200,
        body: {token: 'canvasProvidedToken'},
        headers: {'X-CSRF-Token': 'myVerySafeCsrfToken'},
      })

      fetchMock.mock('http://fake-gateway/graphql', {
        status: 200,
        headers: {Authorization: 'Bearer canvasProvidedToken'},
      })

      const ia = new InstAccess({preferredFetch: fetchMock.fetchHandler})
      await ia.gatewayAuthenticatedFetch('http://fake-gateway/graphql', {})
      expect(fetchMock.calls('/api/v1/inst_access_tokens').length).toEqual(1)
      expect(fetchMock.calls('http://fake-gateway/graphql').length).toEqual(1)
    })

    it('refreshes token when expired', async () => {
      fetchMock.mock('/api/v1/inst_access_tokens', {
        status: 200,
        body: {token: 'freshCanvasProvidedToken'},
        headers: {'X-CSRF-Token': 'myVerySafeCsrfToken'},
      })

      fetchMock.mock('http://fake-gateway/graphql', (url, options) => {
        let statusCode = 401
        if (options.headers.authorization === 'Bearer freshCanvasProvidedToken') {
          // if it uses the provided expired token, it should fail here, and won't get a 200
          // until it refreshes and comes back with a new token
          statusCode = 200
        }
        return {status: statusCode}
      })

      const ia = new InstAccess({
        token: 'ExistingToken',
        preferredFetch: fetchMock.fetchHandler,
      })

      const finalResponse = await ia.gatewayAuthenticatedFetch('http://fake-gateway/graphql', {})
      expect(finalResponse.status).toEqual(200)
      expect(fetchMock.calls('/api/v1/inst_access_tokens').length).toEqual(1)
      expect(fetchMock.calls('http://fake-gateway/graphql').length).toEqual(2)
    })

    it('uses global fetch if no implementation provided', async () => {
      fetchMock.mock('/api/v1/inst_access_tokens', {
        status: 200,
        body: {token: 'my-fake-token'},
      })

      fetchMock.mock('http://fake-gateway/graphql', {
        status: 200,
        body: '{"data": { "aField": "aValue" }, "errors": []}',
      })

      const ia = new InstAccess({})
      const finalResponse = await ia.gatewayAuthenticatedFetch('http://fake-gateway/graphql', {})
      expect(finalResponse.status).toEqual(200)
      expect(fetchMock.calls('/api/v1/inst_access_tokens').length).toEqual(1)
      expect(fetchMock.calls('http://fake-gateway/graphql').length).toEqual(1)
    })
  })
})
