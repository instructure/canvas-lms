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

import AssignmentApi from '../../gradebook-history/api/AssignmentApi';
import * as HistoryActions from '../../gradebook-history/actions/HistoryActions';
import HistoryApi from '../../gradebook-history/api/HistoryApi';
import UserApi from '../../gradebook-history/api/UserApi';
import environment from '../../gradebook-history/environment';

const CLEAR_RECORDS = 'CLEAR_RECORDS';
const FETCH_RECORDS_START = 'FETCH_RECORDS_START';
const FETCH_RECORDS_SUCCESS = 'FETCH_RECORDS_SUCCESS';
const FETCH_RECORDS_FAILURE = 'FETCH_RECORDS_FAILURE';
const FETCH_RECORDS_NEXT_PAGE_START = 'FETCH_RECORDS_NEXT_PAGE_START';
const FETCH_RECORDS_NEXT_PAGE_SUCCESS = 'FETCH_RECORDS_NEXT_PAGE_SUCCESS';
const FETCH_RECORDS_NEXT_PAGE_FAILURE = 'FETCH_RECORDS_NEXT_PAGE_FAILURE';

const courseId = environment.courseId();

const SearchFormActions = {
  fetchRecordsStart (recordType) {
    return {
      type: FETCH_RECORDS_START,
      payload: { recordType }
    };
  },

  fetchRecordsSuccess ({ data, headers }, recordType) {
    return {
      type: FETCH_RECORDS_SUCCESS,
      payload: {
        data,
        link: headers.link,
        recordType
      }
    };
  },

  fetchRecordsFailure (recordType) {
    return {
      type: FETCH_RECORDS_FAILURE,
      payload: { recordType }
    };
  },

  fetchRecordsNextPageStart (recordType) {
    return {
      type: FETCH_RECORDS_NEXT_PAGE_START,
      payload: { recordType }
    };
  },

  fetchRecordsNextPageSuccess ({ data, headers }, recordType) {
    return {
      type: FETCH_RECORDS_NEXT_PAGE_SUCCESS,
      payload: {
        data,
        link: headers.link,
        recordType
      }
    };
  },

  fetchRecordsNextPageFailure (recordType) {
    return {
      type: FETCH_RECORDS_NEXT_PAGE_FAILURE,
      payload: { recordType }
    };
  },

  getGradebookHistory (input) {
    return function (dispatch) {
      dispatch(HistoryActions.fetchHistoryStart());
      return HistoryApi.getGradebookHistory(courseId, input)
        .then((response) => {
          dispatch(HistoryActions.fetchHistorySuccess(response.data, response.headers));
        })
        .catch(() => {
          dispatch(HistoryActions.fetchHistoryFailure());
        });
    };
  },

  clearSearchOptions (recordType) {
    return {
      type: CLEAR_RECORDS,
      payload: { recordType }
    };
  },

  getSearchOptions (recordType, searchTerm) {
    return function (dispatch) {
      dispatch(SearchFormActions.fetchRecordsStart(recordType));

      const enrollmentStates = environment.courseIsConcluded() ? ['completed'] : [];
      const request = recordType === 'assignments' ?
        AssignmentApi.getAssignmentsByName(courseId, searchTerm) :
        UserApi.getUsersByName(courseId, recordType, searchTerm, enrollmentStates);

      return request
        .then((response) => {
          dispatch(SearchFormActions.fetchRecordsSuccess(response, recordType));
        })
        .catch(() => {
          dispatch(SearchFormActions.fetchRecordsFailure(recordType));
        });
    }
  },

  getSearchOptionsNextPage (recordType, url) {
    return function (dispatch) {
      dispatch(SearchFormActions.fetchRecordsNextPageStart(recordType));

      const request = recordType === 'assignments' ?
        AssignmentApi.getAssignmentsNextPage(url) :
        UserApi.getUsersNextPage(url);

      return request
        .then((response) => {
          dispatch(SearchFormActions.fetchRecordsNextPageSuccess(response, recordType));
        })
        .catch(() => {
          dispatch(SearchFormActions.fetchRecordsNextPageFailure(recordType));
        });
    }
  }
};

export default SearchFormActions;

export {
  CLEAR_RECORDS,
  FETCH_RECORDS_START,
  FETCH_RECORDS_SUCCESS,
  FETCH_RECORDS_FAILURE,
  FETCH_RECORDS_NEXT_PAGE_START,
  FETCH_RECORDS_NEXT_PAGE_SUCCESS,
  FETCH_RECORDS_NEXT_PAGE_FAILURE
};
