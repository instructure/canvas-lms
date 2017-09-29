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
import { Provider } from 'react-redux';
import { shallow } from 'enzyme';
import SearchForm from 'jsx/gradebook-history/SearchForm';
import SearchResults from 'jsx/gradebook-history/SearchResults';
import GradebookHistoryApp from 'jsx/gradebook-history/GradebookHistoryApp';
import GradebookHistoryStore from 'jsx/gradebook-history/store/GradebookHistoryStore';

QUnit.module('GradebookHistoryApp has component', {
  setup () {
    this.wrapper = shallow(<GradebookHistoryApp />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('Provider with a store prop', function () {
  const provider = this.wrapper.find(Provider);
  equal(provider.length, 1);
  equal(provider.props().store, GradebookHistoryStore);
});

test('Heading', function () {
  const heading = this.wrapper.find('h1');
  strictEqual(heading.length, 1);
});

test('SearchForm', function () {
  const form = this.wrapper.find(SearchForm);
  strictEqual(form.length, 1);
});

test('SearchResults', function () {
  const results = this.wrapper.find(SearchResults);
  strictEqual(results.length, 1);
});
