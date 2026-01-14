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
    course: {
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
  },
  {
    course: {
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
  },
]

const createWrapper = () => {
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
      <WidgetDashboardProvider>{children}</WidgetDashboardProvider>
    </QueryClientProvider>
  )
}

const server = setupServer(
  graphql.query('GetUserProgressOverview', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          _id: '123',
          enrollmentsConnection: {
            nodes: mockCourses,
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              totalCount: 2,
            },
          },
        },
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
    server.use(
      graphql.query('GetUserProgressOverview', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollmentsConnection: {
                nodes: mockCourses,
                pageInfo: {
                  hasNextPage: true,
                  hasPreviousPage: false,
                  startCursor: null,
                  endCursor: 'cursor1',
                  totalCount: 12,
                },
              },
            },
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

    expect(result.current.totalPages).toBe(3)
    expect(result.current.totalCount).toBe(12)
  })

  it('handles page navigation', async () => {
    const page1Data = {
      data: {
        legacyNode: {
          _id: '123',
          enrollmentsConnection: {
            nodes: [mockCourses[0]],
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: 'cursor1',
              totalCount: 10,
            },
          },
        },
      },
    }

    const page2Data = {
      data: {
        legacyNode: {
          _id: '123',
          enrollmentsConnection: {
            nodes: [mockCourses[1]],
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: true,
              startCursor: 'cursor1',
              endCursor: null,
              totalCount: 10,
            },
          },
        },
      },
    }

    server.use(
      graphql.query('GetUserProgressOverview', ({variables}) => {
        if (variables.after) {
          return HttpResponse.json(page2Data)
        }
        return HttpResponse.json(page1Data)
      }),
    )

    const {result} = renderHook(() => useProgressOverviewPaginated(), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.currentPageIndex).toBe(0)
    expect(result.current.data?.[0].courseId).toBe('1')

    result.current.goToPage(2)

    await waitFor(() => {
      expect(result.current.currentPageIndex).toBe(1)
    })
  })

  it('filters out courses with null submissionStatistics', async () => {
    server.use(
      graphql.query('GetUserProgressOverview', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollmentsConnection: {
                nodes: [
                  mockCourses[0],
                  {
                    course: {
                      _id: '3',
                      name: 'Course Without Stats',
                      courseCode: 'C3',
                      submissionStatistics: null,
                    },
                  },
                ],
                pageInfo: {
                  hasNextPage: false,
                  hasPreviousPage: false,
                  startCursor: null,
                  endCursor: null,
                  totalCount: 1,
                },
              },
            },
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
      graphql.query('GetUserProgressOverview', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollmentsConnection: {
                nodes: [],
                pageInfo: {
                  hasNextPage: false,
                  hasPreviousPage: false,
                  startCursor: null,
                  endCursor: null,
                  totalCount: 0,
                },
              },
            },
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

    expect(result.current.data).toHaveLength(0)
    expect(result.current.totalPages).toBe(0)
  })

  it('handles errors', async () => {
    server.use(
      graphql.query('GetUserProgressOverview', () => {
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
    const {result} = renderHook(() => useProgressOverviewPaginated(), {
      wrapper: createWrapper(),
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
