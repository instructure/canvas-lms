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
import { mount, ReactWrapper } from 'enzyme';
import ModuleFilter from 'jsx/gradezilla/default_gradebook/components/ModuleFilter';

function createExampleProps () {
  return {
    modules: [
      { id: '0', name: 'All Modules', position: -1 },
      { id: '1', name: 'Module 1', position: 2 },
      { id: '2', name: 'Module 2', position: 1 },
    ],
    onSelect: () => {},
    selectedModuleId: '0'
  }
}

function getMenuItem (menuItems, label) {
  return menuItems.map(menuItem => menuItem).find(item => item.text() === label);
}

QUnit.module('Module Filter - basic functionality', {
  setup () {
    const props = createExampleProps();
    this.wrapper = mount(<ModuleFilter {...props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders a button', function () {
  strictEqual(this.wrapper.find('button').length, 1);
});

test('rendered button shows the name of the currently selected module', function () {
  strictEqual(this.wrapper.find('button').text().trim(), 'All Modules');
});

test('clicking on the button opens a menu of modules', function () {
  this.wrapper.find('button').simulate('click');
  const menuContent = new ReactWrapper([this.wrapper.node.menuContent], this.wrapper.node);

  ok(menuContent);
});

test('menu of modules lists all modules', function () {
  this.wrapper.find('button').simulate('click');
  const menuContent = new ReactWrapper([this.wrapper.node.menuContent], this.wrapper.node);

  strictEqual(menuContent.find('MenuItem').length, 3);
});

test('menu lists modules sorted by the position field', function () {
  this.wrapper.find('button').simulate('click');
  const menuContent = new ReactWrapper([this.wrapper.node.menuContent], this.wrapper.node);

  const expectedMenuItemNames = ['All Modules', 'Module 2', 'Module 1'];
  const menuItems = menuContent.find('MenuItem');
  const actualMenuItemNames = [menuItems.at(0).text(), menuItems.at(1).text(), menuItems.at(2).text()];

  deepEqual(actualMenuItemNames, expectedMenuItemNames);
});

test('selecting a menu item calls the onSelect prop with the module id', function () {
  const props = { ...createExampleProps(), onSelect: this.stub() };
  this.wrapper = mount(<ModuleFilter {...props} />);
  this.wrapper.find('button').simulate('click');
  const menuContent = new ReactWrapper([this.wrapper.node.menuContent], this.wrapper.node);
  const menuItems = menuContent.find('MenuItem');

  getMenuItem(menuItems, 'Module 2').simulate('click');

  strictEqual(props.onSelect.callCount, 1);
  strictEqual(props.onSelect.getCall(0).args[0], '2');
});
