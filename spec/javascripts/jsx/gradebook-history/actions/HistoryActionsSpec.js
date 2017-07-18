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
import Fixtures from 'spec/jsx/gradebook-history/Fixtures';

const {
  FETCH_HISTORY_START,
  FETCH_HISTORY_SUCCESS,
  FETCH_HISTORY_FAILURE
} = HistoryActions;

QUnit.module('HistoryActions');

test('fetchHistoryStarted creates an action with type FETCH_HISTORY_START', function () {
  const expectedValue = {
    type: FETCH_HISTORY_START
  };
  deepEqual(HistoryActions.fetchHistoryStarted(), expectedValue);
});

test('fetchHistorySuccess creates an action with type FETCH_HISTORY_SUCCESS and payload', function () {
  const response = Fixtures.response();
  const expectedValue = {
    type: FETCH_HISTORY_SUCCESS,
    payload: {
      events: response.data.events,
      users: response.data.linked.users,
      link: response.headers.link
    }
  };
  deepEqual(HistoryActions.fetchHistorySuccess(response.data, response.headers), expectedValue);
});

test('fetchHistoryFailure creates an action with type FETCH_HISTORY_FAILURE', function () {
  const expectedValue = {
    type: FETCH_HISTORY_FAILURE
  };
  deepEqual(HistoryActions.fetchHistoryFailure(), expectedValue);
});
