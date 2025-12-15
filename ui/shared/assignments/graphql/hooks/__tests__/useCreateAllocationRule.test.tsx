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
import {useCreateAllocationRule} from '../useCreateAllocationRule'
import {
  CreateAllocationRuleInput,
  CreateAllocationRuleResponse,
} from '../../teacher/AssignmentTeacherTypes'
import {executeQuery} from '@canvas/graphql'

vi.mock('@canvas/graphql', () => ({
  executeQuery: vi.fn(),
}))

const mockExecuteQuery = vi.mocked(executeQuery)

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      mutations: {
        retry: false,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <MockedQueryClientProvider client={queryClient}>{children}</MockedQueryClientProvider>
  )
}

describe('useCreateAllocationRule', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  const mockInput: CreateAllocationRuleInput = {
    assignmentId: '1',
    assessorIds: ['2'],
    assesseeIds: ['3'],
    mustReview: true,
    reviewPermitted: true,
    appliesToAssessor: true,
    reciprocal: false,
  }

  describe('successful mutation', () => {
    it('calls onSuccess callback when mutation succeeds with allocation rules', async () => {
      const mockResponse: CreateAllocationRuleResponse = {
        createAllocationRule: {
          allocationRules: [
            {
              _id: '1',
              mustReview: true,
              reviewPermitted: true,
              appliesToAssessor: true,
              assessor: {
                _id: '2',
                name: 'Student 2',
                peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
              },
              assessee: {
                _id: '3',
                name: 'Student 3',
                peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
              },
            },
          ],
          allocationErrors: [],
        },
      }

      mockExecuteQuery.mockResolvedValueOnce(mockResponse)

      const onSuccess = vi.fn()
      const onError = vi.fn()

      const {result, waitForNextUpdate} = renderHook(
        () => useCreateAllocationRule(onSuccess, onError),
        {
          wrapper: createWrapper(),
        },
      )

      result.current.mutate(mockInput)

      await waitForNextUpdate()

      expect(result.current.isSuccess).toBe(true)
      expect(onSuccess).toHaveBeenCalledWith(mockResponse)
      expect(onError).not.toHaveBeenCalled()
      expect(mockExecuteQuery).toHaveBeenCalledWith(expect.any(Object), {input: mockInput})
    })
  })

  describe('validation errors', () => {
    it('calls onError callback when mutation returns allocation errors', async () => {
      const mockAllocationErrors = [
        {
          message: 'conflicts with completed peer review',
          attribute: 'assesseeId',
          attributeId: '3',
        },
      ]

      const mockResponse: CreateAllocationRuleResponse = {
        createAllocationRule: {
          allocationRules: [],
          allocationErrors: mockAllocationErrors,
        },
      }

      mockExecuteQuery.mockResolvedValueOnce(mockResponse)

      const onSuccess = vi.fn()
      const onError = vi.fn()

      const {result, waitForNextUpdate} = renderHook(
        () => useCreateAllocationRule(onSuccess, onError),
        {
          wrapper: createWrapper(),
        },
      )

      result.current.mutate(mockInput)

      await waitForNextUpdate()

      expect(result.current.isSuccess).toBe(true)
      expect(onError).toHaveBeenCalledWith(mockAllocationErrors)
      expect(onSuccess).not.toHaveBeenCalled()
    })

    it('handles empty allocation errors array', async () => {
      const mockResponse: CreateAllocationRuleResponse = {
        createAllocationRule: {
          allocationRules: [
            {
              _id: '1',
              mustReview: true,
              reviewPermitted: true,
              appliesToAssessor: true,
              assessor: {
                _id: '2',
                name: 'Student 2',
                peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
              },
              assessee: {
                _id: '3',
                name: 'Student 3',
                peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
              },
            },
          ],
          allocationErrors: [],
        },
      }

      mockExecuteQuery.mockResolvedValueOnce(mockResponse)

      const onSuccess = vi.fn()
      const onError = vi.fn()

      const {result, waitForNextUpdate} = renderHook(
        () => useCreateAllocationRule(onSuccess, onError),
        {
          wrapper: createWrapper(),
        },
      )

      result.current.mutate(mockInput)

      await waitForNextUpdate()

      expect(result.current.isSuccess).toBe(true)
      expect(onSuccess).toHaveBeenCalledWith(mockResponse)
      expect(onError).not.toHaveBeenCalled()
    })
  })

  describe('network/GraphQL errors', () => {
    it('calls onError callback with empty array when mutation fails', async () => {
      const mockError = new Error('Network error')
      mockExecuteQuery.mockRejectedValueOnce(mockError)

      const onSuccess = vi.fn()
      const onError = vi.fn()

      const {result, waitForNextUpdate} = renderHook(
        () => useCreateAllocationRule(onSuccess, onError),
        {
          wrapper: createWrapper(),
        },
      )

      result.current.mutate(mockInput)

      await waitForNextUpdate()

      expect(result.current.isError).toBe(true)
      expect(onError).toHaveBeenCalledWith([mockError])
      expect(onSuccess).not.toHaveBeenCalled()
    })
  })
})
