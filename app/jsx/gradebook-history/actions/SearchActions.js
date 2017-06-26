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

import { fetchHistoryStarted, fetchHistorySuccess, fetchHistoryFailure } from 'jsx/gradebook-history/actions/HistoryActions';
import { fetchUsersSuccess } from 'jsx/gradebook-history/actions/UserActions';
import HistoryApi from 'jsx/gradebook-history/api/HistoryApi';

function getHistoryByAssignment (assignmentId, timeFrame = {from: '', to: ''}) {
  return function (dispatch) {
    dispatch(fetchHistoryStarted());

    return HistoryApi.getByAssignment(assignmentId, timeFrame)
      .then((response) => {
        dispatch(fetchUsersSuccess(response.data.linked.users));
        dispatch(fetchHistorySuccess(response.data.events));
      })
      .catch(() => {
        dispatch(fetchHistoryFailure());
      });
  };
}

function getHistoryByGrader (graderId, timeFrame = {from: '', to: ''}) {
  return function (dispatch) {
    dispatch(fetchHistoryStarted());

    return HistoryApi.getByGrader(graderId, timeFrame)
      .then((response) => {
        dispatch(fetchUsersSuccess(response.data.linked.users));
        dispatch(fetchHistorySuccess(response.data.events));
      })
      .catch(() => {
        dispatch(fetchHistoryFailure());
      });
  };
}

function getHistoryByStudent (studentId, timeFrame = {from: '', to: ''}) {
  return function (dispatch) {
    dispatch(fetchHistoryStarted());

    return HistoryApi.getByStudent(studentId, timeFrame)
      .then((response) => {
        dispatch(fetchUsersSuccess(response.data.linked.users));
        dispatch(fetchHistorySuccess(response.data.events));
      })
      .catch(() => {
        dispatch(fetchHistoryFailure());
      });
  };
}

export default {
  getHistoryByAssignment,
  getHistoryByGrader,
  getHistoryByStudent
};
