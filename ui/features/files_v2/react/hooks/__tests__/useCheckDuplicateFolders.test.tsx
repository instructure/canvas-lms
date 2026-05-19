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

import React from 'react'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {useCheckDuplicateFolders} from '../useCheckDuplicateFolders'
import type {Folder} from '../../../interfaces/File'

const server = setupServer()

const mockFolder1: Folder = {
  id: '1',
  name: 'Folder',
  full_name: 'course files / Folder',
  context_id: '123',
  context_type: 'Course',
  parent_folder_id: '0',
  created_at: '2026-02-10T14:27:27Z',
  updated_at: '2026-02-10T14:27:27Z',
  lock_at: null,
  unlock_at: null,
  position: 1,
  locked: false,
  folders_url: '',
  files_url: '',
  files_count: 0,
  folders_count: 0,
  hidden: false,
  locked_for_user: false,
  hidden_for_user: false,
  for_submissions: false,
  can_upload: true,
}

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('useCheckDuplicateFolders', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => server.resetHandlers())

  it('fetches duplicate folders successfully', async () => {
    const mockDuplicates = [mockFolder1, {...mockFolder1, id: '2'}]
    server.use(
      http.get('/api/v1/courses/456/folders/123/duplicates', () => {
        return HttpResponse.json({duplicates: mockDuplicates})
      }),
    )

    const {result, waitForNextUpdate} = renderHook(
      () =>
        useCheckDuplicateFolders({
          folderId: '123',
          contextType: 'course',
          contextId: '456',
        }),
      {wrapper: createWrapper()},
    )

    await waitForNextUpdate()

    expect(result.current.data).toEqual(mockDuplicates)
  })

  it('returns empty array on 404 error', async () => {
    server.use(
      http.get('/api/v1/courses/456/folders/123/duplicates', () => {
        return new HttpResponse(null, {status: 404})
      }),
    )

    const {result, waitForNextUpdate} = renderHook(
      () =>
        useCheckDuplicateFolders({
          folderId: '123',
          contextType: 'course',
          contextId: '456',
        }),
      {wrapper: createWrapper()},
    )

    await waitForNextUpdate()

    expect(result.current.data).toEqual([])
    expect(result.current.error).toBeNull()
  })

  it('sets error state on non-404 errors', async () => {
    server.use(
      http.get('/api/v1/courses/456/folders/123/duplicates', () => {
        return new HttpResponse(null, {status: 500})
      }),
    )

    const {result, waitForNextUpdate} = renderHook(
      () =>
        useCheckDuplicateFolders({
          folderId: '123',
          contextType: 'course',
          contextId: '456',
        }),
      {wrapper: createWrapper()},
    )

    await waitForNextUpdate()

    expect(result.current.error).toBeTruthy()
    expect(result.current.data).toBeUndefined()
  })

  it('does not fetch when disabled', () => {
    const {result} = renderHook(
      () =>
        useCheckDuplicateFolders({
          folderId: '123',
          contextType: 'course',
          contextId: '456',
          enabled: false,
        }),
      {wrapper: createWrapper()},
    )

    expect(result.current.isFetching).toBe(false)
  })

  it('constructs correct API path for different context types', async () => {
    server.use(
      http.get('/api/v1/groups/111/folders/789/duplicates', () => {
        return HttpResponse.json({duplicates: []})
      }),
    )

    const {result, waitForNextUpdate} = renderHook(
      () =>
        useCheckDuplicateFolders({
          folderId: '789',
          contextType: 'group',
          contextId: '111',
        }),
      {wrapper: createWrapper()},
    )

    await waitForNextUpdate()

    expect(result.current.data).toEqual([])
  })
})
