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

import HistoryActions from 'jsx/gradebook-history/actions/HistoryActions';
import HistoryApi from 'jsx/gradebook-history/api/HistoryApi';
import UserApi from 'jsx/gradebook-history/api/UserApi';

const FETCH_USERS_BY_NAME_START = 'FETCH_USERS_BY_NAME_START';
const FETCH_USERS_BY_NAME_SUCCESS = 'FETCH_USERS_BY_NAME_SUCCESS';
const FETCH_USERS_BY_NAME_FAILURE = 'FETCH_USERS_BY_NAME_FAILURE';
const FETCH_USERS_NEXT_PAGE_START = 'FETCH_USERS_NEXT_PAGE_START';
const FETCH_USERS_NEXT_PAGE_SUCCESS = 'FETCH_USERS_NEXT_PAGE_SUCCESS';
const FETCH_USERS_NEXT_PAGE_FAILURE = 'FETCH_USERS_NEXT_PAGE_FAILURE';

const SearchFormActions = {
  fetchUsersByNameStarted (userType) {
    return {
      type: FETCH_USERS_BY_NAME_START,
      payload: { userType }
    };
  },

  fetchUsersByNameSuccess ({ data, headers }, userType) {
    return {
      type: FETCH_USERS_BY_NAME_SUCCESS,
      payload: {
        data,
        link: headers.link,
        userType
      }
    };
  },

  fetchUsersByNameFailure (userType) {
    return {
      type: FETCH_USERS_BY_NAME_FAILURE,
      payload: { userType }
    };
  },

  fetchUsersNextPageStart (userType) {
    return {
      type: FETCH_USERS_NEXT_PAGE_START,
      payload: { userType }
    };
  },

  fetchUsersNextPageSuccess ({ data, headers }, userType) {
    return {
      type: FETCH_USERS_NEXT_PAGE_SUCCESS,
      payload: {
        data,
        link: headers.link,
        userType
      }
    };
  },

  fetchUsersNextPageFailure (userType) {
    return {
      type: FETCH_USERS_NEXT_PAGE_FAILURE,
      payload: { userType }
    };
  },

  getHistoryByFunction (fn, id, timeFrame) {
    return function (dispatch) {
      return fn(id, timeFrame)
        .then((response) => {
          dispatch(HistoryActions.fetchHistorySuccess(response.data, response.headers));
        })
        .catch(() => {
          dispatch(HistoryActions.fetchHistoryFailure());
        });
    };
  },

  getHistoryByAssignment (assignmentId, timeFrame = { from: '', to: '' }) {
    return function (dispatch) {
      dispatch(HistoryActions.fetchHistoryStarted());
      return dispatch(SearchFormActions.getHistoryByFunction(HistoryApi.getByAssignment, assignmentId, timeFrame));
    };
  },

  getHistoryByDate (timeFrame = { from: '', to: '' }) {
    return function (dispatch) {
      dispatch(HistoryActions.fetchHistoryStarted());
      return HistoryApi.getByDate(timeFrame)
        .then((response) => {
          dispatch(HistoryActions.fetchHistorySuccess(response.data, response.headers));
        })
        .catch(() => {
          dispatch(HistoryActions.fetchHistoryFailure());
        });
    };
  },

  getHistoryByGrader (graderId, timeFrame = { from: '', to: '' }) {
    return function (dispatch) {
      dispatch(HistoryActions.fetchHistoryStarted());
      return dispatch(SearchFormActions.getHistoryByFunction(HistoryApi.getByGrader, graderId, timeFrame));
    };
  },

  getHistoryByStudent (studentId, timeFrame = { from: '', to: '' }) {
    return function (dispatch) {
      dispatch(HistoryActions.fetchHistoryStarted());
      return dispatch(SearchFormActions.getHistoryByFunction(HistoryApi.getByStudent, studentId, timeFrame));
    };
  },

  getNameOptions (userType, searchTerm) {
    return function (dispatch) {
      dispatch(SearchFormActions.fetchUsersByNameStarted(userType));

      return UserApi.getUsersByName(userType, searchTerm)
        .then((response) => {
          dispatch(SearchFormActions.fetchUsersByNameSuccess(response, userType));
        })
        .catch(() => {
          dispatch(SearchFormActions.fetchUsersByNameFailure(userType));
        });
    };
  },

  getNameOptionsNextPage (userType, url) {
    return function (dispatch) {
      dispatch(SearchFormActions.fetchUsersNextPageStart(userType));

      return UserApi.getUsersNextPage(url)
        .then((response) => {
          dispatch(SearchFormActions.fetchUsersNextPageSuccess(response, userType));
        })
        .catch(() => {
          dispatch(SearchFormActions.fetchUsersNextPageFailure(userType));
        });
    }
  }
}

export default SearchFormActions;

export {
  FETCH_USERS_BY_NAME_START,
  FETCH_USERS_BY_NAME_SUCCESS,
  FETCH_USERS_BY_NAME_FAILURE,
  FETCH_USERS_NEXT_PAGE_START,
  FETCH_USERS_NEXT_PAGE_SUCCESS,
  FETCH_USERS_NEXT_PAGE_FAILURE
};
