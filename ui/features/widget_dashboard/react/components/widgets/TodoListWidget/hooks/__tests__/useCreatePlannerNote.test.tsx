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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {useCreatePlannerNote} from '../useCreatePlannerNote'
import type {ReactNode} from 'react'

const server = setupServer(
  http.post('/api/v1/planner_notes', async ({request}) => {
    const body = (await request.json()) as {
      title: string
      todo_date: string
      details?: string
      course_id?: string
    }

    return HttpResponse.json({
      id: 1,
      title: body.title,
      description: body.details || '',
      user_id: 1,
      workflow_state: 'active',
      course_id: body.course_id ? parseInt(body.course_id, 10) : null,
      todo_date: body.todo_date,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
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
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('useCreatePlannerNote', () => {
  it('creates a planner note successfully', async () => {
    const {result} = renderHook(() => useCreatePlannerNote(), {wrapper: createWrapper()})

    result.current.mutate({
      title: 'Test Todo',
      todo_date: '2025-12-25T00:00:00Z',
      details: 'Test details',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data).toEqual({
      id: 1,
      title: 'Test Todo',
      description: 'Test details',
      user_id: 1,
      workflow_state: 'active',
      course_id: null,
      todo_date: '2025-12-25T00:00:00Z',
      created_at: expect.any(String),
      updated_at: expect.any(String),
    })
  })

  it('creates a planner note without details', async () => {
    const {result} = renderHook(() => useCreatePlannerNote(), {wrapper: createWrapper()})

    result.current.mutate({
      title: 'Test Todo',
      todo_date: '2025-12-25T00:00:00Z',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data).toEqual({
      id: 1,
      title: 'Test Todo',
      description: '',
      user_id: 1,
      workflow_state: 'active',
      course_id: null,
      todo_date: '2025-12-25T00:00:00Z',
      created_at: expect.any(String),
      updated_at: expect.any(String),
    })
  })

  it('handles server error', async () => {
    server.use(
      http.post('/api/v1/planner_notes', () => {
        return HttpResponse.json({errors: [{message: 'Server error'}]}, {status: 500})
      }),
    )

    const {result} = renderHook(() => useCreatePlannerNote(), {wrapper: createWrapper()})

    result.current.mutate({
      title: 'Test Todo',
      todo_date: '2025-12-25T00:00:00Z',
    })

    await waitFor(() => expect(result.current.isError).toBe(true))
  })

  it('invalidates planner items query on success', async () => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
        mutations: {retry: false},
      },
    })

    const invalidateSpy = vi.spyOn(queryClient, 'invalidateQueries')

    const wrapper = ({children}: {children: ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    )

    const {result} = renderHook(() => useCreatePlannerNote(), {wrapper})

    result.current.mutate({
      title: 'Test Todo',
      todo_date: '2025-12-25T00:00:00Z',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(invalidateSpy).toHaveBeenCalledWith({queryKey: ['plannerItems']})
  })
})
