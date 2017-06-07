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
import {
  FETCH_HISTORY_START,
  FETCH_HISTORY_SUCCESS,
  FETCH_HISTORY_FAILURE
} from 'jsx/gradebook-history/actions/HistoryActions';
import reducer, { formatHistoryItems } from 'jsx/gradebook-history/reducers/HistoryReducer';

QUnit.module('HistoryReducer');

test('returns the current state by default', function () {
  const initialState = {
    loading: false,
    items: [],
    fetchHistoryStatus: 'success'
  };
  deepEqual(reducer(initialState, {}), initialState);
});

test('should handle FETCH_HISTORY_START', function () {
  const initialState = {
    loading: false,
    items: [],
    fetchHistoryStatus: 'success'
  };
  const newState = {
    ...initialState,
    loading: true,
    items: null,
    fetchHistoryStatus: 'started'
  };
  deepEqual(reducer(initialState, { type: FETCH_HISTORY_START }), newState);
});

test('should handle FETCH_HISTORY_SUCCESS', function () {
  const payload = Fixtures.payload();
  const initialState = {
    loading: false,
    items: [],
    fetchHistoryStatus: 'started'
  };
  const newState = {
    ...initialState,
    loading: false,
    items: formatHistoryItems(payload),
    fetchHistoryStatus: 'success'
  };
  deepEqual(reducer(initialState, { type: FETCH_HISTORY_SUCCESS, payload }), newState);
});

test('should handle FETCH_HISTORY_FAILURE', function () {
  const initialState = {
    loading: false,
    items: [],
    fetchHistoryStatus: 'started'
  };
  const newState = {
    ...initialState,
    loading: false,
    fetchHistoryStatus: 'failure'
  };
  deepEqual(reducer(initialState, { type: FETCH_HISTORY_FAILURE }), newState);
});
