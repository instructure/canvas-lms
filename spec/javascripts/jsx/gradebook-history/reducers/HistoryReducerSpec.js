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

import Fixtures from '../../gradebook-history/Fixtures';
import {
  FETCH_HISTORY_START,
  FETCH_HISTORY_SUCCESS,
  FETCH_HISTORY_FAILURE,
  FETCH_HISTORY_NEXT_PAGE_START,
  FETCH_HISTORY_NEXT_PAGE_SUCCESS,
  FETCH_HISTORY_NEXT_PAGE_FAILURE
} from 'jsx/gradebook-history/actions/HistoryActions';
import parseLinkHeader from 'jsx/shared/parseLinkHeader';
import reducer from 'jsx/gradebook-history/reducers/HistoryReducer';

QUnit.module('HistoryReducer');

const defaultState = () => (
  {
    loading: false,
    items: [],
    fetchHistoryStatus: 'success'
  }
)

const defaultPayload = () => (
  {
    items: [
      {
        assignment: {
          anonymousGrading: false,
          gradingType: 'points',
          muted: false,
          name: 'Rustic Rubber Car'
        },
        grader: 'Ms. Casey',
        gradeAfter: '25',
        gradeBefore: '20',
        pointsPossibleBefore: '20',
        pointsPossibleAfter: '25',
        student: 'Norman Osborne'
      }
    ],
    link: parseLinkHeader(Fixtures.historyResponse().headers.link)
  }
);

test('returns the current state by default', function () {
  const initialState = defaultState();
  deepEqual(reducer(initialState, {}), initialState);
});

test('should handle FETCH_HISTORY_START', function () {
  const initialState = {
    ...defaultState(),
    nextPage: null
  };
  const newState = {
    ...initialState,
    loading: true,
    items: null,
    fetchHistoryStatus: 'started'
  };
  deepEqual(reducer(initialState, { type: FETCH_HISTORY_START }), newState);
});

test('handles FETCH_HISTORY_SUCCESS', function () {
  const payload = defaultPayload();
  const initialState = {
    ...defaultState(),
    fetchHistoryStatus: 'started'
  };
  const newState = {
    ...initialState,
    loading: false,
    nextPage: payload.link,
    items: payload.items,
    fetchHistoryStatus: 'success'
  };
  deepEqual(reducer(initialState, { type: FETCH_HISTORY_SUCCESS, payload }), newState);
});

test('handles FETCH_HISTORY_FAILURE', function () {
  const initialState = {
    ...defaultState(),
    fetchHistoryStatus: 'started'
  };
  const newState = {
    ...initialState,
    loading: false,
    nextPage: null,
    fetchHistoryStatus: 'failure'
  };
  deepEqual(reducer(initialState, { type: FETCH_HISTORY_FAILURE }), newState);
});

test('handles FETCH_HISTORY_NEXT_PAGE_START', function () {
  const initialState = defaultState();
  const newState = {
    ...initialState,
    fetchNextPageStatus: 'started',
    loading: true,
    nextPage: null
  };
  deepEqual(reducer(initialState, { type: FETCH_HISTORY_NEXT_PAGE_START }), newState);
});

test('handles FETCH_HISTORY_NEXT_PAGE_SUCCESS', function () {
  const payload = defaultPayload();
  const initialState = {
    ...defaultState(),
    items: [
      {
        assignment: 'Rustic Rubber Car',
        grader: 'Ms. Casey',
        gradeAfter: '15',
        gradeBefore: '25',
        pointsPossibleBefore: '20',
        pointsPossibleAfter: '25',
        student: 'Norman Osborne'
      }
    ]
  };
  const newState = {
    ...initialState,
    fetchNextPageStatus: 'success',
    items: initialState.items.concat(payload.items),
    loading: false,
    nextPage: payload.link
  };
  deepEqual(reducer(initialState, { type: FETCH_HISTORY_NEXT_PAGE_SUCCESS, payload }), newState);
});

test('handles FETCH_HISTORY_NEXT_PAGE_FAILURE', function () {
  const initialState = defaultState();
  const newState = {
    ...initialState,
    fetchNextPageStatus: 'failure',
    loading: false,
    nextPage: null
  };
  deepEqual(reducer(initialState, { type: FETCH_HISTORY_NEXT_PAGE_FAILURE }), newState);
});
