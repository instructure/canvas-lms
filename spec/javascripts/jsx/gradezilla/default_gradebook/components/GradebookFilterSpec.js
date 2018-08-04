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
import GradebookFilter from 'jsx/gradezilla/default_gradebook/components/GradebookFilter';

function defaultProps () {
  return {
    items: [
      { id: '1', name: 'Module 1', position: 2 },
      { id: '2', name: 'Module 2', position: 1 },
    ],
    onSelect: () => {},
    selectedItemId: '0',
  }
}

QUnit.module('Gradebook Filter - basic functionality', {
  setup () {
    const props = defaultProps();
    this.wrapper = mount(<GradebookFilter {...props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders a Select component', function () {
  strictEqual(this.wrapper.find('Select').length, 1);
});

test('disables the underlying select component if specified by props', function () {
  const props = { ...defaultProps(), disabled: true };
  this.wrapper = mount(<GradebookFilter {...props} />);

  strictEqual(this.wrapper.find('select').nodes[0].disabled, true)
});

test('renders a screenreader-friendly label', function () {
  strictEqual(this.wrapper.find('ScreenReaderContent').at(1).text(), 'Item Filter');
});

test('the Select component has three options', function () {
  strictEqual(this.wrapper.find('option').length, 3);
});

test('the options are in the same order as they were sent in', function () {
  const actualOptionIds = this.wrapper.find('option').map(opt => opt.node.value);
  const expectedOptionIds = ['0', '1', '2'];

  deepEqual(actualOptionIds, expectedOptionIds);
});

test('the options are displayed in the same order as they were sent in', function () {
  const actualOptionIds = this.wrapper.find('option').map(opt => opt.text());
  const expectedOptionIds = ['All Items', 'Module 1', 'Module 2'];

  deepEqual(actualOptionIds, expectedOptionIds);
});

test('selecting an option calls the onSelect prop', function () {
  const props = { ...defaultProps(), onSelect: sinon.stub() };
  this.wrapper = mount(<GradebookFilter {...props} />);
  this.wrapper.find('select').simulate('change', { target: { value: '2' }});

  strictEqual(props.onSelect.callCount, 1);
});

test('selecting an option calls the onSelect prop with the module id', function () {
  const props = { ...defaultProps(), onSelect: sinon.stub() };
  this.wrapper = mount(<GradebookFilter {...props} />);
  this.wrapper.find('select').simulate('change', { target: { value: '2' }});

  strictEqual(props.onSelect.firstCall.args[0], '2');
});

test('selecting an option while the control is disabled does not call the onSelect prop', function () {
  const props = { ...defaultProps(), onSelect: sinon.stub(), disabled: true };
  this.wrapper = mount(<GradebookFilter {...props} />);
  this.wrapper.find('select').simulate('change', { target: { value: '2' }});

  strictEqual(props.onSelect.callCount, 0);
});
