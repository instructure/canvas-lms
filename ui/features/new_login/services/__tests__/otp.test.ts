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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {cancelOtpRequest, initiateOtpRequest, verifyOtpRequest} from '../otp'

jest.mock('@canvas/authenticity-token', () => jest.fn(() => 'testCsrfToken'))

jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn(),
}))

describe('OTP Service', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('initiateOtpRequest', () => {
    it('should call doFetchApi with correct parameters and handle success', async () => {
      const mockResponse = {json: {otp_sent: true}, response: {status: 200}}
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await initiateOtpRequest()
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/login/otp',
        method: 'GET',
      })
      expect(result).toEqual({status: 200, data: {otp_sent: true}})
    })

    it('should handle failure response correctly', async () => {
      const mockResponse = {json: {error: 'Failed to initiate OTP'}, response: {status: 400}}
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await initiateOtpRequest()
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/login/otp',
        method: 'GET',
      })
      expect(result).toEqual({status: 400, data: {error: 'Failed to initiate OTP'}})
    })
  })

  describe('verifyOtpRequest', () => {
    it('should call doFetchApi with correct parameters and handle success', async () => {
      const mockResponse = {json: {otp_verified: true}, response: {status: 200}}
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await verifyOtpRequest('123456', true)
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/login/otp',
        method: 'POST',
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

    it('should handle failure response correctly', async () => {
      const mockResponse = {json: {error: 'Failed to verify OTP'}, response: {status: 400}}
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await verifyOtpRequest('123456', true)
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/login/otp',
        method: 'POST',
        body: {
          authenticity_token: 'testCsrfToken',
          otp_login: {
            verification_code: '123456',
            remember_me: '1',
          },
        },
      })
      expect(result).toEqual({status: 400, data: {error: 'Failed to verify OTP'}})
    })
  })

  describe('cancelOtpRequest', () => {
    it('should call doFetchApi with correct parameters and handle success', async () => {
      const mockResponse = {json: {}, response: {status: 200}}
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await cancelOtpRequest()
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/login/otp/cancel',
        method: 'DELETE',
        body: {
          authenticity_token: 'testCsrfToken',
        },
      })
      expect(result).toEqual({status: 200, data: {}})
    })

    it('should handle failure response correctly', async () => {
      const mockResponse = {json: {}, response: {status: 400}}
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await cancelOtpRequest()
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/login/otp/cancel',
        method: 'DELETE',
        body: {
          authenticity_token: 'testCsrfToken',
        },
      })
      expect(result).toEqual({status: 400, data: {}})
    })
  })
})
