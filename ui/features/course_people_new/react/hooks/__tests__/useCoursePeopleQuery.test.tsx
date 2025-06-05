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

import React from 'react'
import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import useCoursePeopleQuery, {CoursePeopleQueryResponse, QueryProps} from '../useCoursePeopleQuery'
import {executeQuery} from '@canvas/graphql'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {DEFAULT_OPTION, DEFAULT_SORT_FIELD, DEFAULT_SORT_DIRECTION} from '../../../util/constants'
import type {User} from '../../../types'

jest.mock('../useCoursePeopleContext')
jest.mock('@canvas/graphql')
const mockExecuteQuery = executeQuery as jest.Mock

describe('useCoursePeopleQuery', () => {
  const allRoles = [
    {...DEFAULT_OPTION, id: '1', label: 'Teacher', count: 1},
    {...DEFAULT_OPTION, id: '2', label: 'Student', count: 2},
  ]
  const filterOptions = [DEFAULT_OPTION, ...allRoles]
  const [defaultRole, otherRole] = filterOptions

  const defaultProps: QueryProps = {
    courseId: '123',
    searchTerm: '',
    optionId: defaultRole.id,
    sortField: DEFAULT_SORT_FIELD,
    sortDirection: DEFAULT_SORT_DIRECTION,
  }

  const useCoursePeopleContextMocks = {
    allRoles,
  }

  const defaultQueryProps = {
    courseId: '123',
    enrollmentRoleIds: undefined,
    enrollmentsSortDirection: 'asc',
    enrollmentsSortField: 'section_name',
    searchTerm: '',
    sortField: DEFAULT_SORT_FIELD,
    sortDirection: DEFAULT_SORT_DIRECTION,
  }

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  const mockData: CoursePeopleQueryResponse = {
    course: {
      usersConnection: {
        nodes: [{_id: '1', name: 'Test User'} as User, {_id: '2', name: 'Another User'} as User],
      },
    },
  }

  const filteredMockData: CoursePeopleQueryResponse = {
    course: {
      usersConnection: {
        nodes: [{_id: '1', name: 'Test User'} as User],
      },
    },
  }

  const wrapper = (props: any) => (
    <QueryClientProvider client={queryClient}>{props.children}</QueryClientProvider>
  )

  beforeEach(() => {
    require('../useCoursePeopleContext').default.mockReturnValue(useCoursePeopleContextMocks)
    mockExecuteQuery.mockClear()
    queryClient.clear()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('fetches roster data successfully', async () => {
    mockExecuteQuery.mockResolvedValue(mockData)

    const {result} = renderHook(() => useCoursePeopleQuery(defaultProps), {wrapper})

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(executeQuery).toHaveBeenCalledWith(expect.anything(), defaultQueryProps)
    expect(result.current.data).toEqual(mockData.course.usersConnection.nodes)
  })

  it('handles empty response', async () => {
    mockExecuteQuery.mockResolvedValue({})

    const {result} = renderHook(() => useCoursePeopleQuery(defaultProps), {wrapper})

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(executeQuery).toHaveBeenCalledWith(expect.anything(), defaultQueryProps)
    expect(result.current.data).toEqual([])
  })

  it('handles error state', async () => {
    const error = new Error('Failed to fetch')
    mockExecuteQuery.mockRejectedValue(error)

    const {result} = renderHook(() => useCoursePeopleQuery(defaultProps), {wrapper})

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
    })

    expect(result.current.error).toBeDefined()
  })

  it('includes searchTerm in query parameters', async () => {
    mockExecuteQuery.mockResolvedValue(filteredMockData)

    const {result} = renderHook(() => useCoursePeopleQuery({...defaultProps, searchTerm: 'Test'}), {
      wrapper,
    })

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(executeQuery).toHaveBeenCalledWith(expect.anything(), {
      ...defaultQueryProps,
      searchTerm: 'Test',
    })
  })

  it('updates data when searchTerm changes', async () => {
    mockExecuteQuery.mockResolvedValueOnce(mockData).mockResolvedValueOnce(filteredMockData)

    const {result, rerender} = renderHook<
      {searchTerm: string},
      ReturnType<typeof useCoursePeopleQuery>
    >(({searchTerm}) => useCoursePeopleQuery({...defaultProps, searchTerm}), {
      wrapper,
      initialProps: {searchTerm: ''},
    })

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
      expect(result.current.data).toEqual(mockData.course.usersConnection.nodes)
    })

    rerender({searchTerm: 'Test'})

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
      expect(result.current.data).toEqual(filteredMockData.course.usersConnection.nodes)
    })
  })

  it('does not fetch when search term is one character', () => {
    mockExecuteQuery.mockResolvedValue(mockData)

    const {result} = renderHook(() => useCoursePeopleQuery({...defaultProps, searchTerm: 'a'}), {
      wrapper,
    })

    expect(result.current.isFetching).toBe(false)
    expect(executeQuery).not.toHaveBeenCalled()
  })

  it('updates data when filter role changes', async () => {
    mockExecuteQuery.mockResolvedValue(mockData)

    const {result, rerender} = renderHook<
      {optionId: string},
      ReturnType<typeof useCoursePeopleQuery>
    >(({optionId}) => useCoursePeopleQuery({...defaultProps, optionId}), {
      wrapper,
      initialProps: {optionId: defaultRole.id},
    })

    rerender({optionId: otherRole.id})

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(executeQuery).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        enrollmentRoleIds: [otherRole.id],
      }),
    )
  })
})
