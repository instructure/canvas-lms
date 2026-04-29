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

import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {renderHook} from '@testing-library/react-hooks/dom'
import {waitFor} from '@testing-library/react'
import useManagedCourseSearchApi from '../useManagedCourseSearchApi'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = setupServer()

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

const defaultEnv = {
  current_user_roles: ['user', 'teacher'],
  current_user_is_admin: false,
}

describe('useManagedCourseSearchApi', () => {
  let lastRequestUrl
  let requestCount

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    // Setup fakeENV with default values
    fakeENV.setup(defaultEnv)

    lastRequestUrl = undefined
    requestCount = 0

    server.use(
      http.get('/users/self/manageable_courses', ({request}) => {
        lastRequestUrl = request.url
        requestCount++
        return HttpResponse.json(response)
      }),
    )
  })

  afterEach(() => {
    // Properly teardown fakeENV
    fakeENV.teardown()
    server.resetHandlers()
  })

  it('fetches and reports converted results', async () => {
    const success = vi.fn()
    const error = vi.fn()
    renderHook(() => useManagedCourseSearchApi({error, success, params: {term: 'game'}}))
    await waitFor(() => {
      expect(success).toHaveBeenCalledWith([
        expect.objectContaining({id: '1', name: 'Board Game Basics'}),
        expect.objectContaining({id: '2', name: 'Settlers of Catan 101'}),
      ])
    })
    expect(error).not.toHaveBeenCalled()
  })

  it('passes "enforce_manage_grant_filter" query param on the the xhr call', async () => {
    renderHook(() =>
      useManagedCourseSearchApi({
        params: {term: 'game', enforce_manage_grant_filter: true},
      }),
    )
    await waitFor(() => {
      expect(lastRequestUrl).toContain(
        '/users/self/manageable_courses?term=game&enforce_manage_grant_filter=true',
      )
    })
  })

  it('does not pass an "include" query param in abscence of that param', async () => {
    renderHook(() => useManagedCourseSearchApi({params: {term: 'game'}}))
    await waitFor(() => {
      expect(lastRequestUrl).toContain('/users/self/manageable_courses?term=game')
    })
  })

  it('passes "include" query param properly in addition to existing params', async () => {
    const params = {term: 'Course', include: 'concluded'}
    renderHook(() => useManagedCourseSearchApi({params}))
    await waitFor(() => {
      expect(lastRequestUrl).toContain(
        '/users/self/manageable_courses?term=Course&include=concluded',
      )
    })
  })

  describe('when user is a teacher', () => {
    beforeEach(() => {
      // Setup fakeENV with teacher role and ensure admin flag is false
      fakeENV.setup({
        current_user_roles: ['user', 'teacher'],
        current_user_is_admin: false,
      })

      requestCount = 0
    })

    it('makes network request when search term is not included', async () => {
      // Render the hook with no parameters
      renderHook(() => useManagedCourseSearchApi())

      // Wait for the request
      await waitFor(() => {
        expect(requestCount).toBe(1)
        expect(lastRequestUrl).toContain('/users/self/manageable_courses')
      })
    })
  })

  describe('when user is an admin', () => {
    beforeEach(() => {
      // Setup fakeENV with admin role and flag
      fakeENV.setup({
        current_user_roles: ['user', 'teacher', 'admin'],
        current_user_is_admin: true,
      })

      requestCount = 0
    })

    it('does not make network request if search term is not included', async () => {
      renderHook(useManagedCourseSearchApi)
      // Give it some time to potentially make a request
      await new Promise(resolve => setTimeout(resolve, 100))
      expect(requestCount).toBe(0)
    })

    it('does not make network request if search term is only one character', async () => {
      renderHook(() => useManagedCourseSearchApi({params: {term: 'a'}}))
      // Give it some time to potentially make a request
      await new Promise(resolve => setTimeout(resolve, 100))
      expect(requestCount).toBe(0)
    })
  })
})
