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

import {performSignIn} from '../auth'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn(),
}))

describe('Auth Service', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('performSignIn', () => {
    it('should call doFetchApi with correct parameters and handle success', async () => {
      const mockResponse = {
        json: {pseudonym: {}, location: '/dashboard'},
        response: {status: 200},
      }
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await performSignIn('testUser', 'testPassword', true)
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/login/canvas',
        method: 'POST',
        body: {
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
      const mockResponse = {json: null, response: {status: 200}}
      ;(doFetchApi as jest.Mock).mockResolvedValue(mockResponse)
      const result = await performSignIn('testUser', 'testPassword', true)
      expect(result).toEqual({status: 200, data: {}})
    })
  })
})
