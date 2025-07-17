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

import {TableColHeaderProps} from '@instructure/ui-table'
import {create} from 'zustand'
import {devtools} from 'zustand/middleware'

import {AccessibilityResourceScan, Filters, ParsedFilters} from '../types'

export const USE_ACCESSIBILITY_SCANS_STORE = false

export type TableSortState = {
  sortId?: string | null
  sortDirection?: TableColHeaderProps['sortDirection'] | null
}

export type NewStateToFetch = {
  page?: number
  pageSize?: number
  tableSortState?: TableSortState | null
  search?: string | null
  filters?: ParsedFilters | null
}

/**
 * tableData: ContentItem[] | null - will reintroduce such, only if needed for local state management
 * accessibilityScanDisabled: boolean - removed due to getting that value in js_env from the API
 */
export type AccessibilityCheckerState = {
  page: number
  pageSize: number
  totalCount: number
  loading?: boolean
  error?: string | null
  accessibilityScans: AccessibilityResourceScan[] | null
  tableSortState?: TableSortState | null
  search?: string | null
  filters?: Filters | null
}

export type AccessibilityCheckerActions = {
  setPage: (page: number) => void
  setPageSize: (pageSize: number) => void
  setTotalCount: (totalCount: number) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  setAccessibilityScans: (accessibilityScans: AccessibilityResourceScan[] | null) => void
  setTableSortState: (tableSortState: TableSortState | null) => void
  setSearch: (search: string | null) => void
  setFilters: (filters: Filters | null) => void
}

export const initialState: AccessibilityCheckerState = {
  page: 0,
  pageSize: 10,
  totalCount: 0,
  loading: true,
  error: null,
  accessibilityScans: null,
  tableSortState: null,
  search: null,
  filters: null,
}

export const defaultStateToFetch: NewStateToFetch = {
  page: 0,
  pageSize: 10,
  tableSortState: {} as TableSortState,
  search: null,
  filters: null,
}

export const useAccessibilityScansStore = create<
  AccessibilityCheckerState & AccessibilityCheckerActions
>()(
  devtools(
    set => ({
      ...initialState,

      setPage: page => set({page}),
      setPageSize: pageSize => set({pageSize}),
      setTotalCount: totalCount => set({totalCount}),
      setLoading: loading => set({loading}),
      setError: error => set({error}),
      setAccessibilityScans: accessibilityScans => set({accessibilityScans}),
      setTableSortState: tableSortState => set({tableSortState}),
      setSearch: search => set({search}),
      setFilters: filters => set({filters}),
    }),
    {
      name: 'AccessibilityScansStore',
    },
  ),
)
