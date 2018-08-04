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
import studentRowHeaderConstants from 'jsx/gradezilla/default_gradebook/constants/studentRowHeaderConstants';
import StudentColumnHeader from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/StudentColumnHeader'
import {
  findMenuContent,
  findFlyout,
  findFlyoutMenuContent,
  findMenuItem
} from './columnHeaderHelpers'

function mountComponent (props, mountOptions = {}) {
  return mount(<StudentColumnHeader {...props} />, mountOptions);
}

function mountAndOpenOptions (props) {
  const wrapper = mountComponent(props);
  wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');
  return wrapper;
}

function defaultProps ({ props, sortBySetting } = {}) {
  return {
    disabled: false,
    onToggleEnrollmentFilter () {},
    selectedEnrollmentFilters: [],
    sectionsEnabled: true,
    selectedSecondaryInfo: studentRowHeaderConstants.defaultSecondaryInfo,
    onSelectSecondaryInfo () {},
    selectedPrimaryInfo: studentRowHeaderConstants.defaultPrimaryInfo,
    onSelectPrimaryInfo () {},
    sortBySetting: {
      direction: 'ascending',
      disabled: false,
      isSortColumn: true,
      onSortBySortableNameAscending () {},
      onSortBySortableNameDescending () {},
      settingKey: 'sortable_name',
      ...sortBySetting
    },
    addGradebookElement () {},
    removeGradebookElement () {},
    onMenuDismiss () {},
    ...props
  };
}

