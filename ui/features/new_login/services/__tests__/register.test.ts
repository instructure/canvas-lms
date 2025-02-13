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
import {createParentAccount, createStudentAccount, createTeacherAccount} from '../register'

jest.mock('@canvas/authenticity-token', () => jest.fn(() => 'testCsrfToken'))

jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn(),
}))

describe('Register Service', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should call doFetchApi with correct parameters and handle success', async () => {
    const mockResponse = {
      json: {success: true},
      response: {status: 200},
    }
    ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
    const result = await createTeacherAccount({
      name: 'Test Teacher',
      email: 'test@example.com',
      termsAccepted: true,
      captchaToken: 'mock-captcha-token',
    })
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/users',
      method: 'POST',
      body: {
        authenticity_token: 'testCsrfToken',
        user: {
          initial_enrollment_type: 'teacher',
          name: 'Test Teacher',
          terms_of_use: '1',
        },
        pseudonym: {
          unique_id: 'test@example.com',
        },
        'g-recaptcha-response': 'mock-captcha-token',
      },
    })
    expect(result).toEqual({status: 200, data: {success: true}})
  })

  it('should handle missing JSON in response', async () => {
    const mockResponse = {json: null, response: {status: 400}}
    ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
    const result = await createTeacherAccount({
      name: 'Test Teacher',
      email: 'test@example.com',
      termsAccepted: false,
    })
    expect(result).toEqual({status: 400, data: {success: false}})
  })

  describe('createParentAccount', () => {
    it('should call doFetchApi with correct parameters and handle success', async () => {
      const mockResponse = {
        json: {success: true},
        response: {status: 201},
      }
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await createParentAccount({
        name: 'Test Parent',
        email: 'parent@example.com',
        password: 'testPass123',
        confirmPassword: 'testPass123',
        pairingCode: 'PAIR123',
        termsAccepted: true,
      })
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users',
        method: 'POST',
        body: {
          authenticity_token: 'testCsrfToken',
          user: {
            name: 'Test Parent',
            terms_of_use: '1',
            initial_enrollment_type: 'observer',
            skip_registration: '1',
          },
          pseudonym: {
            unique_id: 'parent@example.com',
            password: 'testPass123',
            password_confirmation: 'testPass123',
          },
          pairing_code: {
            code: 'PAIR123',
          },
          communication_channel: {
            skip_confirmation: '1',
          },
        },
      })
      expect(result).toEqual({status: 201, data: {success: true}})
    })

    it('should handle missing JSON in response', async () => {
      const mockResponse = {json: null, response: {status: 400}}
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await createParentAccount({
        name: 'Test Parent',
        email: 'parent@example.com',
        password: 'testPass123',
        confirmPassword: 'testPass123',
        pairingCode: 'PAIR123',
        termsAccepted: false,
      })
      expect(result).toEqual({status: 400, data: {success: false}})
    })
  })

  describe('createStudentAccount', () => {
    it('should call doFetchApi with correct parameters and handle success with email', async () => {
      const mockResponse = {
        json: {success: true},
        response: {status: 201},
      }
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await createStudentAccount({
        name: 'Test Student',
        username: 'testStudent',
        password: 'studentPass123',
        confirmPassword: 'studentPass123',
        joinCode: 'JOIN123',
        email: 'student@example.com',
        termsAccepted: true,
      })
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users',
        method: 'POST',
        body: {
          authenticity_token: 'testCsrfToken',
          user: {
            name: 'Test Student',
            terms_of_use: '1',
            initial_enrollment_type: 'student',
            self_enrollment_code: 'JOIN123',
          },
          pseudonym: {
            unique_id: 'testStudent',
            password: 'studentPass123',
            password_confirmation: 'studentPass123',
            path: 'student@example.com',
          },
          self_enrollment: '1',
          pseudonym_type: 'username',
        },
      })
      expect(result).toEqual({status: 201, data: {success: true}})
    })

    it('should call doFetchApi without email and handle success', async () => {
      const mockResponse = {
        json: {success: true},
        response: {status: 201},
      }
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await createStudentAccount({
        name: 'Test Student',
        username: 'testStudent',
        password: 'studentPass123',
        confirmPassword: 'studentPass123',
        joinCode: 'JOIN123',
        termsAccepted: true,
      })
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users',
        method: 'POST',
        body: {
          authenticity_token: 'testCsrfToken',
          user: {
            name: 'Test Student',
            terms_of_use: '1',
            initial_enrollment_type: 'student',
            self_enrollment_code: 'JOIN123',
          },
          pseudonym: {
            unique_id: 'testStudent',
            password: 'studentPass123',
            password_confirmation: 'studentPass123',
          },
          self_enrollment: '1',
          pseudonym_type: 'username',
        },
      })
      expect(result).toEqual({status: 201, data: {success: true}})
    })

    it('should handle missing JSON in response', async () => {
      const mockResponse = {json: null, response: {status: 400}}
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await createStudentAccount({
        name: 'Test Student',
        username: 'testStudent',
        password: 'studentPass123',
        confirmPassword: 'studentPass123',
        joinCode: 'JOIN123',
        termsAccepted: false,
      })
      expect(result).toEqual({status: 400, data: {success: false}})
    })
  })
})
