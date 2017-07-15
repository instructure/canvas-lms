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

import React from 'react';
import { shallow } from 'enzyme';
import I18n from 'i18n!gradebook-history';
import Spinner from 'instructure-ui/lib/components/Spinner';
import Table from 'instructure-ui/lib/components/Table';
import { SearchResultsComponent } from 'jsx/gradebook-history/SearchResults';
import $ from 'jquery';
import 'jquery.instructure_date_and_time';

const mockHistoryItem = {
  created_at: '2017-05-19T18:54:01Z',
  grade_before: '0',
  grade_after: '21',
  links: {
    grader: 2,
    student: 8,
    assignment: 3,
    graded_anonymously: false
  }
};

const anotherMockHistoryItem = {
  created_at: '2017-05-20T18:54:01Z',
  grade_before: '21',
  grade_after: '0',
  links: {
    grader: 2,
    student: 10,
    assignment: 3,
    graded_anonymously: true
  }
};

const mockUsers = {
  1: 'admin@instructure.com',
  2: 'teacher@instructure.com',
  8: 'classpres@instructure.com',
  10: 'classclown@instructure.com'
};

const formatHistoryItems = (historyItems, users = {}) => {
  if (historyItems == null) {
    return [];
  }

  const length = historyItems.length;
  const formattedHistoryItems = []

  for (let i = 0; i < length; i += 1) {
    const newHistoryItem = {};

    const dateChanged = new Date(historyItems[i].created_at);

    newHistoryItem.Date = $.dateString(dateChanged, { format: 'medium', timezone: ENV.TIMEZONE });
    newHistoryItem.Time = $.timeString(dateChanged, { format: 'medium', timezone: ENV.TIMEZONE });
    newHistoryItem.From = I18n.n(historyItems[i].grade_before) || '-';
    newHistoryItem.To = I18n.n(historyItems[i].grade_after) || '-';
    newHistoryItem.Grader = users[historyItems[i].links.grader] || 'Not available';
    newHistoryItem.Student = users[historyItems[i].links.student] || 'Not available';
    newHistoryItem.Assignment = historyItems[i].links.assignment;
    newHistoryItem.Anonymous = historyItems[i].graded_anonymously ? I18n.t('yes') : I18n.t('no');

    formattedHistoryItems.push(newHistoryItem);
  }

  return formattedHistoryItems;
};

const mountComponent = (customProps = {}) => {
  const props = {
    historyItems: [],
    label: 'search results',
    requestingResults: false,
    users: {},
    errorMessage: ''
  };
  return shallow(<SearchResultsComponent {...props} {...customProps} />);
};

QUnit.module('SearchResults');

test('does not show a Table/Spinner if no historyItems passed', function () {
  const wrapper = mountComponent();
  notOk(wrapper.find(Table).exists());
});

test('shows a Table if there are historyItems passed', function () {
  const props = { historyItems: [mockHistoryItem] };
  const wrapper = mountComponent(props);
  ok(wrapper.find(Table).exists());
});

test('Table is passed the label and caption props', function () {
  const props = {
    label: 'search results label',
    historyItems: [mockHistoryItem]
  };
  const wrapper = mountComponent(props);
  const table = wrapper.find(Table);
  equal(table.props().label, props.label);
  equal(table.props().caption, props.label);
});

test('Table is passed column headers in correct order', function () {
  const props = { historyItems: [mockHistoryItem] };
  const colHeaders = ['Date', 'Time', 'From', 'To', 'Grader', 'Student', 'Assignment', 'Anonymous'];
  const wrapper = mountComponent(props);
  const table = wrapper.find(Table);
  deepEqual(table.props().colHeaders, colHeaders);
});

test('Table displays the formatted historyItems passed', function () {
  const props = {
    historyItems: [mockHistoryItem, anotherMockHistoryItem],
    users: mockUsers
  };
  const wrapper = mountComponent(props);
  const table = wrapper.find(Table);

  const expectedValue = formatHistoryItems(props.historyItems, props.users);

  deepEqual(table.props().tableData, expectedValue);
});

test('does not show a Spinner if requestingResults false', function () {
  const wrapper = mountComponent({ requestingResults: false });
  notOk(wrapper.find(Spinner).exists());
});

test('shows a Spinner if requestingResults true', function () {
  const props = {
    requestingResults: true
  };
  const wrapper = mountComponent(props);
  ok(wrapper.find(Spinner).exists());
});
