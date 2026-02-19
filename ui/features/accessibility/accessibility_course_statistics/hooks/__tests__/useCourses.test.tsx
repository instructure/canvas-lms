/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {useCourses} from '../useCourses'
import {createMockCourses, createMockLinkHeaderString} from '../../__tests__/factories'

const server = setupServer()
const accountId = '123'

describe('useCourses', () => {
  let queryClient: QueryClient

  beforeAll(() => server.listen())

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
      },
    })
  })

  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })

  afterAll(() => server.close())

  const wrapper = ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )

  const renderUseCourses = (sort = 'sis_course_id', order: 'asc' | 'desc' = 'asc', page = 1) => {
    return renderHook(() => useCourses({accountId, sort, order, page}), {wrapper})
  }

  it('fetches courses successfully', async () => {
    const mockCourses = createMockCourses(2)
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, () => {
        return HttpResponse.json(mockCourses, {
          headers: {Link: createMockLinkHeaderString(1, accountId)},
        })
      }),
    )

    const {result} = renderUseCourses()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data?.courses).toEqual(mockCourses)
    expect(result.current.data?.courses.length).toBe(2)
    expect(result.current.data?.pageCount).toBe(1)
  })

  it('includes correct query parameters in API request', async () => {
    const mockCourses = createMockCourses(1)
    let requestParams: URLSearchParams | undefined

    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, ({request}) => {
        requestParams = new URL(request.url).searchParams
        return HttpResponse.json(mockCourses)
      }),
    )

    const {result} = renderUseCourses('course_name', 'desc')

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const includeParams = requestParams?.getAll('include[]')
    expect(includeParams).toContain('total_students')
    expect(includeParams).toContain('active_teachers')
    expect(includeParams).toContain('subaccount')
    expect(includeParams).toContain('term')
    expect(includeParams).toContain('accessibility_course_statistic')
    expect(requestParams?.get('teacher_limit')).toBe('25')
    expect(requestParams?.get('per_page')).toBe('14')
    expect(requestParams?.get('no_avatar_fallback')).toBe('1')
    expect(requestParams?.get('sort')).toBe('course_name')
    expect(requestParams?.get('order')).toBe('desc')
    expect(requestParams?.get('page')).toBe('1')
  })

  it('includes sort and order in query key for proper caching', async () => {
    const mockCourses = createMockCourses(1)
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, () => {
        return HttpResponse.json(mockCourses)
      }),
    )

    const {result} = renderUseCourses('a11y_active_issue_count', 'asc')

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const cachedData = queryClient.getQueryData([
      'accessibility-courses',
      accountId,
      'a11y_active_issue_count',
      'asc',
      1,
    ])
    expect(cachedData).toBeTruthy()
  })

  it('handles API errors gracefully', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, () => {
        return HttpResponse.json({errors: [{message: 'Server error'}]}, {status: 500})
      }),
    )

    const {result} = renderUseCourses()

    await waitFor(() => expect(result.current.isError).toBe(true))

    expect(result.current.error).toBeTruthy()
    expect(result.current.data).toBeUndefined()
  })

  it('starts in loading state', () => {
    const mockCourses = createMockCourses(1)
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
        return HttpResponse.json(mockCourses)
      }),
    )

    const {result} = renderUseCourses()

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
  })

  it('returns empty array when no courses exist', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, () => {
        return HttpResponse.json([])
      }),
    )

    const {result} = renderUseCourses()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data?.courses).toEqual([])
    expect(result.current.data?.courses.length).toBe(0)
  })

  it('uses correct query key for caching', async () => {
    const mockCourses = createMockCourses(1)
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, () => {
        return HttpResponse.json(mockCourses)
      }),
    )

    const {result} = renderUseCourses()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const cachedData = queryClient.getQueryData([
      'accessibility-courses',
      accountId,
      'sis_course_id',
      'asc',
      1,
    ])
    expect(cachedData).toBeTruthy()
  })

  it('includes accessibility_course_statistic in response', async () => {
    const mockCourses = createMockCourses(1)
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, () => {
        return HttpResponse.json(mockCourses)
      }),
    )

    const {result} = renderUseCourses()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const course = result.current.data?.courses[0]
    expect(course?.accessibility_course_statistic).toBeDefined()
    expect(course?.accessibility_course_statistic?.id).toBe(1)
    expect(course?.accessibility_course_statistic?.active_issue_count).toBe(5)
    expect(course?.accessibility_course_statistic?.workflow_state).toBe('active')
  })

  it('handles courses without accessibility_course_statistic', async () => {
    const mockCourses = createMockCourses(1, {accessibility_course_statistic: null})
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, () => {
        return HttpResponse.json(mockCourses)
      }),
    )

    const {result} = renderUseCourses()

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const course = result.current.data?.courses[0]
    expect(course?.accessibility_course_statistic).toBeNull()
  })

  describe('pagination', () => {
    it('uses provided page number', async () => {
      const mockCourses = createMockCourses(2)
      let requestParams: URLSearchParams | undefined

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, ({request}) => {
          requestParams = new URL(request.url).searchParams
          return HttpResponse.json(mockCourses, {
            headers: {Link: createMockLinkHeaderString(5, accountId)},
          })
        }),
      )

      const {result} = renderHook(
        () => useCourses({accountId, sort: 'sis_course_id', order: 'asc', page: 3}),
        {wrapper},
      )

      await waitFor(() => expect(result.current.isSuccess).toBe(true))

      expect(requestParams?.get('page')).toBe('3')
      expect(result.current.data?.pageCount).toBe(5)
    })

    it('parses page count from Link header', async () => {
      const mockCourses = createMockCourses(14)
      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, () => {
          return HttpResponse.json(mockCourses, {
            headers: {Link: createMockLinkHeaderString(7, accountId)},
          })
        }),
      )

      const {result} = renderHook(
        () => useCourses({accountId, sort: 'sis_course_id', order: 'asc', page: 1}),
        {wrapper},
      )

      await waitFor(() => expect(result.current.isSuccess).toBe(true))

      expect(result.current.data?.pageCount).toBe(7)
    })

    it('defaults pageCount to 1 when Link header is missing', async () => {
      const mockCourses = createMockCourses(5)
      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, () => {
          return HttpResponse.json(mockCourses)
        }),
      )

      const {result} = renderUseCourses()

      await waitFor(() => expect(result.current.isSuccess).toBe(true))

      expect(result.current.data?.pageCount).toBe(1)
    })
  })
})
