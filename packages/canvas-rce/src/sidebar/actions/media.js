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

export const REQUEST_MEDIA = 'REQUEST_MEDIA'
export const RECEIVE_MEDIA = 'RECEIVE_MEDIA'
export const FAIL_MEDIA = 'FAIL_MEDIA'

export function requestMedia(contextType) {
  return {type: REQUEST_MEDIA, payload: {contextType}}
}

export function receiveMedia({response, contextType}) {
  const {files, bookmark} = response
  return {type: RECEIVE_MEDIA, payload: {files, bookmark, contextType}}
}

export function failMedia({error, contextType}) {
  return {type: FAIL_MEDIA, payload: {error, contextType}}
}

// dispatches the start of the load, requests a page for the collection from
// the source, then dispatches the loaded page to the store on success or
// clears the load on failure
export function fetchMedia() {
  return (dispatch, getState) => {
    const state = getState()
    dispatch(requestMedia(state.contextType))
    return state.source
      .fetchMedia(state)
      .then(response => dispatch(receiveMedia({response, contextType: state.contextType})))
      .catch(error => dispatch(failMedia({error, contextType: state.contextType})))
  }
}

// fetches a page only if a page is not already being loaded and the
// collection is not yet completely loaded
export function fetchNextMedia() {
  return (dispatch, getState) => {
    const state = getState()
    const media = state.media[state.contextType]

    if (media && !media.isLoading && media.hasMore) {
      return dispatch(fetchMedia())
    }
  }
}

// fetches the next page (subject to conditions on fetchNextMedia) only if the
// collection is currently empty
export function fetchInitialMedia() {
  return (dispatch, getState) => {
    const state = getState()
    const media = state.media[state.contextType]

    if (media && media.hasMore && !media.isLoading && media.files && media.files.length === 0) {
      return dispatch(fetchMedia())
    }
  }
}
