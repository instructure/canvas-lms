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
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {useProgressOverviewPaginated} from '../useProgressOverview'
import {WidgetDashboardProvider} from '../useWidgetDashboardContext'
import {clearWidgetDashboardCache} from '../../__tests__/testHelpers'

const mockCourses = [
  {
    _id: '1',
    name: 'Course 1',
    courseCode: 'C1',
    submissionStatistics: {
      submittedAndGradedCount: 5,
      submittedNotGradedCount: 2,
      missingSubmissionsCount: 1,
      submissionsDueCount: 3,
    },
  },
  {
    _id: '2',
    name: 'Course 2',
    courseCode: 'C2',
    submissionStatistics: {
      submittedAndGradedCount: 3,
      submittedNotGradedCount: 1,
      missingSubmissionsCount: 2,
      submissionsDueCount: 4,
    },
  },
]

const mockSharedCourseData = [
  {
    courseId: '1',
    courseCode: 'C1',
    courseName: 'Course 1',
    currentGrade: 85,
    gradingScheme: 'percentage' as const,
    lastUpdated: '2025-01-01T00:00:00Z',
  },
  {
    courseId: '2',
    courseCode: 'C2',
    courseName: 'Course 2',
    currentGrade: 90,
    gradingScheme: 'percentage' as const,
    lastUpdated: '2025-01-02T00:00:00Z',
  },
]

const createWrapper = (sharedCourseData = mockSharedCourseData) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider sharedCourseData={sharedCourseData}>
        {children}
      </WidgetDashboardProvider>
    </QueryClientProvider>
  )
}

const server = setupServer(
  graphql.query('GetProgressOverview', () => {
    return HttpResponse.json({
      data: {
        courses: mockCourses,
      },
    })
  }),
)

beforeAll(() => {
  server.listen()
  window.ENV = {
    ...window.ENV,
    current_user_id: '123',
  }
})

afterEach(() => {
  server.resetHandlers()
  clearWidgetDashboardCache()
})

afterAll(() => server.close())

