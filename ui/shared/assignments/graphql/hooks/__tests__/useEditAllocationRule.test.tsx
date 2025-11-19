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
import {useEditAllocationRule} from '../useEditAllocationRule'
import {
  UpdateAllocationRuleInput,
  UpdateAllocationRuleResponse,
} from '../../teacher/AssignmentTeacherTypes'

jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(),
}))

const {executeQuery} = require('@canvas/graphql')
const mockExecuteQuery = executeQuery as jest.MockedFunction<typeof executeQuery>

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

describe('useEditAllocationRule', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  const mockInput: UpdateAllocationRuleInput = {
    ruleId: '1',
    assessorIds: ['2'],
    assesseeIds: ['3'],
    mustReview: false,
    reviewPermitted: true,
    appliesToAssessor: false,
    reciprocal: false,
  }

  describe('successful mutation', () => {
    it('calls onSuccess callback when mutation succeeds with allocation rules', async () => {
      const mockResponse: UpdateAllocationRuleResponse = {
        updateAllocationRule: {
          allocationRules: [
            {
              _id: '1',
              mustReview: false,
              reviewPermitted: true,
              appliesToAssessor: false,
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

      const onSuccess = jest.fn()
      const onError = jest.fn()

      const {result, waitForNextUpdate} = renderHook(
        () => useEditAllocationRule(onSuccess, onError),
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
          message: 'cannot disable required review',
          attribute: 'mustReview',
          attributeId: '1',
        },
      ]

      const mockResponse: UpdateAllocationRuleResponse = {
        updateAllocationRule: {
          allocationRules: [],
          allocationErrors: mockAllocationErrors,
        },
      }

      mockExecuteQuery.mockResolvedValueOnce(mockResponse)

      const onSuccess = jest.fn()
      const onError = jest.fn()

      const {result, waitForNextUpdate} = renderHook(
        () => useEditAllocationRule(onSuccess, onError),
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
      const mockResponse: UpdateAllocationRuleResponse = {
        updateAllocationRule: {
          allocationRules: [
            {
              _id: '1',
              mustReview: false,
              reviewPermitted: true,
              appliesToAssessor: false,
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

      const onSuccess = jest.fn()
      const onError = jest.fn()

      const {result, waitForNextUpdate} = renderHook(
        () => useEditAllocationRule(onSuccess, onError),
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
    it('calls onError callback with array containing error when mutation fails', async () => {
      const mockError = new Error('Network error')
      mockExecuteQuery.mockRejectedValueOnce(mockError)

      const onSuccess = jest.fn()
      const onError = jest.fn()

      const {result, waitForNextUpdate} = renderHook(
        () => useEditAllocationRule(onSuccess, onError),
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
