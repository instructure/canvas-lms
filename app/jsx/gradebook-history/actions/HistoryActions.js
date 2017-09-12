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

import $ from 'jquery';
import 'jquery.instructure_date_and_time'
import I18n from 'i18n!gradebook_history';
import environment from 'jsx/gradebook-history/environment';
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper';
import parseLinkHeader from 'jsx/shared/parseLinkHeader';

const FETCH_HISTORY_START = 'FETCH_HISTORY_START';
const FETCH_HISTORY_SUCCESS = 'FETCH_HISTORY_SUCCESS';
const FETCH_HISTORY_FAILURE = 'FETCH_HISTORY_FAILURE';
const FETCH_HISTORY_NEXT_PAGE_START = 'FETCH_HISTORY_NEXT_PAGE_START';
const FETCH_HISTORY_NEXT_PAGE_SUCCESS = 'FETCH_HISTORY_NEXT_PAGE_SUCCESS';
const FETCH_HISTORY_NEXT_PAGE_FAILURE = 'FETCH_HISTORY_NEXT_PAGE_FAILURE';

function indexNameById (collection = []) {
  return collection.reduce((acc, item) => {
    acc[item.id] = item.name;
    return acc;
  }, {});
}

function formatHistoryItems (data) {
  const historyItems = data.events || [];
  const users = indexNameById(data.users);
  const assignments = indexNameById(data.assignments);

  return historyItems.map((item) => {
    const dateChanged = new Date(item.created_at);
    return {
      date: $.dateString(dateChanged, { format: 'medium', timezone: environment.timezone() }),
      time: $.timeString(dateChanged, { format: 'medium', timezone: environment.timezone() }),
      from: GradeFormatHelper.formatGrade(item.grade_before, { defaultValue: '-' }),
      to: GradeFormatHelper.formatGrade(item.grade_after, { defaultValue: '-' }),
      grader: users[item.links.grader] || I18n.t('Not available'),
      student: users[item.links.student] || I18n.t('Not available'),
      assignment: assignments[item.links.assignment] || I18n.t('Not available'),
      anonymous: item.graded_anonymously ? I18n.t('yes') : I18n.t('no'),
      id: item.id
    };
  });
}

function fetchHistoryStart () {
  return {
    type: FETCH_HISTORY_START
  };
}

function fetchHistorySuccess ({ events, linked: { assignments, users }}, { link }) {
  return {
    type: FETCH_HISTORY_SUCCESS,
    payload: {
      items: formatHistoryItems({ events, assignments, users }),
      link: parseLinkHeader(link).next
    }
  };
}

function fetchHistoryFailure () {
  return {
    type: FETCH_HISTORY_FAILURE
  };
}

function fetchHistoryNextPageStart () {
  return {
    type: FETCH_HISTORY_NEXT_PAGE_START
  };
}

function fetchHistoryNextPageSuccess ({ events, linked: { assignments, users }}, { link }) {
  return {
    type: FETCH_HISTORY_NEXT_PAGE_SUCCESS,
    payload: {
      items: formatHistoryItems({ events, assignments, users }),
      link: parseLinkHeader(link).next
    }
  };
}

function fetchHistoryNextPageFailure () {
  return {
    type: FETCH_HISTORY_NEXT_PAGE_FAILURE
  };
}

export default {
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
};
