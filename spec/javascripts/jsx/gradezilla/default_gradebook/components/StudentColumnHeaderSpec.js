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

import React from 'react'
import { mount, ReactWrapper } from 'enzyme'
import StudentRowHeaderConstants from 'jsx/gradezilla/default_gradebook/constants/StudentRowHeaderConstants'
import StudentColumnHeader from 'jsx/gradezilla/default_gradebook/components/StudentColumnHeader'

function mountAndOpenOptions (props) {
  const wrapper = mount(<StudentColumnHeader {...props} />);
  wrapper.find('.Gradebook__ColumnHeaderAction').simulate('click');
  return wrapper;
}

QUnit.module('StudentColumnHeader - base behavior', {
  setup () {
    const props = {
      onToggleEnrollmentFilter () {},
      selectedEnrollmentFilters: [],
      selectedSecondaryInfo: StudentRowHeaderConstants.defaultSecondaryInfo,
      sectionsEnabled: true,
      selectedPrimaryInfo: StudentRowHeaderConstants.defaultPrimaryInfo,
      onSelectPrimaryInfo () {},
      onSelectSecondaryInfo () {},
      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortBySortableNameAscending () {},
        onSortBySortableNameDescending () {},
        settingKey: 'sortable_name'
      }
    };

    this.wrapper = mount(<StudentColumnHeader {...props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders a title for .Gradebook__ColumnHeaderDetail', function () {
  const selectedElements = this.wrapper.find('.Gradebook__ColumnHeaderDetail');

  ok(selectedElements.text().includes('Student Name'));
});

test('renders a PopoverMenu', function () {
  const selectedElements = this.wrapper.find('PopoverMenu');

  equal(selectedElements.length, 1);
});

test('renders an IconMoreSolid inside the PopoverMenu', function () {
  const selectedElements = this.wrapper.find('PopoverMenu IconMoreSolid');

  equal(selectedElements.length, 1)
});

test('renders a title for the More icon', function () {
  const selectedElements = this.wrapper.find('PopoverMenu IconMoreSolid');

  equal(selectedElements.props().title, 'Student Name Options');
});

QUnit.module('StudentColumnHeader - secondaryInfoMenuGroup', {
  setup () {
    this.props = {
      onToggleEnrollmentFilter () {},
      selectedEnrollmentFilters: [],
      sectionsEnabled: true,
      selectedSecondaryInfo: StudentRowHeaderConstants.defaultSecondaryInfo,
      onSelectSecondaryInfo: this.stub(),
      selectedPrimaryInfo: StudentRowHeaderConstants.defaultPrimaryInfo,
      onSelectPrimaryInfo () {},
      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortBySortableNameAscending () {},
        onSortBySortableNameDescending () {},
        settingKey: 'sortable_name'
      }
    };
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders a MenuItemGroup for secondary info options', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItemGroup = this.wrapper.find('[data-menu-item-group-id="secondary-info"]');
  ok(menuItemGroup);
});

test('renders a MenuItem for each secondary info option', function () {
  this.wrapper = mountAndOpenOptions(this.props);

  StudentRowHeaderConstants.secondaryInfoKeys.forEach((key) => {
    const menuItem = document.querySelector(`[data-menu-item-id="${key}"]`);

    ok(menuItem);
  });
});

test('invokes prop onSelectSecondaryInfo when MenuItem is clicked', function () {
  this.wrapper = mount(<StudentColumnHeader {...this.props} />);

  StudentRowHeaderConstants.secondaryInfoKeys.forEach((key) => {
    this.wrapper.find('.Gradebook__ColumnHeaderAction').simulate('click');
    const menuItem = document.querySelector(`[data-menu-item-id="${key}"]`);

    menuItem.click();

    equal(this.props.onSelectSecondaryInfo.lastCall.args[0], key);
  });
});

test('omits section when sectionsEnabled prop is false', function () {
  this.props.sectionsEnabled = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = document.querySelector('[data-menu-item-id="section"]');
  notOk(menuItem);
});

QUnit.module('StudentColumnHeader - Sort by Settings', {
  setup () {
    this.props = {
      onToggleEnrollmentFilter () {},
      selectedEnrollmentFilters: [],
      sectionsEnabled: true,
      selectedSecondaryInfo: StudentRowHeaderConstants.defaultSecondaryInfo,
      onSelectSecondaryInfo: this.stub(),
      selectedPrimaryInfo: StudentRowHeaderConstants.defaultPrimaryInfo,
      onSelectPrimaryInfo () {},
      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortBySortableNameAscending () {},
        onSortBySortableNameDescending () {},
        settingKey: 'sortable_name'
      }
    };
  },

  getMenuItemGroup () {
    return new ReactWrapper(
      [this.wrapper.node.optionsMenuContent],
      this.wrapper.node
    ).find('MenuItemGroup').first();
  },

  getMenuItem (index) {
    return this.getMenuItemGroup().find('MenuItem').at(index);
  },

  getSelectedMenuItem () {
    return this.getMenuItemGroup().findWhere(menuItem => menuItem.prop('selected'));
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

test('includes "A–Z" sort setting', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(0);
  equal(menuItem.text().trim(), 'A–Z');
});

test('selects "A–Z" when sorting by sortable name ascending', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');
  equal(menuItem.text().trim(), 'A–Z', '"A–Z" is selected');
});

test('does not select "A–Z" when isSortColumn is false', function () {
  this.props.sortBySetting.isSortColumn = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(0);
  equal(menuItem.prop('selected'), false);
});

test('clicking "A–Z" calls onSortBySortableNameAscending', function () {
  this.props.sortBySetting.onSortBySortableNameAscending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(0).simulate('click');
  equal(this.props.sortBySetting.onSortBySortableNameAscending.callCount, 1);
});

test('"A–Z" is optionally disabled', function () {
  this.props.sortBySetting.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(0);
  equal(menuItem.prop('disabled'), true);
});

test('clicking "A–Z" when disabled does not call onSortBySortableNameAscending', function () {
  this.props.sortBySetting.disabled = true;
  this.props.sortBySetting.onSortBySortableNameAscending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(0).simulate('click');
  equal(this.props.sortBySetting.onSortBySortableNameAscending.callCount, 0);
});

test('includes "Z–A" sort setting', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(1);
  equal(menuItem.text().trim(), 'Z–A');
});

test('selects "Z–A" when sorting by sortable name descending', function () {
  this.props.sortBySetting.direction = 'descending';
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');
  equal(menuItem.text().trim(), 'Z–A', '"Z–A" is selected');
});

test('does not select "Z–A" when isSortColumn is false', function () {
  this.props.sortBySetting.direction = 'descending';
  this.props.sortBySetting.isSortColumn = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(1);
  equal(menuItem.prop('selected'), false);
});

test('clicking "Z–A" calls onSortBySortableNameDescending', function () {
  this.props.sortBySetting.onSortBySortableNameDescending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(1).simulate('click');
  equal(this.props.sortBySetting.onSortBySortableNameDescending.callCount, 1);
});

test('"Z–A" is optionally disabled', function () {
  this.props.sortBySetting.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(1);
  equal(menuItem.prop('disabled'), true);
});

test('clicking "Z–A" when disabled does not call onSortBySortableNameDescending', function () {
  this.props.sortBySetting.disabled = true;
  this.props.sortBySetting.onSortBySortableNameDescending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(1).simulate('click');
  equal(this.props.sortBySetting.onSortBySortableNameDescending.callCount, 0);
});

test('uses prop loginHandleName for "login_id" menu item label', function () {
  this.props.loginHandleName = 'custom login handle name';

  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="login_id"]');

  ok(menuItem.textContent.includes(this.props.loginHandleName));
});

