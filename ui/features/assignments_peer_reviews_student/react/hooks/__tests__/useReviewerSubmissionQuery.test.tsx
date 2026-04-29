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
import {useReviewerSubmissionQuery} from '../useReviewerSubmissionQuery'
import {REVIEWER_SUBMISSION_QUERY} from '../../queries'
import {executeQuery} from '@canvas/graphql'

vi.mock('@canvas/graphql', () => ({
  executeQuery: vi.fn(),
}))

const mockExecuteQuery = vi.mocked(executeQuery)

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

describe('useReviewerSubmissionQuery', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockExecuteQuery.mockClear()
  })

  it('initializes with loading set to true and returns submission data successfully', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      submission: {
        _id: 'sub-123',
        id: 'U3VibWlzc2lvbi0xMjM=',
        attempt: 1,
        assignedAssessments: [
          {
            assetId: 'asset-1',
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
          {
            assetId: 'asset-2',
            workflowState: 'completed',
            assetSubmissionType: 'online_text_entry',
          },
        ],
      },
    })

    const {result, waitForNextUpdate} = renderHook(
      () => useReviewerSubmissionQuery('assignment-1', 'user-1'),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
    expect(result.current.isError).toBe(false)

    await waitForNextUpdate()

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toEqual({
      _id: 'sub-123',
      id: 'U3VibWlzc2lvbi0xMjM=',
      attempt: 1,
      assignedAssessments: [
        {
          assetId: 'asset-1',
          workflowState: 'assigned',
          assetSubmissionType: 'online_text_entry',
        },
        {
          assetId: 'asset-2',
          workflowState: 'completed',
          assetSubmissionType: 'online_text_entry',
        },
      ],
    })
    expect(result.current.isError).toBe(false)
  })

  it('returns null when submission is not found', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      submission: null,
    })

    const {result, waitForNextUpdate} = renderHook(
      () => useReviewerSubmissionQuery('assignment-2', 'user-2'),
      {
        wrapper: createWrapper(),
      },
    )

    await waitForNextUpdate()

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toBeNull()
    expect(result.current.isError).toBe(false)
  })

  it('handles empty assigned assessments', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      submission: {
        _id: 'sub-456',
        id: 'U3VibWlzc2lvbi00NTY=',
        attempt: 2,
        assignedAssessments: [],
      },
    })

    const {result, waitForNextUpdate} = renderHook(
      () => useReviewerSubmissionQuery('assignment-3', 'user-3'),
      {
        wrapper: createWrapper(),
      },
    )

    await waitForNextUpdate()

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data?.assignedAssessments).toEqual([])
    expect(result.current.isError).toBe(false)
  })

  it('handles query error', async () => {
    mockExecuteQuery.mockRejectedValueOnce(new Error('Failed to fetch reviewer submission'))

    const {result, waitForNextUpdate} = renderHook(
      () => useReviewerSubmissionQuery('error-assignment', 'error-user'),
      {
        wrapper: createWrapper(),
      },
    )

    await waitForNextUpdate()

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toBeUndefined()
    expect(result.current.isError).toBe(true)
  })

  it('uses correct query key and variables', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      submission: {
        _id: 'sub-789',
        id: 'U3VibWlzc2lvbi03ODk=',
        attempt: 1,
        assignedAssessments: [],
      },
    })

    const {waitForNextUpdate} = renderHook(
      () => useReviewerSubmissionQuery('assignment-123', 'user-456'),
      {
        wrapper: createWrapper(),
      },
    )

    await waitForNextUpdate()

    expect(mockExecuteQuery).toHaveBeenCalledWith(REVIEWER_SUBMISSION_QUERY, {
      assignmentId: 'assignment-123',
      userId: 'user-456',
    })
  })

  it('does not fetch when assignmentId is empty', () => {
    const {result} = renderHook(() => useReviewerSubmissionQuery('', 'user-1'), {
      wrapper: createWrapper(),
    })

    expect(result.current.isLoading).toBe(false)
    expect(mockExecuteQuery).not.toHaveBeenCalled()
  })

  it('does not fetch when userId is empty', () => {
    const {result} = renderHook(() => useReviewerSubmissionQuery('assignment-1', ''), {
      wrapper: createWrapper(),
    })

    expect(result.current.isLoading).toBe(false)
    expect(mockExecuteQuery).not.toHaveBeenCalled()
  })

  it('handles multiple assigned assessments with different workflow states', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      submission: {
        _id: 'sub-999',
        id: 'U3VibWlzc2lvbi05OTk=',
        attempt: 3,
        assignedAssessments: [
          {
            assetId: 'asset-a',
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
          {
            assetId: 'asset-b',
            workflowState: 'completed',
            assetSubmissionType: 'online_upload',
          },
          {
            assetId: 'asset-c',
            workflowState: 'assigned',
            assetSubmissionType: null,
          },
        ],
      },
    })

    const {result, waitForNextUpdate} = renderHook(
      () => useReviewerSubmissionQuery('assignment-4', 'user-4'),
      {
        wrapper: createWrapper(),
      },
    )

    await waitForNextUpdate()

    expect(result.current.data?.assignedAssessments).toHaveLength(3)
    expect(result.current.data?.assignedAssessments?.[0].workflowState).toBe('assigned')
    expect(result.current.data?.assignedAssessments?.[1].workflowState).toBe('completed')
    expect(result.current.data?.assignedAssessments?.[2].assetSubmissionType).toBeNull()
  })
})
