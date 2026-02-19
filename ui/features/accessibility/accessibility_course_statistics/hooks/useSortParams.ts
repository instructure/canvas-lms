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

interface UseSortParamsOptions {
  defaultSort: string
  defaultOrder: SortOrder
}

interface UseSortParamsReturn {
  sort: string
  order: SortOrder
  handleChangeSort: (columnId: string) => void
}

export const useSortParams = ({
  defaultSort,
  defaultOrder,
}: UseSortParamsOptions): UseSortParamsReturn => {
  const [searchParams, setSearchParams] = useSearchParams()

  const sort = searchParams.get('sort') || defaultSort
  const order = (searchParams.get('order') || defaultOrder) as SortOrder

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

  return {
    sort,
    order,
    handleChangeSort,
  }
}
