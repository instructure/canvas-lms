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

import {
  START_FLICKR_SEARCH,
  RECEIVE_FLICKR_RESULTS,
  FAIL_FLICKR_SEARCH,
  TOGGLE_FLICKR_FORM
} from "../actions/flickr";

export default function(state = {}, action) {
  switch (action.type) {
    case START_FLICKR_SEARCH:
      return {
        ...state,
        searching: true,
        searchTerm: action.term
      };
    case RECEIVE_FLICKR_RESULTS:
      return {
        ...state,
        searching: false,
        searchResults: action.results
      };
    case FAIL_FLICKR_SEARCH:
      return {
        ...state,
        searching: false,
        searchTerm: "",
        searchResults: []
      };
    case TOGGLE_FLICKR_FORM:
      return {
        ...state,
        formExpanded: !state.formExpanded
      };
    default:
      return state;
  }
}
