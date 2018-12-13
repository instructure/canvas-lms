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
import AssignmentGroupFilter from 'jsx/gradezilla/default_gradebook/components/AssignmentGroupFilter';

function defaultProps () {
  return {
    items: [
      { id: '1', name: 'Assignment Group 1' },
      { id: '2', name: 'Assignment Group 2' },
    ],
    onSelect: () => {},
    selectedItemId: '0',
  }
}

QUnit.module('Assignment Group Filter - subclass functionality', {
  setup () {
    const props = defaultProps();
    this.wrapper = mount(<AssignmentGroupFilter {...props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders a screenreader-friendly label', function () {
  strictEqual(this.wrapper.find('ScreenReaderContent').text(), 'Assignment Group Filter');
});

test('the options are displayed in the same order as they were sent in', function () {
  const actualOptionIds = this.wrapper.find('option').map(opt => opt.text());
  const expectedOptionIds = ['All Assignment Groups', 'Assignment Group 1', 'Assignment Group 2'];

  deepEqual(actualOptionIds, expectedOptionIds);
});
