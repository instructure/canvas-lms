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
import {useCourseInstructors} from '../useCourseInstructors'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {clearWidgetDashboardCache} from '../../__tests__/testHelpers'

const server = setupServer()

const setup = (hookFn: any) => {
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
      queryClient.clear()
    },
  }
}

const mockInstructorsResponse = {
  data: {
    courseInstructorsConnection: {
      nodes: [
        {
          user: {
            _id: '101',
            name: 'Professor Smith',
            sortableName: 'Smith, Professor',
            shortName: 'Prof Smith',
            avatarUrl: 'https://example.com/avatar1.jpg',
            email: 'prof.smith@example.com',
          },
          course: {
            _id: '1',
            name: 'Advanced Mathematics',
            courseCode: 'MATH301',
          },
          type: 'TeacherEnrollment',
          role: {
            _id: '1',
            name: 'Teacher',
          },
          enrollmentState: 'active',
        },
        {
          user: {
            _id: '102',
            name: 'TA Johnson',
            sortableName: 'Johnson, TA',
            shortName: 'TA Johnson',
            avatarUrl: 'https://example.com/avatar2.jpg',
            email: 'ta.johnson@example.com',
          },
          course: {
            _id: '1',
            name: 'Advanced Mathematics',
            courseCode: 'MATH301',
          },
          type: 'TaEnrollment',
          role: {
            _id: '2',
            name: 'Teaching Assistant',
          },
          enrollmentState: 'active',
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
}

describe('useCourseInstructors', () => {
  beforeAll(() => {
    server.listen({
      onUnhandledRequest: 'bypass',
    })
    window.ENV = {
      current_user_id: '123',
      GRAPHQL_URL: '/api/graphql',
      CSRF_TOKEN: 'mock-csrf-token',
    } as any
  })

  beforeEach(() => {
    clearWidgetDashboardCache()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    server.use(
      graphql.query('GetCourseInstructorsPaginated', () => {
        return HttpResponse.json(mockInstructorsResponse)
      }),
    )
  })

  it('should return loading state initially', () => {
    server.use(
      graphql.query('GetCourseInstructorsPaginated', async () => {
        await new Promise(() => {}) // Never resolves
      }),
    )

    const {result, cleanup} = setup(() => useCourseInstructors({courseIds: ['1']}))

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    cleanup()
  })

  it('should fetch instructors for specified courses', async () => {
    const {result, cleanup} = setup(() => useCourseInstructors({courseIds: ['1']}))

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.error).toBeNull()
    expect(result.current.data.pages[0].data).toHaveLength(2)
    expect(result.current.data.pages[0].data[0].name).toBe('Professor Smith')
    expect(result.current.data.pages[0].data[1].name).toBe('TA Johnson')

    cleanup()
  })

  it('should handle empty course list', async () => {
    const {result, cleanup} = setup(() => useCourseInstructors({courseIds: []}))

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.data.pages[0].data).toHaveLength(2)
    expect(result.current.error).toBeNull()

    cleanup()
  })

  it('should handle disabled state', () => {
    const {result, cleanup} = setup(() => useCourseInstructors({courseIds: ['1'], enabled: false}))

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    cleanup()
  })

  it('should handle GraphQL errors', async () => {
    const originalConsoleError = console.error
    console.error = vi.fn()

    server.use(
      graphql.query('GetCourseInstructorsPaginated', () => {
        return HttpResponse.json(
          {
            errors: [{message: 'GraphQL Error'}],
          },
          {status: 500},
        )
      }),
    )

    const {result, cleanup} = setup(() => useCourseInstructors({courseIds: ['1']}))

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.error).toBeTruthy()
    })

    console.error = originalConsoleError
    cleanup()
  })

  it('should support pagination controls', async () => {
    const {result, cleanup} = setup(() => useCourseInstructors({courseIds: ['1']}))

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(typeof result.current.fetchNextPage).toBe('function')
    expect(typeof result.current.fetchPreviousPage).toBe('function')
    expect(result.current.hasNextPage).toBe(false)
    expect(result.current.hasPreviousPage).toBe(false)

    cleanup()
  })
})
