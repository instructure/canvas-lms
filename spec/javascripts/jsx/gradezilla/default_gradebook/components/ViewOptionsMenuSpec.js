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

function defaultProps ({ props, filterSettings } = {}) {
  return {
    columnSortSettings: {
      criterion: 'due_date',
      direction: 'ascending',
      disabled: false,
      modulesEnabled: true,
      onSortByDefault () {},
      onSortByDueDateAscending () {},
      onSortByDueDateDescending () {},
      onSortByNameAscending () {},
      onSortByNameDescending () {},
      onSortByPointsAscending () {},
      onSortByPointsDescending () {},
      onSortByModuleAscending () {},
      onSortByModuleDescending () {}
    },
    filterSettings: {
      available: ['assignmentGroups', 'gradingPeriods', 'modules', 'sections'],
      onSelect () {},
      selected: [],
      ...filterSettings
    },
    onSelectShowStatusesModal () {},
    onSelectShowUnpublishedAssignments () {},
    showUnpublishedAssignments: false,
    teacherNotes: {
      disabled: false,
      onSelect () {},
      selected: true
    },
    ...props
  };
}

function mountAndOpenOptions (props) {
  const wrapper = mount(<ViewOptionsMenu {...props} />);
  wrapper.find('button').simulate('click');
  return wrapper;
}

function openArrangeBy (props) {
  const wrapper = mountAndOpenOptions(props);
  const menuContent = new ReactWrapper(wrapper.node.menuContent, wrapper.node);
  const flyouts = menuContent.find('Menu').map(flyout => flyout);
  const flyout = flyouts.find(menuItem => menuItem.text().trim() === 'Arrange By')
  flyout.find('button').simulate('mouseOver');
  return wrapper;
}

function openFilters (props) {
  const wrapper = mountAndOpenOptions(props);
  const menuContent = new ReactWrapper(wrapper.node.menuContent, wrapper.node);
  const flyouts = menuContent.find('Menu').map(flyout => flyout);
  const flyout = flyouts.find(menuItem => menuItem.text().trim() === 'Filters')
  flyout.find('button').simulate('mouseOver');
  return wrapper;
}


QUnit.module('ViewOptionsMenu#focus');

test('trigger is focused', function () {
  const props = defaultProps();
  const wrapper = mount(<ViewOptionsMenu {...props} />, { attachTo: document.getElementById('fixtures') });
  wrapper.instance().focus();
  equal(document.activeElement, wrapper.find('button').node);
  wrapper.unmount();
});


