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

import 'jquery.instructure_date_and_time'
import parseLinkHeader from '../../shared/parseLinkHeader';

export const FETCH_HISTORY_START = 'FETCH_HISTORY_START';
export const FETCH_HISTORY_SUCCESS = 'FETCH_HISTORY_SUCCESS';
export const FETCH_HISTORY_FAILURE = 'FETCH_HISTORY_FAILURE';
export const FETCH_HISTORY_NEXT_PAGE_START = 'FETCH_HISTORY_NEXT_PAGE_START';
export const FETCH_HISTORY_NEXT_PAGE_SUCCESS = 'FETCH_HISTORY_NEXT_PAGE_SUCCESS';
export const FETCH_HISTORY_NEXT_PAGE_FAILURE = 'FETCH_HISTORY_NEXT_PAGE_FAILURE';

function indexById (collection = []) {
  return collection.reduce((acc, item) => {
    acc[item.id] = item;
    return acc;
  }, {});
}

function pointsPossibleCurrent (assignments, item) {
  const assignment = assignments[item.links.assignment];
  if (!assignment || assignment.points_possible == null) {
    return '–';
  }
  return assignment.points_possible.toString();
}

function formatHistoryItems (data) {
  const historyItems = data.events || [];
  const users = indexById(data.users);
  const assignments = indexById(data.assignments);

  return historyItems.map(item => {
    let assignment;

    if (assignments[item.links.assignment]) {
      assignment = {
        anonymousGrading: assignments[item.links.assignment].anonymous_grading,
        gradingType: assignments[item.links.assignment].grading_type,
        muted: assignments[item.links.assignment].muted,
        name: assignments[item.links.assignment].name
      };
    } else {
      assignment = {};
    }

    return {
      assignment,
      date: item.created_at,
      displayAsPoints: assignment ? assignment.gradingType === 'points' : false,
      gradedAnonymously: item.graded_anonymously,
      grader: users[item.links.grader] ? users[item.links.grader].name : '',
      gradeAfter: item.grade_after || '',
      gradeBefore: item.grade_before || '',
      gradeCurrent: item.grade_current || '',
      id: item.id,
      pointsPossibleAfter: item.points_possible_after ? item.points_possible_after.toString() : '–',
      pointsPossibleBefore: item.points_possible_before ? item.points_possible_before.toString() : '–',
      pointsPossibleCurrent: pointsPossibleCurrent(assignments, item),
      student: users[item.links.student] ? users[item.links.student].name : '',
    };
  });
}

export function fetchHistoryStart () {
  return {
    type: FETCH_HISTORY_START
  };
}

export function fetchHistorySuccess ({ events, linked: { assignments, users }}, { link }) {
  return {
    type: FETCH_HISTORY_SUCCESS,
    payload: {
      items: formatHistoryItems({ events, assignments, users }),
      link: parseLinkHeader(link).next
    }
  };
}

export function fetchHistoryFailure () {
  return {
    type: FETCH_HISTORY_FAILURE
  };
}

export function fetchHistoryNextPageStart () {
  return {
    type: FETCH_HISTORY_NEXT_PAGE_START
  };
}

export function fetchHistoryNextPageSuccess ({ events, linked: { assignments, users }}, { link }) {
  return {
    type: FETCH_HISTORY_NEXT_PAGE_SUCCESS,
    payload: {
      items: formatHistoryItems({ events, assignments, users }),
      link: parseLinkHeader(link).next
    }
  };
}

export function fetchHistoryNextPageFailure () {
  return {
    type: FETCH_HISTORY_NEXT_PAGE_FAILURE
  };
}
