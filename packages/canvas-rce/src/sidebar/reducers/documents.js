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

import {REQUEST_INITIAL_DOCS, REQUEST_DOCS, RECEIVE_DOCS, FAIL_DOCS} from '../actions/documents'
import {CHANGE_CONTEXT, CHANGE_SEARCH_STRING} from '../actions/filter'

// manages the state for a specific collection. assumes the action is intended
// for this collection (see collections.js)
export default function documentsReducer(prevState = {}, action) {
  const ctxt = action.payload && action.payload.contextType
  const state = {...prevState}
  if (ctxt && !state[ctxt]) {
    state[ctxt] = {
      files: [],
      bookmark: null,
      isLoading: false,
      hasMore: true,
    }
  }
  switch (action.type) {
    case REQUEST_INITIAL_DOCS:
      state[ctxt] = {
        files: [],
        bookmark: null,
        isLoading: true,
        hasMore: true,
      }
      return state

    case REQUEST_DOCS:
      state[ctxt].isLoading = true
      return state

    case RECEIVE_DOCS:
      // add to collection, store bookmark if more, resolve loading
      state[ctxt] = {
        files: state[ctxt].files.concat(action.payload.files),
        bookmark: action.payload.bookmark,
        isLoading: false,
        hasMore: !!action.payload.bookmark,
      }
      return state

    case FAIL_DOCS: {
      state[ctxt] = {
        isLoading: false,
        error: action.payload.error,
      }
      if (action.payload.files && action.payload.files.length === 0) {
        state[ctxt].bookmark = null
      }
      return state
    }

    case CHANGE_CONTEXT: {
      return state
    }

    case CHANGE_SEARCH_STRING: {
      return state
    }

    default:
      return prevState
  }
}
