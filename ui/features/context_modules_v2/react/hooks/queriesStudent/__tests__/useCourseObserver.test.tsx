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

import {useCourseObserver} from '../useCourseObserver'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'

const mockObservedStudent = {id: '101', name: 'Alice Student'}

const mockCourseObserverData = {
  name: 'Observer Course',
  submissionStatistics: {
    missingSubmissionsCount: 8,
    submissionsDueThisWeekCount: 15,
  },
  settings: {
    showStudentOnlyModuleId: 'mod_obs_1',
  },
}

const mockGqlResponse = {
  legacyNode: {
    name: mockCourseObserverData.name,
    submissionStatistics: mockCourseObserverData.submissionStatistics,
    settings: mockCourseObserverData.settings,
  },
}

const courseId = '123'
const errorMsg = 'Observer test error'
const queryClient = new QueryClient({defaultOptions: {queries: {retry: false}}})

const renderUseCourseObserverHook = (
  courseId: string,
  observedStudent: {id: string; name: string} | null = null,
) =>
  renderHook(() => useCourseObserver(courseId, observedStudent), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    ),
  })

const server = setupServer()

describe('useCourseObserver', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })
  afterAll(() => server.close())

  it('should be in error state if gql query throws exception', async () => {
    server.use(
      graphql.query('GetCourseStudentQuery', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    const {result} = renderUseCourseObserverHook(courseId, mockObservedStudent)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.error?.message).toContain(errorMsg)
    })
  })

  it('should map the observer data correctly for successful response', async () => {
    server.use(
      graphql.query('GetCourseStudentQuery', ({variables}) => {
        expect(variables.courseId).toBe(courseId)
        return HttpResponse.json({
          data: {legacyNode: mockGqlResponse.legacyNode},
        })
      }),
    )

    const {result} = renderUseCourseObserverHook(courseId, mockObservedStudent)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.courseData).toEqual(mockCourseObserverData)
      expect(result.current.observedStudent).toEqual(mockObservedStudent)
    })
  })

  it('should handle single observed student', async () => {
    const singleStudent = {id: '101', name: 'Alice Student'}

    server.use(
      graphql.query('GetCourseStudentQuery', () => {
        return HttpResponse.json({
          data: {legacyNode: mockGqlResponse.legacyNode},
        })
      }),
    )

    const {result} = renderUseCourseObserverHook(courseId, singleStudent)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.observedStudent).toEqual(singleStudent)
    })
  })

  it('should handle null observed student', async () => {
    const {result} = renderUseCourseObserverHook(courseId, null)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.observedStudent).toBeNull()
      expect(result.current.courseData).toBeUndefined()
    })
  })

  it('should handle undefined data in the response', async () => {
    server.use(
      graphql.query('GetCourseStudentQuery', () => {
        return HttpResponse.json({
          data: {legacyNode: null},
        })
      }),
    )

    const {result} = renderUseCourseObserverHook(courseId, mockObservedStudent)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.courseData).toEqual({
        name: undefined,
        submissionStatistics: undefined,
        settings: undefined,
      })
    })
  })

  it('should not make request when courseId is empty', async () => {
    const {result} = renderUseCourseObserverHook('', mockObservedStudent)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.courseData).toBeUndefined()
    })
  })

  it('should not make request when observed student is null', async () => {
    const {result} = renderUseCourseObserverHook(courseId, null)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.courseData).toBeUndefined()
    })
  })

  it('should handle response when missing submissions data', async () => {
    const dataWithoutStats = {
      name: 'Observer Course',
      submissionStatistics: null,
      settings: {showStudentOnlyModuleId: 'mod_1'},
    }

    server.use(
      graphql.query('GetCourseStudentQuery', () => {
        return HttpResponse.json({
          data: {legacyNode: dataWithoutStats},
        })
      }),
    )

    const {result} = renderUseCourseObserverHook(courseId, mockObservedStudent)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.courseData?.submissionStatistics).toBeNull()
    })
  })
})
