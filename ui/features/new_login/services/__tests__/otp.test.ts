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

import {cancelOtpRequest, initiateOtpRequest, verifyOtpRequest} from '../otp'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

vi.mock('@canvas/authenticity-token', () => ({
  __esModule: true,
  default: vi.fn(() => 'testCsrfToken'),
}))

const server = setupServer()

let capturedRequest: {path: string; body: any} | null = null

describe('OTP Service', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    capturedRequest = null
    vi.clearAllMocks()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  describe('initiateOtpRequest', () => {
    it('should call doFetchApi with correct parameters and handle success', async () => {
      server.use(
        http.get('/login/otp', ({request}) => {
          capturedRequest = {
            path: new URL(request.url).pathname,
            body: null,
          }
          return HttpResponse.json({otp_sent: true})
        }),
      )
      const result = await initiateOtpRequest()
      expect(capturedRequest?.path).toBe('/login/otp')
      expect(result).toEqual({status: 200, data: {otp_sent: true}})
    })

    it('should throw on failure response', async () => {
      server.use(
        http.get('/login/otp', ({request}) => {
          capturedRequest = {
            path: new URL(request.url).pathname,
            body: null,
          }
          return HttpResponse.json({error: 'Failed to initiate OTP'}, {status: 400})
        }),
      )
      await expect(initiateOtpRequest()).rejects.toThrow('doFetchApi received a bad response')
      expect(capturedRequest?.path).toBe('/login/otp')
    })
  })

  describe('verifyOtpRequest', () => {
    it('should call doFetchApi with correct parameters and handle success', async () => {
      server.use(
        http.post('/login/otp', async ({request}) => {
          capturedRequest = {
            path: new URL(request.url).pathname,
            body: await request.json(),
          }
          return HttpResponse.json({otp_verified: true})
        }),
      )
      const result = await verifyOtpRequest('123456', true)
      expect(capturedRequest).toEqual({
        path: '/login/otp',
        body: {
          authenticity_token: 'testCsrfToken',
          otp_login: {
            verification_code: '123456',
            remember_me: '1',
          },
        },
      })
      expect(result).toEqual({status: 200, data: {otp_verified: true}})
    })

    it('should throw on failure response', async () => {
      server.use(
        http.post('/login/otp', async ({request}) => {
          capturedRequest = {
            path: new URL(request.url).pathname,
            body: await request.json(),
          }
          return HttpResponse.json({error: 'Failed to verify OTP'}, {status: 400})
        }),
      )
      await expect(verifyOtpRequest('123456', true)).rejects.toThrow(
        'doFetchApi received a bad response',
      )
      expect(capturedRequest).toEqual({
        path: '/login/otp',
        body: {
          authenticity_token: 'testCsrfToken',
          otp_login: {
            verification_code: '123456',
            remember_me: '1',
          },
        },
      })
    })
  })

  describe('cancelOtpRequest', () => {
    it('should call doFetchApi with correct parameters and handle success', async () => {
      server.use(
        http.delete('/login/otp/cancel', async ({request}) => {
          capturedRequest = {
            path: new URL(request.url).pathname,
            body: {},
          }
          return HttpResponse.json({})
        }),
      )
      const result = await cancelOtpRequest()
      expect(capturedRequest).toEqual({
        path: '/login/otp/cancel',
        body: {},
      })
      expect(result).toEqual({status: 200, data: {}})
    })

    it('should throw on failure response', async () => {
      server.use(
        http.delete('/login/otp/cancel', async ({request}) => {
          capturedRequest = {
            path: new URL(request.url).pathname,
            body: {},
          }
          return HttpResponse.json({}, {status: 400})
        }),
      )
      await expect(cancelOtpRequest()).rejects.toThrow('doFetchApi received a bad response')
      expect(capturedRequest).toEqual({
        path: '/login/otp/cancel',
        body: {},
      })
    })
  })
})