QUnit.module('StudentColumnHeader', {
  setup () {
    this.props = defaultProps({
      props: {
        addGradebookElement: sinon.stub(),
        removeGradebookElement: sinon.stub(),
        onMenuDismiss: sinon.stub()
      }
    });
    this.wrapper = mountComponent(this.props);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders a title for .Gradebook__ColumnHeaderDetail', function () {
  const selectedElements = this.wrapper.find('.Gradebook__ColumnHeaderDetail');

  ok(selectedElements.text().includes('Student Name'));
});

test('renders a Menu', function () {
  const selectedElements = this.wrapper.find('Menu');

  strictEqual(selectedElements.length, 1);
});

test('renders a Menu with a trigger', function () {
  const optionsMenuTrigger = this.wrapper.find('.Gradebook__ColumnHeaderAction button');

  strictEqual(optionsMenuTrigger.length, 1);
});

test('adds a class to the action container when the Menu is opened', function () {
  const actionContainer = this.wrapper.find('.Gradebook__ColumnHeaderAction');
  actionContainer.find('button').simulate('click');
  ok(actionContainer.hasClass('menuShown'));
});

test('renders a title for the More icon', function () {
  const selectedElements = this.wrapper.find('Button ScreenReaderContent');
  equal(selectedElements.text(), 'Student Name Options');
});

test('calls addGradebookElement prop on open', function () {
  notOk(this.props.addGradebookElement.called);

  this.wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');

  ok(this.props.addGradebookElement.called);
});

test('calls removeGradebookElement prop on close', function () {
  notOk(this.props.removeGradebookElement.called);

  this.wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');
  this.wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');

  ok(this.props.removeGradebookElement.called);
});

test('calls onMenuDismiss prop on close', function () {
  this.wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');
  this.wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');

  strictEqual(this.props.onMenuDismiss.callCount, 1);
});

QUnit.module('StudentColumnHeader disabled prop', {
  setup () {
    this.mountAndOpenOptions = mountAndOpenOptions;
  }
});

test('renders flyout menus disabled when prop is true', function () {
  this.wrapper = findMenuContent.call(this, defaultProps({props: {disabled: true}}));
  const flyoutMenus = this.wrapper.find('Menu');

  flyoutMenus.forEach((flyoutMenu) => {
    ok(flyoutMenu.prop('disabled'));
  });
});

test('renders menu items disabled when prop is true', function () {
  this.wrapper = findMenuContent.call(this, defaultProps({props: {disabled: true}}));
  const menuItemGroups = this.wrapper.find('MenuItemGroup');

  menuItemGroups.forEach((menuItemGroup) => {
    const menuItems = menuItemGroup.find('MenuItem');
    menuItems.forEach((menuItem) => {
      ok(menuItem.prop('disabled'));
    })
  });
});

test('renders flyout menus enabled when prop is false', function () {
  this.wrapper = findMenuContent.call(this, defaultProps({props: {disabled: false}}));
  const flyoutMenus = this.wrapper.find('Menu');

  flyoutMenus.forEach((flyoutMenu) => {
    notOk(flyoutMenu.prop('disabled'));
  });
});

test('renders menu items enabled when prop is false', function () {
  this.wrapper = findMenuContent.call(this, defaultProps({props: {disabled: false}}));
  const menuItemGroups = this.wrapper.find('MenuItemGroup');

  menuItemGroups.forEach((menuItemGroup) => {
    const menuItems = menuItemGroup.find('MenuItem');
    menuItems.forEach((menuItem) => {
      notOk(menuItem.prop('disabled'));
    })
  });
});

QUnit.module('StudentColumnHeader: Secondary info', {
  setup () {
    this.mountAndOpenOptions = mountAndOpenOptions;
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('sort by menu group does not allow multiple selections', function () {
  const flyout = findFlyoutMenuContent.call(this, defaultProps(), 'Sort by');
  strictEqual(flyout.find('MenuItemGroup').prop('allowMultiple'), false);
});

QUnit.module('StudentColumnHeader: Secondary info > Section', {
  setup () {
    this.mountAndOpenOptions = mountAndOpenOptions;
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('includes a Section MenuItem', function () {
  const menuItem = findMenuItem.call(this, defaultProps(), 'Secondary info', 'Section');
  strictEqual(menuItem.length, 1);
});

test('calls onSelectSecondaryInfo once', function () {
  const onSelectSecondaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectSecondaryInfo } });
  const section = findMenuItem.call(this, props, 'Secondary info', 'Section');
  section.simulate('click');
  strictEqual(onSelectSecondaryInfo.callCount, 1);
});

test('calls onSelectSecondaryInfo with "section"', function () {
  const onSelectSecondaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectSecondaryInfo } });
  const section = findMenuItem.call(this, props, 'Secondary info', 'Section');
  section.simulate('click');

  ok(onSelectSecondaryInfo.calledWithExactly('section'));
});

test('omits section when sectionsEnabled prop is false', function () {
  const props = defaultProps({ props: { sectionsEnabled: false } });
  const section = findMenuItem.call(this, props, 'Secondary info', 'Section');
  notOk(section);
});

QUnit.module('StudentColumnHeader: Secondary info > SIS ID', {
  setup () {
    this.mountAndOpenOptions = mountAndOpenOptions;
    const props = defaultProps();
    this.SISIDMenuItem = findMenuItem.call(this, props, 'Secondary info', 'SIS ID');
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('includes an SIS ID MenuItem', function () {
  strictEqual(this.SISIDMenuItem.length, 1);
});

test('calls onSelectSecondaryInfo once', function () {
  const onSelectSecondaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectSecondaryInfo } });
  const SISID = findMenuItem.call(this, props, 'Secondary info', 'SIS ID');
  SISID.simulate('click');

  strictEqual(onSelectSecondaryInfo.callCount, 1);
});

test('calls onSelectSecondaryInfo with "sis id"', function () {
  const onSelectSecondaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectSecondaryInfo } });
  const SISID = findMenuItem.call(this, props, 'Secondary info', 'SIS ID');
  SISID.simulate('click');

  ok(onSelectSecondaryInfo.calledWithExactly('sis_id'));
});

QUnit.module('StudentColumnHeader: Secondary info > Login ID', {
  setup () {
    this.mountAndOpenOptions = mountAndOpenOptions;
    const props = defaultProps();
    this.loginIDMenuItem = findMenuItem.call(this, props, 'Secondary info', 'Login ID');
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('includes a Login ID MenuItem', function () {
  strictEqual(this.loginIDMenuItem.length, 1);
});

test('calls onSelectSecondaryInfo once', function () {
  const onSelectSecondaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectSecondaryInfo } });
  const loginID = findMenuItem.call(this, props, 'Secondary info', 'Login ID');
  loginID.simulate('click');

  strictEqual(onSelectSecondaryInfo.callCount, 1);
});

