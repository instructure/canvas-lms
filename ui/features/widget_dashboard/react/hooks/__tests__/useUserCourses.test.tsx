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
import {useUserCourses, useUserCoursesWithGrades} from '../useUserCourses'

const mockCoursesData = [
  {
    id: '1',
    name: 'Introduction to Computer Science',
  },
  {
    id: '2',
    name: 'Advanced Mathematics',
  },
  {
    id: '3',
    name: 'Biology Fundamentals',
  },
]

const mockCourseGradesData = [
  {
    courseId: '1',
    courseCode: 'CS101',
    courseName: 'Introduction to Computer Science',
    currentGrade: 95,
    gradingScheme: 'letter',
    lastUpdated: new Date('2025-01-01T00:00:00Z'),
  },
  {
    courseId: '2',
    courseCode: 'MATH301',
    courseName: 'Advanced Mathematics',
    currentGrade: 87,
    gradingScheme: 'letter',
    lastUpdated: new Date('2025-01-01T00:00:00Z'),
  },
  {
    courseId: '3',
    courseCode: 'BIO101',
    courseName: 'Biology Fundamentals',
    currentGrade: 92,
    gradingScheme: 'letter',
    lastUpdated: new Date('2025-01-01T00:00:00Z'),
  },
]

// Mock response structure that matches the GraphQL query in useUserCourses
const mockGqlResponse = {
  data: {
    legacyNode: {
      _id: '123',
      enrollments: [
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
        {
          course: {
            _id: '3',
            name: 'Biology Fundamentals',
            courseCode: 'BIO101',
          },
          updatedAt: '2025-01-01T00:00:00Z',
          grades: {
            currentScore: 92,
            currentGrade: 'A-',
            finalScore: 92,
            finalGrade: 'A-',
            overrideScore: null,
            overrideGrade: null,
          },
        },
      ],
    },
  },
}

const errorMsg = 'Failed to fetch courses'

const buildDefaultProps = () => ({
  current_user_id: '123',
})

const setup = (hookFn: any = useUserCourses, envOverrides = {}) => {
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

describe('useUserCourses', () => {
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
      graphql.query('GetUserCoursesWithGrades', () => {
        // Return a delayed response to test loading state
        return new Promise(resolve => {
          setTimeout(() => {
            resolve(HttpResponse.json(mockGqlResponse))
          }, 100)
        })
      }),
    )

    const {result, cleanup} = setup(useUserCourses)

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    cleanup()
  })

  it('should return courses data on successful request', async () => {
    server.use(
      graphql.query('GetUserCoursesWithGrades', ({variables}) => {
        expect(variables.userId).toBe('123')
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup(useUserCourses)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual(mockCoursesData)
      expect(result.current.error).toBeNull()
    })

    cleanup()
  })

  it('should handle GraphQL errors', async () => {
    server.use(
      graphql.query('GetUserCoursesWithGrades', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    const {result, cleanup} = setup(useUserCourses)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toBeUndefined()
      expect(result.current.error?.message).toContain(errorMsg)
    })

    cleanup()
  })

  it('should handle network errors', async () => {
    server.use(
      graphql.query('GetUserCoursesWithGrades', () => {
        return new HttpResponse(null, {status: 500})
      }),
    )

    const {result, cleanup} = setup(useUserCourses)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toBeUndefined()
      expect(result.current.error).toBeTruthy()
    })

    cleanup()
  })

  it('should handle empty courses response', async () => {
    const emptyResponse = {
      data: {
        legacyNode: {
          _id: '123',
          enrollments: [],
        },
      },
    }

    server.use(
      graphql.query('GetUserCoursesWithGrades', () => {
        return HttpResponse.json(emptyResponse)
      }),
    )

    const {result, cleanup} = setup(useUserCourses)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual([])
      expect(result.current.error).toBeNull()
    })

    cleanup()
  })

  it('should refetch courses when invalidated', async () => {
    let callCount = 0
    server.use(
      graphql.query('GetUserCoursesWithGrades', () => {
        callCount++
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup(useUserCourses)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(callCount).toBe(1)
    })

    // Trigger refetch
    result.current.refetch()

    await waitFor(() => {
      expect(callCount).toBe(2)
    })

    cleanup()
  })

  it('should skip request when current_user_id is missing', () => {
    const {result, cleanup} = setup(useUserCourses, {current_user_id: undefined})

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    cleanup()
  })
})

describe('useUserCoursesWithGrades', () => {
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
      graphql.query('GetUserCoursesWithGrades', () => {
        // Return a delayed response to test loading state
        return new Promise(resolve => {
          setTimeout(() => {
            resolve(HttpResponse.json(mockGqlResponse))
          }, 100)
        })
      }),
    )

    const {result, cleanup} = setup(useUserCoursesWithGrades)

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    cleanup()
  })

  it('should return course grades data on successful request', async () => {
    server.use(
      graphql.query('GetUserCoursesWithGrades', ({variables}) => {
        expect(variables.userId).toBe('123')
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup(useUserCoursesWithGrades)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual(mockCourseGradesData)
      expect(result.current.error).toBeNull()
    })

    cleanup()
  })

  it('should handle GraphQL errors', async () => {
    server.use(
      graphql.query('GetUserCoursesWithGrades', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    const {result, cleanup} = setup(useUserCoursesWithGrades)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toBeUndefined()
      expect(result.current.error?.message).toContain(errorMsg)
    })

    cleanup()
  })

  it('should handle network errors', async () => {
    server.use(
      graphql.query('GetUserCoursesWithGrades', () => {
        return new HttpResponse(null, {status: 500})
      }),
    )

    const {result, cleanup} = setup(useUserCoursesWithGrades)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toBeUndefined()
      expect(result.current.error).toBeTruthy()
    })

    cleanup()
  })

  it('should handle empty courses response', async () => {
    const emptyResponse = {
      data: {
        legacyNode: {
          _id: '123',
          enrollments: [],
        },
      },
    }

    server.use(
      graphql.query('GetUserCoursesWithGrades', () => {
        return HttpResponse.json(emptyResponse)
      }),
    )

    const {result, cleanup} = setup(useUserCoursesWithGrades)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual([])
      expect(result.current.error).toBeNull()
    })

    cleanup()
  })

  it('should skip request when current_user_id is missing', () => {
    const {result, cleanup} = setup(useUserCoursesWithGrades, {current_user_id: undefined})

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    cleanup()
  })
})
