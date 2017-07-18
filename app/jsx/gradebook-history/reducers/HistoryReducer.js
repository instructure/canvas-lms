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
import constants from 'jsx/gradebook-history/constants';
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper';
import {
  FETCH_HISTORY_START,
  FETCH_HISTORY_SUCCESS,
  FETCH_HISTORY_FAILURE
} from 'jsx/gradebook-history/actions/HistoryActions';

function mapUsers (users = []) {
  return users.reduce((acc, user) => {
    acc[user.id] = user.name;
    return acc;
  }, {});
}

function formatHistoryItems (data) {
  const historyItems = data.events || [];
  const users = mapUsers(data.users);

  return historyItems.map((item) => {
    const dateChanged = new Date(item.created_at);
    return {
      date: $.dateString(dateChanged, { format: 'medium', timezone: constants.timezone() }),
      time: $.timeString(dateChanged, { format: 'medium', timezone: constants.timezone() }),
      from: GradeFormatHelper.formatGrade(item.grade_before, { defaultValue: '-' }),
      to: GradeFormatHelper.formatGrade(item.grade_after, {defaultValue: '-' }),
      grader: users[item.links.grader] || I18n.t('Not available'),
      student: users[item.links.student] || I18n.t('Not available'),
      assignment: item.links.assignment,
      anonymous: item.graded_anonymously ? I18n.t('yes') : I18n.t('no'),
      id: item.id
    };
  });
}

function history (state = {}, { type, payload }) {
  switch (type) {
    case FETCH_HISTORY_START: {
      return {
        ...state,
        loading: true,
        items: null,
        fetchHistoryStatus: 'started'
      };
    }
    case FETCH_HISTORY_SUCCESS: {
      return {
        ...state,
        loading: false,
        items: formatHistoryItems(payload),
        fetchHistoryStatus: 'success'
      };
    }
    case FETCH_HISTORY_FAILURE: {
      return {
        ...state,
        loading: false,
        fetchHistoryStatus: 'failure'
      };
    }
    default: {
      return state;
    }
  }
}

export default history;

export {
  formatHistoryItems,
  mapUsers
};
