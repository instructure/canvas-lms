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

export const REQUEST_INITIAL_DOCS = 'REQUEST_INITIAL_DOCS'
export const REQUEST_DOCS = 'REQUEST_NEXT_DOCS'
export const RECEIVE_DOCS = 'RECEIVE_DOCS'
export const FAIL_DOCS = 'FAIL_DOCS'

export function requestInitialDocs(contextType) {
  return {type: REQUEST_INITIAL_DOCS, payload: {contextType}}
}
export function requestDocs(contextType) {
  return {type: REQUEST_DOCS, payload: {contextType}}
}

export function receiveDocs({response, contextType, contextId}) {
  const {files, bookmark} = response
  return {type: RECEIVE_DOCS, payload: {files, bookmark, contextType, contextId}}
}

export function failDocs({error, contextType}) {
  return {type: FAIL_DOCS, payload: {error, contextType}}
}

// dispatches the start of the load, requests a page for the collection from
// the source, then dispatches the loaded page to the store on success or
// clears the load on failure
export function fetchDocs(sortBy) {
  return (dispatch, getState) => {
    const state = getState()
    return state.source
      .fetchDocs({...state, ...sortBy})
      .then(response =>
        dispatch(
          receiveDocs({response, contextType: state.contextType, contextId: state.contextId})
        )
      )
      .catch(error => dispatch(failDocs({error, contextType: state.contextType})))
  }
}

// fetches a page only if a page is not already being loaded and the
// collection is not yet completely loaded
export function fetchNextDocs(sortBy) {
  return (dispatch, getState) => {
    const state = getState()
    const documents = state.documents[state.contextType]

    if (!documents?.isLoading && documents?.hasMore) {
      dispatch(requestDocs(state.contextType))
      return dispatch(fetchDocs(sortBy))
    }
  }
}

// fetches the first page
export function fetchInitialDocs(sortBy) {
  return (dispatch, getState) => {
    const state = getState()

    dispatch(requestInitialDocs(state.contextType))
    return dispatch(fetchDocs(sortBy))
  }
}
