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

import {ContentItem} from '../types'

export type TableSortState = {
  sortId?: string
  sortDirection?: TableColHeaderProps['sortDirection']
}

export type AccessibilityCheckerState = {
  page: number
  pageSize: number
  totalCount: number
  loading?: boolean
  error?: string | null
  tableSortState?: TableSortState | null
  tableData?: ContentItem[] | null
}

export type AccessibilityCheckerActions = {
  setPage: (page: number) => void
  setPageSize: (pageSize: number) => void
  setTotalCount: (totalCount: number) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  setTableSortState: (tableSortState: TableSortState | null) => void
  setTableData: (tableData: ContentItem[] | null) => void
}

export const initialState: AccessibilityCheckerState = {
  page: 0,
  pageSize: 10,
  totalCount: 0,
  loading: false,
  error: null,
  tableSortState: null,
  tableData: null,
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
      setTableSortState: tableSortState => set({tableSortState}),
      setTableData: tableData => set({tableData}),
    }),
    {
      name: 'AccessibilityCheckerStore',
    },
  ),
)
