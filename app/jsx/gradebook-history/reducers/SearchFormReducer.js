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

import parseLinkHeader from '../../shared/parseLinkHeader';
import {
  CLEAR_RECORDS,
  FETCH_RECORDS_START,
  FETCH_RECORDS_SUCCESS,
  FETCH_RECORDS_FAILURE,
  FETCH_RECORDS_NEXT_PAGE_START,
  FETCH_RECORDS_NEXT_PAGE_SUCCESS,
  FETCH_RECORDS_NEXT_PAGE_FAILURE
} from '../../gradebook-history/actions/SearchFormActions';

const initialState = {
  records: {
    assignments: {
      fetchStatus: null,
      items: [],
      nextPage: null
    },
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
    case FETCH_RECORDS_START: {
      return {
        ...state,
        records: {
          ...state.records,
          [payload.recordType]: {
            ...state.records[payload.recordType],
            fetchStatus: 'started',
            items: [],
            nextPage: null
          }
        }
      };
    }
    case FETCH_RECORDS_SUCCESS: {
      return {
        ...state,
        records: {
          ...state.records,
          [payload.recordType]: {
            ...state.records[payload.recordType],
            fetchStatus: 'success',
            items: payload.data,
            nextPage: parseLinkHeader(payload.link).next
          }
        }
      };
    }
    case FETCH_RECORDS_FAILURE: {
      return {
        ...state,
        records: {
          ...state.records,
          [payload.recordType]: {
            ...state.records[payload.recordType],
            fetchStatus: 'failure',
            items: [],
            nextPage: null
          }
        }
      };
    }
    case FETCH_RECORDS_NEXT_PAGE_START: {
      return {
        ...state,
        records: {
          ...state.records,
          [payload.recordType]: {
            ...state.records[payload.recordType],
            fetchStatus: 'started',
            nextPage: null,
          }
        }
      };
    }
    case FETCH_RECORDS_NEXT_PAGE_SUCCESS: {
      return {
        ...state,
        records: {
          ...state.records,
          [payload.recordType]: {
            ...state.records[payload.recordType],
            fetchStatus: 'success',
            items: state.records[payload.recordType].items.concat(payload.data),
            nextPage: parseLinkHeader(payload.link).next
          }
        }
      };
    }
    case FETCH_RECORDS_NEXT_PAGE_FAILURE: {
      return {
        ...state,
        records: {
          ...state.records,
          [payload.recordType]: {
            ...state.records[payload.recordType],
            fetchStatus: 'failure',
            nextPage: null
          }
        }
      };
    }
    case CLEAR_RECORDS: {
      return {
        ...state,
        records: {
          ...state.records,
          [payload.recordType]: {
            ...state.records[payload.recordType],
            fetchStatus: null,
            items: [],
            nextPage: null
          }
        }
      }
    }
    default: {
      return state;
    }
  }
}

export default searchForm;
