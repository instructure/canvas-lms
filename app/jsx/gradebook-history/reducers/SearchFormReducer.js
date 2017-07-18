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

import parseLinkHeader from 'jsx/shared/parseLinkHeader';
import {
  FETCH_USERS_BY_NAME_START,
  FETCH_USERS_BY_NAME_SUCCESS,
  FETCH_USERS_BY_NAME_FAILURE,
  FETCH_USERS_NEXT_PAGE_START,
  FETCH_USERS_NEXT_PAGE_SUCCESS,
  FETCH_USERS_NEXT_PAGE_FAILURE
} from 'jsx/gradebook-history/actions/SearchFormActions';

const initialState = {
  options: {
    graders: {
      fetchStatus: null,
      items: [],
      nextPage: null
    },
    students: {
      fetchStatus: null,
      items: [],
      nextPage: null
    }
  }
};

function searchForm (state = initialState, { type, payload }) {
  switch (type) {
    case FETCH_USERS_BY_NAME_START: {
      return {
        ...state,
        options: {
          ...state.options,
          [payload.userType]: {
            ...state.options[payload.userType],
            fetchStatus: 'started',
            items: [],
            nextPage: null
          }
        }
      };
    }
    case FETCH_USERS_BY_NAME_SUCCESS: {
      return {
        ...state,
        options: {
          ...state.options,
          [payload.userType]: {
            ...state.options[payload.userType],
            fetchStatus: 'success',
            items: payload.data,
            nextPage: parseLinkHeader(payload.link).next
          }
        }
      };
    }
    case FETCH_USERS_BY_NAME_FAILURE: {
      return {
        ...state,
        options: {
          ...state.options,
          [payload.userType]: {
            ...state.options[payload.userType],
            fetchStatus: 'failure',
            items: [],
            nextPage: null
          }
        }
      };
    }
    case FETCH_USERS_NEXT_PAGE_START: {
      return {
        ...state,
        options: {
          ...state.options,
          [payload.userType]: {
            ...state.options[payload.userType],
            fetchStatus: 'started',
            nextPage: null,
          }
        }
      };
    }
    case FETCH_USERS_NEXT_PAGE_SUCCESS: {
      return {
        ...state,
        options: {
          ...state.options,
          [payload.userType]: {
            ...state.options[payload.userType],
            fetchStatus: 'success',
            items: state.options[payload.userType].items.concat(payload.data),
            nextPage: parseLinkHeader(payload.link).next
          }
        }
      };
    }
    case FETCH_USERS_NEXT_PAGE_FAILURE: {
      return {
        ...state,
        options: {
          ...state.options,
          [payload.userType]: {
            ...state.options[payload.userType],
            fetchStatus: 'failure',
            nextPage: null
          }
        }
      };
    }
    default: {
      return state;
    }
  }
}

export default searchForm;
