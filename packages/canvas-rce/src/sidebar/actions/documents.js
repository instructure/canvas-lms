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

export const REQUEST_DOCS = 'REQUEST_DOCS'
export const RECEIVE_DOCS = 'RECEIVE_DOCS'
export const FAIL_DOCS = 'FAIL_DOCS'

export function requestDocs(contextType) {
  return {type: REQUEST_DOCS, payload: {contextType}}
}

export function receiveDocs({response, contextType}) {
  const {files, bookmark} = response
  return {type: RECEIVE_DOCS, payload: {files, bookmark, contextType}}
}

export function failDocs({error, contextType}) {
  return {type: FAIL_DOCS, payload: {error, contextType}}
}

// dispatches the start of the load, requests a page for the collection from
// the source, then dispatches the loaded page to the store on success or
// clears the load on failure
export function fetchDocs() {
  return (dispatch, getState) => {
    const state = getState()
    dispatch(requestDocs(state.contextType))
    return state.source
      .fetchDocs(state)
      .then(response => dispatch(receiveDocs({response, contextType: state.contextType})))
      .catch(error => dispatch(failDocs({error, contextType: state.contextType})))
  }
}

// fetches a page only if a page is not already being loaded and the
// collection is not yet completely loaded
export function fetchNextDocs() {
  return (dispatch, getState) => {
    const state = getState()
    const documents = state.documents[state.contextType]

    if (documents && !documents.isLoading && documents.hasMore) {
      return dispatch(fetchDocs())
    }
  }
}

// fetches the next page (subject to conditions on fetchNextDocs) only if the
// collection is currently empty
export function fetchInitialDocs() {
  return (dispatch, getState) => {
    const state = getState()
    const documents = state.documents[state.contextType]

    if (
      documents &&
      documents.hasMore &&
      !documents.isLoading &&
      documents.files &&
      documents.files.length === 0
    ) {
      return dispatch(fetchDocs())
    }
  }
}
