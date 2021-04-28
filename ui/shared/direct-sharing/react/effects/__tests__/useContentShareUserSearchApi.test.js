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

import useContentShareUserSearchApi from '../useContentShareUserSearchApi'

describe('useContentShareUserSearchApi', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  const path = '/api/v1/courses/42/content_share_users'

  it('reports null as its result if the search term is too short', () => {
    const success = jest.fn()
    renderHook(() =>
      useContentShareUserSearchApi({success, courseId: '42', params: {search_term: '12'}})
    )
    expect(success).toHaveBeenCalledWith(null)
  })

  it('fetches results if the search term is long enough', async () => {
    fetchMock.mock(`path:${path}`, ['list of users'])
    const success = jest.fn()
    renderHook(() =>
      useContentShareUserSearchApi({success, courseId: '42', params: {search_term: '123'}})
    )
    await fetchMock.flush(true)
    expect(fetchMock.done()).toBe(true)
    expect(success).toHaveBeenCalledWith(['list of users'])
  })

  it('throws if the courseId parameter is missing', () => {
    const {result} = renderHook(() => useContentShareUserSearchApi({params: {search_term: '123'}}))
    expect(result.error).toBeDefined()
    expect(result.error.message).toMatch(/courseId.*required/)
  })
})
