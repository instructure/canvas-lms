/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {useSearchParams} from 'react-router-dom'
import type {SortOrder} from '../react/components/SortableTableHeader'

interface UseCoursesParamsOptions {
  defaultSort: string
  defaultOrder: SortOrder
}

interface UseCoursesParamsReturn {
  sort: string
  order: SortOrder
  page: number
  search: string
  handleChangeSort: (columnId: string) => void
  handlePageChange: (newPage: number) => void
  handleSearchChange: (newSearch: string) => void
}

export const useCoursesParams = ({
  defaultSort,
  defaultOrder,
}: UseCoursesParamsOptions): UseCoursesParamsReturn => {
  const [searchParams, setSearchParams] = useSearchParams()

  const sort = searchParams.get('sort') || defaultSort
  const order = (searchParams.get('order') || defaultOrder) as SortOrder
  const parsedPage = parseInt(searchParams.get('page') || '1', 10)
  const page = parsedPage > 0 ? parsedPage : 1
  const search = searchParams.get('search') || ''

  const handleChangeSort = useCallback(
    (columnId: string) => {
      const newOrder = columnId === sort && order === 'asc' ? 'desc' : 'asc'

      setSearchParams(params => {
        const newParams = new URLSearchParams(params)
        newParams.set('sort', columnId)
        newParams.set('order', newOrder)
        newParams.set('page', '1')
        return newParams
      })
    },
    [sort, order, setSearchParams],
  )

  const handlePageChange = useCallback(
    (newPage: number) => {
      setSearchParams(params => {
        const newParams = new URLSearchParams(params)
        newParams.set('page', String(newPage))
        return newParams
      })
    },
    [setSearchParams],
  )

  const handleSearchChange = useCallback(
    (newSearch: string) => {
      setSearchParams(params => {
        const newParams = new URLSearchParams(params)
        if (newSearch) {
          newParams.set('search', newSearch)
        } else {
          newParams.delete('search')
        }
        newParams.set('page', '1')
        return newParams
      })
    },
    [setSearchParams],
  )

  return {
    sort,
    order,
    page,
    search,
    handleChangeSort,
    handlePageChange,
    handleSearchChange,
  }
}
