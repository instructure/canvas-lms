/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
  FETCH_HISTORY_START,
  FETCH_HISTORY_SUCCESS,
  FETCH_HISTORY_FAILURE,
  FETCH_HISTORY_NEXT_PAGE_START,
  FETCH_HISTORY_NEXT_PAGE_SUCCESS,
  FETCH_HISTORY_NEXT_PAGE_FAILURE
} from '../../gradebook-history/actions/HistoryActions';

function history (state = {}, { type, payload }) {
  switch (type) {
    case FETCH_HISTORY_START: {
      return {
        ...state,
        loading: true,
        items: null,
        nextPage: null,
        fetchHistoryStatus: 'started'
      };
    }
    case FETCH_HISTORY_SUCCESS: {
      return {
        ...state,
        loading: false,
        nextPage: payload.link,
        items: payload.items,
        fetchHistoryStatus: 'success'
      };
    }
    case FETCH_HISTORY_FAILURE: {
      return {
        ...state,
        loading: false,
        nextPage: null,
        fetchHistoryStatus: 'failure'
      };
    }
    case FETCH_HISTORY_NEXT_PAGE_START: {
      return {
        ...state,
        loading: true,
        nextPage: null,
        fetchNextPageStatus: 'started',
      };
    }
    case FETCH_HISTORY_NEXT_PAGE_SUCCESS: {
      return {
        ...state,
        items: state.items.concat(payload.items),
        loading: false,
        nextPage: payload.link,
        fetchNextPageStatus: 'success'
      };
    }
    case FETCH_HISTORY_NEXT_PAGE_FAILURE: {
      return {
        ...state,
        loading: false,
        nextPage: null,
        fetchNextPageStatus: 'failure'
      }
    }
    default: {
      return state;
    }
  }
}

export default history;
