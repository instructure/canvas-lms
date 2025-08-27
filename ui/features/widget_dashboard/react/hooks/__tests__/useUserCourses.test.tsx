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
import {useUserCourses} from '../useUserCourses'

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
          },
        },
        {
          course: {
            _id: '2',
            name: 'Advanced Mathematics',
          },
        },
        {
          course: {
            _id: '3',
            name: 'Biology Fundamentals',
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

const setup = (envOverrides = {}) => {
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

  const result = renderHook(() => useUserCourses(), {
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
      graphql.query('GetUserCourses', () => {
        // Return a delayed response to test loading state
        return new Promise(resolve => {
          setTimeout(() => {
            resolve(HttpResponse.json(mockGqlResponse))
          }, 100)
        })
      }),
    )

    const {result, cleanup} = setup()

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    cleanup()
  })

  it('should return courses data on successful request', async () => {
    server.use(
      graphql.query('GetUserCourses', ({variables}) => {
        expect(variables.userId).toBe('123')
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual(mockCoursesData)
      expect(result.current.error).toBeNull()
    })

    cleanup()
  })

  it('should handle GraphQL errors', async () => {
    server.use(
      graphql.query('GetUserCourses', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toBeUndefined()
      expect(result.current.error?.message).toContain(errorMsg)
    })

    cleanup()
  })

  it('should handle network errors', async () => {
    server.use(
      graphql.query('GetUserCourses', () => {
        return new HttpResponse(null, {status: 500})
      }),
    )

    const {result, cleanup} = setup()

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
      graphql.query('GetUserCourses', () => {
        return HttpResponse.json(emptyResponse)
      }),
    )

    const {result, cleanup} = setup()

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
      graphql.query('GetUserCourses', () => {
        callCount++
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup()

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
    const {result, cleanup} = setup({current_user_id: undefined})

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    cleanup()
  })
})
