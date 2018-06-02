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

export const START_FLICKR_SEARCH = "START_FLICKR_SEARCH";
export const RECEIVE_FLICKR_RESULTS = "RECEIVE_FLICKR_RESULTS";
export const FAIL_FLICKR_SEARCH = "FAIL_FLICKR_SEARCH";
export const TOGGLE_FLICKR_FORM = "TOGGLE_FLICKR_FORM";

export function startFlickrSearch(term) {
  return { type: START_FLICKR_SEARCH, term };
}

export function receiveFlickrResults(results) {
  return { type: RECEIVE_FLICKR_RESULTS, results };
}

export function failFlickrSearch(error) {
  return { type: FAIL_FLICKR_SEARCH, error };
}

export function openOrCloseFlickrForm() {
  return { type: TOGGLE_FLICKR_FORM };
}

export function searchFlickr(term) {
  return (dispatch, getState) => {
    const { source, host, flickr } = getState();
    if (flickr && !flickr.searching) {
      dispatch(startFlickrSearch(term));
      return source
        .searchFlickr(term, { host })
        .then(results => dispatch(receiveFlickrResults(results)))
        .catch(error => dispatch(failFlickrSearch(error)));
    }
  };
}
