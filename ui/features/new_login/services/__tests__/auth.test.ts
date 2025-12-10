/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {forgotPassword, performSignIn} from '../auth'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

jest.mock('@canvas/authenticity-token', () => jest.fn(() => 'testCsrfToken'))

const server = setupServer()

let capturedRequest: {path: string; body: any} | null = null

describe('Auth Service', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    capturedRequest = null
    jest.clearAllMocks()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  describe('performSignIn', () => {
    it('should call doFetchApi with correct parameters and handle success', async () => {
      server.use(
        http.post('/login/canvas', async ({request}) => {
          capturedRequest = {
            path: new URL(request.url).pathname,
            body: await request.json(),
          }
          return HttpResponse.json({pseudonym: {}, location: '/dashboard'})
        }),
      )
      const result = await performSignIn('testUser', 'testPassword', true, '/login/canvas')
      expect(capturedRequest).toEqual({
        path: '/login/canvas',
        body: {
          authenticity_token: 'testCsrfToken',
          pseudonym_session: {
            unique_id: 'testUser',
            password: 'testPassword',
            remember_me: '1',
          },
        },
      })
      expect(result).toEqual({
        status: 200,
        data: {
          pseudonym: {},
          location: '/dashboard',
        },
      })
    })

    it('should return empty data when response has no json', async () => {
      server.use(http.post('/login/canvas', () => new HttpResponse(null, {status: 200})))
      const result = await performSignIn('testUser', 'testPassword', true, '/login/canvas')
      expect(result).toEqual({status: 200, data: {}})
    })
  })

  describe('forgotPassword', () => {
    it('should call doFetchApi with correct parameters and handle success', async () => {
      server.use(
        http.post('/forgot_password', async ({request}) => {
          capturedRequest = {
            path: new URL(request.url).pathname,
            body: await request.json(),
          }
          return HttpResponse.json({requested: true})
        }),
      )
      const result = await forgotPassword('test@example.com')
      expect(capturedRequest).toEqual({
        path: '/forgot_password',
        body: {
          authenticity_token: 'testCsrfToken',
          pseudonym_session: {
            unique_id_forgot: 'test@example.com',
          },
        },
      })
      expect(result).toEqual({
        status: 200,
        data: {requested: true},
      })
    })

    it('should return {requested: false} when response has no json', async () => {
      server.use(http.post('/forgot_password', () => new HttpResponse(null, {status: 200})))
      const result = await forgotPassword('test@example.com')
      expect(result).toEqual({status: 200, data: {requested: false}})
    })
  })
})
