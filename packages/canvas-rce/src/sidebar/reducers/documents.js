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

import { REQUEST_DOCS, RECEIVE_DOCS, FAIL_DOCS } from "../actions/documents";

// manages the state for a specific collection. assumes the action is intended
// for this collection (see collections.js)
export default function documentsReducer(state = {}, action) {
  switch (action.type) {
    case REQUEST_DOCS:
      // set loading flag to true
      return Object.assign({}, state, { isLoading: true });

    case RECEIVE_DOCS:
      // add links to collection, store bookmark if more, resolve loading
      return {
        files: state.files.concat(action.files),
        bookmark: action.bookmark,
        isLoading: false,
        hasMore: !!action.bookmark
      };

    case FAIL_DOCS: {
      let overrides = {
        isLoading: false,
        error: action.error
      };
      if (state.files.length == 0) {
        overrides.bookmark = null;
      }
      return Object.assign({}, state, overrides);
    }
    default:
      return state;
  }
}
