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

import {describe, it, expect, vi, beforeEach} from 'vitest'
import {executeQuery, getGraphqlDefaults} from '../index'
import getCookie from '@instructure/get-cookie'
import {request} from 'graphql-request'
import {gql} from '@apollo/client'

// Mock dependencies
vi.mock('@instructure/get-cookie')
vi.mock('graphql-request', () => ({
  request: vi.fn(),
}))

const mockGetCookie = vi.mocked(getCookie)
const mockRequest = vi.mocked(request)

describe('@canvas/graphql', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Set default return value for getCookie
    mockGetCookie.mockReturnValue('default-token')
    mockRequest.mockResolvedValue({data: 'mock-data'})
  })

  describe('getGraphqlDefaults', () => {
    it('reads CSRF token fresh on each call', () => {
      mockGetCookie.mockReturnValueOnce('token1')
      const defaults1 = getGraphqlDefaults()
      expect(defaults1.requestHeaders['X-CSRF-Token']).toBe('token1')

      mockGetCookie.mockReturnValueOnce('token2')
      const defaults2 = getGraphqlDefaults()
      expect(defaults2.requestHeaders['X-CSRF-Token']).toBe('token2')

      expect(mockGetCookie).toHaveBeenCalledTimes(2)
      expect(mockGetCookie).toHaveBeenCalledWith('_csrf_token')
    })

    it('includes static headers alongside token', () => {
      const defaults = getGraphqlDefaults()

      expect(defaults.requestHeaders).toMatchObject({
        'X-Requested-With': 'XMLHttpRequest',
        'GraphQL-Metrics': 'true',
        'X-CSRF-Token': 'default-token',
      })
    })
  })

  describe('executeQuery', () => {
    const testQuery = gql`
      query TestQuery($courseId: ID!) {
        course(id: $courseId) {
          _id
        }
      }
    `

    it('uses fresh CSRF token on each request', async () => {
      mockGetCookie.mockReturnValueOnce('first-token')
      await executeQuery(testQuery, {})

      expect(mockRequest).toHaveBeenCalledWith(
        expect.stringContaining('/api/graphql'),
        testQuery,
        {},
        expect.objectContaining({
          'X-CSRF-Token': 'first-token',
        }),
      )

      mockGetCookie.mockReturnValueOnce('second-token')
      await executeQuery(testQuery, {})

      expect(mockRequest).toHaveBeenCalledWith(
        expect.stringContaining('/api/graphql'),
        testQuery,
        {},
        expect.objectContaining({
          'X-CSRF-Token': 'second-token',
        }),
      )
    })

    it('merges custom headers with defaults', async () => {
      const customHeaders = {'Custom-Header': 'test-id'}

      await executeQuery(testQuery, {}, customHeaders)

      expect(mockRequest).toHaveBeenCalledWith(
        expect.any(String),
        testQuery,
        {},
        expect.objectContaining({
          'X-CSRF-Token': 'default-token',
          'X-Requested-With': 'XMLHttpRequest',
          'GraphQL-Metrics': 'true',
          'Custom-Header': 'test-id',
        }),
      )
    })

    it('allows custom headers to override CSRF token', async () => {
      const customHeaders = {'X-CSRF-Token': 'override-token'}

      await executeQuery(testQuery, {}, customHeaders)

      expect(mockRequest).toHaveBeenCalledWith(
        expect.any(String),
        testQuery,
        {},
        expect.objectContaining({
          'X-CSRF-Token': 'override-token',
        }),
      )
    })
  })
})
