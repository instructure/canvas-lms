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
  FETCH_HISTORY_STARTED,
  FETCH_HISTORY_SUCCESS,
  FETCH_HISTORY_FAILURE
} from 'jsx/gradebook-history/actions/HistoryActions';

export default function history (state = {}, action) {
  switch (action.type) {
    case FETCH_HISTORY_STARTED:
      return {
        ...state,
        loading: true,
        items: null,
        fetchHistoryStatus: 'started'
      };

    case FETCH_HISTORY_SUCCESS:
      return {
        ...state,
        loading: false,
        items: action.payload,
        fetchHistoryStatus: 'success'
      };

    case FETCH_HISTORY_FAILURE:
      return {
        ...state,
        loading: false,
        fetchHistoryStatus: 'failure'
      };

    default:
      return state;
  }
}
