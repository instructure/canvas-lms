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
import AssignmentGroupColumnHeader from 'jsx/gradezilla/default_gradebook/components/AssignmentGroupColumnHeader'

function createExampleProps () {
  return {
    assignmentGroup: {
      groupWeight: 42.5,
      name: 'Assignment Group 1'
    },
    sortBySetting: {
      direction: 'ascending',
      disabled: false,
      isSortColumn: true,
      onSortByGradeAscending () {},
      onSortByGradeDescending () {},
      settingKey: 'grade'
    },
    weightedGroups: true
  };
}

function mountComponent (props) {
  return mount(<AssignmentGroupColumnHeader {...props} />);
}

function mountAndOpenOptions (props) {
  const wrapper = mountComponent(props);
  wrapper.find('.Gradebook__ColumnHeaderAction').simulate('click');
  return wrapper;
}

QUnit.module('AssignmentGroupColumnHeader - base behavior', {
  setup () {
    const props = createExampleProps();
    this.wrapper = mountComponent(props);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders the assignment group name', function () {
  const assignmentGroupName = this.wrapper.find('.Gradebook__ColumnHeaderDetail').childAt(0);
  equal(assignmentGroupName.text(), 'Assignment Group 1');
});

test('renders the assignment groupWeight percentage', function () {
  const groupWeight = this.wrapper.find('.Gradebook__ColumnHeaderDetail').childAt(1);
  equal(groupWeight.text(), '42.50% of grade');
});

QUnit.module('AssignmentGroupColumnHeader - non-standard assignment group', {
  setup () {
    this.props = createExampleProps();
  },
});

test('renders 0% as the groupWeight percentage when weightedGroups is true but groupWeight is 0', function () {
  this.props.assignmentGroup.groupWeight = 0;

  const wrapper = mountComponent(this.props);

  const groupWeight = wrapper.find('.Gradebook__ColumnHeaderDetail').childAt(1);
  equal(groupWeight.text(), '0.00% of grade');
});

test('does not render the groupWeight percentage when weightedGroups is false', function () {
  this.props.weightedGroups = false;

  const wrapper = mountComponent(this.props);

  const headerDetails = wrapper.find('.Gradebook__ColumnHeaderDetail').children();
  equal(headerDetails.length, 1, 'only the assignment group name is visible');
  equal(headerDetails.text(), 'Assignment Group 1');
});

QUnit.module('AssignmentColumnHeader - Sort by Settings', {
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
