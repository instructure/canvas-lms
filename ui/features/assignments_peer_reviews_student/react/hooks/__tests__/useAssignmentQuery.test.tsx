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
import {useAssignmentQuery} from '../useAssignmentQuery'
import {PEER_REVIEW_ASSIGNMENT_QUERY} from '../../queries'

jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(),
}))

const {executeQuery} = require('@canvas/graphql')
const mockExecuteQuery = executeQuery as jest.MockedFunction<typeof executeQuery>

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

describe('useAssignmentQuery', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('initializes with loading set to true and returns assignment data successfully', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '1',
        name: 'Peer Review Assignment',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>Assignment description</p>',
        courseId: '100',
        peerReviews: {
          count: 2,
        },
        assessmentRequestsForCurrentUser: [
          {
            _id: 'ar-1',
            available: true,
            workflowState: 'assigned',
            createdAt: '2025-11-01T00:00:00Z',
          },
          {
            _id: 'ar-2',
            available: true,
            workflowState: 'assigned',
            createdAt: '2025-11-02T00:00:00Z',
          },
        ],
      },
    })

    const {result, waitForNextUpdate} = renderHook(() => useAssignmentQuery('1'), {
      wrapper: createWrapper(),
    })

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
    expect(result.current.isError).toBe(false)

    await waitForNextUpdate()

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data?.assignment).toEqual({
      _id: '1',
      name: 'Peer Review Assignment',
      dueAt: '2025-12-31T23:59:59Z',
      description: '<p>Assignment description</p>',
      courseId: '100',
      peerReviews: {
        count: 2,
      },
      assessmentRequestsForCurrentUser: [
        {
          _id: 'ar-1',
          available: true,
          workflowState: 'assigned',
          createdAt: '2025-11-01T00:00:00Z',
        },
        {
          _id: 'ar-2',
          available: true,
          workflowState: 'assigned',
          createdAt: '2025-11-02T00:00:00Z',
        },
      ],
    })
    expect(result.current.isError).toBe(false)
  })

  it('handles assignment with no due date', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '2',
        name: 'Assignment Without Due Date',
        dueAt: null,
        description: '<p>Description here</p>',
        courseId: '100',
        peerReviews: {
          count: 1,
        },
        assessmentRequestsForCurrentUser: [],
      },
    })

    const {result, waitForNextUpdate} = renderHook(() => useAssignmentQuery('2'), {
      wrapper: createWrapper(),
    })

    await waitForNextUpdate()

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data?.assignment.dueAt).toBeNull()
    expect(result.current.data?.assignment.name).toBe('Assignment Without Due Date')
    expect(result.current.isError).toBe(false)
  })

  it('handles assignment with no description', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '3',
        name: 'Assignment Without Description',
        dueAt: '2025-12-31T23:59:59Z',
        description: null,
        courseId: '100',
        peerReviews: {
          count: 3,
        },
        assessmentRequestsForCurrentUser: null,
      },
    })

    const {result, waitForNextUpdate} = renderHook(() => useAssignmentQuery('3'), {
      wrapper: createWrapper(),
    })

    await waitForNextUpdate()

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data?.assignment.description).toBeNull()
    expect(result.current.data?.assignment.name).toBe('Assignment Without Description')
    expect(result.current.isError).toBe(false)
  })

  it('handles query error', async () => {
    mockExecuteQuery.mockRejectedValueOnce(new Error('Failed to fetch assignment'))

    const {result, waitForNextUpdate} = renderHook(() => useAssignmentQuery('error-id'), {
      wrapper: createWrapper(),
    })

    await waitForNextUpdate()

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toBeUndefined()
    expect(result.current.isError).toBe(true)
  })

  it('uses correct query key and variables', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '123',
        name: 'Test Assignment',
        dueAt: null,
        description: null,
        courseId: '100',
        peerReviews: {
          count: 2,
        },
        assessmentRequestsForCurrentUser: [],
      },
    })

    const {waitForNextUpdate} = renderHook(() => useAssignmentQuery('123'), {
      wrapper: createWrapper(),
    })

    await waitForNextUpdate()

    expect(mockExecuteQuery).toHaveBeenCalledWith(PEER_REVIEW_ASSIGNMENT_QUERY, {
      assignmentId: '123',
    })
  })

  describe('Submission data', () => {
    it('returns submission data with text entry fields', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '4',
          name: 'Assignment With Text Submission',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-01T00:00:00Z',
              submission: {
                _id: 'sub-1',
                attempt: 1,
                body: '<p>This is the student submission text</p>',
                submissionType: 'online_text_entry',
              },
            },
          ],
        },
      })

      const {result, waitForNextUpdate} = renderHook(() => useAssignmentQuery('4'), {
        wrapper: createWrapper(),
      })

      await waitForNextUpdate()

      expect(
        result.current.data?.assignment.assessmentRequestsForCurrentUser?.[0].submission,
      ).toEqual({
        _id: 'sub-1',
        attempt: 1,
        body: '<p>This is the student submission text</p>',
        submissionType: 'online_text_entry',
      })
    })

    it('returns multiple assessment requests with their submissions', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '6',
          name: 'Multiple Peer Reviews',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-01T00:00:00Z',
              submission: {
                _id: 'sub-1',
                attempt: 1,
                body: '<p>First submission</p>',
                submissionType: 'online_text_entry',
              },
            },
            {
              _id: 'ar-2',
              available: true,
              workflowState: 'completed',
              createdAt: '2025-11-02T00:00:00Z',
              submission: {
                _id: 'sub-2',
                attempt: 2,
                body: '<p>Second submission</p>',
                submissionType: 'online_text_entry',
              },
            },
          ],
        },
      })

      const {result, waitForNextUpdate} = renderHook(() => useAssignmentQuery('6'), {
        wrapper: createWrapper(),
      })

      await waitForNextUpdate()

      const assessmentRequests = result.current.data?.assignment.assessmentRequestsForCurrentUser
      expect(assessmentRequests).toHaveLength(2)
      expect(assessmentRequests?.[0].submission?.body).toBe('<p>First submission</p>')
      expect(assessmentRequests?.[1].submission?.body).toBe('<p>Second submission</p>')
    })
  })
})
