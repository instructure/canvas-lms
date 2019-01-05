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
    finalGradeOverrideEnabled: false,
    teacherNotes: {
      disabled: false,
      onSelect () {},
      selected: true
    },
    overrides: {
      disabled: false,
      label: 'Overrides',
      onSelect () {},
      selected: false
    },
    ...props
  };
}

function mouseover($el) {
  const event = new MouseEvent('mouseover', {
    bubbles: true,
    cancelable: true,
    view: window
  })
  $el.dispatchEvent(event)
}

function getMenuItemWithLabel($parent, label) {
  const $children = [...$parent.querySelectorAll('[role^="menuitem"]')]
  return $children.find($child => $child.textContent.trim() === label)
}

function getFlyoutWithLabel($parent, label) {
  const $children = [...$parent.querySelectorAll('[role="button"]')]
  return $children.find($child => $child.textContent.trim() === label)
}

function getSubmenu($menuItem) {
  return document.querySelector(`[aria-labelledby="${$menuItem.id}"]`)
}

function getMenuItem($menu, ...path) {
  return path.reduce(($el, label, index) => {
    if (index < path.length - 1) {
      const $next = getFlyoutWithLabel($el, label)
      mouseover($next)
      return getSubmenu($next)
    }

    return getMenuItemWithLabel($el, label) || getFlyoutWithLabel($el, label)
  }, $menu)
}

function mountAndOpenOptions (props) {
  const wrapper = mount(<ViewOptionsMenu {...props} />);
  wrapper.find('button').simulate('click');
  return wrapper;
}

QUnit.module('ViewOptionsMenu#focus');

test('trigger is focused', function () {
  const props = defaultProps();
  const wrapper = mount(<ViewOptionsMenu {...props} />, { attachTo: document.getElementById('fixtures') });
  wrapper.instance().focus();
  equal(document.activeElement, wrapper.find('button').instance());
  wrapper.unmount();
});


