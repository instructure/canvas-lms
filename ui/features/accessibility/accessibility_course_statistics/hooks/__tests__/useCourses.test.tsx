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
import {createMockCourses} from '../../__tests__/factories'

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

  it('fetches courses successfully', async () => {
    const mockCourses = createMockCourses(2)
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, () => {
        return HttpResponse.json(mockCourses)
      }),
    )

    const {result} = renderHook(() => useCourses({accountId}), {wrapper})

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data?.courses).toEqual(mockCourses)
    expect(result.current.data?.courses.length).toBe(2)
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

    const {result} = renderHook(() => useCourses({accountId}), {wrapper})

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(requestParams?.get('include[]')).toContain('total_students')
    expect(requestParams?.get('teacher_limit')).toBe('25')
    expect(requestParams?.get('per_page')).toBe('15')
    expect(requestParams?.get('no_avatar_fallback')).toBe('1')
  })

  it('handles API errors gracefully', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, () => {
        return HttpResponse.json({errors: [{message: 'Server error'}]}, {status: 500})
      }),
    )

    const {result} = renderHook(() => useCourses({accountId}), {wrapper})

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

    const {result} = renderHook(() => useCourses({accountId}), {wrapper})

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
  })

  it('returns empty array when no courses exist', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/courses`, () => {
        return HttpResponse.json([])
      }),
    )

    const {result} = renderHook(() => useCourses({accountId}), {wrapper})

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

    const {result} = renderHook(() => useCourses({accountId}), {wrapper})

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const cachedData = queryClient.getQueryData(['accessibility-courses', accountId])
    expect(cachedData).toBeTruthy()
  })
})
