/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {renderHook} from '@testing-library/react-hooks/dom'
import fetchMock from 'fetch-mock'
import useFilters from '../useFilters'

describe('useFilters', () => {
  let url
  let courseId
  const getRequests = () => fetchMock.calls(url)

  beforeEach(() => {
    courseId = '1'
    url = `/api/v1/courses/${courseId}/gradebook_filters`
  })

  describe('when the request succeeds', () => {
    let exampleData

    beforeEach(() => {
      exampleData = [
        {
          gradebook_filter: {
            id: '3',
            name: 'my filter',
            payload: {some: 'data'},
            created_at: '2021-01-05T16:57:49Z'
          }
        }
      ]
      fetchMock.mock(url, exampleData)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('starts loading if filters are enabled', () => {
      const {result} = renderHook(() => useFilters(courseId, true))
      expect(result.current.loading).toStrictEqual(true)
      expect(result.current.data).toStrictEqual([])
    })

    it('does not start loading if filters are disabled', () => {
      const {result} = renderHook(() => useFilters(courseId, false))
      expect(result.current.loading).toStrictEqual(false)
      expect(result.current.data).toStrictEqual([])
    })

    it('sends a request to the gradebook filters url', () => {
      renderHook(() => useFilters(courseId, true))
      const requests = getRequests()
      expect(requests.length).toStrictEqual(1)
    })

    it('includes the formatted gradebook filters when loading gradebook', async () => {
      const {result, waitForValueToChange} = renderHook(() => useFilters(courseId, true))
      await waitForValueToChange(() => result.current.data)
      expect(result.current.data).toStrictEqual([
        {
          id: '3',
          label: 'my filter',
          conditions: [],
          isApplied: false,
          createdAt: '2021-01-05T16:57:49Z'
        }
      ])
    })

    it('sets loading to false once the request returns', async () => {
      const {result, waitForValueToChange} = renderHook(() => useFilters(courseId, true))
      await waitForValueToChange(() => result.current.data)
      expect(result.current.loading).toStrictEqual(false)
    })
  })

  describe('when the request fails', () => {
    beforeEach(() => {
      fetchMock.mock(url, 500)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('starts loading if filters are enabled', () => {
      const {result} = renderHook(() => useFilters(courseId, true))
      expect(result.current.loading).toStrictEqual(true)
      expect(result.current.data).toStrictEqual([])
    })

    it('does not start loading if filters are disabled', () => {
      const {result} = renderHook(() => useFilters(courseId, false))
      expect(result.current.loading).toStrictEqual(false)
      expect(result.current.data).toStrictEqual([])
    })

    it('sends a request to the gradebook filters url', () => {
      renderHook(() => useFilters(courseId, true))
      const requests = getRequests()
      expect(requests.length).toStrictEqual(1)
    })

    it('sets the errors once the request returns', async () => {
      const {result, waitForValueToChange} = renderHook(() => useFilters(courseId, true))
      await waitForValueToChange(() => result.current.errors)
      expect(result.current.errors).toStrictEqual([
        {
          key: 'filters-loading-error',
          message: 'There was an error fetching gradebook filters.',
          variant: 'error'
        }
      ])
    })

    it('sets loading to false once the request returns', async () => {
      const {result, waitForValueToChange} = renderHook(() => useFilters(courseId, true))
      await waitForValueToChange(() => result.current.errors)
      expect(result.current.loading).toStrictEqual(false)
    })
  })
})