QUnit.module('ViewOptionsMenu - notes', {
  setup () {
    this.props = defaultProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('teacher notes are optionally enabled', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = getMenuItem(this.wrapper.instance().menuContent, 'Notes');
  strictEqual(menuItem.getAttribute('aria-disabled'), null);
});

test('teacher notes are optionally disabled', function () {
  this.props.teacherNotes.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = getMenuItem(this.wrapper.instance().menuContent, 'Notes');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('triggers the onSelect when the "Notes" option is clicked', function () {
  sandbox.stub(this.props.teacherNotes, 'onSelect');
  this.wrapper = mountAndOpenOptions(this.props);
  getMenuItem(this.wrapper.instance().menuContent, 'Notes').click();
  equal(this.props.teacherNotes.onSelect.callCount, 1);
});

test('the "Notes" option is optionally selected', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = getMenuItem(this.wrapper.instance().menuContent, 'Notes');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('the "Notes" option is optionally deselected', function () {
  this.props.teacherNotes.selected = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = getMenuItem(this.wrapper.instance().menuContent, 'Notes');
  strictEqual(menuItem.getAttribute('aria-checked'), 'false');
});

QUnit.module('ViewOptionsMenu - Overrides', (moduleHooks) => {
  let props = {}
  let wrapper

  moduleHooks.beforeEach(() => { props = defaultProps() })

  moduleHooks.afterEach(() => wrapper.unmount())

  test('is hidden by default', () => {
    wrapper = mountAndOpenOptions(props)
    const menuItem = getMenuItem(wrapper.instance().menuContent, 'Overrides')
    strictEqual(menuItem, undefined)
  })

  QUnit.module('when "Final Grade Override" is enabled', hooks => {
    hooks.beforeEach(() => {
      props = {
        ...defaultProps(),
        finalGradeOverrideEnabled: true
      }
    })

    test('is not disabled', () => {
      wrapper = mountAndOpenOptions(props)
      const menuItem = getMenuItem(wrapper.instance().menuContent, 'Overrides')
      strictEqual(menuItem.getAttribute('aria-disabled'), null)
    })

    test('can be optionally disabled', () => {
      props.overrides.disabled = true
      wrapper = mountAndOpenOptions(props)
      const menuItem = getMenuItem(wrapper.instance().menuContent, 'Overrides')
      strictEqual(menuItem.getAttribute('aria-disabled'), props.overrides.disabled.toString())
    })

    test('triggers the onSelect when the "Overrides" option is clicked', () => {
      sandbox.stub(props.overrides, 'onSelect')
      wrapper = mountAndOpenOptions(props)
      getMenuItem(wrapper.instance().menuContent, 'Overrides').click()
      equal(props.overrides.onSelect.callCount, 1)
    })

    test('is optionally not selected', () => {
      wrapper = mountAndOpenOptions(props)
      const menuItem = getMenuItem(wrapper.instance().menuContent, 'Overrides')
      strictEqual(menuItem.getAttribute('aria-checked'), props.overrides.selected.toString())
    })

    test('is optionally selected', () => {
      props.overrides.selected = true
      wrapper = mountAndOpenOptions(props)
      const menuItem = getMenuItem(wrapper.instance().menuContent, 'Overrides')
      strictEqual(menuItem.getAttribute('aria-checked'), props.overrides.selected.toString())
    })

    test('can be given a different label', () => {
      const someLabel = 'Grading Periods Label'
      props.overrides.label = someLabel
      wrapper = mountAndOpenOptions(props)
      const menuItem = getMenuItem(wrapper.instance().menuContent, someLabel)
      strictEqual(menuItem.textContent, someLabel)
    })
  })
})

QUnit.module('ViewOptionsMenu - Filters', {
  teardown () {
    this.wrapper.unmount();
  }
});

test('includes each available filter', function () {
  this.wrapper = mountAndOpenOptions(defaultProps());
  ['Assignment Groups', 'Grading Periods', 'Modules', 'Sections'].forEach(label => {
    ok(getMenuItem(this.wrapper.instance().menuContent, 'Filters', label), `'${label}' is present`)
  })
});

test('includes only available filters', function () {
  const props = defaultProps({ filterSettings: { available: ['gradingPeriods', 'modules'] } });
  this.wrapper = mountAndOpenOptions(props);
  ['Assignment Groups', 'Sections'].forEach(label => {
    notOk(getMenuItem(this.wrapper.instance().menuContent, 'Filters', label), `'${label}' is not present`)
  })
});

test('does not display filters group when no filters are available', function () {
  const props = defaultProps({ filterSettings: { available: [] } });
  this.wrapper = mountAndOpenOptions(props);
  notOk(getMenuItem(this.wrapper.instance().menuContent, 'Filters'))
});

test('onSelect is called when a filter is selected', function () {
  const onSelect = sinon.stub();
  const props = defaultProps({ filterSettings: { onSelect } });
  this.wrapper = mountAndOpenOptions(props);
  getMenuItem(this.wrapper.instance().menuContent, 'Filters', 'Grading Periods').click()
  strictEqual(onSelect.callCount, 1);
});

test('onSelect is called with the selected filter', function () {
  const onSelect = sinon.stub();
  const props = defaultProps({ filterSettings: { onSelect } });
  this.wrapper = mountAndOpenOptions(props);
  getMenuItem(this.wrapper.instance().menuContent, 'Filters', 'Modules').click()
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
  this.wrapper = mountAndOpenOptions(props);
  getMenuItem(this.wrapper.instance().menuContent, 'Filters', 'Grading Periods').click()
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

  teardown () {
    if (this.wrapper) {
      this.wrapper.unmount();
    }
  }
});

test('Unpublished Assignments is selected when showUnpublishedAssignments is true', function () {
  this.wrapper = this.mountViewOptionsMenu({ showUnpublishedAssignments: true });
  this.wrapper.find('button').simulate('click');
  const menuItem = getMenuItem(this.wrapper.instance().menuContent, 'Unpublished Assignments');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Unpublished Assignments is not selected when showUnpublishedAssignments is false', function () {
  this.wrapper = this.mountViewOptionsMenu({ showUnpublishedAssignments: false });
  this.wrapper.find('button').simulate('click');
  const menuItem = getMenuItem(this.wrapper.instance().menuContent, 'Unpublished Assignments');
  strictEqual(menuItem.getAttribute('aria-checked'), 'false');
});

test('onSelectShowUnpublishedAssignment is called when selected', function () {
  const onSelectShowUnpublishedAssignmentsStub = sinon.stub();
  this.wrapper = this.mountViewOptionsMenu({
    onSelectShowUnpublishedAssignments: onSelectShowUnpublishedAssignmentsStub
  });
  this.wrapper.find('button').simulate('click');
  getMenuItem(this.wrapper.instance().menuContent, 'Unpublished Assignments').click();
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

test('Default Order is selected when criterion is default and direction is ascending', function () {
  const wrapper = mountAndOpenOptions(this.props('default', 'ascending'));
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Default Order');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Default Order is selected when criterion is default and direction is descending', function () {
  const wrapper = mountAndOpenOptions(this.props('default', 'descending'));
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Default Order');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Assignment Name - A-Z is selected when criterion is name and direction is ascending', function () {
  const wrapper = mountAndOpenOptions(this.props('name', 'ascending'));
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Assignment Name - A-Z');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Assignment Name - Z-A is selected when criterion is name and direction is ascending', function () {
  const wrapper = mountAndOpenOptions(this.props('name', 'descending'));
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Assignment Name - Z-A');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Due Date - Oldest to Newest is selected when criterion is due_date and direction is ascending', function () {
  const wrapper = mountAndOpenOptions(this.props('due_date', 'ascending'));
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Due Date - Oldest to Newest');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Due Date - Oldest to Newest is selected when criterion is due_date and direction is ascending', function () {
  const wrapper = mountAndOpenOptions(this.props('due_date', 'descending'));
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Due Date - Newest to Oldest');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Points - Lowest to Highest is selected when criterion is points and direction is ascending', function () {
  const wrapper = mountAndOpenOptions(this.props('points', 'ascending'));
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Points - Lowest to Highest');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Points - Lowest to Highest is selected when criterion is points and direction is ascending', function () {
  const wrapper = mountAndOpenOptions(this.props('points', 'descending'));
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Points - Highest to Lowest');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Module - First to Last is selected when criterion is module_position and direction is ascending', function () {
  const wrapper = mountAndOpenOptions(this.props('module_position', 'ascending'));
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Module - First to Last');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Module - Last to First is selected when criterion is module_position and direction is ascending', function () {
  const wrapper = mountAndOpenOptions(this.props('module_position', 'descending'));
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Module - Last to First');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('Module - First to Last is not shown when modules are not enabled', function () {
  const wrapper = mountAndOpenOptions(this.props('default', 'ascending', false, false));
  notOk(getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Module - First to Last'));
});

test('Module - Last to First is not shown when modules are not enabled', function () {
  const wrapper = mountAndOpenOptions(this.props('default', 'ascending', false, false));
  notOk(getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Module - Last to First'));
});

test('Default Order is disabled when column ordering settings are disabled', function () {
  const props = this.props();
  props.columnSortSettings.disabled = true;
  const wrapper = mountAndOpenOptions(props);
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Default Order');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('Assignment Name - A-Z is disabled when column ordering settings are disabled', function () {
  const props = this.props();
  props.columnSortSettings.disabled = true;
  const wrapper = mountAndOpenOptions(props);
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Assignment Name - A-Z');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('Assignment Name - Z-A is disabled when column ordering settings are disabled', function () {
  const props = this.props();
  props.columnSortSettings.disabled = true;
  const wrapper = mountAndOpenOptions(props);
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Assignment Name - Z-A');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('Due Date - Oldest to Newest is disabled when column ordering settings are disabled', function () {
  const props = this.props();
  props.columnSortSettings.disabled = true;
  const wrapper = mountAndOpenOptions(props);
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Due Date - Oldest to Newest');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('Due Date - Newest to Oldest is disabled when column ordering settings are disabled', function () {
  const props = this.props();
  props.columnSortSettings.disabled = true;
  const wrapper = mountAndOpenOptions(props);
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Due Date - Newest to Oldest');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('Points - Lowest to Highest is disabled when column ordering settings are disabled', function () {
  const props = this.props();
  props.columnSortSettings.disabled = true;
  const wrapper = mountAndOpenOptions(props);
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Points - Lowest to Highest');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('Points - Highest to Lowest is disabled when column ordering settings are disabled', function () {
  const props = this.props();
  props.columnSortSettings.disabled = true;
  const wrapper = mountAndOpenOptions(props);
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Points - Highest to Lowest');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('Module - First to Last is disabled when column ordering settings are disabled', function () {
  const props = this.props();
  props.columnSortSettings.disabled = true;
  const wrapper = mountAndOpenOptions(props);
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Module - First to Last');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('Module - Last to First is disabled when column ordering settings are disabled', function () {
  const props = this.props();
  props.columnSortSettings.disabled = true;
  const wrapper = mountAndOpenOptions(props);
  const menuItem = getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Module - Last to First');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('clicking on "Default Order" triggers onSortByDefault', function () {
  const props = this.props();
  const wrapper = mountAndOpenOptions(props);
  getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Default Order').click();
  ok(props.columnSortSettings.onSortByDefault.calledOnce);
});

test('clicking on "Assignments - A-Z" triggers onSortByNameAscending', function () {
  const props = this.props();
  const wrapper = mountAndOpenOptions(props);
  getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Assignment Name - A-Z').click();
  ok(props.columnSortSettings.onSortByNameAscending.calledOnce);
});

test('clicking on "Assignments - Z-A" triggers onSortByNameDescending', function () {
  const props = this.props();
  const wrapper = mountAndOpenOptions(props);
  getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Assignment Name - Z-A').click();
  ok(props.columnSortSettings.onSortByNameDescending.calledOnce);
});

test('clicking on "Due Date - Oldest to Newest" triggers onSortByDueDateAscending', function () {
  const props = this.props();
  const wrapper = mountAndOpenOptions(props);
  getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Due Date - Oldest to Newest').click();
  ok(props.columnSortSettings.onSortByDueDateAscending.calledOnce);
});

test('clicking on "Due Date - Newest to Oldest" triggers onSortByDueDateDescending', function () {
  const props = this.props();
  const wrapper = mountAndOpenOptions(props);
  getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Due Date - Newest to Oldest').click();
  ok(props.columnSortSettings.onSortByDueDateDescending.calledOnce);
});

test('clicking on "Points - Lowest to Highest" triggers onSortByPointsAscending', function () {
  const props = this.props();
  const wrapper = mountAndOpenOptions(props);
  getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Points - Lowest to Highest').click();
  ok(props.columnSortSettings.onSortByPointsAscending.calledOnce);
});

test('clicking on "Points - Highest to Lowest" triggers onSortByPointsDescending', function () {
  const props = this.props();
  const wrapper = mountAndOpenOptions(props);
  getMenuItem(wrapper.instance().menuContent, 'Arrange By', 'Points - Highest to Lowest').click();
  ok(props.columnSortSettings.onSortByPointsDescending.calledOnce);
});

QUnit.module('ViewOptionsMenu - Statuses');

test('clicking Statuses calls onSelectShowStatusesModal', function () {
  const props = {
    ...defaultProps(),
    onSelectShowStatusesModal: sinon.stub()
  };
  const wrapper = mountAndOpenOptions(props);
  getMenuItem(wrapper.instance().menuContent, 'Statuses…').click();
  ok(props.onSelectShowStatusesModal.calledOnce);
});
