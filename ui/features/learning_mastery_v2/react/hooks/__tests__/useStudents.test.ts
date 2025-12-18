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
import {useStudents} from '../useStudents'
import * as apiClient from '../../apiClient'
import {Student} from '../../types/rollup'

vi.mock('../../apiClient')

describe('useStudents', () => {
  const courseId = '123'

  const mockStudents: Student[] = [
    {
      id: '1',
      name: 'Alice Student',
      display_name: 'Alice',
      sortable_name: 'Student, Alice',
    },
    {
      id: '2',
      name: 'Bob Student',
      display_name: 'Bob',
      sortable_name: 'Student, Bob',
    },
    {
      id: '3',
      name: 'Charlie Student',
      display_name: 'Charlie',
      sortable_name: 'Student, Charlie',
    },
  ]

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('returns initial loading state with empty students', () => {
    vi.spyOn(apiClient, 'loadCourseUsers').mockReturnValue(new Promise(() => {}))

    const {result} = renderHook(() => useStudents(courseId))

    expect(result.current.isLoading).toBe(true)
    expect(result.current.students).toEqual([])
    expect(result.current.error).toBeNull()
  })

  it('loads students successfully', async () => {
    vi.spyOn(apiClient, 'loadCourseUsers').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: mockStudents,
    })

    const {result, waitForNextUpdate} = renderHook(() => useStudents(courseId))
    await waitForNextUpdate()

    expect(result.current.students).toEqual(mockStudents)
    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBeNull()
  })

  it('calls loadCourseUsers with correct courseId', async () => {
    const loadCourseUsersSpy = vi.spyOn(apiClient, 'loadCourseUsers').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: mockStudents,
    })

    const {waitForNextUpdate} = renderHook(() => useStudents(courseId))
    await waitForNextUpdate()

    expect(loadCourseUsersSpy).toHaveBeenCalledWith(courseId, undefined)
    expect(loadCourseUsersSpy).toHaveBeenCalledTimes(1)
  })

  it('sets error state on failed request', async () => {
    vi.spyOn(apiClient, 'loadCourseUsers').mockRejectedValue(new Error('Network error'))

    const {result, waitForNextUpdate} = renderHook(() => useStudents(courseId))
    await waitForNextUpdate()

    expect(result.current.students).toEqual([])
    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBe('Failed to load students')
  })

  it('clears students array on error', async () => {
    vi.spyOn(apiClient, 'loadCourseUsers').mockRejectedValue(new Error('API error'))

    const {result, waitForNextUpdate} = renderHook(() => useStudents(courseId))
    await waitForNextUpdate()

    expect(result.current.students).toEqual([])
    expect(result.current.error).toBeTruthy()
  })

  it('handles empty students array response', async () => {
    vi.spyOn(apiClient, 'loadCourseUsers').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: [],
    })

    const {result, waitForNextUpdate} = renderHook(() => useStudents(courseId))
    await waitForNextUpdate()

    expect(result.current.students).toEqual([])
    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBeNull()
  })

  it('refetches students when courseId changes', async () => {
    const loadCourseUsersSpy = vi.spyOn(apiClient, 'loadCourseUsers').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: mockStudents,
    })

    const {rerender, waitForNextUpdate} = renderHook(({id}) => useStudents(id), {
      initialProps: {id: '123'},
    })
    await waitForNextUpdate()

    expect(loadCourseUsersSpy).toHaveBeenCalledWith('123', undefined)
    expect(loadCourseUsersSpy).toHaveBeenCalledTimes(1)

    rerender({id: '456'})
    await waitForNextUpdate()

    expect(loadCourseUsersSpy).toHaveBeenCalledWith('456', undefined)
    expect(loadCourseUsersSpy).toHaveBeenCalledTimes(2)
  })

  it('sets loading to true when refetching after courseId change', async () => {
    vi.spyOn(apiClient, 'loadCourseUsers').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: mockStudents,
    })

    const {result, rerender, waitForNextUpdate} = renderHook(({id}) => useStudents(id), {
      initialProps: {id: '123'},
    })
    await waitForNextUpdate()

    expect(result.current.isLoading).toBe(false)

    rerender({id: '456'})
    expect(result.current.isLoading).toBe(true)
  })

  it('clears previous error on new request', async () => {
    vi
      .spyOn(apiClient, 'loadCourseUsers')
      .mockRejectedValueOnce(new Error('First error'))
      .mockResolvedValueOnce({
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {},
        data: mockStudents,
      })

    const {result, rerender, waitForNextUpdate} = renderHook(({id}) => useStudents(id), {
      initialProps: {id: '123'},
    })
    await waitForNextUpdate()

    expect(result.current.error).toBe('Failed to load students')

    rerender({id: '456'})
    await waitForNextUpdate()

    expect(result.current.error).toBeNull()
    expect(result.current.students).toEqual(mockStudents)
  })

  it('handles non-200 status code response', async () => {
    vi.spyOn(apiClient, 'loadCourseUsers').mockResolvedValue({
      status: 404,
      statusText: 'Not Found',
      headers: {},
      config: {},
      data: [],
    })

    const {result, waitForNextUpdate} = renderHook(() => useStudents(courseId))
    await waitForNextUpdate()

    expect(result.current.students).toEqual([])
    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBeNull()
  })

  it('handles response without data field', async () => {
    vi.spyOn(apiClient, 'loadCourseUsers').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: [],
    })

    const {result, waitForNextUpdate} = renderHook(() => useStudents(courseId))
    await waitForNextUpdate()

    expect(result.current.students).toEqual([])
    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBeNull()
  })

  it('works with numeric courseId', async () => {
    const loadCourseUsersSpy = vi.spyOn(apiClient, 'loadCourseUsers').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: mockStudents,
    })

    const {waitForNextUpdate} = renderHook(() => useStudents('456'))
    await waitForNextUpdate()

    expect(loadCourseUsersSpy).toHaveBeenCalledWith('456', undefined)
  })

  it('preserves student data structure from API response', async () => {
    const studentsWithAllFields: Student[] = [
      {
        id: '1',
        name: 'Alice Student',
        display_name: 'Alice',
        sortable_name: 'Student, Alice',
        sis_id: 'SIS123',
        integration_id: 'INT456',
        login_id: 'alice@example.com',
        avatar_url: 'https://example.com/avatar.jpg',
        status: 'active',
      },
    ]

    vi.spyOn(apiClient, 'loadCourseUsers').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: studentsWithAllFields,
    })

    const {result, waitForNextUpdate} = renderHook(() => useStudents(courseId))
    await waitForNextUpdate()

    expect(result.current.students).toEqual(studentsWithAllFields)
    expect(result.current.students[0].sis_id).toBe('SIS123')
    expect(result.current.students[0].integration_id).toBe('INT456')
    expect(result.current.students[0].login_id).toBe('alice@example.com')
  })
})
