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
import Spinner from '@instructure/ui-elements/lib/components/Spinner';
import Table from '@instructure/ui-elements/lib/components/Table';
import Text from '@instructure/ui-elements/lib/components/Text';
import { SearchResultsComponent } from 'jsx/gradebook-history/SearchResults';

function defaultHistoryItems () {
  return [
    {
      anonymous: false,
      assignment: 'Rustic Rubber Duck',
      date: 'May 30, 2017',
      displayAsPoints: true,
      grader: 'Ms. Twillie Jones',
      gradeAfter: '21',
      gradeBefore: '19',
      gradeCurrent: '22',
      id: '123456',
      pointsPossibleBefore: '25',
      pointsPossibleAfter: '25',
      pointsPossibleCurrent: '30',
      student: 'Norval Abbott',
      time: '11:16pm'
    }
  ];
}

function defaultProps () {
  return {
    caption: 'search results caption',
    fetchHistoryStatus: 'success',
    historyItems: defaultHistoryItems(),
    getNextPage () {},
    nextPage: 'example.com',
    requestingResults: false
  };
}

function mountComponent (customProps = {}) {
  return shallow(<SearchResultsComponent {...defaultProps()} {...customProps} />);
}

QUnit.module('SearchResults', {
  setup () {
    this.wrapper = mountComponent(defaultProps());
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('does not show a Table/Spinner if no historyItems passed', function () {
  const wrapper = mountComponent({ historyItems: [] });
  notOk(wrapper.find(Table).exists());
});

test('shows a Table if there are historyItems passed', function () {
  ok(this.wrapper.find(Table).exists());
});

test('Table is passed the label and caption props', function () {
  const table = this.wrapper.find(Table);
  equal(table.props().caption, 'search results caption');
});

test('Table has column headers in correct order', function () {
  const expectedHeaders = [
    'Date',
    'Anonymous Grading',
    'Student',
    'Grader',
    'Assignment',
    'Before',
    'After',
    'Current'
  ];
  const wrapper = mount(<SearchResultsComponent {...defaultProps()} />);
  const headers = wrapper.find('thead').find('tr').find('th').map(n => n.text());

  deepEqual(headers, expectedHeaders);
  wrapper.unmount();
});

test('Table displays the formatted historyItems passed it', function () {
  const items = defaultHistoryItems();
  const props = { ...defaultProps(), items }
  const tableBody = mount(<SearchResultsComponent {...props} />);
  equal(tableBody.find('tbody').find('tr').length, items.length);
  tableBody.unmount();
});

test('does not show a Spinner if requestingResults false', function () {
  notOk(this.wrapper.find(Spinner).exists());
});

test('shows a Spinner if requestingResults true', function () {
  const wrapper = mountComponent({ requestingResults: true });
  ok(wrapper.find(Spinner).exists());
  wrapper.unmount();
});

test('Table shows text if request was made but no results were found', function () {
  const props = { ...defaultProps(), fetchHistoryStatus: 'success', historyItems: [] };
  const wrapper = mount(<SearchResultsComponent {...props} />);
  const textBox = wrapper.find(Text);
  ok(textBox.exists());
  equal(textBox.text(), 'No results found.');
  wrapper.unmount();
});

test('shows text indicating that the end of results was reached', function () {
  const historyItems = defaultHistoryItems();
  const props = { ...defaultProps(), nextPage: '', requestingResults: false, historyItems };
  const wrapper = mount(<SearchResultsComponent {...props} />);
  const textBox = wrapper.find(Text);
  ok(textBox.exists());
  equal(textBox.text(), 'No more results to load.');
  wrapper.unmount();
});

test('loads next page if possible and the first results did not result in a scrollbar', function () {
  const actualInnerHeight = window.innerHeight;
  // fake to test that there's not a vertical scrollbar
  window.innerHeight = document.body.clientHeight + 1;
  const historyItems = defaultHistoryItems();
  const props = { ...defaultProps(), nextPage: 'example.com', getNextPage: sinon.stub() };
  const wrapper = mount(<SearchResultsComponent {...props} />);
  wrapper.setProps({ historyItems });
  ok(props.getNextPage.callCount > 0);
  window.innerHeight = actualInnerHeight;
  wrapper.unmount();
});

test('loads next page on scroll if possible', function () {
  const actualInnerHeight = window.innerHeight;
  const props = {
    ...defaultProps(),
    nextPage: 'example.com',
    getNextPage: sinon.stub()
  };
  const wrapper = mount(<SearchResultsComponent {...props} />);
  window.innerHeight = document.body.clientHeight - 1;
  document.dispatchEvent(new Event('scroll'));
  ok(props.getNextPage.callCount > 0);
  window.innerHeight = actualInnerHeight;
  wrapper.unmount();
});

test('loads next page if available on window resize that causes window to not have a scrollbar', function () {
  const historyItems = defaultHistoryItems();
  const props = {
    ...defaultProps(),
    historyItems,
    nextPage: 'example.com',
    getNextPage: sinon.stub()
  };
  const wrapper = mount(<SearchResultsComponent {...props} />);
  window.innerHeight = document.body.clientHeight;
  window.dispatchEvent(new Event('resize'));
  strictEqual(props.getNextPage.callCount, 1);
  wrapper.unmount();
});