test('calls onSelectSecondaryInfo with "login id"', function () {
  const onSelectSecondaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectSecondaryInfo } });
  const loginID = findMenuItem.call(this, props, 'Secondary info', 'Login ID');
  loginID.simulate('click');

  ok(onSelectSecondaryInfo.calledWithExactly('login_id'));
});

QUnit.module('StudentColumnHeader: Secondary info > None', {
  setup () {
    this.mountAndOpenOptions = mountAndOpenOptions;
    const props = defaultProps();
    this.noneMenuItem = findMenuItem.call(this, props, 'Secondary info', 'None');
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('includes a None MenuItem', function () {
  strictEqual(this.noneMenuItem.length, 1);
});

test('calls onSelectSecondaryInfo once', function () {
  const onSelectSecondaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectSecondaryInfo } });
  const none = findMenuItem.call(this, props, 'Secondary info', 'None');
  none.simulate('click');

  strictEqual(onSelectSecondaryInfo.callCount, 1);
});

test('calls onSelectSecondaryInfo with "none"', function () {
  const onSelectSecondaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectSecondaryInfo } });
  const none = findMenuItem.call(this, props, 'Secondary info', 'None');
  none.simulate('click');

  ok(onSelectSecondaryInfo.calledWithExactly('none'));
});

QUnit.module('StudentColumnHeader - Sort by Settings', {
  setup () {
    this.mountAndOpenOptions = mountAndOpenOptions;
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('includes the "Sort by" group', function () {
  const flyout = findFlyout.call(this, defaultProps(), 'Sort by');
  strictEqual(flyout.prop('label'), 'Sort by');
});

test('includes "A–Z" sort setting', function () {
  const menuItem = findMenuItem.call(this, defaultProps(), 'Sort by', 'A–Z');
  strictEqual(menuItem.text().trim(), 'A–Z');
});

test('selects "A–Z" when sorting by sortable name ascending', function () {
  const menuItem = findMenuItem.call(this, defaultProps(), 'Sort by', 'A–Z');
  strictEqual(menuItem.prop('selected'), true);
});

test('does not select "A–Z" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { isSortColumn: false } });
  const menuItem = findMenuItem.call(this, props, 'Sort by', 'A–Z');
  strictEqual(menuItem.prop('selected'), false);
});

test('clicking "A–Z" calls onSortBySortableNameAscending', function () {
  const onSortBySortableNameAscending = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortBySortableNameAscending } });
  findMenuItem.call(this, props, 'Sort by', 'A–Z').simulate('click');
  strictEqual(onSortBySortableNameAscending.callCount, 1);
});

test('"A–Z" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  const menuItem = findMenuItem.call(this, props, 'Sort by', 'A–Z');
  strictEqual(menuItem.prop('disabled'), true);
});

test('includes "Z–A" sort setting', function () {
  const sortBySortableNameDescending = findMenuItem.call(this, defaultProps(), 'Sort by', 'Z–A');
  strictEqual(sortBySortableNameDescending.text().trim(), 'Z–A');
});

test('selects "Z–A" when sorting by sortable name descending', function () {
  const props = defaultProps({ sortBySetting: { direction: 'descending' } });
  const menuItem = findMenuItem.call(this, props, 'Sort by', 'Z–A');
  strictEqual(menuItem.prop('selected'), true);
});

test('does not select "Z–A" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { direction: 'descending', isSortColumn: false } });
  const menuItem = findMenuItem.call(this, props, 'Sort by', 'Z–A');
  strictEqual(menuItem.prop('selected'), false);
});

test('clicking "Z–A" calls onSortBySortableNameDescending', function () {
  const onSortBySortableNameDescending = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortBySortableNameDescending } });
  findMenuItem.call(this, props, 'Sort by', 'Z–A').simulate('click');
  strictEqual(onSortBySortableNameDescending.callCount, 1);
});

