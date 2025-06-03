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

import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks/dom'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useUserTags} from '../useUserTags'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')
const mockedDoFetchApi = doFetchApi as jest.Mock

describe('useUserTags', () => {
  let queryClient: QueryClient

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })
    jest.clearAllMocks()
  })

  const wrapper = ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )

  it('fetches user tags correctly', async () => {
    const mockResponse = {
      json: [
        {
          id: 1,
          name: 'Group 1',
          group_category_name: 'Category 1',
          is_single_tag: false,
        },
        {
          id: 2,
          name: 'Group 2',
          group_category_name: 'Category 2',
          is_single_tag: true,
        },
      ],
    }
    mockedDoFetchApi.mockResolvedValueOnce(mockResponse)

    const {result} = renderHook(() => useUserTags(123, 456), {wrapper})

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })
    expect(result.current.error).toBeNull()
    expect(result.current.data).toEqual([
      {
        id: 1,
        name: 'Group 1',
        groupCategoryName: 'Category 1',
        isSingleTag: false,
      },
      {
        id: 2,
        name: 'Group 2',
        groupCategoryName: 'Category 2',
        isSingleTag: true,
      },
    ])
    expect(mockedDoFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/courses/123/groups',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      params: {
        collaboration_state: 'non_collaborative',
        user_id: 456,
        per_page: 40,
      },
    })
  })

  it('handles API errors correctly', async () => {
    const mockError = new Error('Failed to fetch user tags')
    mockedDoFetchApi.mockRejectedValueOnce(mockError)

    const {result} = renderHook(() => useUserTags(123, 456), {wrapper})

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeTruthy()
    expect(result.current.error?.message).toContain('Failed to fetch user tags')
  })

  it('handles empty JSON response', async () => {
    mockedDoFetchApi.mockResolvedValueOnce({json: null})

    const {result} = renderHook(() => useUserTags(123, 456), {wrapper})

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeTruthy()
    expect(result.current.error?.message).toBe('Failed to fetch user tags')
  })

  it('does not fetch when courseId is missing', () => {
    renderHook(() => useUserTags(0, 456), {wrapper})
    expect(mockedDoFetchApi).not.toHaveBeenCalled()
  })

  it('does not fetch when userId is missing', () => {
    renderHook(() => useUserTags(123, 0), {wrapper})
    expect(mockedDoFetchApi).not.toHaveBeenCalled()
  })

  it('respects custom perPage parameter', async () => {
    mockedDoFetchApi.mockResolvedValueOnce({json: []})

    renderHook(() => useUserTags(123, 456, 20), {wrapper})

    await waitFor(() => {
      expect(mockedDoFetchApi).toHaveBeenCalled()
    })
    expect(mockedDoFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        params: expect.objectContaining({
          per_page: 20,
        }),
      }),
    )
  })
})
