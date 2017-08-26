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
import { mount } from 'enzyme';
import Fixtures from 'spec/jsx/gradebook-history/Fixtures';
import { formatHistoryItems } from 'jsx/gradebook-history/actions/HistoryActions';
import SearchResultsRow from 'jsx/gradebook-history/SearchResultsRow';

const mountComponent = (props = {}) => {
  const singleItem = formatHistoryItems(Fixtures.historyResponse().data)[0];
  const defaultProps = { item: singleItem };
  const tbody = document.getElementById('search-results-tbody');

  return mount(<SearchResultsRow {...defaultProps} {...props} />, {attachTo: tbody});
}

QUnit.module('SearchResultsRow', {
  setup () {
    // can't insert <tr/> into a <div/>, so create a <tbody/> first
    const tbody = document.createElement('tbody');
    tbody.id = 'search-results-tbody';
    document.body.appendChild(tbody);

    this.item = formatHistoryItems(Fixtures.historyResponse().data)[0];
    this.wrapper = mountComponent({ item: this.item });
  },

  teardown () {
    const tbody = document.getElementById('search-results-tbody');
    this.wrapper.detach();
    tbody.remove();
  }
});

test('displays the history date', function () {
  const date = this.wrapper.find('td').nodes[0].innerText;
  strictEqual(date, this.item.date);
});

test('displays the history time', function () {
  const time = this.wrapper.find('td').nodes[1].innerText;
  strictEqual(time, this.item.time);
});

test('displays the history from', function () {
  const from = this.wrapper.find('td').nodes[2].innerText;
  strictEqual(from, this.item.from);
});

test('displays the history to', function () {
  const to = this.wrapper.find('td').nodes[3].innerText;
  strictEqual(to, this.item.to);
});

test('displays the history grader', function () {
  const grader = this.wrapper.find('td').nodes[4].innerText;
  strictEqual(grader, this.item.grader);
});

test('displays the history student', function () {
  const student = this.wrapper.find('td').nodes[5].innerText;
  strictEqual(student, this.item.student);
});

test('displays the history assignment', function () {
  const assignment = this.wrapper.find('td').nodes[6].innerText;
  strictEqual(assignment, this.item.assignment.toString());
});

test('displays the history anonymity', function () {
  const anonymous = this.wrapper.find('td').nodes[7].innerText;
  strictEqual(anonymous, this.item.anonymous);
});
