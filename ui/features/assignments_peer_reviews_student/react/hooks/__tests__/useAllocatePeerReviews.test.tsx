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
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {useAllocatePeerReviews} from '../useAllocatePeerReviews'
import type {ReactNode} from 'react'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: vi.fn(() => vi.fn()),
}))

const server = setupServer(
  http.post('/api/v1/courses/:courseId/assignments/:assignmentId/allocate', () => {
    return HttpResponse.json(null, {status: 200})
  }),
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {retry: false},
      mutations: {retry: false},
    },
  })
  return ({children}: {children: ReactNode}) => (
    <MockedQueryClientProvider client={queryClient}>{children}</MockedQueryClientProvider>
  )
}

describe('useAllocatePeerReviews', () => {
  it('allocates peer reviews successfully', async () => {
    const {result} = renderHook(() => useAllocatePeerReviews(), {wrapper: createWrapper()})

    result.current.mutate({
      courseId: '100',
      assignmentId: '10',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
  })

  it('handles server error', async () => {
    server.use(
      http.post('/api/v1/courses/:courseId/assignments/:assignmentId/allocate', () => {
        return HttpResponse.json({errors: [{message: 'Server error'}]}, {status: 500})
      }),
    )

    const {result} = renderHook(() => useAllocatePeerReviews(), {wrapper: createWrapper()})

    result.current.mutate({
      courseId: '100',
      assignmentId: '10',
    })

    await waitFor(() => expect(result.current.isError).toBe(true))
  })

  it('shows flash error message on failure', async () => {
    server.use(
      http.post('/api/v1/courses/:courseId/assignments/:assignmentId/allocate', () => {
        return HttpResponse.json({errors: [{message: 'Server error'}]}, {status: 500})
      }),
    )

    const {result} = renderHook(() => useAllocatePeerReviews(), {wrapper: createWrapper()})

    result.current.mutate({
      courseId: '100',
      assignmentId: '10',
    })

    await waitFor(() => expect(result.current.isError).toBe(true))

    expect(showFlashError).toHaveBeenCalledWith('Failed to allocate peer reviews')
  })

  it('invalidates assignment query on success', async () => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
        mutations: {retry: false},
      },
    })

    const invalidateSpy = vi.spyOn(queryClient, 'invalidateQueries')

    const wrapper = ({children}: {children: ReactNode}) => (
      <MockedQueryClientProvider client={queryClient}>{children}</MockedQueryClientProvider>
    )

    const {result} = renderHook(() => useAllocatePeerReviews(), {wrapper})

    result.current.mutate({
      courseId: '100',
      assignmentId: '10',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(invalidateSpy).toHaveBeenCalledWith({queryKey: ['peerReviewAssignment', '10']})
  })
})