test('"Z–A" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  const menuItem = findMenuItem.call(this, props, 'Sort by', 'Z–A');
  strictEqual(menuItem.prop('disabled'), true);
});

test('uses prop loginHandleName for "login_id" menu item label', function () {
  const loginHandleName = 'custom login handle name';
  const props = defaultProps({ props: { loginHandleName } });
  const loginHandleNameMenuItem = findMenuItem.call(this, props, 'Secondary info', loginHandleName);
  strictEqual(loginHandleNameMenuItem.text().trim(), loginHandleName);
});

test('uses default label when loginHandleName prop is an empty string', function () {
  const loginHandleName = '';
  const props = defaultProps({ props: { loginHandleName } });
  const menuContent = findFlyoutMenuContent.call(this, props, 'Secondary info');
  const subMenuItems = menuContent.find('MenuItem').map(menuItem => menuItem);
  const loginIDMenuItem = subMenuItems.find(menuItem => menuItem.text().trim() === 'Login ID');
  strictEqual(loginIDMenuItem.length, 1);
});

test('uses prop sisName for "sis_id" menu item label', function () {
  const sisName = 'custom login handle name';
  const props = defaultProps({ props: { sisName } });
  const loginHandleNameMenuItem = findMenuItem.call(this, props, 'Secondary info', sisName);
  strictEqual(loginHandleNameMenuItem.text().trim(), sisName);
});

test('uses default label when sisName prop is an empty string', function () {
  const sisName = '';
  const props = defaultProps({ props: { sisName } });
  const menuContent = findFlyoutMenuContent.call(this, props, 'Secondary info');
  const subMenuItems = menuContent.find('MenuItem').map(menuItem => menuItem);
  const SISIDMenuItem = subMenuItems.find(menuItem => menuItem.text().trim() === 'SIS ID');
  strictEqual(SISIDMenuItem.length, 1);
});

QUnit.module('StudentColumnHeader - primaryInfoMenuGroup', {
  setup () {
    this.mountAndOpenOptions = mountAndOpenOptions;
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('includes a MenuItemFlyout for primary info options', function () {
  const displayAsFlyout = findFlyout.call(this, defaultProps(), 'Display as');
  ok(displayAsFlyout.length, 1);
});

test('includes "First, Last Name"', function () {
  const menuItem = findMenuItem.call(this, defaultProps(), 'Display as', 'First, Last Name');
  strictEqual(menuItem.length, 1);
});

test('includes "Last, First Name"', function () {
  const menuItem = findMenuItem.call(this, defaultProps(), 'Display as', 'Last, First Name');
  strictEqual(menuItem.length, 1);
});

test('calls onSelectPrimaryInfo when "First, Last Name" MenuItem is clicked', function () {
  const onSelectPrimaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectPrimaryInfo } });
  findMenuItem.call(this, props, 'Display as', 'First, Last Name').simulate('click');
  strictEqual(onSelectPrimaryInfo.callCount, 1);
});

test('calls onSelectPrimaryInfo with "first_last" when "First, Last Name" MenuItem is clicked', function () {
  const onSelectPrimaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectPrimaryInfo } });
  findMenuItem.call(this, props, 'Display as', 'First, Last Name').simulate('click');
  ok(onSelectPrimaryInfo.calledWithExactly('first_last'));
});

test('calls onSelectPrimaryInfo when "Last, FirstName" MenuItem is clicked', function () {
  const onSelectPrimaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectPrimaryInfo } });
  findMenuItem.call(this, props, 'Display as', 'Last, First Name').simulate('click');
  strictEqual(onSelectPrimaryInfo.callCount, 1);
});

test('calls onSelectPrimaryInfo with "last_first" when "Last, First Name" MenuItem is clicked', function () {
  const onSelectPrimaryInfo = sinon.stub();
  const props = defaultProps({ props: { onSelectPrimaryInfo } });
  findMenuItem.call(this, props, 'Display as', 'Last, First Name').simulate('click');
  ok(onSelectPrimaryInfo.calledWithExactly('last_first'));
});

