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

  import ImageSearchInitialState from '../stores/ImageSearchStore'
  import _ from 'underscore'

  const imageSearchHandlers = {
    START_IMAGE_SEARCH (state, action) {
      state.page = action.page;
      state.searching = true;
      state.searchTerm = action.term;
      return state;
    },
    RECEIVE_IMAGE_SEARCH_RESULTS (state, action) {
      state.searchResults = action.results;
      state.searching = false;
      return state;
    },
    CLEAR_IMAGE_SEARCH (state) {
      state.searchResults = [];
      state.searching = false;
      state.page = 1;
      state.searchTerm = '';
      return state;
    },
    FAIL_IMAGE_SEARCH (state) {
      state.searchResults = [];
      state.searching = false;
      return state;
    }
  };

  const imageSearchReducer = (state = ImageSearchInitialState, action) => {
    if (imageSearchHandlers[action.type]) {
      const newState = _.extend({}, state);
      return imageSearchHandlers[action.type](newState, action);
    }
    else {
      return state;
    }
  };

export default imageSearchReducer
