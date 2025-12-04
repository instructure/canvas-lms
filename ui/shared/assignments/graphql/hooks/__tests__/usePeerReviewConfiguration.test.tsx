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

import {renderHook} from '@testing-library/react-hooks'
import {QueryClient} from '@tanstack/react-query'
import React from 'react'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {usePeerReviewConfiguration} from '../usePeerReviewConfiguration'
import {PEER_REVIEW_CONFIGURATION_QUERY} from '../../teacher/Queries'

jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(),
}))

const {executeQuery} = require('@canvas/graphql')
const mockExecuteQuery = executeQuery as jest.MockedFunction<typeof executeQuery>

const mockPeerReviewConfig = {
  assignment: {
    hasGroupCategory: false,
    peerReviews: {
      acrossSections: true,
      anonymousReviews: false,
      count: 5,
      submissionRequired: true,
      intraReviews: false,
    },
    peerReviewSubAssignment: {
      pointsPossible: 10,
    },
  },
}

const mockGroupAssignmentConfig = {
  assignment: {
    hasGroupCategory: true,
    peerReviews: {
      acrossSections: false,
      anonymousReviews: true,
      count: 3,
      submissionRequired: false,
      intraReviews: true,
    },
    peerReviewSubAssignment: {
      pointsPossible: 15,
    },
  },
}

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <MockedQueryClientProvider client={queryClient}>{children}</MockedQueryClientProvider>
  )
}

describe('usePeerReviewConfiguration', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('with assignmentId', () => {
    it('initializes with loading set to true and returns configuration successfully', async () => {
      mockExecuteQuery.mockResolvedValueOnce(mockPeerReviewConfig)

      const {result, waitForNextUpdate} = renderHook(
        () => usePeerReviewConfiguration('assignment-123'),
        {
          wrapper: createWrapper(),
        },
      )

      expect(result.current.loading).toBe(true)
      expect(result.current.peerReviews).toBe(null)
      expect(result.current.peerReviewSubAssignment).toBe(null)
      expect(result.current.hasGroupCategory).toBe(false)
      expect(result.current.error).toBe(null)

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.peerReviews).toEqual(mockPeerReviewConfig.assignment.peerReviews)
      expect(result.current.peerReviewSubAssignment).toEqual(
        mockPeerReviewConfig.assignment.peerReviewSubAssignment,
      )
      expect(result.current.hasGroupCategory).toBe(false)
      expect(result.current.error).toBe(null)
    })

    it('returns configuration for group assignment', async () => {
      mockExecuteQuery.mockResolvedValueOnce(mockGroupAssignmentConfig)

      const {result, waitForNextUpdate} = renderHook(
        () => usePeerReviewConfiguration('assignment-456'),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.peerReviews).toEqual(mockGroupAssignmentConfig.assignment.peerReviews)
      expect(result.current.peerReviewSubAssignment).toEqual(
        mockGroupAssignmentConfig.assignment.peerReviewSubAssignment,
      )
      expect(result.current.hasGroupCategory).toBe(true)
      expect(result.current.error).toBe(null)
    })

    it('handles query error', async () => {
      mockExecuteQuery.mockRejectedValueOnce(new Error('Failed to fetch configuration'))

      const {result, waitForNextUpdate} = renderHook(
        () => usePeerReviewConfiguration('assignment-error'),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.peerReviews).toBe(null)
      expect(result.current.peerReviewSubAssignment).toBe(null)
      expect(result.current.hasGroupCategory).toBe(false)
      expect(result.current.error).toBeTruthy()
      expect(result.current.error?.message).toBe('Failed to fetch configuration')
    })

    it('handles null peerReviews in response', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          hasGroupCategory: false,
          peerReviews: null,
          peerReviewSubAssignment: null,
        },
      })

      const {result, waitForNextUpdate} = renderHook(
        () => usePeerReviewConfiguration('assignment-789'),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.peerReviews).toBe(null)
      expect(result.current.peerReviewSubAssignment).toBe(null)
      expect(result.current.hasGroupCategory).toBe(false)
      expect(result.current.error).toBe(null)
    })

    it('handles null peerReviewSubAssignment', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          hasGroupCategory: false,
          peerReviews: mockPeerReviewConfig.assignment.peerReviews,
          peerReviewSubAssignment: null,
        },
      })

      const {result, waitForNextUpdate} = renderHook(
        () => usePeerReviewConfiguration('assignment-no-points'),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.peerReviews).toEqual(mockPeerReviewConfig.assignment.peerReviews)
      expect(result.current.peerReviewSubAssignment).toBe(null)
      expect(result.current.error).toBe(null)
    })

    it('calls executeQuery with correct parameters', async () => {
      mockExecuteQuery.mockResolvedValueOnce(mockPeerReviewConfig)

      const {result, waitForNextUpdate} = renderHook(
        () => usePeerReviewConfiguration('assignment-123'),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(mockExecuteQuery).toHaveBeenCalledWith(PEER_REVIEW_CONFIGURATION_QUERY, {
        assignmentId: 'assignment-123',
      })
    })
  })

  describe('with no assignmentId', () => {
    it('returns empty state without making any queries', () => {
      const {result} = renderHook(() => usePeerReviewConfiguration(''), {
        wrapper: createWrapper(),
      })

      expect(result.current.loading).toBe(false)
      expect(result.current.peerReviews).toBe(null)
      expect(result.current.peerReviewSubAssignment).toBe(null)
      expect(result.current.hasGroupCategory).toBe(false)
      expect(result.current.error).toBe(null)
      expect(mockExecuteQuery).not.toHaveBeenCalled()
    })
  })
})
