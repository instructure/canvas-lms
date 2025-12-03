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
import {renderHook} from '@testing-library/react-hooks'
import {waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {useRecentGrades} from '../useRecentGrades'
import {WidgetDashboardProvider} from '../useWidgetDashboardContext'
import {clearWidgetDashboardCache} from '../../__tests__/testHelpers'

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterEach(() => {
  server.resetHandlers()
})

afterAll(() => {
  server.close()
})

beforeEach(() => {
  window.ENV = {current_user_id: '1'} as any
})

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {queries: {retry: false}, mutations: {retry: false}},
  })

  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider>{children}</WidgetDashboardProvider>
    </QueryClientProvider>
  )
}

const mockGradedSubmissions = [
  {
    _id: 'sub1',
    score: 95,
    grade: 'A',
    submittedAt: '2025-11-28T10:00:00Z',
    gradedAt: '2025-11-30T14:30:00Z',
    state: 'graded',
    assignment: {
      _id: '101',
      name: 'Introduction to React Hooks',
      htmlUrl: '/courses/1/assignments/101',
      pointsPossible: 100,
      submissionTypes: ['online_text_entry'],
      quiz: null,
      discussion: null,
      course: {
        _id: '1',
        name: 'Advanced Web Development',
        courseCode: 'CS-401',
      },
    },
  },
  {
    _id: 'sub2',
    score: 88,
    grade: 'B+',
    submittedAt: '2025-11-27T09:00:00Z',
    gradedAt: '2025-11-29T16:45:00Z',
    state: 'graded',
    assignment: {
      _id: '102',
      name: 'Data Structures Quiz',
      htmlUrl: '/courses/2/assignments/102',
      pointsPossible: 100,
      submissionTypes: ['online_quiz'],
      quiz: {_id: '102', title: 'Data Structures Quiz'},
      discussion: null,
      course: {
        _id: '2',
        name: 'Computer Science 101',
        courseCode: 'CS-101',
      },
    },
  },
  {
    _id: 'sub3',
    score: 92,
    grade: 'A-',
    submittedAt: '2025-11-26T11:30:00Z',
    gradedAt: '2025-11-28T10:15:00Z',
    state: 'graded',
    assignment: {
      _id: '103',
      name: 'Essay on Modern Literature',
      htmlUrl: '/courses/3/assignments/103',
      pointsPossible: 100,
      submissionTypes: ['online_text_entry'],
      quiz: null,
      discussion: null,
      course: {
        _id: '3',
        name: 'English Literature 201',
        courseCode: 'ENG-201',
      },
    },
  },
]

describe('useRecentGrades', () => {
  beforeEach(() => {
    clearWidgetDashboardCache()
  })

  it('fetches graded submissions successfully', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetRecentGrades')) {
          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: mockGradedSubmissions,
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    endCursor: null,
                    startCursor: null,
                    totalCount: 3,
                  },
                },
              },
            },
          })
        }
      }),
    )

    const {result} = renderHook(() => useRecentGrades({pageSize: 5}), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.currentPage?.submissions).toHaveLength(3)
    expect(result.current.currentPage?.submissions[0].assignment.name).toBe(
      'Introduction to React Hooks',
    )
    expect(result.current.currentPage?.submissions[0].score).toBe(95)
    expect(result.current.currentPage?.submissions[0].grade).toBe('A')
    expect(result.current.totalCount).toBe(3)
  })

  it('filters by course when courseFilter is provided', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetRecentGrades')) {
          expect(body.variables.courseFilter).toBe('1')
          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: [mockGradedSubmissions[0]],
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    endCursor: null,
                    startCursor: null,
                    totalCount: 1,
                  },
                },
              },
            },
          })
        }
      }),
    )

    const {result} = renderHook(() => useRecentGrades({pageSize: 5, courseFilter: '1'}), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.currentPage?.submissions).toHaveLength(1)
    expect(result.current.currentPage?.submissions[0].assignment.course._id).toBe('1')
  })

  it('handles pagination correctly', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetRecentGrades')) {
          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: mockGradedSubmissions.slice(0, 2),
                  pageInfo: {
                    hasNextPage: true,
                    hasPreviousPage: false,
                    endCursor: 'cursor2',
                    startCursor: 'cursor1',
                    totalCount: 10,
                  },
                },
              },
            },
          })
        }
      }),
    )

    const {result} = renderHook(() => useRecentGrades({pageSize: 2}), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.totalCount).toBe(10)
    expect(result.current.totalPages).toBe(5)
    expect(result.current.currentPageIndex).toBe(0)
    expect(result.current.currentPage?.pageInfo.hasNextPage).toBe(true)
  })

  it('handles empty submissions gracefully', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetRecentGrades')) {
          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: [],
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    endCursor: null,
                    startCursor: null,
                    totalCount: 0,
                  },
                },
              },
            },
          })
        }
      }),
    )

    const {result} = renderHook(() => useRecentGrades({pageSize: 5}), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.currentPage?.submissions).toHaveLength(0)
    expect(result.current.totalCount).toBe(0)
    expect(result.current.totalPages).toBe(0)
  })

  it('handles GraphQL errors', async () => {
    server.use(
      http.post('/api/graphql', async () => {
        return HttpResponse.json(
          {
            errors: [{message: 'Failed to fetch submissions'}],
          },
          {status: 500},
        )
      }),
    )

    const {result} = renderHook(() => useRecentGrades({pageSize: 5}), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.error).toBeTruthy()
    })

    expect(result.current.error?.message).toContain('GraphQL Error')
  })

  it('handles network errors', async () => {
    server.use(
      http.post('/api/graphql', async () => {
        return HttpResponse.error()
      }),
    )

    const {result} = renderHook(() => useRecentGrades({pageSize: 5}), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.error).toBeTruthy()
    })
  })

  it('resets to page 0 when course filter changes', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetRecentGrades')) {
          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: mockGradedSubmissions,
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    endCursor: null,
                    startCursor: null,
                    totalCount: 3,
                  },
                },
              },
            },
          })
        }
      }),
    )

    const {result: result1} = renderHook(() => useRecentGrades({pageSize: 5}), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result1.current.isLoading).toBe(false)
    })

    result1.current.goToPage(2)

    await waitFor(() => {
      expect(result1.current.currentPageIndex).toBe(1)
    })

    const {result: result2} = renderHook(() => useRecentGrades({pageSize: 5, courseFilter: '1'}), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result2.current.currentPageIndex).toBe(0)
    })
  })
})
