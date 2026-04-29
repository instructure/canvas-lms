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
import {useDeleteAllocationRule} from '../useDeleteAllocationRule'
import {
  DeleteAllocationRuleInput,
  DeleteAllocationRuleResponse,
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

describe('useDeleteAllocationRule', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  const mockInput: DeleteAllocationRuleInput = {
    ruleId: '1',
  }

  describe('successful mutation', () => {
    it('calls onSuccess callback when mutation succeeds', async () => {
      const mockResponse: DeleteAllocationRuleResponse = {
        deleteAllocationRule: {
          allocationRuleId: '1',
        },
      }

      mockExecuteQuery.mockResolvedValueOnce(mockResponse)

      const onSuccess = vi.fn()
      const onError = vi.fn()

      const {result, waitForNextUpdate} = renderHook(
        () => useDeleteAllocationRule(onSuccess, onError),
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
    it('calls onError when the mutation returns an error', async () => {
      const mockError = new Error('Allocation rule not found')
      mockExecuteQuery.mockRejectedValueOnce(mockError)

      const onSuccess = vi.fn()
      const onError = vi.fn()

      const {result, waitForNextUpdate} = renderHook(
        () => useDeleteAllocationRule(onSuccess, onError),
        {
          wrapper: createWrapper(),
        },
      )

      result.current.mutate({ruleId: 'nonexistent'})

      await waitForNextUpdate()

      expect(result.current.isError).toBe(true)
      expect(onError).toHaveBeenCalledWith(mockError)
      expect(onSuccess).not.toHaveBeenCalled()
    })
  })
})
