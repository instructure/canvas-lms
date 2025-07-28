/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import fetchMock from 'fetch-mock'
import {renderHook} from '@testing-library/react-hooks/dom'
import useManagedCourseSearchApi from '../useManagedCourseSearchApi'
import fakeENV from '@canvas/test-utils/fakeENV'

function setupManagedCoursesResponse() {
  const response = [
    {
      id: '1',
      label: 'Board Game Basics',
    },
    {
      id: '2',
      label: 'Settlers of Catan 101',
    },
  ]
  fetchMock.mock('path:/users/self/manageable_courses', response)
  return response
}

const defaultEnv = {
  current_user_roles: ['user', 'teacher'],
  current_user_is_admin: false,
}

describe('useManagedCourseSearchApi', () => {
  beforeEach(() => {
    // Setup fakeENV with default values
    fakeENV.setup(defaultEnv)

    // Reset fetchMock to ensure clean state
    fetchMock.restore()
  })

  afterEach(() => {
    // Properly teardown fakeENV
    fakeENV.teardown()
    fetchMock.restore()
  })

  it('fetches and reports converted results', async () => {
    setupManagedCoursesResponse()
    const success = jest.fn()
    const error = jest.fn()
    renderHook(() => useManagedCourseSearchApi({error, success, params: {term: 'game'}}))
    await fetchMock.flush(true)
    expect(error).not.toHaveBeenCalled()
    expect(success).toHaveBeenCalledWith([
      expect.objectContaining({id: '1', name: 'Board Game Basics'}),
      expect.objectContaining({id: '2', name: 'Settlers of Catan 101'}),
    ])
  })

  it('passes "enforce_manage_grant_filter" query param on the the xhr call', async () => {
    setupManagedCoursesResponse()
    renderHook(() =>
      useManagedCourseSearchApi({
        params: {term: 'game', enforce_manage_grant_filter: true},
      }),
    )
    await fetchMock.flush(true)
    expect(fetchMock.lastCall()[0]).toBe(
      '/users/self/manageable_courses?term=game&enforce_manage_grant_filter=true',
    )
  })

  it('does not pass an "include" query param in abscence of that param', async () => {
    setupManagedCoursesResponse()
    renderHook(() => useManagedCourseSearchApi({params: {term: 'game'}}))
    await fetchMock.flush(true)
    expect(fetchMock.lastCall()[0]).toBe('/users/self/manageable_courses?term=game')
  })

  it('passes "include" query param properly in addition to existing params', async () => {
    const params = {term: 'Course', include: 'concluded'}
    setupManagedCoursesResponse()
    renderHook(() => useManagedCourseSearchApi({params}))
    await fetchMock.flush(true)
    expect(fetchMock.lastCall()[0]).toBe(
      '/users/self/manageable_courses?term=Course&include=concluded',
    )
  })

  describe('when user is a teacher', () => {
    beforeEach(() => {
      // Setup fakeENV with teacher role and ensure admin flag is false
      fakeENV.setup({
        current_user_roles: ['user', 'teacher'],
        current_user_is_admin: false,
      })

      // Reset fetchMock to ensure clean state
      fetchMock.restore()
    })

    it('makes network request when search term is not included', async () => {
      // Setup the mock response
      setupManagedCoursesResponse()

      // Render the hook with no parameters
      renderHook(() => useManagedCourseSearchApi())

      // Wait for all fetch calls to complete
      await fetchMock.flush(true)

      // Verify a network request was made
      expect(fetchMock.calls()).toHaveLength(1)
      expect(fetchMock.lastCall()[0]).toBe('/users/self/manageable_courses')
    })
  })

  describe('when user is an admin', () => {
    beforeEach(() => {
      // Setup fakeENV with admin role and flag
      fakeENV.setup({
        current_user_roles: ['user', 'teacher', 'admin'],
        current_user_is_admin: true,
      })

      // Reset fetchMock to ensure clean state
      fetchMock.restore()
    })

    it('does not make network request if search term is not included', async () => {
      setupManagedCoursesResponse()
      renderHook(useManagedCourseSearchApi)
      await fetchMock.flush(true)
      expect(fetchMock.calls()).toHaveLength(0)
    })

    it('does not make network request if search term is only one character', async () => {
      setupManagedCoursesResponse()
      renderHook(() => useManagedCourseSearchApi({params: {term: 'a'}}))
      await fetchMock.flush(true)
      expect(fetchMock.calls()).toHaveLength(0)
    })
  })
})
