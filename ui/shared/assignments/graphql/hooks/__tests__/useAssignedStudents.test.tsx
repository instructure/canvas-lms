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
import {useAssignedStudents} from '../useAssignedStudents'
import {ASSIGNED_STUDENTS_QUERY} from '../../teacher/Queries'
import {CourseStudent} from '../../teacher/AssignmentTeacherTypes'
import {executeQuery} from '@canvas/graphql'

vi.mock('@canvas/graphql', () => ({
  executeQuery: vi.fn(),
}))

const mockExecuteQuery = vi.mocked(executeQuery)

const mockAssignedStudents: CourseStudent[] = [
  {_id: '1', name: 'Squirtle', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
  {_id: '2', name: 'Mudkip', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
  {_id: '3', name: 'Dragonite', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
]

const mockCourseStudents: CourseStudent[] = [
  {_id: '1', name: 'Squirtle', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
  {_id: '2', name: 'Mudkip', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
  {_id: '3', name: 'Dragonite', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
  {_id: '4', name: 'Snorlax', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
  {_id: '5', name: 'Psyduck', peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0}},
]

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

describe('useAssignedStudents', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('with assignmentId', () => {
    it('initializes with loading set to true and returns assigned students successfully', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: mockAssignedStudents,
          },
        },
      })

      const {result, waitForNextUpdate} = renderHook(
        () => useAssignedStudents('assignment-123', ''),
        {
          wrapper: createWrapper(),
        },
      )

      expect(result.current.loading).toBe(true)
      expect(result.current.students).toEqual([])
      expect(result.current.error).toBe(null)

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.students).toEqual(mockAssignedStudents)
      expect(result.current.error).toBe(null)
    })

    it('returns filtered assigned students with search term', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: [mockAssignedStudents[0]],
          },
        },
      })

      const {result, waitForNextUpdate} = renderHook(
        () => useAssignedStudents('assignment-123', 'Squirtle'),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.students).toEqual([mockAssignedStudents[0]])
      expect(result.current.error).toBe(null)
    })

    it('handles assigned students query error', async () => {
      mockExecuteQuery.mockRejectedValueOnce(new Error('Assignment not found'))

      const {result, waitForNextUpdate} = renderHook(
        () => useAssignedStudents('assignment-error', ''),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.students).toEqual([])
      expect(result.current.error).toBeTruthy()
      expect(result.current.error?.message).toBe('Assignment not found')
    })

    it('returns empty array when no assigned students found', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: [],
          },
        },
      })

      const {result, waitForNextUpdate} = renderHook(
        () => useAssignedStudents('assignment-empty', ''),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.students).toEqual([])
      expect(result.current.error).toBe(null)
    })
  })

  describe('with no assignmentId', () => {
    it('returns empty state without making any queries', () => {
      const {result} = renderHook(() => useAssignedStudents('', ''), {
        wrapper: createWrapper(),
      })

      expect(result.current.loading).toBe(false)
      expect(result.current.students).toEqual([])
      expect(result.current.error).toBe(null)
    })
  })

  describe('search term handling', () => {
    it('passes undefined for empty search term', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: mockAssignedStudents,
          },
        },
      })

      const {result, waitForNextUpdate} = renderHook(
        () => useAssignedStudents('assignment-123', ''),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.students).toEqual(mockAssignedStudents)
      expect(result.current.error).toBe(null)
    })

    it('passes search term when provided', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: [mockAssignedStudents[0]],
          },
        },
      })

      const {result, waitForNextUpdate} = renderHook(
        () => useAssignedStudents('assignment-123', 'Squirtle'),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.students).toEqual([mockAssignedStudents[0]])
      expect(result.current.error).toBe(null)
    })

    it('handles whitespace-only search term as undefined', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          assignedStudents: {
            nodes: mockAssignedStudents,
          },
        },
      })

      const {result, waitForNextUpdate} = renderHook(
        () => useAssignedStudents('assignment-123', '   '),
        {
          wrapper: createWrapper(),
        },
      )

      await waitForNextUpdate()

      expect(result.current.loading).toBe(false)
      expect(result.current.students).toEqual(mockAssignedStudents)
      expect(result.current.error).toBe(null)

      // Verify that searchTerm was passed as undefined due to whitespace trimming
      expect(mockExecuteQuery).toHaveBeenCalledWith(ASSIGNED_STUDENTS_QUERY, {
        assignmentId: 'assignment-123',
        filter: {
          searchTerm: undefined,
        },
      })
    })
  })
})
