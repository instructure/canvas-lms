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

import type { AnyAction } from 'redux'
import type { BulkEditStudentsState, OrderType, SortableColumn } from '../types'
import {
  SET_SEARCH_TERM,
  SET_FILTER_SECTION,
  SET_FILTER_PACE_STATUS,
  SET_SORT,
  SET_PAGE,
  SET_LOADING,
  SET_ERROR,
  SET_STUDENTS,
  SET_SECTIONS,
  SET_PAGE_COUNT,
  RESET_BULK_EDIT_STATE
} from '../actions/bulk_edit_students_actions'

const initialState: BulkEditStudentsState = {
  searchTerm: '',
  filterSection: 'all',
  filterPaceStatus: 'all',
  sortBy: null,
  orderType: 'asc',
  page: 1,
  pageCount: 1,
  students: [],
  sections: [],
  isLoading: false,
  error: undefined,
}

export function bulkEditStudentsReducer(
  state = initialState,
  action: AnyAction
): BulkEditStudentsState {
  switch (action.type) {
    case SET_SEARCH_TERM:
      return { ...state, searchTerm: action.payload }
    case SET_FILTER_SECTION:
      return { ...state, filterSection: action.payload }
    case SET_FILTER_PACE_STATUS:
      return { ...state, filterPaceStatus: action.payload }
    case SET_SORT: {
      const { sortBy, orderType } = action.payload as {
        sortBy: SortableColumn
        orderType: OrderType
      }
      return { ...state, sortBy, orderType }
    }
    case SET_PAGE:
      return { ...state, page: action.payload }
    case SET_LOADING:
      return { ...state, isLoading: action.payload }
    case SET_ERROR:
      return { ...state, error: action.payload }
    case SET_STUDENTS:
      return { ...state, students: action.payload }
    case SET_SECTIONS:
      return { ...state, sections: action.payload }
    case SET_PAGE_COUNT:
      return { ...state, pageCount: action.payload }
    case RESET_BULK_EDIT_STATE:
        return { ...initialState }
    default:
      return state
  }
}
