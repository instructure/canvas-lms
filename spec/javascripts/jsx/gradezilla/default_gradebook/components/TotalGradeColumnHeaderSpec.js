/*
 * Copyright (C) 2017 Instructure, Inc.
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
import { mount, ReactWrapper } from 'enzyme'
import TotalGradeColumnHeader from 'jsx/gradezilla/default_gradebook/components/TotalGradeColumnHeader'

function createExampleProps () {
  return {
    sortBySetting: {
      direction: 'ascending',
      disabled: false,
      isSortColumn: true,
      onSortByGradeAscending () {},
      onSortByGradeDescending () {},
      settingKey: 'grade'
    }
  };
}

function mountAndOpenOptions (props) {
  const wrapper = mount(<TotalGradeColumnHeader {...props} />);
  wrapper.find('.Gradebook__ColumnHeaderAction').simulate('click');
  return wrapper;
}

QUnit.module('TotalGradeColumnHeader - Sort by Settings', {
  setup () {
    this.props = createExampleProps();
  },

  getMenuItem (index) {
    const menuItemGroup = new ReactWrapper([this.wrapper.node.optionsMenuContent], this.wrapper.node);
    return menuItemGroup.find('MenuItem').at(index);
  },

  getSelectedMenuItem () {
    const menuItemGroup = new ReactWrapper([this.wrapper.node.optionsMenuContent], this.wrapper.node);
    return menuItemGroup.find('MenuItem').findWhere(menuItem => menuItem.prop('selected'));
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('includes the "Sort by" group', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const optionsMenu = new ReactWrapper([this.wrapper.node.optionsMenuContent], this.wrapper.node);
  const menuItemGroup = optionsMenu.find('MenuItemGroup').at(0);
  equal(menuItemGroup.length, 1, '"Sort by" group exists');
  equal(menuItemGroup.prop('label'), 'Sort by');
});

test('includes "Grade - Low to High" sort setting', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(0);
  equal(menuItem.text(), 'Grade - Low to High');
});

test('selects "Grade - Low to High" when sorting by grade ascending', function () {
  this.props.sortBySetting.settingKey = 'grade';
  this.props.sortBySetting.direction = 'ascending';
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');
  equal(menuItem.text(), 'Grade - Low to High', '"Grade - Low to High" is selected');
});

test('does not select "Grade - Low to High" when isSortColumn is false', function () {
  this.props.sortBySetting.settingKey = 'grade';
  this.props.sortBySetting.direction = 'ascending';
  this.props.sortBySetting.isSortColumn = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(0);
  equal(menuItem.prop('selected'), false);
});

test('clicking "Grade - Low to High" calls onSortByGradeAscending', function () {
  this.props.sortBySetting.onSortByGradeAscending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(0).simulate('click');
  equal(this.props.sortBySetting.onSortByGradeAscending.callCount, 1);
});

test('"Grade - Low to High" is optionally disabled', function () {
  this.props.sortBySetting.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(0);
  equal(menuItem.prop('disabled'), true);
});

test('clicking "Grade - Low to High" when disabled does not call onSortByGradeAscending', function () {
  this.props.sortBySetting.disabled = true;
  this.props.sortBySetting.onSortByGradeAscending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(0).simulate('click');
  equal(this.props.sortBySetting.onSortByGradeAscending.callCount, 0);
});

test('includes "Grade - High to Low" sort setting', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(1);
  equal(menuItem.text(), 'Grade - High to Low');
});

test('selects "Grade - High to Low" when sorting by grade descending', function () {
  this.props.sortBySetting.settingKey = 'grade';
  this.props.sortBySetting.direction = 'descending';
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');
  equal(menuItem.text(), 'Grade - High to Low', '"Grade - High to Low" is selected');
});

test('does not select "Grade - High to Low" when isSortColumn is false', function () {
  this.props.sortBySetting.settingKey = 'grade';
  this.props.sortBySetting.direction = 'descending';
  this.props.sortBySetting.isSortColumn = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(1);
  equal(menuItem.prop('selected'), false);
});

test('clicking "Grade - High to Low" calls onSortByGradeDescending', function () {
  this.props.sortBySetting.onSortByGradeDescending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(1).simulate('click');
  equal(this.props.sortBySetting.onSortByGradeDescending.callCount, 1);
});

test('"Grade - High to Low" is optionally disabled', function () {
  this.props.sortBySetting.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(1);
  equal(menuItem.prop('disabled'), true);
});

test('clicking "Grade - High to Low" when disabled does not call onSortByGradeDescending', function () {
  this.props.sortBySetting.disabled = true;
  this.props.sortBySetting.onSortByGradeDescending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(1).simulate('click');
  equal(this.props.sortBySetting.onSortByGradeDescending.callCount, 0);
});
