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
import {useCourseWork} from '../useCourseWork'
import type {CourseWorkItem} from '../useCourseWork'

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

const tomorrow = new Date()
tomorrow.setDate(tomorrow.getDate() + 1)
const dayAfterTomorrow = new Date()
dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 2)
const threeDaysFromNow = new Date()
threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3)
const fiveDaysFromNow = new Date()
fiveDaysFromNow.setDate(fiveDaysFromNow.getDate() + 5)

beforeEach(() => {
  window.ENV = {current_user_id: '1'} as any
})

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {queries: {retry: false}, mutations: {retry: false}},
  })

  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('useCourseWork', () => {
  it('returns course work items from multiple courses', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetUserCourseWork')) {
          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: [
                    {
                      _id: 'sub2',
                      cachedDueDate: tomorrow.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                      assignment: {
                        _id: '2',
                        name: 'Chapter Quiz Assignment',
                        dueAt: tomorrow.toISOString(),
                        pointsPossible: 50,
                        htmlUrl: '/courses/101/assignments/2',
                        submissionTypes: ['online_quiz'],
                        state: 'published',
                        published: true,
                        quiz: {_id: '2', title: 'Chapter 5 Quiz'},
                        discussion: null,
                        course: {
                          _id: '101',
                          name: 'Biology',
                        },
                      },
                    },
                    {
                      _id: 'sub1',
                      cachedDueDate: dayAfterTomorrow.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                      assignment: {
                        _id: '1',
                        name: 'Lab Assignment',
                        dueAt: dayAfterTomorrow.toISOString(),
                        pointsPossible: 25,
                        htmlUrl: '/courses/101/assignments/1',
                        submissionTypes: ['online_upload'],
                        state: 'published',
                        published: true,
                        quiz: null,
                        discussion: null,
                        course: {
                          _id: '101',
                          name: 'Biology',
                        },
                      },
                    },
                    {
                      _id: 'sub3',
                      cachedDueDate: threeDaysFromNow.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                      assignment: {
                        _id: '3',
                        name: 'Discussion Assignment',
                        dueAt: threeDaysFromNow.toISOString(),
                        pointsPossible: 15,
                        htmlUrl: '/courses/102/assignments/3',
                        submissionTypes: ['discussion_topic'],
                        state: 'published',
                        published: true,
                        quiz: null,
                        discussion: {_id: '3', title: 'WWI Discussion'},
                        course: {
                          _id: '102',
                          name: 'History',
                        },
                      },
                    },
                  ],
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    endCursor: null,
                    startCursor: null,
                  },
                },
              },
            },
          })
        }
        return HttpResponse.json({errors: [{message: 'Query not matched'}]}, {status: 400})
      }),
    )

    const {result} = renderHook(() => useCourseWork(), {wrapper: createWrapper()})

    await waitFor(() => {
      expect(result.current.data?.pages?.[0]?.items).toBeDefined()
    })

    const expectedItems: CourseWorkItem[] = [
      {
        id: '2',
        title: 'Chapter 5 Quiz',
        course: {id: '101', name: 'Biology'},
        dueAt: tomorrow.toISOString(),
        points: 50,
        htmlUrl: '/courses/101/assignments/2',
        type: 'quiz',
        late: false,
        missing: false,
        state: 'unsubmitted',
      },
      {
        id: '1',
        title: 'Lab Assignment',
        course: {id: '101', name: 'Biology'},
        dueAt: dayAfterTomorrow.toISOString(),
        points: 25,
        htmlUrl: '/courses/101/assignments/1',
        type: 'assignment',
        late: false,
        missing: false,
        state: 'unsubmitted',
      },
      {
        id: '3',
        title: 'WWI Discussion',
        course: {id: '102', name: 'History'},
        dueAt: threeDaysFromNow.toISOString(),
        points: 15,
        htmlUrl: '/courses/102/assignments/3',
        type: 'discussion',
        late: false,
        missing: false,
        state: 'unsubmitted',
      },
    ]

    expect(result.current.data?.pages?.[0]?.items).toEqual(expectedItems)
  })

  it('supports course filtering', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetUserCourseWork')) {
          // Mock backend filtering - only return Biology course items when courseFilter is provided
          const submissions =
            body.variables.courseFilter === '101'
              ? [
                  {
                    _id: 'sub1',
                    cachedDueDate: dayAfterTomorrow.toISOString(),
                    submittedAt: null,
                    late: false,
                    missing: false,
                    excused: false,
                    state: 'unsubmitted',
                    assignment: {
                      _id: '1',
                      name: 'Lab Assignment',
                      dueAt: dayAfterTomorrow.toISOString(),
                      pointsPossible: 25,
                      htmlUrl: '/courses/101/assignments/1',
                      submissionTypes: ['online_upload'],
                      state: 'published',
                      published: true,
                      quiz: null,
                      discussion: null,
                      course: {
                        _id: '101',
                        name: 'Biology',
                      },
                    },
                  },
                ]
              : []

          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: submissions,
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    endCursor: null,
                    startCursor: null,
                  },
                },
              },
            },
          })
        }
        return HttpResponse.json({errors: [{message: 'Query not matched'}]}, {status: 400})
      }),
    )

    const {result} = renderHook(() => useCourseWork({courseFilter: '101'}), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.data?.pages?.[0]?.items).toBeDefined()
    })

    expect(result.current.data?.pages?.[0]?.items).toHaveLength(1)
    expect(result.current.data?.pages?.[0]?.items?.[0].course.id).toBe('101')
    expect(result.current.data?.pages?.[0]?.items?.[0].title).toBe('Lab Assignment')
  })

  it('supports different page sizes', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetUserCourseWork')) {
          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: [
                    {
                      _id: 'sub1',
                      cachedDueDate: tomorrow.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                      assignment: {
                        _id: '1',
                        name: 'Page Size Test Item',
                        dueAt: tomorrow.toISOString(),
                        pointsPossible: 25,
                        htmlUrl: '/courses/101/assignments/1',
                        submissionTypes: ['online_upload'],
                        state: 'published',
                        published: true,
                        quiz: null,
                        discussion: null,
                        course: {
                          _id: '101',
                          name: 'Biology',
                        },
                      },
                    },
                  ],
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    endCursor: null,
                    startCursor: null,
                  },
                },
              },
            },
          })
        }
        return HttpResponse.json({errors: [{message: 'Query not matched'}]}, {status: 400})
      }),
    )

    const {result} = renderHook(() => useCourseWork({pageSize: 2}), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.data?.pages?.[0]?.items).toBeDefined()
    })

    expect(result.current.data?.pages?.[0]?.items).toHaveLength(1)
    expect(result.current.data?.pages?.[0]?.items?.[0].title).toBe('Page Size Test Item')
  })

  it('handles null response', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetUserCourseWork')) {
          return HttpResponse.json({
            data: {
              legacyNode: null,
            },
          })
        }
        return HttpResponse.json({errors: [{message: 'Query not matched'}]}, {status: 400})
      }),
    )

    const {result} = renderHook(() => useCourseWork(), {wrapper: createWrapper()})

    await waitFor(() => {
      expect(result.current.data?.pages?.[0]?.items).toBeDefined()
    })

    expect(result.current.data?.pages?.[0]?.items).toEqual([])
    expect(result.current.data?.pages?.[0]?.pageInfo.hasNextPage).toBe(false)
  })

  it('handles empty response', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetUserCourseWork')) {
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
                  },
                },
              },
            },
          })
        }
        return HttpResponse.json({errors: [{message: 'Query not matched'}]}, {status: 400})
      }),
    )

    const {result} = renderHook(() => useCourseWork(), {wrapper: createWrapper()})

    await waitFor(() => {
      expect(result.current.data?.pages?.[0]?.items).toBeDefined()
    })

    expect(result.current.data?.pages?.[0]?.items).toEqual([])
    expect(result.current.data?.pages?.[0]?.pageInfo.hasNextPage).toBe(false)
  })

  it('sorts items by due date (soonest first, null last)', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetUserCourseWork')) {
          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: [
                    {
                      _id: 'sub1',
                      cachedDueDate: tomorrow.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                      assignment: {
                        _id: '1',
                        name: 'Assignment A',
                        dueAt: tomorrow.toISOString(),
                        pointsPossible: 25,
                        htmlUrl: '/courses/101/assignments/1',
                        submissionTypes: ['online_upload'],
                        state: 'published',
                        published: true,
                        quiz: null,
                        discussion: null,
                        course: {
                          _id: '101',
                          name: 'Course 1',
                        },
                      },
                    },
                    {
                      _id: 'sub2',
                      cachedDueDate: threeDaysFromNow.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                      assignment: {
                        _id: '2',
                        name: 'Assignment C',
                        dueAt: threeDaysFromNow.toISOString(),
                        pointsPossible: 50,
                        htmlUrl: '/courses/101/assignments/2',
                        submissionTypes: ['online_upload'],
                        state: 'published',
                        published: true,
                        quiz: null,
                        discussion: null,
                        course: {
                          _id: '101',
                          name: 'Course 1',
                        },
                      },
                    },
                    {
                      _id: 'sub3',
                      cachedDueDate: null,
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                      assignment: {
                        _id: '3',
                        name: 'Assignment B',
                        dueAt: null,
                        pointsPossible: 10,
                        htmlUrl: '/courses/101/assignments/3',
                        submissionTypes: ['online_upload'],
                        state: 'published',
                        published: true,
                        quiz: null,
                        discussion: null,
                        course: {
                          _id: '101',
                          name: 'Course 1',
                        },
                      },
                    },
                  ],
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    endCursor: null,
                    startCursor: null,
                  },
                },
              },
            },
          })
        }
        return HttpResponse.json({errors: [{message: 'Query not matched'}]}, {status: 400})
      }),
    )

    const {result} = renderHook(() => useCourseWork(), {wrapper: createWrapper()})

    await waitFor(() => {
      expect(result.current.data?.pages?.[0]?.items).toBeDefined()
    })

    expect(
      result.current.data?.pages?.[0]?.items?.map((item: CourseWorkItem) => item.title),
    ).toEqual([
      'Assignment A', // Earliest due date
      'Assignment C', // Later due date
      'Assignment B', // No due date (null)
    ])
  })
})
