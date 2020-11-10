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

export const CHANGE_CONTEXT = 'CHANGE_CONTEXT'
export const CHANGE_CONTEXT_TYPE = 'CHANGE_CONTEXT_TYPE'
export const CHANGE_CONTEXT_ID = 'CHANGE_CONTEXT_ID'
export const CHANGE_SEARCH_STRING = 'CHANGE_SEARCH_STRING'
export const CHANGE_SORT_BY = 'CHANGE_SORT_BY'

export function changeContext({contextType, contextId}) {
  return dispatch => {
    dispatch(changeContextType(contextType))
    dispatch(changeContextId(contextId))
    dispatch({type: CHANGE_CONTEXT, payload: {contextType, contextId}})
  }
}

export function changeContextType(contextType) {
  return {type: CHANGE_CONTEXT_TYPE, payload: contextType}
}

export function changeContextId(contextId) {
  return {type: CHANGE_CONTEXT_ID, payload: contextId}
}

export function changeSearchString(searchString) {
  return {type: CHANGE_SEARCH_STRING, payload: searchString}
}

export function changeSortBy(sortBy) {
  return {type: CHANGE_SORT_BY, payload: sortBy}
}
