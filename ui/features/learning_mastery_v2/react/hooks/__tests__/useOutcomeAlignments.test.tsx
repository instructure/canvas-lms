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

import React from 'react'
import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import fetchMock from 'fetch-mock'
import {useOutcomeAlignments} from '../useOutcomeAlignments'

describe('useOutcomeAlignments', () => {
  const courseId = '123'
  const studentId = '456'
  const assignmentId = '789'

  const mockAlignments = [
    {
      id: 1,
      learning_outcome_id: 10,
      assignment_id: 789,
      submission_types: 'online_text_entry',
      url: '/courses/123/assignments/789',
      title: 'Assignment 1',
    },
    {
      id: 2,
      learning_outcome_id: 20,
      assignment_id: 789,
      submission_types: 'online_upload',
      url: '/courses/123/assignments/789',
      title: 'Assignment 1',
    },
  ]

  const createWrapper = () => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    const Wrapper: React.FC<any> = ({children}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    )
    return Wrapper
  }

  beforeEach(() => {
    fetchMock.restore()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  describe('successful data fetching', () => {
    it('fetches and returns outcome alignments with studentId and assignmentId', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        mockAlignments,
      )

      const {result} = renderHook(
        () => useOutcomeAlignments({courseId, studentId, assignmentId, enabled: true}),
        {
          wrapper: createWrapper(),
        },
      )

      expect(result.current.isLoading).toBe(true)
      expect(result.current.data).toBeUndefined()

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(result.current.data).toEqual(mockAlignments)
      expect(result.current.isLoading).toBe(false)
      expect(result.current.error).toBeNull()
    })

    it('fetches with only studentId', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}`,
        mockAlignments,
      )

      const {result} = renderHook(() => useOutcomeAlignments({courseId, studentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(result.current.data).toEqual(mockAlignments)
    })

    it('fetches with only assignmentId', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?assignment_id=${assignmentId}`,
        mockAlignments,
      )

      const {result} = renderHook(() => useOutcomeAlignments({courseId, assignmentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(result.current.data).toEqual(mockAlignments)
    })

    it('returns alignment details correctly', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        mockAlignments,
      )

      const {result} = renderHook(() => useOutcomeAlignments({courseId, studentId, assignmentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.data).toHaveLength(2)
        expect(result.current.data?.[0].learning_outcome_id).toBe(10)
        expect(result.current.data?.[0].assignment_id).toBe(789)
        expect(result.current.data?.[1].learning_outcome_id).toBe(20)
      })
    })

    it('handles empty alignments array', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        [],
      )

      const {result} = renderHook(() => useOutcomeAlignments({courseId, studentId, assignmentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.data).toEqual([])
      })
    })
  })

  describe('error handling', () => {
    it('handles 404 error', async () => {
      fetchMock.get(`/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}`, {
        status: 404,
        body: {error: 'Not found'},
      })

      const {result} = renderHook(() => useOutcomeAlignments({courseId, studentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isError).toBe(true)
      })

      expect(result.current.error).toBeTruthy()
      expect(result.current.data).toBeUndefined()
    })

    it('handles 500 server error', async () => {
      fetchMock.get(`/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}`, {
        status: 500,
        body: {error: 'Internal server error'},
      })

      const {result} = renderHook(() => useOutcomeAlignments({courseId, studentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isError).toBe(true)
      })

      expect(result.current.error).toBeTruthy()
      expect(result.current.data).toBeUndefined()
    })

    it('handles network error', async () => {
      fetchMock.get(`/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}`, {
        throws: new Error('Network error'),
      })

      const {result} = renderHook(() => useOutcomeAlignments({courseId, studentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isError).toBe(true)
      })

      expect(result.current.error).toBeTruthy()
    })
  })

  describe('enabled parameter', () => {
    it('does not fetch when enabled is false', async () => {
      fetchMock.get(/.*/, mockAlignments)

      const {result} = renderHook(
        () => useOutcomeAlignments({courseId, studentId, enabled: false}),
        {
          wrapper: createWrapper(),
        },
      )

      // Query should be disabled immediately
      expect(result.current.isLoading).toBe(false)
      expect(result.current.isFetching).toBe(false)

      // Wait to ensure stable state
      await waitFor(() => {
        expect(result.current.data).toBeUndefined()
      })

      expect(fetchMock.calls()).toHaveLength(0)
    })

    it('fetches when enabled changes from false to true', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}`,
        mockAlignments,
      )

      const {result, rerender} = renderHook(
        ({enabled}: {enabled: boolean}) => useOutcomeAlignments({courseId, studentId, enabled}),
        {
          wrapper: createWrapper(),
          initialProps: {enabled: false},
        },
      )

      expect(fetchMock.calls()).toHaveLength(0)

      rerender({enabled: true})

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(fetchMock.calls()).toHaveLength(1)
      expect(result.current.data).toEqual(mockAlignments)
    })

    it('does not fetch when courseId is missing', async () => {
      fetchMock.get(/.*/, mockAlignments)

      const {result} = renderHook(() => useOutcomeAlignments({courseId: '', studentId}), {
        wrapper: createWrapper(),
      })

      // Query should be disabled immediately when courseId is empty
      expect(result.current.isLoading).toBe(false)

      // Wait to ensure stable state
      await waitFor(() => {
        expect(result.current.data).toBeUndefined()
      })

      expect(fetchMock.calls()).toHaveLength(0)
    })

    it('does not fetch when both studentId and assignmentId are missing', async () => {
      fetchMock.get(/.*/, mockAlignments)

      const {result} = renderHook(() => useOutcomeAlignments({courseId}), {
        wrapper: createWrapper(),
      })

      // Query should be disabled immediately when both IDs are missing
      expect(result.current.isLoading).toBe(false)

      // Wait to ensure stable state
      await waitFor(() => {
        expect(result.current.data).toBeUndefined()
      })

      expect(fetchMock.calls()).toHaveLength(0)
    })
  })

  describe('caching behavior', () => {
    it('uses different cache keys for different students', async () => {
      const student1Id = '111'
      const student2Id = '222'

      fetchMock.get(`/api/v1/courses/${courseId}/outcome_alignments?student_id=${student1Id}`, [
        {...mockAlignments[0], learning_outcome_id: 100},
      ])
      fetchMock.get(`/api/v1/courses/${courseId}/outcome_alignments?student_id=${student2Id}`, [
        {...mockAlignments[0], learning_outcome_id: 200},
      ])

      const wrapper = createWrapper()

      const {result: result1} = renderHook(
        () => useOutcomeAlignments({courseId, studentId: student1Id}),
        {wrapper},
      )

      await waitFor(() => {
        expect(result1.current.data?.[0].learning_outcome_id).toBe(100)
      })

      const {result: result2} = renderHook(
        () => useOutcomeAlignments({courseId, studentId: student2Id}),
        {wrapper},
      )

      await waitFor(() => {
        expect(result2.current.data?.[0].learning_outcome_id).toBe(200)
      })

      expect(fetchMock.calls()).toHaveLength(2)
    })

    it('uses different cache keys for different assignments', async () => {
      const assignment1Id = '100'
      const assignment2Id = '200'

      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignment1Id}`,
        [{...mockAlignments[0], assignment_id: 100}],
      )
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignment2Id}`,
        [{...mockAlignments[0], assignment_id: 200}],
      )

      const wrapper = createWrapper()

      const {result: result1} = renderHook(
        () => useOutcomeAlignments({courseId, studentId, assignmentId: assignment1Id}),
        {wrapper},
      )

      await waitFor(() => {
        expect(result1.current.data?.[0].assignment_id).toBe(100)
      })

      const {result: result2} = renderHook(
        () => useOutcomeAlignments({courseId, studentId, assignmentId: assignment2Id}),
        {wrapper},
      )

      await waitFor(() => {
        expect(result2.current.data?.[0].assignment_id).toBe(200)
      })

      expect(fetchMock.calls()).toHaveLength(2)
    })
  })

  describe('query string construction', () => {
    it('constructs query string with both studentId and assignmentId', async () => {
      fetchMock.get(/.*/, mockAlignments)

      const {result} = renderHook(() => useOutcomeAlignments({courseId, studentId, assignmentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      const calls = fetchMock.calls()
      expect(calls[0][0]).toContain('student_id=456')
      expect(calls[0][0]).toContain('assignment_id=789')
    })

    it('constructs query string with only studentId', async () => {
      fetchMock.get(/.*/, mockAlignments)

      const {result} = renderHook(() => useOutcomeAlignments({courseId, studentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      const calls = fetchMock.calls()
      expect(calls[0][0]).toContain('student_id=456')
      expect(calls[0][0]).not.toContain('assignment_id')
    })
  })

  describe('default parameters', () => {
    it('uses enabled=true by default when conditions are met', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}`,
        mockAlignments,
      )

      const {result} = renderHook(() => useOutcomeAlignments({courseId, studentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(fetchMock.calls()).toHaveLength(1)
      expect(result.current.data).toEqual(mockAlignments)
    })
  })
})
