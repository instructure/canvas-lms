/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

export const REQUEST_INITIAL_PAGE = 'REQUEST_INITIAL_PAGE'
export const REQUEST_PAGE = 'REQUEST_PAGE'
export const RECEIVE_PAGE = 'RECEIVE_PAGE'
export const FAIL_PAGE = 'FAIL_PAGE'

export function requestInitialPage(key, cancel, searchString) {
  return {type: REQUEST_INITIAL_PAGE, key, cancel, searchString}
}

export function requestPage(key, cancel) {
  return {type: REQUEST_PAGE, key, cancel}
}

export function receivePage(key, page) {
  const {links, bookmark} = page
  return {type: RECEIVE_PAGE, key, links, bookmark}
}

export function failPage(key, error) {
  return {type: FAIL_PAGE, key, error}
}

// dispatches the start of the load, requests a page for the collection from
// the source, then dispatches the loaded page to the store on success or
// clears the load on failure
export function fetchPage(key, isInitial, searchString) {
  return (dispatch, getState) => {
    let isCancelled = false
    const cancel = () => (isCancelled = true)

    if (isInitial) {
      dispatch(requestInitialPage(key, cancel, searchString))
    } else {
      dispatch(requestPage(key, cancel))
    }

    const state = getState()
    const {source} = state
    return source
      .fetchLinks(key, state)
      .then(page => {
        if (isCancelled) return
        dispatch(receivePage(key, page))
      })
      .catch(error => {
        if (isCancelled) return
        dispatch(failPage(key, error))
      })
  }
}

export function fetchNextPage(key) {
  return (dispatch, getState) => {
    const state = getState()
    const collection = state.collections[key]
    if (collection) {
      if (collection.cancel) collection.cancel()
      return dispatch(fetchPage(key, false))
    }
  }
}

export function fetchInitialPage(key) {
  return (dispatch, getState) => {
    const state = getState()
    const collection = state.collections[key]

    if (
      collection &&
      (collection.links.length === 0 || collection.searchString !== state.searchString)
    ) {
      if (collection.cancel) collection.cancel()
      return dispatch(fetchPage(key, true, state.searchString))
    }
  }
}
