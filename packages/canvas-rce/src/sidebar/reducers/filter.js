/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {
  CHANGE_CONTEXT_TYPE,
  CHANGE_CONTEXT_ID,
  CHANGE_SEARCH_STRING,
  CHANGE_SORT_BY,
} from '../actions/filter'

export function changeContextType(state = '', action) {
  if (action.type === CHANGE_CONTEXT_TYPE) {
    return action.payload
  }
  return state
}

export function changeContextId(state = '', action) {
  if (action.type === CHANGE_CONTEXT_ID) {
    return action.payload
  }
  return state
}

export function changeSearchString(state = '', action) {
  if (action.type === CHANGE_SEARCH_STRING) {
    return action.payload
  }
  return state
}

export function changeSortBy(state = {order: 'desc', sort: 'date_added'}, action) {
  if (action.type === CHANGE_SORT_BY) {
    return action.payload
  }
  return state
}
