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
import useModuleCourseSearchApi from '../useModuleCourseSearchApi'

function setupCourseModulesResponse() {
  const response = [
    {
      id: '1',
      name: 'Module Fire',
    },
    {
      id: '2',
      name: 'Module Water',
    },
  ]
  fetchMock.mock('path:/api/v1/courses/1/modules', response)
  return response
}

describe('useModuleCourseSearchApi', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('fetches and reports results', async () => {
    setupCourseModulesResponse()
    const success = jest.fn()
    const error = jest.fn()
    renderHook(() => useModuleCourseSearchApi({success, params: {contextId: 1}}))
    await fetchMock.flush(true)
    expect(error).not.toHaveBeenCalled()
    expect(success).toHaveBeenCalledWith([
      expect.objectContaining({id: '1', name: 'Module Fire'}),
      expect.objectContaining({id: '2', name: 'Module Water'}),
    ])
  })

  it('passes "per_page" query param on to the xhr call', async () => {
    setupCourseModulesResponse()
    const success = jest.fn()
    renderHook(() => useModuleCourseSearchApi({success, params: {contextId: 1, per_page: 50}}))
    await fetchMock.flush(true)
    expect(fetchMock.lastCall()[0]).toBe('/api/v1/courses/1/modules?per_page=50')
  })
})