QUnit.module('StudentColumnHeader - Enrollment Filters Group', {
  setup () {
    this.mountAndOpenOptions = mountAndOpenOptions;
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders a MenuItemGroup for enrollment filter options', function () {
  const menuContent = findMenuContent.call(this, defaultProps());
  const menuItemGroups = menuContent.find('MenuItemGroup').map(group => group);
  const menuItemGroup = menuItemGroups.find(group => group.prop('label') === 'Show');
  strictEqual(menuItemGroup.length, 1);
});

test('enrollment filters group allows multiple selections', function () {
  const menuContent = findMenuContent.call(this, defaultProps());
  const menuItemGroups = menuContent.find('MenuItemGroup').map(group => group);
  const menuItemGroup = menuItemGroups.find(group => group.prop('label') === 'Show');
  strictEqual(menuItemGroup.prop('allowMultiple'), true);
});

test('includes a MenuItem for "Inactive Enrollments"', function () {
  const menuContent = findMenuContent.call(this, defaultProps());
  const menuItemGroups = menuContent.find('MenuItemGroup').map(group => group);
  const menuItemGroup = menuItemGroups.find(group => group.prop('label') === 'Show');
  const menuItems = menuItemGroup.find('MenuItem').map(item => item);
  const menuItem = menuItems.find(item => item.text().trim() === 'Inactive enrollments');
  strictEqual(menuItem.length, 1);
});

test('includes a MenuItem for "Concluded Enrollments"', function () {
  const menuContent = findMenuContent.call(this, defaultProps());
  const menuItemGroups = menuContent.find('MenuItemGroup').map(group => group);
  const menuItemGroup = menuItemGroups.find(group => group.prop('label') === 'Show');
  const menuItems = menuItemGroup.find('MenuItem').map(item => item);
  const menuItem = menuItems.find(item => item.text().trim() === 'Concluded enrollments');
  strictEqual(menuItem.length, 1);
});

test('calls onToggleEnrollmentFilter when "Inactive enrollments" is clicked', function () {
  const onToggleEnrollmentFilter = sinon.stub();
  const props = defaultProps({ props: { onToggleEnrollmentFilter } });
  const menuContent = findMenuContent.call(this, props);
  const menuItemGroups = menuContent.find('MenuItemGroup').map(group => group);
  const menuItemGroup = menuItemGroups.find(group => group.prop('label') === 'Show');
  const menuItems = menuItemGroup.find('MenuItem').map(item => item);
  const menuItem = menuItems.find(item => item.text().trim() === 'Inactive enrollments');
  menuItem.simulate('click');
  strictEqual(onToggleEnrollmentFilter.callCount, 1);
});

test('calls onToggleEnrollmentFilter with "inactive" when "Inactive enrollments" is clicked', function () {
  const onToggleEnrollmentFilter = sinon.stub();
  const props = defaultProps({ props: { onToggleEnrollmentFilter } });
  const menuContent = findMenuContent.call(this, props);
  const menuItemGroups = menuContent.find('MenuItemGroup').map(group => group);
  const menuItemGroup = menuItemGroups.find(group => group.prop('label') === 'Show');
  const menuItems = menuItemGroup.find('MenuItem').map(item => item);
  const menuItem = menuItems.find(item => item.text().trim() === 'Inactive enrollments');
  menuItem.simulate('click');
  ok(onToggleEnrollmentFilter.calledWithExactly('inactive'));
});

test('calls onToggleEnrollmentFilter when "Concuded enrollments" is clicked', function () {
  const onToggleEnrollmentFilter = sinon.stub();
  const props = defaultProps({ props: { onToggleEnrollmentFilter } });
  const menuContent = findMenuContent.call(this, props);
  const menuItemGroups = menuContent.find('MenuItemGroup').map(group => group);
  const menuItemGroup = menuItemGroups.find(group => group.prop('label') === 'Show');
  const menuItems = menuItemGroup.find('MenuItem').map(item => item);
  const menuItem = menuItems.find(item => item.text().trim() === 'Concluded enrollments');
  menuItem.simulate('click');
  strictEqual(onToggleEnrollmentFilter.callCount, 1);
});

test('calls onToggleEnrollmentFilter with "concluded" when "Concluded enrollments" is clicked', function () {
  const onToggleEnrollmentFilter = sinon.stub();
  const props = defaultProps({ props: { onToggleEnrollmentFilter } });
  const menuContent = findMenuContent.call(this, props);
  const menuItemGroups = menuContent.find('MenuItemGroup').map(group => group);
  const menuItemGroup = menuItemGroups.find(group => group.prop('label') === 'Show');
  const menuItems = menuItemGroup.find('MenuItem').map(item => item);
  const menuItem = menuItems.find(item => item.text().trim() === 'Concluded enrollments');
  menuItem.simulate('click');
  ok(onToggleEnrollmentFilter.calledWithExactly('concluded'));
});

QUnit.module('StudentColumnHeader#handleKeyDown', function (hooks) {
  hooks.beforeEach(function () {
    this.wrapper = mountComponent(defaultProps(), { attachTo: document.querySelector('#fixtures') });
    this.preventDefault = sinon.spy();
  });

  hooks.afterEach(function () {
    this.wrapper.unmount();
  });

  this.handleKeyDown = function (which, shiftKey = false) {
    return this.wrapper.node.handleKeyDown({ which, shiftKey, preventDefault: this.preventDefault });
  };

  QUnit.module('with focus on options menu trigger', {
    setup () {
      this.wrapper.node.optionsMenuTrigger.focus();
    }
  });

  test('does not handle Tab', function () {
    // This allows Grid Support Navigation to handle navigation.
    const returnValue = this.handleKeyDown(9, false); // Tab
    equal(typeof returnValue, 'undefined');
  });

  test('does not handle Shift+Tab', function () {
    // This allows Grid Support Navigation to handle navigation.
    const returnValue = this.handleKeyDown(9, true); // Shift+Tab
    equal(typeof returnValue, 'undefined');
  });

  test('Enter opens the options menu', function () {
    this.handleKeyDown(13); // Enter
    const optionsMenu = this.wrapper.find('Menu');
    strictEqual(optionsMenu.node.shown, true);
  });

  test('returns false for Enter on options menu', function () {
    // This prevents additional behavior in Grid Support Navigation.
    const returnValue = this.handleKeyDown(13); // Enter
    strictEqual(returnValue, false);
  });

  QUnit.module('without focus');

  test('does not handle Tab', function () {
    const returnValue = this.handleKeyDown(9, false); // Tab
    equal(typeof returnValue, 'undefined');
  });

  test('does not handle Shift+Tab', function () {
    const returnValue = this.handleKeyDown(9, true); // Shift+Tab
    equal(typeof returnValue, 'undefined');
  });

  test('does not handle Enter', function () {
    const returnValue = this.handleKeyDown(13); // Enter
    equal(typeof returnValue, 'undefined');
  });
});

QUnit.module('StudentColumnHeader: focus', {
  setup () {
    this.wrapper = mountComponent(defaultProps(), { attachTo: document.querySelector('#fixtures') });
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('#focusAtStart sets focus on the options menu trigger', function () {
  this.wrapper.node.focusAtStart();
  equal(document.activeElement, this.wrapper.node.optionsMenuTrigger);
});

test('#focusAtEnd sets focus on the options menu trigger', function () {
  this.wrapper.node.focusAtEnd();
  equal(document.activeElement, this.wrapper.node.optionsMenuTrigger);
});

test('applies the "focused" class when the options menu has focus', function(assert) {
  const done = assert.async();
  this.wrapper.setState({ hasFocus: true }, () => {
    ok(this.wrapper.hasClass('focused'));
    done();
  });
})

test('removes the "focused" class when the header blurs', function(assert) {
  const done = assert.async()
  this.wrapper.setState({ hasFocus: true }, () => {
    this.wrapper.setState({ hasFocus: false }, () => {
      notOk(this.wrapper.hasClass('focused'));
      done();
    });
  });
})