test('uses default label when loginHandleName prop is falsy', function () {
  this.props.loginHandleName = '';

  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="login_id"]');

  ok(menuItem.textContent.includes(StudentRowHeaderConstants.secondaryInfoLabels.login_id));
});

test('uses prop sisName for "sis_id" menu item label', function () {
  this.props.sisName = 'custom sis name';

  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="sis_id"]');

  ok(menuItem.textContent.includes(this.props.sisName));
});

test('uses default label when sisName prop is falsy', function () {
  this.props.sisName = '';

  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="sis_id"]');

  ok(menuItem.textContent.includes(StudentRowHeaderConstants.secondaryInfoLabels.sis_id));
});

QUnit.module('StudentColumnHeader - primaryInfoMenuGroup', {
  setup () {
    this.props = {
      onToggleEnrollmentFilter () {},
      selectedEnrollmentFilters: [],
      sectionsEnabled: true,
      selectedSecondaryInfo: StudentRowHeaderConstants.defaultSecondaryInfo,
      onSelectSecondaryInfo () {},
      selectedPrimaryInfo: StudentRowHeaderConstants.defaultPrimaryInfo,
      onSelectPrimaryInfo: this.stub(),
      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortBySortableNameAscending () {},
        onSortBySortableNameDescending () {},
        settingKey: 'sortable_name'
      }
    };
  },

  teardown () {
    this.renderOutput.unmount();
  }
});

