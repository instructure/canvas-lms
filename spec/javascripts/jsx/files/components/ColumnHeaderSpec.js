/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import TestUtils from 'react-dom/test-utils'
import ColumnHeaders from 'jsx/files/ColumnHeaders'

QUnit.module('ColumnHeaders');

test('`queryParamsFor` returns correct values', () => {
  const SORT_UPDATED_AT_DESC = {sort: 'updated_at', order: 'desc'};
  const queryParamsFor = ColumnHeaders.prototype.queryParamsFor;

  deepEqual(queryParamsFor({}, 'updated_at'), SORT_UPDATED_AT_DESC, 'was not sorted by anything');
  deepEqual(queryParamsFor({sort: 'created_at', order: 'desc'}, 'updated_at'), SORT_UPDATED_AT_DESC, 'was sorted by other column');
  deepEqual(queryParamsFor({sort: 'updated_at', order: 'asc' }, 'updated_at'), SORT_UPDATED_AT_DESC, 'was sorted by this column ascending');
  deepEqual(queryParamsFor({sort: 'updated_at', order: 'desc'}, 'updated_at'), {sort: 'updated_at', order: 'asc'});
});

test('headers have the proper href', () => {
  const props = {
    pathname: '/some/path/to/files',
    query: {
      sort: 'something',
      order: 'asc'
    },
    areAllItemsSelected () {},
    toggleAllSelected () {}
  };

  const component = TestUtils.renderIntoDocument(<ColumnHeaders {...props} />);
  const nameLink = TestUtils.scryRenderedDOMComponentsWithTag(component, 'a')[0];
  const url = new URL(nameLink.href)
  equal(url.pathname, props.pathname)
  equal(url.search, '?sort=name&order=desc')
});
