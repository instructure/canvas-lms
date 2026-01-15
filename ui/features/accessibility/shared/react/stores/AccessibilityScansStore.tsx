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
import {AccessibilityIssuesSummaryData, AccessibilityResourceScan, Filters} from '../types'
import {IssuesTableColumns} from '../../../accessibility_checker/react/constants'

export const USE_ACCESSIBILITY_SCANS_STORE = false

export type NextResource = {
  index: number
  item?: AccessibilityResourceScan | null
}

export type TableSortState = {
  sortId?: string | null
  sortDirection?: TableColHeaderProps['sortDirection'] | null
}

export type NewStateToFetch = {
  page?: number
  pageSize?: number
  tableSortState?: TableSortState | null
  search?: string | null
  filters?: Filters | null
}

export type AccessibilityScansState = {
  page: number
  pageCount: number
  pageSize: number
  tableSortState?: TableSortState | null
  search?: string | null
  filters?: Filters | null
  totalCount: number
  loading?: boolean
  loadingOfSummary?: boolean
  error?: string | null
  errorOfSummary?: string | null
  accessibilityScans: AccessibilityResourceScan[] | null
  issuesSummary: AccessibilityIssuesSummaryData | null
  nextResource: NextResource
  isAiAltTextGenerationEnabled?: boolean
  isAiTableCaptionGenerationEnabled?: boolean
  discussionTopicsEnabled?: boolean
}

export type AccessibilityScansActions = {
  setPage: (page: number) => void
  setPageCount: (pageCount: number) => void
  setPageSize: (pageSize: number) => void
  setTableSortState: (tableSortState: TableSortState | null) => void
  setSearch: (search: string | null) => void
  setFilters: (filters: Filters | null) => void
  setTotalCount: (totalCount: number) => void
  setLoading: (loading: boolean) => void
  setLoadingOfSummary: (loadingOfSummary: boolean) => void
  setError: (error: string | null) => void
  setErrorOfSummary: (errorOfSummary: string | null) => void
  setAccessibilityScans: (accessibilityScans: AccessibilityResourceScan[] | null) => void
  setIssuesSummary: (issuesSummary: AccessibilityIssuesSummaryData | null) => void
  setNextResource: (nextResource: NextResource) => void
}

export const defaultNextResource: NextResource = {index: -1, item: null}

const defaultTableSortState: TableSortState = {
  sortId: IssuesTableColumns.Issues,
  sortDirection: 'descending',
}

export const initialState: AccessibilityScansState = {
  page: 1,
  pageCount: 1,
  pageSize: 10,
  tableSortState: defaultTableSortState,
  search: null,
  filters: null,
  totalCount: 0,
  loading: true,
  loadingOfSummary: true,
  error: null,
  errorOfSummary: null,
  accessibilityScans: null,
  issuesSummary: null,
  nextResource: defaultNextResource,
  discussionTopicsEnabled: window.ENV.FEATURES?.a11y_checker_additional_resources || false,
  isAiAltTextGenerationEnabled: window.ENV.FEATURES?.a11y_checker_ai_alt_text_generation || false,
  isAiTableCaptionGenerationEnabled:
    window.ENV.FEATURES?.a11y_checker_ai_table_caption_generation || false,
}

export const defaultStateToFetch: NewStateToFetch = {
  page: 1,
  pageSize: 10,
  tableSortState: defaultTableSortState,
  search: null,
  filters: null,
}

export const useAccessibilityScansStore = create<
  AccessibilityScansState & AccessibilityScansActions
>()(
  devtools(
    set => ({
      ...initialState,

      setPage: page => set({page}),
      setPageCount: pageCount => set({pageCount}),
      setPageSize: pageSize => set({pageSize}),
      setTableSortState: tableSortState => set({tableSortState}),
      setSearch: search => set({search}),
      setFilters: filters => set({filters}),
      setTotalCount: totalCount => set({totalCount}),
      setLoading: loading => set({loading}),
      setLoadingOfSummary: loadingOfSummary => set({loadingOfSummary}),
      setError: error => set({error}),
      setErrorOfSummary: errorOfSummary => set({errorOfSummary}),
      setAccessibilityScans: accessibilityScans => set({accessibilityScans}),
      setIssuesSummary: issuesSummary => set({issuesSummary}),
      setNextResource: nextResource => set({nextResource}),
    }),
    {
      name: 'AccessibilityScansStore',
    },
  ),
)
