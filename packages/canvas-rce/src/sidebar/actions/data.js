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

export const REQUEST_PAGE = 'REQUEST_PAGE'
export const RECEIVE_PAGE = 'RECEIVE_PAGE'
export const FAIL_PAGE = 'FAIL_PAGE'

export function requestPage(key, searchString) {
  return {type: REQUEST_PAGE, key, searchString}
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
export function fetchPage(key, searchString) {
  return (dispatch, getState) => {
    const state = getState()
    const {source, collections} = state
    let bookmark = collections[key].bookmark
    if (searchString !== collections[key].searchString) {
      bookmark = source.uriFor(key, {...state, searchString})
    }
    dispatch(requestPage(key, searchString))
    return source
      .fetchPage(bookmark)
      .then(page => dispatch(receivePage(key, page)))
      .catch(error => dispatch(failPage(key, error)))
  }
}

// fetches a page only if a page is not already being loaded and the
// collection is not yet completely loaded
export function fetchNextPage(key, searchString) {
  return (dispatch, getState) => {
    const state = getState()
    const collection = state.collections[key]
    if (collection && !collection.loading) {
      if (searchString !== collection.searchString) {
        // start over
        dispatch(fetchInitialPage(key, searchString))
      } else if (collection.bookmark) {
        return dispatch(fetchPage(key, searchString))
      }
    }
  }
}

// fetches the next page (subject to conditions on fetchNextPage) only if the
// collection is currently empty
export function fetchInitialPage(key, searchString) {
  return (dispatch, getState) => {
    const state = getState()
    const collection = state.collections[key]
    if (collection && (collection.links.length === 0 || collection.searchString !== searchString)) {
      return dispatch(fetchPage(key, searchString))
    }
  }
}
