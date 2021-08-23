/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import FlickrInitialState from '../stores/FlickrInitialState'

const flickrHandlers = {
  START_FLICKR_SEARCH(state, action) {
    state.page = action.page
    state.searching = true
    state.searchTerm = action.term
    return state
  },
  RECEIVE_FLICKR_RESULTS(state, action) {
    state.searchResults = action.results
    state.searching = false
    return state
  },
  CLEAR_FLICKR_SEARCH(state) {
    state.searchResults = []
    state.searching = false
    state.page = 1
    state.searchTerm = ''
    return state
  },
  FAIL_FLICKR_SEARCH(state, action) {
    state.searchResults = []
    state.searching = false
    return state
  }
}

const flickr = (state = FlickrInitialState, action) => {
  if (flickrHandlers[action.type]) {
    const newState = {...state}
    return flickrHandlers[action.type](newState, action)
  } else {
    return state
  }
}

export default flickr
