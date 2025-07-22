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

import {useCallback} from 'react'
import {useShallow} from 'zustand/react/shallow'
import doFetchApi, {DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {TableColHeaderProps} from '@instructure/ui-table'

import {
  defaultStateToFetch,
  NewStateToFetch,
  TableSortState,
  useAccessibilityCheckerStore,
} from '../stores/AccessibilityCheckerStore'
import {API_FETCH_ERROR_MESSAGE_PREFIX, IssuesTableColumns} from '../constants'
import {AccessibilityData} from '../types'
import {convertKeysToCamelCase, processAccessibilityData} from '../utils/apiData'

export const useAccessibilityFetchUtils = () => {
  const [page, pageSize, search, tableSortState] = useAccessibilityCheckerStore(
    useShallow(state => [state.page, state.pageSize, state.search, state.tableSortState]),
  )
  const [
    setAccessibilityIssues,
    setError,
    setLoading,
    setPage,
    setPageSize,
    setTableData,
    setTableSortState,
    setSearch,
  ] = useAccessibilityCheckerStore(
    useShallow(state => [
      state.setAccessibilityIssues, // Set accessibility issues
      state.setError,
      state.setLoading,
      state.setPage,
      state.setPageSize,
      state.setTableData,
      state.setTableSortState,
      state.setSearch,
    ]),
  )

  const parseFetchParams = useCallback(() => {
    const parsedFetchParams: NewStateToFetch = {
      page: defaultStateToFetch.page,
      pageSize: defaultStateToFetch.pageSize,
      tableSortState: {
        ...defaultStateToFetch.tableSortState,
      },
      search: defaultStateToFetch.search,
    }
    const queryParams = new URLSearchParams(window.location.search)

    if (queryParams.has('page')) {
      const page = parseInt(queryParams.get('page') || ``)
      parsedFetchParams.page = isNaN(page) ? defaultStateToFetch.page : Math.max(page, 1) - 1
    }

    if (queryParams.has('page-size')) {
      const pageSize = parseInt(queryParams.get('page-size') || ``)
      parsedFetchParams.pageSize = isNaN(pageSize)
        ? defaultStateToFetch.pageSize
        : Math.max(pageSize, 1)
    }

    if (queryParams.has('sort-id')) {
      const sortId = queryParams.get('sort-id')

      if (Object.values(IssuesTableColumns).includes(sortId ?? '')) {
        const sortDirection = queryParams.get('sort-direction')
        if (['ascending', 'descending'].includes(sortDirection ?? '')) {
          parsedFetchParams.tableSortState!.sortId = sortId
          parsedFetchParams.tableSortState!.sortDirection =
            sortDirection as TableColHeaderProps['sortDirection']
        }
      }

      parsedFetchParams.tableSortState!.sortId = queryParams.get('sort-id')
    }

    if (queryParams.has('search')) {
      parsedFetchParams.search = queryParams.get('search') || defaultStateToFetch.search
    }

    return parsedFetchParams
  }, [])

  /**
   * Temporarily used function, until changing this won't need to trigger a refetch.
   */
  const updateQueryParamPage = useCallback((newPage?: number) => {
    const queryParams = new URLSearchParams(window.location.search)
    if (newPage !== undefined) {
      queryParams.set('page', (newPage + 1).toString())
    } else {
      queryParams.delete('page')
    }

    window.history.replaceState(null, '', `${window.location.pathname}?${queryParams.toString()}`)
  }, [])

  /**
   * Temporarily used function, until changing this won't need to trigger a refetch.
   */
  const updateQueryParamPageSize = useCallback((newPageSize?: number) => {
    const queryParams = new URLSearchParams(window.location.search)
    if (newPageSize !== undefined && newPageSize !== defaultStateToFetch.pageSize) {
      queryParams.set('page-size', newPageSize.toString())
    } else {
      queryParams.delete('page-size')
    }

    window.history.replaceState(null, '', `${window.location.pathname}?${queryParams.toString()}`)
  }, [])

  /**
   * Temporarily used function, until changing this won't need to trigger a refetch.
   */
  const updateQueryParamTableSortState = useCallback((newTableSortState?: TableSortState) => {
    const queryParams = new URLSearchParams(window.location.search)

    const newSortDirectionUsed = newTableSortState?.sortDirection || 'none'

    if (newTableSortState?.sortId && newSortDirectionUsed !== 'none') {
      queryParams.set('sort-id', newTableSortState.sortId)
      queryParams.set('sort-direction', newSortDirectionUsed)
    } else {
      queryParams.delete('sort-id')
      queryParams.delete('sort-direction')
    }

    window.history.replaceState(null, '', `${window.location.pathname}?${queryParams.toString()}`)
  }, [])

  const updateQueryParams = useCallback((latestFetchedState: NewStateToFetch) => {
    const queryParams = new URLSearchParams(window.location.search)
    const {page, pageSize, tableSortState, search} = latestFetchedState

    if (page !== undefined) {
      queryParams.set('page', (page + 1).toString())
    } else {
      queryParams.delete('page')
    }

    if (pageSize !== undefined && pageSize !== defaultStateToFetch.pageSize) {
      queryParams.set('page-size', pageSize.toString())
    } else {
      queryParams.delete('page-size')
    }

    const newSortDirectionUsed = tableSortState?.sortDirection || 'none'

    if (tableSortState?.sortId && newSortDirectionUsed !== 'none') {
      queryParams.set('sort-id', tableSortState.sortId)
      queryParams.set('sort-direction', tableSortState.sortDirection || 'none')
    } else {
      queryParams.delete('sort-id')
      queryParams.delete('sort-direction')
    }

    if (search) {
      queryParams.set('search', search)
    } else {
      queryParams.delete('search')
    }

    window.history.replaceState(null, '', `${window.location.pathname}?${queryParams.toString()}`)
  }, [])

  /**
   * @param requestedFetch - New state to fetch, can be partial
   */
  const doFetchAccessibilityIssues = useCallback(
    async (requestedStateChange: Partial<NewStateToFetch>) => {
      try {
        // Picking up existing state (or default, if not yet set)
        const newStateToFetch: NewStateToFetch = {
          ...defaultStateToFetch,
          page,
          pageSize,
          tableSortState: tableSortState || defaultStateToFetch.tableSortState,
          search,
        }

        Object.assign(newStateToFetch, requestedStateChange)

        setLoading(true)
        setError(null)

        const data: DoFetchApiResults<any> = await doFetchApi({
          path: window.location.pathname + '/issues',
          method: 'POST',
          body: JSON.stringify({
            search: newStateToFetch.search,
          }),
        })

        const accessibilityIssues = convertKeysToCamelCase(data.json) as AccessibilityData
        setAccessibilityIssues(accessibilityIssues)
        setTableData(processAccessibilityData(accessibilityIssues))

        setPage(newStateToFetch.page!)
        setPageSize(newStateToFetch.pageSize!)
        setTableSortState(newStateToFetch.tableSortState!)
        setSearch(newStateToFetch.search!)

        updateQueryParams(newStateToFetch)
      } catch (err: any) {
        setError(API_FETCH_ERROR_MESSAGE_PREFIX + err.message)
        setAccessibilityIssues(null)
        setTableData([])
      } finally {
        setLoading(false)
      }
    },
    [
      page,
      pageSize,
      search,
      tableSortState,
      setAccessibilityIssues,
      setError,
      setLoading,
      setPage,
      setPageSize,
      setTableData,
      setTableSortState,
      setSearch,
      updateQueryParams,
    ],
  )

  return {
    doFetchAccessibilityIssues,
    parseFetchParams,
    updateQueryParamPage,
    updateQueryParamPageSize,
    updateQueryParamTableSortState,
  }
}
