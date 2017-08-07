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

import Fixtures from 'spec/jsx/gradebook-history/Fixtures';
import parseLinkHeader from 'jsx/shared/parseLinkHeader';

import {
  FETCH_HISTORY_START,
  FETCH_HISTORY_SUCCESS,
  FETCH_HISTORY_FAILURE,
  FETCH_HISTORY_NEXT_PAGE_START,
  FETCH_HISTORY_NEXT_PAGE_SUCCESS,
  FETCH_HISTORY_NEXT_PAGE_FAILURE,
  fetchHistoryStart,
  fetchHistorySuccess,
  fetchHistoryFailure,
  fetchHistoryNextPageStart,
  fetchHistoryNextPageSuccess,
  fetchHistoryNextPageFailure,
  formatHistoryItems
} from 'jsx/gradebook-history/actions/HistoryActions';

QUnit.module('HistoryActions');

test('fetchHistoryStart creates an action with type FETCH_HISTORY_START', function () {
  const expectedValue = {
    type: FETCH_HISTORY_START
  };
  deepEqual(fetchHistoryStart(), expectedValue);
});

test('fetchHistorySuccess creates an action with type FETCH_HISTORY_SUCCESS and payload', function () {
  const response = Fixtures.historyResponse();
  const { events, linked: { assignments, users } } = response.data;
  const expectedValue = {
    type: FETCH_HISTORY_SUCCESS,
    payload: {
      items: formatHistoryItems({ events, users, assignments }),
      link: parseLinkHeader(response.headers.link).next
    }
  };
  deepEqual(fetchHistorySuccess(response.data, response.headers), expectedValue);
});

test('fetchHistoryFailure creates an action with type FETCH_HISTORY_FAILURE', function () {
  const expectedValue = {
    type: FETCH_HISTORY_FAILURE
  };
  deepEqual(fetchHistoryFailure(), expectedValue);
});

test('fetchHistoryNextPageStart creates an action with type FETCH_HISTORY_NEXT_PAGE_START', function () {
  const expectedValue = {
    type: FETCH_HISTORY_NEXT_PAGE_START
  };
  deepEqual(fetchHistoryNextPageStart(), expectedValue);
});

test('fetchHistoryNextPageSuccess creates an action with type FETCH_HISTORY_NEXT_PAGE_SUCCESS and payload', function () {
  const response = Fixtures.historyResponse();
  const expectedValue = {
    type: FETCH_HISTORY_NEXT_PAGE_SUCCESS,
    payload: {
      items: formatHistoryItems(response.data),
      link: parseLinkHeader(response.headers.link).next
    }
  };
  deepEqual(fetchHistoryNextPageSuccess(response.data, response.headers), expectedValue);
});

test('fetchHistoryNextPageFailure creates an action with type FETCH_HISTORY_NEXT_PAGE_FAILURE', function () {
  const expectedValue = {
    type: FETCH_HISTORY_NEXT_PAGE_FAILURE
  };
  deepEqual(fetchHistoryNextPageFailure(), expectedValue);
});
