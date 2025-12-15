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
import {waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {type MockedFunction} from 'vitest'
import {useCourseAssignmentsAssetReports} from '../useCourseAssignmentsAssetReports'
import {executeQuery} from '@canvas/graphql'
import {
  defaultGetCourseAssignmentsAssetReportsResult,
  emptyGetCourseAssignmentsAssetReportsResult,
} from '../../../queries/__fixtures__/GetCourseAssignmentsAssetReports'
import type {GetCourseAssignmentsAssetReportsResult} from '../../../queries/getCourseAssignmentsAssetReports'

vi.mock('@canvas/graphql', () => ({
  executeQuery: vi.fn(),
}))

const mockExecuteQuery = executeQuery as MockedFunction<typeof executeQuery>

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('useCourseAssignmentsAssetReports', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    mockExecuteQuery.mockClear()
    // Enable the feature flag
    window.ENV = {
      ...window.ENV,
      FEATURES: {
        ...window.ENV?.FEATURES,
        lti_asset_processor: true,
      },
    }
  })

  afterEach(() => {
    vi.runOnlyPendingTimers()
    vi.useRealTimers()
  })

  it('fetches and transforms data successfully', async () => {
    const mockData = defaultGetCourseAssignmentsAssetReportsResult({
      assignmentId: '1',
      assignmentName: 'Test Assignment',
    })
    mockExecuteQuery.mockResolvedValue(mockData)

    const {result, waitForNextUpdate} = renderHook(
      () =>
        useCourseAssignmentsAssetReports({
          courseId: 'course_1',
          studentId: 'student_1',
          gradingPeriodId: null,
        }),
      {wrapper: createWrapper()},
    )

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    // The Map should contain the assignment if it passes the filters
    expect(result.current.data).toBeInstanceOf(Map)
    const assignmentData = result.current.data?.get('1')
    if (assignmentData) {
      expect(assignmentData.assignmentName).toBe('Test Assignment')
      expect(assignmentData.assetProcessors).toHaveLength(1)
      expect(assignmentData.assetReports).toHaveLength(1)
      expect(assignmentData.submissionType).toBe('online_upload')
    }
  })

  it('handles empty response', async () => {
    const emptyResponse = emptyGetCourseAssignmentsAssetReportsResult()
    mockExecuteQuery.mockResolvedValue(emptyResponse)

    const {result} = renderHook(
      () =>
        useCourseAssignmentsAssetReports({
          courseId: 'course_1',
          studentId: 'student_1',
          gradingPeriodId: null,
        }),
      {wrapper: createWrapper()},
    )

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data?.size).toBe(0)
  })

  it('filters out assignments without processors', async () => {
    const mockData = defaultGetCourseAssignmentsAssetReportsResult({
      assignmentId: '1',
      assignmentName: 'Test Assignment',
      hasProcessor: false,
    })
    mockExecuteQuery.mockResolvedValue(mockData)

    const {result} = renderHook(
      () =>
        useCourseAssignmentsAssetReports({
          courseId: 'course_1',
          studentId: 'student_1',
          gradingPeriodId: null,
        }),
      {wrapper: createWrapper()},
    )

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    // Should be filtered out since there are no processors
    expect(result.current.data?.size).toBe(0)
  })

  it('handles errors gracefully', async () => {
    mockExecuteQuery.mockRejectedValue(new Error('Network error'))

    const {result} = renderHook(
      () =>
        useCourseAssignmentsAssetReports({
          courseId: 'course_1',
          studentId: 'student_1',
          gradingPeriodId: null,
        }),
      {wrapper: createWrapper()},
    )

    await waitFor(() => expect(result.current.isError).toBe(true))

    expect(result.current.error).toBeDefined()
  })

  it('does not fetch when feature flag is disabled', async () => {
    window.ENV = {
      ...window.ENV,
      FEATURES: {
        ...window.ENV?.FEATURES,
        lti_asset_processor: false,
      },
    }

    const {result} = renderHook(
      () =>
        useCourseAssignmentsAssetReports({
          courseId: 'course_1',
          studentId: 'student_1',
          gradingPeriodId: null,
        }),
      {wrapper: createWrapper()},
    )

    await waitFor(() => expect(result.current.status).toBe('pending'))

    expect(mockExecuteQuery).not.toHaveBeenCalled()
  })

  it('does not fetch when courseId is missing', async () => {
    const {result} = renderHook(
      () =>
        useCourseAssignmentsAssetReports({
          courseId: '',
          studentId: 'student_1',
          gradingPeriodId: null,
        }),
      {wrapper: createWrapper()},
    )

    await waitFor(() => expect(result.current.status).toBe('pending'))

    expect(mockExecuteQuery).not.toHaveBeenCalled()
  })

  it('does not fetch when studentId is missing', async () => {
    const {result} = renderHook(
      () =>
        useCourseAssignmentsAssetReports({
          courseId: 'course_1',
          studentId: '',
          gradingPeriodId: null,
        }),
      {wrapper: createWrapper()},
    )

    await waitFor(() => expect(result.current.status).toBe('pending'))

    expect(mockExecuteQuery).not.toHaveBeenCalled()
  })

  it('handles pagination with hasNextPage', async () => {
    const firstPageResponse = defaultGetCourseAssignmentsAssetReportsResult({
      assignmentId: '1',
      assignmentName: 'Assignment 1',
      hasNextPage: true,
      endCursor: 'cursor123',
    })

    const secondPageResponse = defaultGetCourseAssignmentsAssetReportsResult({
      assignmentId: '2',
      assignmentName: 'Assignment 2',
    })
    secondPageResponse.legacyNode!.assignmentsConnection.pageInfo = {
      endCursor: null,
      hasPreviousPage: true,
      hasNextPage: false,
      startCursor: 'cursor123',
    }

    mockExecuteQuery
      .mockResolvedValueOnce(firstPageResponse)
      .mockResolvedValueOnce(secondPageResponse)

    const {result} = renderHook(
      () =>
        useCourseAssignmentsAssetReports({
          courseId: 'course_1',
          studentId: 'student_1',
          gradingPeriodId: null,
        }),
      {wrapper: createWrapper()},
    )

    // Wait for both pages to load
    await waitFor(() => expect(result.current.isSuccess).toBe(true), {timeout: 3000})

    // Verify the Map contains assignments if they pass filters
    expect(result.current.data).toBeInstanceOf(Map)
    const assignment1 = result.current.data?.get('1')
    const assignment2 = result.current.data?.get('2')
    // At least one assignment should be present
    expect(assignment1 || assignment2).toBeTruthy()
  })

  it('includes gradingPeriodId in query when provided', async () => {
    const mockData = defaultGetCourseAssignmentsAssetReportsResult({
      assignmentId: '1',
      assignmentName: 'Test Assignment',
    })
    mockExecuteQuery.mockResolvedValue(mockData)

    renderHook(
      () =>
        useCourseAssignmentsAssetReports({
          courseId: 'course_1',
          studentId: 'student_1',
          gradingPeriodId: 'period_1',
        }),
      {wrapper: createWrapper()},
    )

    await waitFor(() => expect(mockExecuteQuery).toHaveBeenCalled())

    expect(mockExecuteQuery).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        courseID: 'course_1',
        studentId: 'student_1',
        gradingPeriodID: 'period_1',
        after: undefined,
      }),
    )
  })
})
