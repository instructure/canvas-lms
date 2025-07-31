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

import {Sorting} from '../types/shapes'
import {SortBy, SortOrder} from '../utils/constants'

const getSearchParams = (_window: Window = window) => {
  const searchParams = new URLSearchParams(_window.location.search)
  return {
    currentPage: parseInt(searchParams.get('page') || '', 10) || undefined,
    studentsPerPage: parseInt(searchParams.get('per_page') || '', 10) || undefined,
    sortBy: Object.values(SortBy).includes((searchParams.get('sort_by') || '') as SortBy)
      ? (searchParams.get('sort_by') as SortBy)
      : undefined,
    sortOrder: Object.values(SortOrder).includes(
      (searchParams.get('sort_order') || '') as SortOrder,
    )
      ? (searchParams.get('sort_order') as SortOrder)
      : undefined,
  }
}

const setSearchParams = (
  currentPage: number,
  studentsPerPage: number,
  sorting: Sorting,
  _window: Window = window,
) => {
  const searchParams = new URLSearchParams()
  searchParams.set('page', currentPage.toString())
  searchParams.set('per_page', studentsPerPage.toString())
  searchParams.set('sort_by', sorting.sortBy)
  searchParams.set('sort_order', sorting.sortOrder)
  const url = new URL(_window.location.href)
  url.search = searchParams.toString()
  _window.history.replaceState({}, '', url.toString())
}

export {getSearchParams, setSearchParams}
