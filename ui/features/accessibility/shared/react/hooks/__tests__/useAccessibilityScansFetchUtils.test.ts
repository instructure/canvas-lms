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

import {act, renderHook} from '@testing-library/react-hooks'

import doFetchApi from '@canvas/do-fetch-api-effect'

import {useAccessibilityScansFetchUtils} from '../useAccessibilityScansFetchUtils'
import {
  defaultStateToFetch,
  initialState,
  NewStateToFetch,
  useAccessibilityScansStore,
} from '../../stores/AccessibilityScansStore'
import {
  API_FETCH_ERROR_MESSAGE_PREFIX,
  IssuesTableColumns,
  IssuesTableHeaderApiNames,
} from '../../../../accessibility_checker/react/constants'

jest.mock('@canvas/do-fetch-api-effect')

describe('useAccessibilityScanFetchUtils', () => {
  const mockState = {
    ...initialState,
  }

  const testNewStateToFetch: NewStateToFetch = {
    page: 2,
    pageSize: 5,
    tableSortState: {sortId: IssuesTableColumns.Issues, sortDirection: 'ascending'},
    search: 'test',
    filters: {ruleTypes: [{value: 'type1', label: 'type1'}]},
  }

  beforeEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
    useAccessibilityScansStore.setState({...mockState})
  })

  it('should make a fetch attempt with default state, when newStateToFetch object is empty', async () => {
    const {result: storeResult} = renderHook(() => useAccessibilityScansStore())
    const {result} = renderHook(() => useAccessibilityScansFetchUtils())
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({})

    await act(async () => {
      await result.current.doFetchAccessibilityScanData({})
    })

    const callObj = (doFetchApi as jest.Mock).mock.calls[0][0]

    expect(callObj).toEqual(
      expect.objectContaining({
        params: expect.objectContaining({
          page: defaultStateToFetch.page,
          per_page: defaultStateToFetch.pageSize,
        }),
      }),
    )

    expect(callObj.params).toHaveProperty('sort')
    expect(callObj.params).toHaveProperty('direction')

    expect(storeResult.current.page).toBe(defaultStateToFetch.page)
    expect(storeResult.current.pageSize).toBe(defaultStateToFetch.pageSize)
    expect(storeResult.current.tableSortState).toEqual(defaultStateToFetch.tableSortState)
    expect(storeResult.current.search).toBe(defaultStateToFetch.search)
  })

  it('should set pageCount based on API response headers', async () => {
    const {result: storeResult} = renderHook(() => useAccessibilityScansStore())
    const {result} = renderHook(() => useAccessibilityScansFetchUtils())
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
      json: [],
      response: {
        headers: new Headers({
          link:
            '</courses/1/accessibility/resource_scan?page=1&per_page=10>; rel="current",' +
            '</courses/1/accessibility/resource_scan?page=2&per_page=10>; rel="next",' +
            '</courses/1/accessibility/resource_scan?page=1&per_page=10>; rel="first",' +
            '</courses/1/accessibility/resource_scan?page=5&per_page=10>; rel="last"', // PageCount calculated from last link
        }),
      },
    })

    await act(async () => {
      await result.current.doFetchAccessibilityScanData({})
    })

    expect(storeResult.current.pageCount).toBe(5)
  })

  it('should make a fetch attempt based on a non-empty newStateToFetch object, and update the store', async () => {
    const {result: storeResult} = renderHook(() => useAccessibilityScansStore())
    const {result} = renderHook(() => useAccessibilityScansFetchUtils())
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({})

    await act(async () => {
      await result.current.doFetchAccessibilityScanData(testNewStateToFetch)
    })

    const callObj = (doFetchApi as jest.Mock).mock.calls[0][0]

    expect(callObj).toEqual(
      expect.objectContaining({
        params: expect.objectContaining({
          page: testNewStateToFetch.page,
          per_page: testNewStateToFetch.pageSize,
          filters: {
            ...testNewStateToFetch.filters,
            ruleTypes: testNewStateToFetch.filters?.ruleTypes?.map(rule => rule.value),
          },
          search: testNewStateToFetch.search,
          sort: IssuesTableHeaderApiNames[testNewStateToFetch.tableSortState!.sortId!],
          direction:
            testNewStateToFetch.tableSortState!.sortDirection === 'ascending' ? 'asc' : 'desc',
        }),
      }),
    )

    expect(storeResult.current.error).toBeNull()
    expect(storeResult.current.loading).toBe(false)

    expect(storeResult.current.page).toBe(testNewStateToFetch.page)
    expect(storeResult.current.pageSize).toBe(testNewStateToFetch.pageSize)
    expect(storeResult.current.tableSortState).toEqual(testNewStateToFetch.tableSortState)
    expect(storeResult.current.filters).toBe(testNewStateToFetch.filters)
    expect(storeResult.current.search).toBe(testNewStateToFetch.search)
  })

  it('should only save the error message in the store if the fetch fails', async () => {
    const {result: storeResult} = renderHook(() => useAccessibilityScansStore())
    const {result} = renderHook(() => useAccessibilityScansFetchUtils())
    ;(doFetchApi as jest.Mock).mockRejectedValueOnce(new Error('Fetch failed'))

    await act(async () => {
      await result.current.doFetchAccessibilityScanData(testNewStateToFetch)
    })

    const callObj = (doFetchApi as jest.Mock).mock.calls[0][0]

    expect(callObj).toEqual(
      expect.objectContaining({
        params: expect.objectContaining({
          page: testNewStateToFetch.page,
          per_page: testNewStateToFetch.pageSize,
          sort: IssuesTableHeaderApiNames[testNewStateToFetch.tableSortState!.sortId!],
          direction:
            testNewStateToFetch.tableSortState!.sortDirection === 'ascending' ? 'asc' : 'desc',
          // search: testNewStateToFetch.search, - TODO uncomment when API supports search
        }),
      }),
    )

    expect(storeResult.current.error).toEqual(API_FETCH_ERROR_MESSAGE_PREFIX + 'Fetch failed')
    expect(storeResult.current.loading).toBe(false)

    expect(storeResult.current.page).toBe(initialState.page)
    expect(storeResult.current.pageSize).toBe(initialState.pageSize)
    expect(storeResult.current.tableSortState).toEqual(initialState.tableSortState)
    expect(storeResult.current.search).toBe(initialState.search)
  })
})
