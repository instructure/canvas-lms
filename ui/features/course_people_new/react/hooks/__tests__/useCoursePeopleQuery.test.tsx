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

import React, {ReactNode} from 'react'
import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import useCoursePeopleQuery from '../useCoursePeopleQuery'
import {executeQuery} from '@canvas/query/graphql'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

jest.mock('@canvas/query/graphql')

const mockExecuteQuery = executeQuery as jest.Mock

describe('useCoursePeopleQuery', () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false
      }
    }
  })

  const mockData = {
    course: {
      usersConnection: {
        nodes: [
          {_id: '1', name: 'Test User'},
          {_id: '2', name: 'Another User'}
        ]
      }
    }
  }

  const filteredMockData = {
    course: {
      usersConnection: {
        nodes: [
          {_id: '1', name: 'Test User'}
        ]
      }
    }
  }

  const wrapper = ({children}: {children: ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )

  beforeEach(() => {
    mockExecuteQuery.mockClear()
    queryClient.clear()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('fetches roster data successfully', async () => {
    mockExecuteQuery.mockResolvedValue(mockData)

    const {result} = renderHook(
      () => useCoursePeopleQuery({courseId: '123', searchTerm: ''}),
      {wrapper}
    )

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(executeQuery).toHaveBeenCalledWith(expect.anything(), {courseId: '123', searchTerm: ''})
    expect(result.current.data).toEqual(mockData.course.usersConnection.nodes)
  })

  it('handles empty response', async () => {
    mockExecuteQuery.mockResolvedValue({})

    const {result} = renderHook(
      () => useCoursePeopleQuery({courseId: '123', searchTerm: ''}),
      {wrapper}
    )

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(executeQuery).toHaveBeenCalledWith(expect.anything(), {courseId: '123', searchTerm: ''})
    expect(result.current.data).toEqual([])
  })

  it('handles error state', async () => {
    const error = new Error('Failed to fetch')
    mockExecuteQuery.mockRejectedValue(error)

    const {result} = renderHook(
      () => useCoursePeopleQuery({courseId: '123', searchTerm: ''}),
      {wrapper}
    )

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
    })

    expect(result.current.error).toBeDefined()
  })

  it('includes searchTerm in query parameters', async () => {
    mockExecuteQuery.mockResolvedValue(filteredMockData)

    const {result} = renderHook(
      () => useCoursePeopleQuery({courseId: '123', searchTerm: 'Test'}),
      {wrapper}
    )

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(executeQuery).toHaveBeenCalledWith(expect.anything(), {courseId: '123', searchTerm: 'Test'})
  })

  it('updates data when searchTerm changes', async () => {
    mockExecuteQuery
      .mockResolvedValueOnce(mockData)
      .mockResolvedValueOnce(filteredMockData)

    let searchTerm = ''
    const {result, rerender} = renderHook(
      () => useCoursePeopleQuery({courseId: '123', searchTerm}),
      {wrapper}
    )

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
      expect(result.current.data).toEqual(mockData.course.usersConnection.nodes)
    })

    searchTerm = 'Test'
    rerender()

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
      expect(result.current.data).toEqual(filteredMockData.course.usersConnection.nodes)
    })

    expect(executeQuery).toHaveBeenCalledTimes(2)
    expect(executeQuery).toHaveBeenNthCalledWith(1, expect.anything(), {courseId: '123', searchTerm: ''})
    expect(executeQuery).toHaveBeenNthCalledWith(2, expect.anything(), {courseId: '123', searchTerm: 'Test'})
  })
})
