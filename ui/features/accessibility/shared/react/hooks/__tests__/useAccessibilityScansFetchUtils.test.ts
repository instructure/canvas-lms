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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

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

const server = setupServer()

// Mock getCourseBasedPath to return a predictable path
jest.mock('../../utils/query', () => ({
  ...jest.requireActual('../../utils/query'),
  getCourseBasedPath: (newPath: string) => `/courses/1${newPath}`,
  updateQueryParams: jest.fn(),
}))

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

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
    useAccessibilityScansStore.setState({...mockState})
  })

  afterEach(() => {
    server.resetHandlers()
  })

  it('should make a fetch attempt with default state, when newStateToFetch object is empty', async () => {
    let capturedUrl = ''
    server.use(
      http.get('*/accessibility/resource_scan', ({request}) => {
        capturedUrl = request.url
        return HttpResponse.json([])
      }),
    )

    const {result: storeResult} = renderHook(() => useAccessibilityScansStore())
    const {result} = renderHook(() => useAccessibilityScansFetchUtils())

    await act(async () => {
      await result.current.doFetchAccessibilityScanData({})
    })

    const params = new URL(capturedUrl).searchParams
    expect(params.get('page')).toBe(String(defaultStateToFetch.page))
    expect(params.get('per_page')).toBe(String(defaultStateToFetch.pageSize))
    expect(params.has('sort')).toBe(true)
    expect(params.has('direction')).toBe(true)

    expect(storeResult.current.page).toBe(defaultStateToFetch.page)
    expect(storeResult.current.pageSize).toBe(defaultStateToFetch.pageSize)
    expect(storeResult.current.tableSortState).toEqual(defaultStateToFetch.tableSortState)
    expect(storeResult.current.search).toBe(defaultStateToFetch.search)
  })

  it('should set pageCount based on API response headers', async () => {
    server.use(
      http.get('*/accessibility/resource_scan', () => {
        return HttpResponse.json([], {
          headers: {
            link:
              '</courses/1/accessibility/resource_scan?page=1&per_page=10>; rel="current",' +
              '</courses/1/accessibility/resource_scan?page=2&per_page=10>; rel="next",' +
              '</courses/1/accessibility/resource_scan?page=1&per_page=10>; rel="first",' +
              '</courses/1/accessibility/resource_scan?page=5&per_page=10>; rel="last"',
          },
        })
      }),
    )

    const {result: storeResult} = renderHook(() => useAccessibilityScansStore())
    const {result} = renderHook(() => useAccessibilityScansFetchUtils())

    await act(async () => {
      await result.current.doFetchAccessibilityScanData({})
    })

    expect(storeResult.current.pageCount).toBe(5)
  })

  it('should make a fetch attempt based on a non-empty newStateToFetch object, and update the store', async () => {
    let capturedUrl = ''
    server.use(
      http.get('*/accessibility/resource_scan', ({request}) => {
        capturedUrl = request.url
        return HttpResponse.json([])
      }),
    )

    const {result: storeResult} = renderHook(() => useAccessibilityScansStore())
    const {result} = renderHook(() => useAccessibilityScansFetchUtils())

    await act(async () => {
      await result.current.doFetchAccessibilityScanData(testNewStateToFetch)
    })

    const params = new URL(capturedUrl).searchParams
    expect(params.get('page')).toBe(String(testNewStateToFetch.page))
    expect(params.get('per_page')).toBe(String(testNewStateToFetch.pageSize))
    expect(params.get('search')).toBe(testNewStateToFetch.search)
    expect(params.get('sort')).toBe(
      IssuesTableHeaderApiNames[testNewStateToFetch.tableSortState!.sortId!],
    )
    expect(params.get('direction')).toBe(
      testNewStateToFetch.tableSortState!.sortDirection === 'ascending' ? 'asc' : 'desc',
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
    let capturedUrl = ''
    server.use(
      http.get('*/accessibility/resource_scan', ({request}) => {
        capturedUrl = request.url
        return HttpResponse.error()
      }),
    )

    const {result: storeResult} = renderHook(() => useAccessibilityScansStore())
    const {result} = renderHook(() => useAccessibilityScansFetchUtils())

    await act(async () => {
      await result.current.doFetchAccessibilityScanData(testNewStateToFetch)
    })

    const params = new URL(capturedUrl).searchParams
    expect(params.get('page')).toBe(String(testNewStateToFetch.page))
    expect(params.get('per_page')).toBe(String(testNewStateToFetch.pageSize))
    expect(params.get('sort')).toBe(
      IssuesTableHeaderApiNames[testNewStateToFetch.tableSortState!.sortId!],
    )
    expect(params.get('direction')).toBe(
      testNewStateToFetch.tableSortState!.sortDirection === 'ascending' ? 'asc' : 'desc',
    )

    expect(storeResult.current.error).toContain(API_FETCH_ERROR_MESSAGE_PREFIX)
    expect(storeResult.current.loading).toBe(false)

    expect(storeResult.current.page).toBe(initialState.page)
    expect(storeResult.current.pageSize).toBe(initialState.pageSize)
    expect(storeResult.current.tableSortState).toEqual(initialState.tableSortState)
    expect(storeResult.current.search).toBe(initialState.search)
  })
})
