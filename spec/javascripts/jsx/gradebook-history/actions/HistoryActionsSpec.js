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
  fetchHistoryNextPageFailure
} from 'jsx/gradebook-history/actions/HistoryActions';

function defaultResponse () {
  return {
    data: {
      events: [
        {
          created_at: '2017-05-30T23:16:59Z',
          event_type: 'grade_change',
          grade_after: '21',
          grade_before: '19',
          grade_current: '22',
          graded_anonymously: false,
          id: '123456',
          points_possible_after: '25',
          points_possible_before: '25',
          links: {
            assignment: 1,
            course: 1,
            grader: 100,
            student: 110
          }
        }
      ],
      linked: {
        assignments: [
          {
            anonymous_grading: false,
            grading_type: 'points',
            id: 1,
            muted: false,
            name: 'Rustic Rubber Duck',
            points_possible: 26
          }
        ],
        users: [{ id: 100, name: 'Ms. Twillie Jones' }, { id: 110, name: 'Norval Abbott' }]
      }
    },
    headers: {
      link: '<http://example.com/3?&page=first>; rel="current",<http://example.com/3?&page=bookmark:asdf>; rel="next"'
    }
  };
}

QUnit.module('HistoryActions');

test('fetchHistoryStart creates an action with type FETCH_HISTORY_START', function () {
  const expectedValue = {
    type: FETCH_HISTORY_START
  };
  deepEqual(fetchHistoryStart(), expectedValue);
});

test('fetchHistorySuccess creates an action with type FETCH_HISTORY_SUCCESS', function () {
  const response = defaultResponse();
  strictEqual(fetchHistorySuccess(response.data, response.headers).type, FETCH_HISTORY_SUCCESS);
});

test('fetchHistorySuccess creates an action with history items in payload', function () {
  const response = defaultResponse();
  const expectedItems = [
    {
      assignment: {
        anonymousGrading: false,
        gradingType: 'points',
        muted: false,
        name: 'Rustic Rubber Duck'
      },
      date: '2017-05-30T23:16:59Z',
      displayAsPoints: true,
      gradedAnonymously: false,
      grader: 'Ms. Twillie Jones',
      gradeAfter: '21',
      gradeBefore: '19',
      gradeCurrent: '22',
      id: '123456',
      pointsPossibleBefore: '25',
      pointsPossibleAfter: '25',
      pointsPossibleCurrent: '26',
      student: 'Norval Abbott'
    }
  ];
  deepEqual(fetchHistorySuccess(response.data, response.headers).payload.items, expectedItems);
});

test('fetchHistorySuccess returns "0" pointsPossibleCurrent when an assignment is zero', function () {
  const response = {
    data: {
      events: [{ links: {} }],
      linked: {
        assignments: [{ points_possible: 0 }]
      }
    },
    headers: {}
  };
  const { pointsPossibleCurrent } = fetchHistorySuccess(response.data, response.headers).payload.items[0]
  strictEqual(pointsPossibleCurrent, '0');
});

test('fetchHistorySuccess returns "–" pointsPossibleCurrent when an assignment has no points possible', function () {
  const response = {
    data: {
      events: [{ links: {} }],
      linked: {
        assignments: [{ points_possible: null }]
      }
    },
    headers: {}
  };
  const { pointsPossibleCurrent } = fetchHistorySuccess(response.data, response.headers).payload.items[0]
  strictEqual(pointsPossibleCurrent, '–');
});

test('fetchHistorySuccess returns "–" pointsPossibleAfter when an assignment now has no points possible', function () {
  const response = {
    data: {
      events: [{ points_possible_after: null, links: {} }],
      linked: {
        assignments: [{ points_possible: null }]
      }
    },
    headers: {}
  };
  const { pointsPossibleAfter } = fetchHistorySuccess(response.data, response.headers).payload.items[0];
  strictEqual(pointsPossibleAfter, '–');
});

test('fetchHistorySuccess returns "–" pointsPossibleBefore when an assignment had no points possible', function () {
  const response = {
    data: {
      events: [{ points_possible_before: null, links: {} }],
      linked: {
        assignments: [{ points_possible: null }]
      }
    },
    headers: {}
  };
  const { pointsPossibleBefore } = fetchHistorySuccess(response.data, response.headers).payload.items[0];
  strictEqual(pointsPossibleBefore, '–');
});

test('fetchHistorySuccess creates an action with history next page link in payload', function () {
  const response = defaultResponse();
  const expectedUrl = 'http://example.com/3?&page=bookmark:asdf';
  strictEqual(fetchHistoryNextPageSuccess(response.data, response.headers).payload.link, expectedUrl);
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

test('fetchHistoryNextPageSuccess creates an action with type FETCH_HISTORY_NEXT_PAGE_SUCCESS', function () {
  const response = defaultResponse();
  strictEqual(fetchHistoryNextPageSuccess(response.data, response.headers).type, FETCH_HISTORY_NEXT_PAGE_SUCCESS);
});

test('fetchHistoryNextPageSuccess creates an action with history items in payload', function () {
  const response = defaultResponse();
  const expectedItems = [
    {
      assignment: {
        anonymousGrading: false,
        gradingType: 'points',
        muted: false,
        name: 'Rustic Rubber Duck'
      },
      date: '2017-05-30T23:16:59Z',
      displayAsPoints: true,
      gradedAnonymously: false,
      grader: 'Ms. Twillie Jones',
      gradeAfter: '21',
      gradeBefore: '19',
      gradeCurrent: '22',
      id: '123456',
      pointsPossibleBefore: '25',
      pointsPossibleAfter: '25',
      pointsPossibleCurrent: '26',
      student: 'Norval Abbott'
    }
  ];
  deepEqual(fetchHistoryNextPageSuccess(response.data, response.headers).payload.items, expectedItems);
});

test('fetchHistoryNextPageSuccess creates an action with history next page link in payload', function () {
  const response = defaultResponse();
  const expectedUrl = 'http://example.com/3?&page=bookmark:asdf';
  strictEqual(fetchHistoryNextPageSuccess(response.data, response.headers).payload.link, expectedUrl);
});

test('fetchHistoryNextPageFailure creates an action with type FETCH_HISTORY_NEXT_PAGE_FAILURE', function () {
  const expectedValue = {
    type: FETCH_HISTORY_NEXT_PAGE_FAILURE
  };
  deepEqual(fetchHistoryNextPageFailure(), expectedValue);
});
