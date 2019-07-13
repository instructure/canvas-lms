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

export const REQUEST_DOCS = "REQUEST_DOCS";
export const RECEIVE_DOCS = "RECEIVE_DOCS";
export const FAIL_DOCS = "FAIL_DOCS";

export function requestDocs() {
  return { type: REQUEST_DOCS };
}

export function receiveDocs(docs) {
  let { files, bookmark } = docs;
  return { type: RECEIVE_DOCS, files, bookmark };
}

export function failDocs( error) {
  return { type: FAIL_DOCS, error };
}

// dispatches the start of the load, requests a page for the collection from
// the source, then dispatches the loaded page to the store on success or
// clears the load on failure
export function fetchDocs() {
  return (dispatch, getState) => {
    const { source, documents } = getState();
    let bookmark = documents.bookmark;
    dispatch(requestDocs());
    return source
      .fetchDocs(bookmark)
      .then(docs => dispatch(receiveDocs(docs)))
      .catch(error => dispatch(failDocs(error)));
  };
}

// fetches a page only if a page is not already being loaded and the
// collection is not yet completely loaded
export function fetchNextDocs() {
  return (dispatch, getState) => {
    const state = getState();

    if (state.documents && !state.documents.isLoading && state.documents.bookmark) {
      return dispatch(fetchDocs());
    }
  };
}

// fetches the next page (subject to conditions on fetchNextDocs) only if the
// collection is currently empty
export function fetchInitialDocs() {
  return (dispatch, getState) => {
    const state = getState();

    if (state.documents.files && state.documents.files.length === 0) {
      return dispatch(fetchNextDocs());
    }
  };
}
