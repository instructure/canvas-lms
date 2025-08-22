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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {usePaginatedCoursesWithGrades} from '../useUserCourses'

const errorMsg = 'Failed to fetch courses'

const buildDefaultProps = () => ({
  current_user_id: '123',
})

const setup = (hookFn: any, envOverrides = {}) => {
  // Set up Canvas ENV with current_user_id
  const originalEnv = window.ENV
  window.ENV = {
    ...originalEnv,
    ...buildDefaultProps(),
    ...envOverrides,
  }

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  const result = renderHook(() => hookFn(), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    ),
  })

  return {
    ...result,
    queryClient,
    cleanup: () => {
      window.ENV = originalEnv
      queryClient.clear()
    },
  }
}

const server = setupServer()

// Mock response structure for the connection query
const mockConnectionResponse = {
  data: {
    legacyNode: {
      _id: '123',
      enrollmentsConnection: {
        nodes: [
          {
            course: {
              _id: '1',
              name: 'Introduction to Computer Science',
              courseCode: 'CS101',
            },
            updatedAt: '2025-01-01T00:00:00Z',
            grades: {
              currentScore: 95,
              currentGrade: 'A',
              finalScore: 95,
              finalGrade: 'A',
              overrideScore: null,
              overrideGrade: null,
            },
          },
          {
            course: {
              _id: '2',
              name: 'Advanced Mathematics',
              courseCode: 'MATH301',
            },
            updatedAt: '2025-01-01T00:00:00Z',
            grades: {
              currentScore: 87,
              currentGrade: 'B+',
              finalScore: 87,
              finalGrade: 'B+',
              overrideScore: null,
              overrideGrade: null,
            },
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'cursor1',
          endCursor: 'cursor2',
        },
      },
    },
  },
}

const mockConnectionResponseWithPagination = {
  data: {
    legacyNode: {
      _id: '123',
      enrollmentsConnection: {
        nodes: [
          {
            course: {
              _id: '1',
              name: 'Introduction to Computer Science',
              courseCode: 'CS101',
            },
            updatedAt: '2025-01-01T00:00:00Z',
            grades: {
              currentScore: 95,
              currentGrade: 'A',
              finalScore: 95,
              finalGrade: 'A',
              overrideScore: null,
              overrideGrade: null,
            },
          },
        ],
        pageInfo: {
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'cursor1',
          endCursor: 'cursor1',
        },
      },
    },
  },
}

describe('usePaginatedCoursesWithGrades', () => {
  beforeAll(() => {
    server.listen({
      onUnhandledRequest: 'error',
    })
  })
  afterEach(() => {
    server.resetHandlers()
  })
  afterAll(() => server.close())

  it('should return loading state initially', () => {
    server.use(
      graphql.query('GetUserCoursesWithGradesConnection', () => {
        return new Promise(resolve => {
          setTimeout(() => {
            resolve(HttpResponse.json(mockConnectionResponse))
          }, 100)
        })
      }),
    )

    const {result, cleanup} = setup(() => usePaginatedCoursesWithGrades())

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toEqual([])
    expect(result.current.error).toBeNull()
    expect(result.current.hasNextPage).toBe(false)
    expect(result.current.hasPreviousPage).toBe(false)
    expect(result.current.currentPage).toBe(1)
    expect(result.current.totalPages).toBe(1)
    expect(typeof result.current.fetchNextPage).toBe('function')
    expect(typeof result.current.fetchPreviousPage).toBe('function')

    cleanup()
  })

  it('should return course grades data on successful request', async () => {
    server.use(
      graphql.query('GetUserCoursesWithGradesConnection', ({variables}) => {
        expect(variables.userId).toBe('123')
        expect(variables.first).toBe(6) // Default limit
        expect(variables.after).toBeUndefined()
        return HttpResponse.json(mockConnectionResponse)
      }),
    )

    const {result, cleanup} = setup(() => usePaginatedCoursesWithGrades())

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.error).toBeNull()
      expect(result.current.data).toHaveLength(2)
      expect(result.current.data[0]).toEqual({
        courseId: '1',
        courseCode: 'CS101',
        courseName: 'Introduction to Computer Science',
        currentGrade: 95,
        gradingScheme: 'letter',
        lastUpdated: new Date('2025-01-01T00:00:00Z'),
      })
      expect(result.current.hasNextPage).toBe(false)
      expect(result.current.hasPreviousPage).toBe(false)
      expect(result.current.currentPage).toBe(1)
      expect(result.current.totalPages).toBe(1)
    })

    cleanup()
  })

  it('should support custom limit parameter', async () => {
    server.use(
      graphql.query('GetUserCoursesWithGradesConnection', ({variables}) => {
        expect(variables.first).toBe(3)
        return HttpResponse.json(mockConnectionResponse)
      }),
    )

    const {result, cleanup} = setup(() => usePaginatedCoursesWithGrades({limit: 3}))

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    cleanup()
  })

  it('should return correct pagination state when hasNextPage is true', async () => {
    server.use(
      graphql.query('GetUserCoursesWithGradesConnection', () => {
        return HttpResponse.json(mockConnectionResponseWithPagination)
      }),
    )

    const {result, cleanup} = setup(() => usePaginatedCoursesWithGrades({limit: 1}))

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toHaveLength(1)
      expect(result.current.hasNextPage).toBe(true)
      expect(result.current.hasPreviousPage).toBe(false)
      expect(result.current.currentPage).toBe(1)
    })

    cleanup()
  })

  it('should handle GraphQL errors', async () => {
    server.use(
      graphql.query('GetUserCoursesWithGradesConnection', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    const {result, cleanup} = setup(() => usePaginatedCoursesWithGrades())

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual([])
      expect(result.current.error?.message).toContain(errorMsg)
      expect(result.current.hasNextPage).toBe(false)
      expect(result.current.hasPreviousPage).toBe(false)
    })

    cleanup()
  })

  it('should handle empty connection response', async () => {
    const emptyConnectionResponse = {
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
            },
          },
        },
      },
    }

    server.use(
      graphql.query('GetUserCoursesWithGradesConnection', () => {
        return HttpResponse.json(emptyConnectionResponse)
      }),
    )

    const {result, cleanup} = setup(() => usePaginatedCoursesWithGrades())

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual([])
      expect(result.current.error).toBeNull()
      expect(result.current.hasNextPage).toBe(false)
      expect(result.current.hasPreviousPage).toBe(false)
      expect(result.current.currentPage).toBe(1)
      expect(result.current.totalPages).toBe(1)
    })

    cleanup()
  })

  it('should handle missing enrollmentsConnection in response', async () => {
    const invalidResponse = {
      data: {
        legacyNode: {
          _id: '123',
          enrollmentsConnection: null,
        },
      },
    }

    server.use(
      graphql.query('GetUserCoursesWithGradesConnection', () => {
        return HttpResponse.json(invalidResponse)
      }),
    )

    const {result, cleanup} = setup(() => usePaginatedCoursesWithGrades())

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual([])
      expect(result.current.error).toBeNull()
      expect(result.current.hasNextPage).toBe(false)
      expect(result.current.hasPreviousPage).toBe(false)
    })

    cleanup()
  })

  it('should transform enrollments to course grades correctly', async () => {
    const responseWithDifferentGradeTypes = {
      data: {
        legacyNode: {
          _id: '123',
          enrollmentsConnection: {
            nodes: [
              {
                course: {
                  _id: '1',
                  name: 'Course with Override',
                  courseCode: 'TEST101',
                },
                updatedAt: '2025-01-01T00:00:00Z',
                grades: {
                  currentScore: 85,
                  currentGrade: 'B',
                  finalScore: 88,
                  finalGrade: 'B+',
                  overrideScore: 92,
                  overrideGrade: 'A-',
                },
              },
              {
                course: {
                  _id: '2',
                  name: 'Course with Final Only',
                  courseCode: null, // Test default course code
                },
                updatedAt: '2025-01-01T00:00:00Z',
                grades: {
                  currentScore: 85,
                  currentGrade: 'B',
                  finalScore: 88,
                  finalGrade: null, // Test percentage scheme
                  overrideScore: null,
                  overrideGrade: null,
                },
              },
            ],
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
            },
          },
        },
      },
    }

    server.use(
      graphql.query('GetUserCoursesWithGradesConnection', () => {
        return HttpResponse.json(responseWithDifferentGradeTypes)
      }),
    )

    const {result, cleanup} = setup(() => usePaginatedCoursesWithGrades())

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toHaveLength(2)

      // Test override grade priority
      expect(result.current.data[0]).toEqual({
        courseId: '1',
        courseCode: 'TEST101',
        courseName: 'Course with Override',
        currentGrade: 92, // Override score used
        gradingScheme: 'letter', // Has override grade
        lastUpdated: new Date('2025-01-01T00:00:00Z'),
      })

      // Test final grade fallback and default course code
      expect(result.current.data[1]).toEqual({
        courseId: '2',
        courseCode: 'N/A', // Default course code
        courseName: 'Course with Final Only',
        currentGrade: 88, // Final score used
        gradingScheme: 'percentage', // No final grade string
        lastUpdated: new Date('2025-01-01T00:00:00Z'),
      })
    })

    cleanup()
  })

  it('should skip request when current_user_id is missing', () => {
    const {result, cleanup} = setup(() => usePaginatedCoursesWithGrades(), {
      current_user_id: undefined,
    })

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toEqual([])
    expect(result.current.error).toBeNull()
    expect(result.current.hasNextPage).toBe(false)
    expect(result.current.hasPreviousPage).toBe(false)

    cleanup()
  })
})
