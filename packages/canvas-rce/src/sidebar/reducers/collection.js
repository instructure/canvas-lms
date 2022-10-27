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

import {REQUEST_INITIAL_PAGE, REQUEST_PAGE, RECEIVE_PAGE, FAIL_PAGE} from '../actions/data'

// manages the state for a specific collection. assumes the action is intended
// for this collection (see collections.js)
export default function (state = {}, action) {
  switch (action.type) {
    case REQUEST_INITIAL_PAGE:
      return {
        ...state,
        links: [],
        bookmark: null,
        isLoading: true,
        cancel: action.cancel,
        hasMore: true,
        searchString: action.searchString,
      }
    case REQUEST_PAGE:
      return {
        ...state,
        isLoading: true,
        cancel: action.cancel,
      }

    case RECEIVE_PAGE:
      // add links to collection, store bookmark if more, resolve loading
      return {
        ...state,
        links: state.links.concat(action.links),
        bookmark: action.bookmark,
        isLoading: false,
        cancel: null,
        hasMore: !!action.bookmark,
      }

    case FAIL_PAGE: {
      const overrides = {
        isLoading: false,
        cancel: null,
        error: action.error,
      }
      if (state.links.length === 0) {
        overrides.bookmark = null
      }
      return {...state, ...overrides}
    }
    default:
      return state
  }
}