test('renders a MenuItemGroup for primary info options', function () {
  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);
  this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

  const menuItemGroup = document.querySelector('[data-menu-item-group-id="primary-info"]');

  ok(menuItemGroup);
});

test('renders a MenuItem for each primary info option', function () {
  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);
  this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

  StudentRowHeaderConstants.primaryInfoKeys.forEach((key) => {
    const menuItem = document.querySelector(`[data-menu-item-id="${key}"]`);
    ok(menuItem, `menu item ${key} is present`);
  });
});

test('invokes prop onSelectPrimaryInfo when MenuItem is clicked', function () {
  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);

  StudentRowHeaderConstants.primaryInfoKeys.forEach((key) => {
    this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');
    const menuItem = document.querySelector(`[data-menu-item-id="${key}"]`);

    menuItem.click();

    equal(this.props.onSelectPrimaryInfo.lastCall.args[0], key);
  });
});

QUnit.module('StudentColumnHeader - enrollmentFilterGroup', {
  setup () {
    this.props = {
      onToggleEnrollmentFilter: this.stub(),
      selectedEnrollmentFilters: [],
      sectionsEnabled: true,
      selectedSecondaryInfo: StudentRowHeaderConstants.defaultSecondaryInfo,
      onSelectSecondaryInfo () {},
      selectedPrimaryInfo: StudentRowHeaderConstants.defaultPrimaryInfo,
      onSelectPrimaryInfo: this.stub(),
      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortBySortableNameAscending () {},
        onSortBySortableNameDescending () {},
        settingKey: 'sortable_name'
      }
    };
  },

  teardown () {
    this.renderOutput.unmount();
  }
});

test('renders a MenuItemGroup for enrollment filter options', function () {
  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);
  this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

  const menuItemGroup = document.querySelector('[data-menu-item-group-id="enrollment-filter"]');

  ok(menuItemGroup);
});

test('renders a MenuItem for each enrollment filter option', function () {
  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);
  this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

  StudentRowHeaderConstants.enrollmentFilterKeys.forEach((key) => {
    const menuItem = document.querySelector(`[data-menu-item-id="${key}"]`);
    ok(menuItem);
  });
});

test('invokes prop onToggleEnrollmentFilter when MenuItem is clicked', function () {
  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);
  const onToggle = this.props.onToggleEnrollmentFilter;

  StudentRowHeaderConstants.enrollmentFilterKeys.forEach((key) => {
    this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');
    const menuItem = document.querySelector(`[data-menu-item-id="${key}"]`);

    menuItem.click();

    equal(onToggle.lastCall.args[0], key, `invocation arg matches clicked menu item ${key}`);
  });
});