QUnit.module('ViewOptionsMenu - notes', {
  setup () {
    this.props = defaultProps();
  },

  getMenuItemGroup () {
    return new ReactWrapper(
      [this.wrapper.node.menuContent],
      this.wrapper.node
    ).find('MenuItemGroup').at(1);
  },

  getMenuItem () {
    const optionsMenu = new ReactWrapper(this.wrapper.node.menuContent, this.wrapper.node);
    return optionsMenu.findWhere(component => (
      component.name() === 'MenuItem' && component.text().includes('Notes')
    ));
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('teacher notes are optionally enabled', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const notesMenuItem = this.getMenuItem();
  strictEqual(notesMenuItem.prop('disabled'), false);
});

test('teacher notes are optionally disabled', function () {
  this.props.teacherNotes.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const notesMenuItem = this.getMenuItem();
  equal(notesMenuItem.prop('disabled'), true);
});

test('triggers the onSelect when the "Notes" option is clicked', function () {
  sandbox.stub(this.props.teacherNotes, 'onSelect');
  this.wrapper = mountAndOpenOptions(this.props);
  const notesMenuItem = this.getMenuItem();
  notesMenuItem.simulate('click');
  equal(this.props.teacherNotes.onSelect.callCount, 1);
});

test('the "Notes" option is optionally selected', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const notesMenuItem = this.getMenuItem();
  equal(notesMenuItem.prop('selected'), true);
});

test('the "Notes" option is optionally deselected', function () {
  this.props.teacherNotes.selected = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const notesMenuItem = this.getMenuItem();
  equal(notesMenuItem.prop('selected'), false);
});

QUnit.module('ViewOptionsMenu - Filters', {
  teardown () {
    this.wrapper.unmount();
  }
});

test('Filters menu does allows multiple selections', function () {
  this.wrapper = openFilters(defaultProps());
  const menuContent = new ReactWrapper(this.wrapper.node.filtersMenuContent, this.wrapper.node);
  const group = menuContent.find('MenuItemGroup');
  strictEqual(group.prop('allowMultiple'), true);
});

test('includes each available filter', function () {
  this.wrapper = openFilters(defaultProps());
  const menuContent = new ReactWrapper(this.wrapper.node.filtersMenuContent, this.wrapper.node);
  const group = menuContent.find('MenuItemGroup');
  strictEqual(group.find('MenuItem').length, 4);
});

test('displays filters by name', function () {
  this.wrapper = openFilters(defaultProps());
  const menuContent = new ReactWrapper(this.wrapper.node.filtersMenuContent, this.wrapper.node);
  const filters = menuContent.find('MenuItem');
  const names = filters.map(filter => filter.text());
  deepEqual(names, ['Assignment Groups', 'Grading Periods', 'Modules', 'Sections']);
});

test('includes only available filters', function () {
  const props = defaultProps({ filterSettings: { available: ['gradingPeriods', 'modules'] } });
  this.wrapper = openFilters(props);
  const menuContent = new ReactWrapper(this.wrapper.node.filtersMenuContent, this.wrapper.node);
  const filters = menuContent.find('MenuItem');
  const names = filters.map(filter => filter.text());
  deepEqual(names, ['Grading Periods', 'Modules']);
});

test('does not display filters group when no filters are available', function () {
  const props = defaultProps({ filterSettings: { available: [] } });
  this.wrapper = mountAndOpenOptions(props);
  const menuContent = new ReactWrapper(this.wrapper.node.menuContent, this.wrapper.node);
  const flyouts = menuContent.find('Menu').map(flyout => flyout);
  const flyout = flyouts.find(menuItem => menuItem.text().trim() === 'Filters')
  strictEqual(flyout, undefined);
});

test('onSelect is called when a filter is selected', function () {
  const onSelect = sinon.stub();
  const props = defaultProps({ filterSettings: { onSelect } });
  this.wrapper = openFilters(props);
  const menuContent = new ReactWrapper(this.wrapper.node.filtersMenuContent, this.wrapper.node);
  const menuItems = menuContent.find('MenuItem').map(menuItem => menuItem);
  const filter = menuItems.find(menuItem => menuItem.text().trim() === 'Grading Periods')
  filter.simulate('click');
  strictEqual(onSelect.callCount, 1);
});

test('onSelect is called with the selected filter', function () {
  const onSelect = sinon.stub();
  const props = defaultProps({ filterSettings: { onSelect } });
  this.wrapper = openFilters(props);
  const menuContent = new ReactWrapper(this.wrapper.node.filtersMenuContent, this.wrapper.node);
  const menuItems = menuContent.find('MenuItem').map(menuItem => menuItem);
  const filter = menuItems.find(menuItem => menuItem.text().trim() === 'Modules')
  filter.simulate('click');
  strictEqual(onSelect.calledWithExactly(['modules']), true);
});

test('onSelect is called with list of selected filters upon any selection change', function () {
  const onSelect = sinon.stub();
  const props = defaultProps({
    filterSettings: {
      onSelect,
      selected: ['assignmentGroups', 'sections']
    }
  });
  this.wrapper = openFilters(props);
  const menuContent = new ReactWrapper(this.wrapper.node.filtersMenuContent, this.wrapper.node);
  const menuItems = menuContent.find('MenuItem').map(menuItem => menuItem);
  const filter = menuItems.find(menuItem => menuItem.text().trim() === 'Grading Periods')
  filter.simulate('click');
  strictEqual(onSelect.calledWithExactly(['assignmentGroups', 'sections', 'gradingPeriods']), true);
});

QUnit.module('ViewOptionsMenu - unpublished assignments', {
  mountViewOptionsMenu ({
    showUnpublishedAssignments = true,
    onSelectShowUnpublishedAssignments = () => {}
  } = {}) {
    const props = defaultProps();
    return mount(
      <ViewOptionsMenu
        {...props}
        showUnpublishedAssignments={showUnpublishedAssignments}
        onSelectShowUnpublishedAssignments={onSelectShowUnpublishedAssignments}
      />
    );
  },

  getMenuItem () {
    const optionsMenu = new ReactWrapper(this.wrapper.node.menuContent, this.wrapper.node);
    return optionsMenu.findWhere(component => (
      component.name() === 'MenuItem' && component.text().includes('Unpublished Assignments')
    ));
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
  const menuItemProps = this.getMenuItem().props();
  strictEqual(menuItemProps.selected, true);
});

test('Unpublished Assignments is not selected when showUnpublishedAssignments is false', function () {
  this.wrapper = this.mountViewOptionsMenu({ showUnpublishedAssignments: false });
  this.wrapper.find('button').simulate('click');
  const menuItemProps = this.getMenuItem().props();
  strictEqual(menuItemProps.selected, false);
});

test('onSelectShowUnpublishedAssignment is called when selected', function () {
  const onSelectShowUnpublishedAssignmentsStub = sinon.stub();
  this.wrapper = this.mountViewOptionsMenu({
    onSelectShowUnpublishedAssignments: onSelectShowUnpublishedAssignmentsStub
  });
  this.wrapper.find('button').simulate('click');
  this.getMenuItem().simulate('click');
  strictEqual(onSelectShowUnpublishedAssignmentsStub.callCount, 1);
});

QUnit.module('ViewOptionsMenu - Column Sorting', {
  props (criterion = 'due_date', direction = 'ascending', disabled = false, modulesEnabled = true) {
    return {
      ...defaultProps(),
      columnSortSettings: {
        criterion,
        direction,
        disabled,
        modulesEnabled,
        onSortByDefault: sinon.stub(),
        onSortByNameAscending: sinon.stub(),
        onSortByNameDescending: sinon.stub(),
        onSortByDueDateAscending: sinon.stub(),
        onSortByDueDateDescending: sinon.stub(),
        onSortByPointsAscending: sinon.stub(),
        onSortByPointsDescending: sinon.stub(),
        onSortByModuleAscending: sinon.stub(),
        onSortByModuleDescending: sinon.stub(),
      }
    };
  },
});

test('Arrange By menu does not allow multiple selections', function () {
  const wrapper = openArrangeBy(this.props('default', 'acending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByFlyout = arrangeByMenu.find('MenuItemGroup');
  equal(arrangeByFlyout.props().allowMultiple, false);
});

test('Default Order is selected when criterion is default and direction is ascending', function () {
  const wrapper = openArrangeBy(this.props('default', 'ascending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.props().selected);

  equal(selectedMenuItem.text().trim(), 'Default Order');
});

test('Default Order is selected when criterion is default and direction is descending', function () {
  const wrapper = openArrangeBy(this.props('default', 'descending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.props().selected);

  equal(selectedMenuItem.text().trim(), 'Default Order');
});

test('Assignment Name - A-Z is selected when criterion is name and direction is ascending', function () {
  const wrapper = openArrangeBy(this.props('name', 'ascending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.props().selected);

  equal(selectedMenuItem.text().trim(), 'Assignment Name - A-Z');
});

test('Assignment Name - Z-A is selected when criterion is name and direction is ascending', function () {
  const wrapper = openArrangeBy(this.props('name', 'descending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.props().selected);

  equal(selectedMenuItem.text().trim(), 'Assignment Name - Z-A');
});

test('Due Date - Oldest to Newest is selected when criterion is due_date and direction is ascending', function () {
  const wrapper = openArrangeBy(this.props('due_date', 'ascending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.props().selected);

  equal(selectedMenuItem.text().trim(), 'Due Date - Oldest to Newest');
});

test('Due Date - Oldest to Newest is selected when criterion is due_date and direction is ascending', function () {
  const wrapper = openArrangeBy(this.props('due_date', 'descending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.props().selected);

  equal(selectedMenuItem.text().trim(), 'Due Date - Newest to Oldest');
});

test('Points - Lowest to Highest is selected when criterion is points and direction is ascending', function () {
  const wrapper = openArrangeBy(this.props('points', 'ascending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.props().selected);

  equal(selectedMenuItem.text().trim(), 'Points - Lowest to Highest');
});

test('Points - Lowest to Highest is selected when criterion is points and direction is ascending', function () {
  const wrapper = openArrangeBy(this.props('points', 'descending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.props().selected);

  equal(selectedMenuItem.text().trim(), 'Points - Highest to Lowest');
});

test('Module - First to Last is selected when criterion is module_position and direction is ascending', function () {
  const wrapper = openArrangeBy(this.props('module_position', 'ascending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.text().trim() === 'Module - First to Last');

  strictEqual(selectedMenuItem.prop('selected'), true);
});

test('Module - Last to First is selected when criterion is module_position and direction is ascending', function () {
  const wrapper = openArrangeBy(this.props('module_position', 'descending'));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.text().trim() === 'Module - Last to First');

  strictEqual(selectedMenuItem.prop('selected'), true);
});

test('Module - First to Last is not shown when modules are not enabled', function () {
  const wrapper = openArrangeBy(this.props('default', 'ascending', false, false));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.text().trim() === 'Module - First to Last');

  strictEqual(selectedMenuItem, undefined);
});

test('Module - Last to First is not shown when modules are not enabled', function () {
  const wrapper = openArrangeBy(this.props('default', 'ascending', false, false));
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const selectedMenuItem = arrangeByMenuItems.find(menuItem => menuItem.text().trim() === 'Module - Last to First');

  strictEqual(selectedMenuItem, undefined);
});

test('all column ordering options are disabled when the column ordering settings are disabled', function () {
  const props = this.props();
  props.columnSortSettings.disabled = true;
  const wrapper = openArrangeBy(props);
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const disabledMenuItems =
    arrangeByMenu.find('MenuItem').findWhere(menuItem => menuItem.props().disabled);

  strictEqual(disabledMenuItems.length, 9);
});

test('clicking on "Default Order" triggers onSortByDefault', function () {
  const props = this.props();
  const wrapper = openArrangeBy(props);
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const defaultOrderMenuItem =
    arrangeByMenuItems.find(menuItem => menuItem.props().children === 'Default Order');
  defaultOrderMenuItem.simulate('click');

  ok(props.columnSortSettings.onSortByDefault.calledOnce);
});

test('clicking on "Assignments - A-Z" triggers onSortByNameAscending', function () {
  const props = this.props();
  const wrapper = openArrangeBy(props);
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const assignmentNameAscendingMenuItem =
    arrangeByMenuItems.find(menuItem => menuItem.props().children === 'Assignment Name - A-Z');
  assignmentNameAscendingMenuItem.simulate('click');

  ok(props.columnSortSettings.onSortByNameAscending.calledOnce);
});

test('clicking on "Assignments - Z-A" triggers onSortByNameDescending', function () {
  const props = this.props();
  const wrapper = openArrangeBy(props);
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const assignmentNameDescendingMenuItem =
    arrangeByMenuItems.find(menuItem => menuItem.props().children === 'Assignment Name - Z-A');
  assignmentNameDescendingMenuItem.simulate('click');

  ok(props.columnSortSettings.onSortByNameDescending.calledOnce);
});

test('clicking on "Due Date - Oldest to Newest" triggers onSortByDueDateAscending', function () {
  const props = this.props();
  const wrapper = openArrangeBy(props);
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const dueDateOldestToNewestMenuItem =
    arrangeByMenuItems.find(menuItem => menuItem.props().children === 'Due Date - Oldest to Newest');
  dueDateOldestToNewestMenuItem.simulate('click');

  ok(props.columnSortSettings.onSortByDueDateAscending.calledOnce);
});

test('clicking on "Due Date - Newest to Oldest" triggers onSortByDueDateDescending', function () {
  const props = this.props();
  const wrapper = openArrangeBy(props);
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const dueDateNewestToOldestMenuItem =
    arrangeByMenuItems.find(menuItem => menuItem.props().children === 'Due Date - Newest to Oldest');
  dueDateNewestToOldestMenuItem.simulate('click');

  ok(props.columnSortSettings.onSortByDueDateDescending.calledOnce);
});

test('clicking on "Points - Lowest to Highest" triggers onSortByPointsAscending', function () {
  const props = this.props();
  const wrapper = openArrangeBy(props);
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const arrangeByPointsLowestToHighestMenuItem =
    arrangeByMenuItems.find(menuItem => menuItem.props().children === 'Points - Lowest to Highest');
  arrangeByPointsLowestToHighestMenuItem.simulate('click');

  ok(props.columnSortSettings.onSortByPointsAscending.calledOnce);
});

test('clicking on "Points - Highest to Lowest" triggers onSortByPointsDescending', function () {
  const props = this.props();
  const wrapper = openArrangeBy(props);
  const arrangeByMenu = new ReactWrapper(wrapper.node.arrangeByMenuContent, wrapper.node);
  const arrangeByMenuItems = arrangeByMenu.find('MenuItem').map(menuItem => menuItem);
  const arrangeByPointsHighestToLowestMenuItem =
    arrangeByMenuItems.find(menuItem => menuItem.props().children === 'Points - Highest to Lowest');
  arrangeByPointsHighestToLowestMenuItem.simulate('click');

  ok(props.columnSortSettings.onSortByPointsDescending.calledOnce);
});

QUnit.module('ViewOptionsMenu - Statuses');

test('clicking Statuses calls onSelectShowStatusesModal', function () {
  const props = {
    ...defaultProps(),
    onSelectShowStatusesModal: sinon.stub()
  };
  const wrapper = mountAndOpenOptions(props);
  const optionsMenu = new ReactWrapper(wrapper.node.menuContent, wrapper.node);
  const statusesMenuItem = optionsMenu.findWhere(component =>
    component.name() === 'MenuItem' && component.text() === 'Statuses…'
  );
  statusesMenuItem.simulate('click');
  ok(props.onSelectShowStatusesModal.calledOnce);
});
