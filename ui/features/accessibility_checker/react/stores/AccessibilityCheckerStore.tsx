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

import {AccessibilityData, ContentItem} from '../types'

export type NextResource = {
  index: number
  item?: ContentItem | null
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
}

export type AccessibilityCheckerState = {
  page: number
  pageSize: number
  totalCount: number
  loading?: boolean
  error?: string | null
  accessibilityIssues: AccessibilityData | null
  accessibilityScanDisabled: boolean
  tableSortState?: TableSortState | null
  tableData: ContentItem[] | null // TODO convert items to ContentItemForDisplay[]
  orderedTableData: ContentItem[] | null
  nextResource: NextResource
  search?: string | null
}

export type AccessibilityCheckerActions = {
  setPage: (page: number) => void
  setPageSize: (pageSize: number) => void
  setTotalCount: (totalCount: number) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  setAccessibilityIssues: (accessibilityIssues: AccessibilityData | null) => void
  setAccessibilityScanDisabled: (accessibilityScanDisabled: boolean) => void
  setTableSortState: (tableSortState: TableSortState | null) => void
  setTableData: (tableData: ContentItem[] | null) => void
  setOrderedTableData: (paginatedData: ContentItem[] | null) => void
  setNextResource: (nextResource: NextResource) => void
  setSearch: (search: string | null) => void
}

export const defaultNextResource: NextResource = {index: -1, item: null}

export const initialState: AccessibilityCheckerState = {
  page: 0,
  pageSize: 10,
  totalCount: 0,
  loading: true,
  error: null,
  accessibilityIssues: null,
  accessibilityScanDisabled: false,
  tableSortState: null,
  tableData: null,
  orderedTableData: null,
  nextResource: defaultNextResource,
  search: null,
}

export const defaultStateToFetch: NewStateToFetch = {
  page: 0,
  pageSize: 10,
  tableSortState: {} as TableSortState,
  search: null,
}

export const useAccessibilityCheckerStore = create<
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
      setAccessibilityIssues: accessibilityIssues => set({accessibilityIssues}),
      setAccessibilityScanDisabled: accessibilityScanDisabled => set({accessibilityScanDisabled}),
      setTableSortState: tableSortState => set({tableSortState}),
      setTableData: tableData => set({tableData}),
      setOrderedTableData: orderedTableData => set({orderedTableData}),
      setNextResource: nextResource => set({nextResource}),
      setSearch: search => set({search}),
    }),
    {
      name: 'AccessibilityCheckerStore',
    },
  ),
)