describe('useProgressOverviewPaginated', () => {
  it('fetches and returns paginated course data', async () => {
    const {result} = renderHook(() => useProgressOverviewPaginated(), {
      wrapper: createWrapper(),
    })

    expect(result.current.isLoading).toBe(true)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.data).toHaveLength(2)
    expect(result.current.data?.[0].courseId).toBe('1')
    expect(result.current.data?.[1].courseId).toBe('2')
  })

  it('calculates total pages correctly', async () => {
    // Create 12 mock courses
    const manyCourses = Array.from({length: 12}, (_, i) => ({
      _id: `${i + 1}`,
      name: `Course ${i + 1}`,
      courseCode: `C${i + 1}`,
      submissionStatistics: {
        submittedAndGradedCount: 5,
        submittedNotGradedCount: 2,
        missingSubmissionsCount: 1,
        submissionsDueCount: 3,
      },
    }))

    const manySharedCourses = Array.from({length: 12}, (_, i) => ({
      courseId: `${i + 1}`,
      courseCode: `C${i + 1}`,
      courseName: `Course ${i + 1}`,
      currentGrade: 85,
      gradingScheme: 'percentage' as const,
      lastUpdated: '2025-01-01T00:00:00Z',
    }))

    server.use(
      graphql.query('GetProgressOverview', () => {
        return HttpResponse.json({
          data: {
            courses: manyCourses,
          },
        })
      }),
    )

    const {result} = renderHook(() => useProgressOverviewPaginated(), {
      wrapper: createWrapper(manySharedCourses),
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.totalPages).toBe(3)
    expect(result.current.totalCount).toBe(12)
  })

  it('handles page navigation', async () => {
    const tenCourses = Array.from({length: 10}, (_, i) => ({
      _id: `${i + 1}`,
      name: `Course ${i + 1}`,
      courseCode: `C${i + 1}`,
      submissionStatistics: {
        submittedAndGradedCount: 5,
        submittedNotGradedCount: 2,
        missingSubmissionsCount: 1,
        submissionsDueCount: 3,
      },
    }))

    const tenSharedCourses = Array.from({length: 10}, (_, i) => ({
      courseId: `${i + 1}`,
      courseCode: `C${i + 1}`,
      courseName: `Course ${i + 1}`,
      currentGrade: 85,
      gradingScheme: 'percentage' as const,
      lastUpdated: '2025-01-01T00:00:00Z',
    }))

    server.use(
      graphql.query('GetProgressOverview', () => {
        return HttpResponse.json({
          data: {
            courses: tenCourses,
          },
        })
      }),
    )

    const {result} = renderHook(() => useProgressOverviewPaginated(), {
      wrapper: createWrapper(tenSharedCourses),
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.currentPageIndex).toBe(0)
    expect(result.current.data?.[0].courseId).toBe('1')
    expect(result.current.data).toHaveLength(5)

    result.current.goToPage(2)

    await waitFor(() => {
      expect(result.current.currentPageIndex).toBe(1)
    })

    expect(result.current.data?.[0].courseId).toBe('6')
    expect(result.current.data).toHaveLength(5)
  })

  it('filters out courses with null submissionStatistics', async () => {
    server.use(
      graphql.query('GetProgressOverview', () => {
        return HttpResponse.json({
          data: {
            courses: [
              mockCourses[0],
              {
                _id: '3',
                name: 'Course Without Stats',
                courseCode: 'C3',
                submissionStatistics: null,
              },
            ],
          },
        })
      }),
    )

    const {result} = renderHook(() => useProgressOverviewPaginated(), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.data).toHaveLength(1)
    expect(result.current.data?.[0].courseId).toBe('1')
  })

  it('handles empty results', async () => {
    server.use(
      graphql.query('GetProgressOverview', () => {
        return HttpResponse.json({
          data: {
            courses: [],
          },
        })
      }),
    )

    const {result} = renderHook(() => useProgressOverviewPaginated(), {
      wrapper: createWrapper([]),
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.data).toHaveLength(0)
    expect(result.current.totalPages).toBe(0)
  })

  it('handles errors', async () => {
    server.use(
      graphql.query('GetProgressOverview', () => {
        return HttpResponse.json({errors: [{message: 'Failed to fetch'}]}, {status: 500})
      }),
    )

    const {result} = renderHook(() => useProgressOverviewPaginated(), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.error).toBeTruthy()
    })

    expect(result.current.isLoading).toBe(false)
  })

  it('resets pagination correctly', async () => {
    // Create 10 courses so we have multiple pages to navigate
    const tenCourses = Array.from({length: 10}, (_, i) => ({
      _id: `${i + 1}`,
      name: `Course ${i + 1}`,
      courseCode: `C${i + 1}`,
      submissionStatistics: {
        submittedAndGradedCount: 5,
        submittedNotGradedCount: 2,
        missingSubmissionsCount: 1,
        submissionsDueCount: 3,
      },
    }))

    const tenSharedCourses = Array.from({length: 10}, (_, i) => ({
      courseId: `${i + 1}`,
      courseCode: `C${i + 1}`,
      courseName: `Course ${i + 1}`,
      currentGrade: 85,
      gradingScheme: 'percentage' as const,
      lastUpdated: '2025-01-01T00:00:00Z',
    }))

    server.use(
      graphql.query('GetProgressOverview', () => {
        return HttpResponse.json({
          data: {
            courses: tenCourses,
          },
        })
      }),
    )

    const {result} = renderHook(() => useProgressOverviewPaginated(), {
      wrapper: createWrapper(tenSharedCourses),
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    result.current.goToPage(2)

    await waitFor(() => {
      expect(result.current.currentPageIndex).toBe(1)
    })

    result.current.resetPagination()

    expect(result.current.currentPageIndex).toBe(0)
  })
})
