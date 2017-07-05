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
import { mount, shallow } from 'enzyme';
import Spinner from 'instructure-ui/lib/components/Spinner';
import Table from 'instructure-ui/lib/components/Table';
import Typography from 'instructure-ui/lib/components/Typography';
import constants from 'jsx/gradebook-history/constants';
import { SearchResultsComponent } from 'jsx/gradebook-history/SearchResults';
import { formatHistoryItems } from 'jsx/gradebook-history/reducers/HistoryReducer';
import Fixtures from 'spec/jsx/gradebook-history/Fixtures';

const defaultProps = () => (
  {
    caption: 'search results',
    fetchHistoryStatus: '',
    historyItems: [],
    loadMore () {},
    requestingResults: false
  }
);

const mountComponent = (customProps = {}) => (
  shallow(<SearchResultsComponent {...defaultProps()} {...customProps} />)
);

QUnit.module('SearchResults');

test('does not show a Table/Spinner if no historyItems passed', function () {
  const wrapper = mountComponent();
  notOk(wrapper.find(Table).exists());
});

test('shows a Table if there are historyItems passed', function () {
  const historyItems = formatHistoryItems(Fixtures.payload());
  const props = { historyItems };
  const wrapper = mountComponent(props);
  ok(wrapper.find(Table).exists());
});

test('Table is passed the label and caption props', function () {
  const historyItems = formatHistoryItems(Fixtures.payload());
  const props = { caption: 'search results caption', historyItems };
  const wrapper = mountComponent(props);
  const table = wrapper.find(Table);
  equal(table.props().caption, props.caption);
});

test('Table is passed column headers in correct order', function () {
  const historyItems = formatHistoryItems(Fixtures.payload());
  const props = { historyItems };
  const wrapper = mountComponent(props);
  const table = wrapper.find(Table);
  deepEqual(table.props().colHeaders, constants.colHeaders);
});

test('Table displays the formatted historyItems passed it', function () {
  const payload = Fixtures.payload();
  const events = payload.events;
  const historyItems = formatHistoryItems(payload);
  const props = { ...defaultProps(), historyItems }
  const tableBody = mount(<SearchResultsComponent {...props} />).find('tbody');
  equal(tableBody.find('tr').length, events.length);
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

test('Table shows text if request was made but no results were found', function () {
  const props = { ...defaultProps(), fetchHistoryStatus: 'success', historyItems: [] };
  const wrapper = mount(<SearchResultsComponent {...props} />);
  const textBox = wrapper.find(Typography);
  ok(textBox.exists());
  equal(textBox.text(), 'No results found');
});
