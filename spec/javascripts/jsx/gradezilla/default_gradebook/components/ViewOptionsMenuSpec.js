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
import ViewOptionsMenu from 'jsx/gradezilla/default_gradebook/components/ViewOptionsMenu';

function mountAndOpenOptions (props) {
  const wrapper = mount(<ViewOptionsMenu {...props} />);
  wrapper.find('button').simulate('click');
  return wrapper;
}

QUnit.module('ViewOptionsMenu - notes', {
  setup () {
    this.props = {
      columnSortSettings: {
        criterion: 'due_date',
        direction: 'ascending',
        disabled: false,
        onSortByDefault () {},
        onSortByNameAscending () {},
        onSortByNameDescending () {},
        onSortByDueDateAscending () {},
        onSortByDueDateDescending () {},
        onSortByPointsAscending () {},
        onSortByPointsDescending () {}
      },
      showUnpublishedAssignments: false,
      onSelectShowUnpublishedAssignments: () => {},
      teacherNotes: {
        disabled: false,
        onSelect: () => {},
        selected: true
      }
    };
  },

  getMenuItemGroup () {
    return new ReactWrapper(
      [this.wrapper.node.menuContent],
      this.wrapper.node
    ).find('MenuItemGroup').at(1);
  },

  getMenuItem (index) {
    return this.getMenuItemGroup().find('MenuItem').at(index);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('teacher notes are optionally enabled', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const notesMenuItem = this.getMenuItem(0);
  strictEqual(notesMenuItem.prop('disabled'), false)
});

test('teacher notes are optionally disabled', function () {
  this.props.teacherNotes.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const notesMenuItem = this.getMenuItem(0);
  equal(notesMenuItem.prop('disabled'), true)
});

test('triggers the onSelect when the "Notes" option is clicked', function () {
  this.stub(this.props.teacherNotes, 'onSelect');
  this.wrapper = mountAndOpenOptions(this.props);
  const notesMenuItem = this.getMenuItem(0);
  notesMenuItem.simulate('click');
  equal(this.props.teacherNotes.onSelect.callCount, 1);
});

test('the "Notes" option is optionally selected', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const notesMenuItem = this.getMenuItem(0);
  equal(notesMenuItem.prop('selected'), true);
});

test('the "Notes" option is optionally deselected', function () {
  this.props.teacherNotes.selected = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const notesMenuItem = this.getMenuItem(0);
  equal(notesMenuItem.prop('selected'), false);
});

QUnit.module('ViewOptionsMenu - unpublished assignments', {
  mountViewOptionsMenu ({
    showUnpublishedAssignments = true,
    onSelectShowUnpublishedAssignments = () => {}
  } = {}) {
    return mount(
      <ViewOptionsMenu
        showUnpublishedAssignments={showUnpublishedAssignments}
        onSelectShowUnpublishedAssignments={onSelectShowUnpublishedAssignments}
        teacherNotes={{
          disabled: false,
          onSelect: () => {},
          selected: false
        }}
        columnSortSettings={{
          criterion: 'due_date',
          direction: 'ascending',
          disabled: false,
          onSortByDefault () {},
          onSortByNameAscending () {},
          onSortByNameDescending () {},
          onSortByDueDateAscending () {},
          onSortByDueDateDescending () {},
          onSortByPointsAscending () {},
          onSortByPointsDescending () {}
        }}
      />
    );
  },

  getMenuItemGroupAndMenuItem ({ groupIndex, itemIndex } = {}) {
    return new ReactWrapper([this.wrapper.node.menuContent], this.wrapper.node)
      .find('MenuItemGroup')
      .at(groupIndex)
      .find('MenuItem')
      .at(itemIndex);
  },

  teardown () {
    if (this.wrapper) {
      this.wrapper.unmount();
    }
  }
});

test('Unpublished Assignments is selected when showUnpublishedAssignments is true', function () {
  this.wrapper = this.mountViewOptionsMenu({ showUnpublishedAssignments: true });
  this.wrapper.find('button').simulate('click');
  const menuItemProps = this.getMenuItemGroupAndMenuItem({ groupIndex: 1, itemIndex: 1 }).props();
  strictEqual(menuItemProps.selected, true);
});

test('Unpublished Assignments is not selected when showUnpublishedAssignments is false', function () {
  this.wrapper = this.mountViewOptionsMenu({ showUnpublishedAssignments: false });
  this.wrapper.find('button').simulate('click');
  const menuItemProps = this.getMenuItemGroupAndMenuItem({ groupIndex: 1, itemIndex: 1 }).props();
  strictEqual(menuItemProps.selected, false);
});

test('onSelectShowUnpublishedAssignment is called when selected', function () {
  const onSelectShowUnpublishedAssignmentsStub = this.stub();
  this.wrapper = this.mountViewOptionsMenu({
    onSelectShowUnpublishedAssignments: onSelectShowUnpublishedAssignmentsStub
  });
  this.wrapper.find('button').simulate('click');
  this.getMenuItemGroupAndMenuItem({ groupIndex: 1, itemIndex: 1 }).simulate('click');
  strictEqual(onSelectShowUnpublishedAssignmentsStub.callCount, 1);
});

QUnit.module('ViewOptionsMenu - Column Sorting', {
  getProps (criterion = 'due_date', direction = 'ascending', disabled = false) {
    return {
      columnSortSettings: {
        criterion,
        direction,
        disabled,
        onSortByDefault: this.stub(),
        onSortByNameAscending: this.stub(),
        onSortByNameDescending: this.stub(),
        onSortByDueDateAscending: this.stub(),
        onSortByDueDateDescending: this.stub(),
        onSortByPointsAscending: this.stub(),
        onSortByPointsDescending: this.stub()
      },
      showUnpublishedAssignments: false,
      onSelectShowUnpublishedAssignments: () => {},
      teacherNotes: {
        disabled: false,
        onSelect: () => {},
        selected: true
      }
    };
  },

  getMenuContainer () {
    return new ReactWrapper(this.wrapper.node.menuContent, this.wrapper.node);
  },

  getMenuItemGroup (name) {
    let selectedMenuItemGroup;
    const menuContainer = this.getMenuContainer();
    const menuItemGroups = menuContainer.find('MenuItemGroup');
    const menuItemGroupCount = menuItemGroups.length;

    for (let groupIdx = 0; groupIdx < menuItemGroupCount; groupIdx++) {
      const group = menuItemGroups.at(groupIdx);

      if (group.props().label === name) {
        selectedMenuItemGroup = group;
        break;
      }
    }

    return selectedMenuItemGroup;
  },

  getMenuItem (name, menuItemContainer) {
    let selectedMenuItem;
    const container = menuItemContainer || this.getMenuContainer();
    const menuItems = container.find('MenuItem');
    const menuItemCount = menuItems.length;

    for (let menuItemIdx = 0; menuItemIdx < menuItemCount; menuItemIdx++) {
      const menuItem = menuItems.at(menuItemIdx);

      if (menuItem.text().trim() === name) {
        selectedMenuItem = menuItem;
        break;
      }
    }

    return selectedMenuItem;
  },

  getMenuItems (filterProp, filterValue, menuItemContainer) {
    const selectedMenuItems = [];
    const container = menuItemContainer || this.getMenuContainer();
    const menuItems = container.find('MenuItem');
    const menuItemCount = menuItems.length;

    for (let menuItemIdx = 0; menuItemIdx < menuItemCount; menuItemIdx++) {
      const menuItem = menuItems.at(menuItemIdx);

      if (filterProp === undefined || menuItem.props()[filterProp] === filterValue) {
        selectedMenuItems.push(menuItem);
      }
    }

    return selectedMenuItems;
  },

  teardown () {
    if (this.wrapper) {
      this.wrapper.unmount();
    }
  }
});

test('Default Order is selected when criterion is default and direction is ascending', function () {
  const props = this.getProps('default', 'ascending');

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const selectedMenuItems = this.getMenuItems('selected', true, arrangeByMenuItemGroup);

  strictEqual(selectedMenuItems.length, 1, 'only one menu item should be selected');
  strictEqual(selectedMenuItems[0].text().trim(), 'Default Order');
});

test('Default Order is selected when criterion is default and direction is descending', function () {
  const props = this.getProps('default', 'descending');

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const selectedMenuItems = this.getMenuItems('selected', true, arrangeByMenuItemGroup);

  strictEqual(selectedMenuItems.length, 1, 'only one menu item should be selected');
  strictEqual(selectedMenuItems[0].text().trim(), 'Default Order');
});

test('Assignment Name - A-Z is selected when criterion is name and direction is ascending', function () {
  const props = this.getProps('name', 'ascending');

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const selectedMenuItems = this.getMenuItems('selected', true, arrangeByMenuItemGroup);

  strictEqual(selectedMenuItems.length, 1, 'only one menu item should be selected');
  strictEqual(selectedMenuItems[0].text().trim(), 'Assignment Name - A-Z');
});

test('Assignment Name - Z-A is selected when criterion is name and direction is ascending', function () {
  const props = this.getProps('name', 'descending');

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const selectedMenuItems = this.getMenuItems('selected', true, arrangeByMenuItemGroup);

  strictEqual(selectedMenuItems.length, 1, 'only one menu item should be selected');
  strictEqual(selectedMenuItems[0].text().trim(), 'Assignment Name - Z-A');
});

test('Due Date - Oldest to Newest is selected when criterion is name and direction is ascending', function () {
  const props = this.getProps('due_date', 'ascending');

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const selectedMenuItems = this.getMenuItems('selected', true, arrangeByMenuItemGroup);

  strictEqual(selectedMenuItems.length, 1, 'only one menu item should be selected');
  strictEqual(selectedMenuItems[0].text().trim(), 'Due Date - Oldest to Newest');
});

test('Due Date - Oldest to Newest is selected when criterion is name and direction is ascending', function () {
  const props = this.getProps('due_date', 'descending');

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const selectedMenuItems = this.getMenuItems('selected', true, arrangeByMenuItemGroup);

  strictEqual(selectedMenuItems.length, 1, 'only one menu item should be selected');
  strictEqual(selectedMenuItems[0].text().trim(), 'Due Date - Newest to Oldest');
});

test('Points - Lowest to Highest is selected when criterion is name and direction is ascending', function () {
  const props = this.getProps('points', 'ascending');

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const selectedMenuItems = this.getMenuItems('selected', true, arrangeByMenuItemGroup);

  strictEqual(selectedMenuItems.length, 1, 'only one menu item should be selected');
  strictEqual(selectedMenuItems[0].text().trim(), 'Points - Lowest to Highest');
});

test('Points - Lowest to Highest is selected when criterion is name and direction is ascending', function () {
  const props = this.getProps('points', 'descending');

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const selectedMenuItems = this.getMenuItems('selected', true, arrangeByMenuItemGroup);

  strictEqual(selectedMenuItems.length, 1, 'only one menu item should be selected');
  strictEqual(selectedMenuItems[0].text().trim(), 'Points - Highest to Lowest');
});

test('all column ordering options are disabled when the column ordering settings are disabled', function () {
  const props = this.getProps();
  props.columnSortSettings.disabled = true;

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const disabledMenuItems = this.getMenuItems('disabled', true, arrangeByMenuItemGroup);

  strictEqual(disabledMenuItems.length, 7, 'all column ordering menu items are disabled');
});

test('clicking on "Default Order" triggers onSortByDefault', function () {
  const props = this.getProps();

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const specificMenuItem = this.getMenuItem('Default Order', arrangeByMenuItemGroup);

  specificMenuItem.simulate('click');

  strictEqual(props.columnSortSettings.onSortByDefault.callCount, 1);
});

test('clicking on "Assignments - A-Z" triggers onSortByNameAscending', function () {
  const props = this.getProps();

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const specificMenuItem = this.getMenuItem('Assignment Name - A-Z', arrangeByMenuItemGroup);

  specificMenuItem.simulate('click');

  strictEqual(props.columnSortSettings.onSortByNameAscending.callCount, 1);
});

test('clicking on "Assignments - Z-A" triggers onSortByNameDescending', function () {
  const props = this.getProps();

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const specificMenuItem = this.getMenuItem('Assignment Name - Z-A', arrangeByMenuItemGroup);

  specificMenuItem.simulate('click');

  strictEqual(props.columnSortSettings.onSortByNameDescending.callCount, 1);
});

test('clicking on "Due Date - Oldest to Newest" triggers onSortByDueDateAscending', function () {
  const props = this.getProps();

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const specificMenuItem = this.getMenuItem('Due Date - Oldest to Newest', arrangeByMenuItemGroup);

  specificMenuItem.simulate('click');

  strictEqual(props.columnSortSettings.onSortByDueDateAscending.callCount, 1);
});

test('clicking on "Due Date - Newest to Oldest" triggers onSortByDueDateDescending', function () {
  const props = this.getProps();

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const specificMenuItem = this.getMenuItem('Due Date - Newest to Oldest', arrangeByMenuItemGroup);

  specificMenuItem.simulate('click');

  strictEqual(props.columnSortSettings.onSortByDueDateDescending.callCount, 1);
});

test('clicking on "Points - Lowest to Highest" triggers onSortByPointsAscending', function () {
  const props = this.getProps();

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const specificMenuItem = this.getMenuItem('Points - Lowest to Highest', arrangeByMenuItemGroup);

  specificMenuItem.simulate('click');

  strictEqual(props.columnSortSettings.onSortByPointsAscending.callCount, 1);
});

test('clicking on "Points - Highest to Lowest" triggers onSortByPointsDescending', function () {
  const props = this.getProps();

  this.wrapper = mountAndOpenOptions(props);

  const arrangeByMenuItemGroup = this.getMenuItemGroup('Arrange By');
  const specificMenuItem = this.getMenuItem('Points - Highest to Lowest', arrangeByMenuItemGroup);

  specificMenuItem.simulate('click');

  strictEqual(props.columnSortSettings.onSortByPointsDescending.callCount, 1);
});

