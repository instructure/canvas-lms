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
import AssignmentGroupColumnHeader from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/AssignmentGroupColumnHeader'
import {findMenuItem, findFlyout} from './columnHeaderHelpers'

function mountComponent (props, mountOptions = {}) {
  return mount(<AssignmentGroupColumnHeader {...props} />, mountOptions);
}

function mountAndOpenOptions (props) {
  const wrapper = mountComponent(props);
  wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');
  return wrapper;
}

function defaultProps ({ props, sortBySetting, assignmentGroup } = {}) {
  return {
    assignmentGroup: {
      groupWeight: 42.5,
      name: 'Assignment Group 1',
      ...assignmentGroup
    },
    sortBySetting: {
      direction: 'ascending',
      disabled: false,
      isSortColumn: true,
      onSortByGradeAscending () {},
      onSortByGradeDescending () {},
      settingKey: 'grade',
      ...sortBySetting
    },
    weightedGroups: true,
    addGradebookElement () {},
    removeGradebookElement () {},
    onMenuDismiss () {},
    ...props
  };
}

QUnit.module('AssignmentGroupColumnHeader - base behavior', {
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

test('renders the assignment group name', function () {
  const assignmentGroupName = this.wrapper.find('.Gradebook__ColumnHeaderDetail').childAt(0);
  equal(assignmentGroupName.text().trim(), 'Assignment Group 1');
});

test('renders the assignment groupWeight percentage', function () {
  const groupWeight = this.wrapper.find('.Gradebook__ColumnHeaderDetail').childAt(1);
  equal(groupWeight.text().trim(), '42.5% of grade');
});

test('renders a Menu with a trigger', function () {
  const optionsMenuTrigger = this.wrapper.find('.Gradebook__ColumnHeaderAction button');
  equal(optionsMenuTrigger.length, 1);
});

test('adds a class to the action container when the Menu is opened', function () {
  const actionContainer = this.wrapper.find('.Gradebook__ColumnHeaderAction');
  actionContainer.find('button').simulate('click');
  ok(actionContainer.hasClass('menuShown'));
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

QUnit.module('AssignmentGroupColumnHeader - non-standard assignment group');

test('renders 0% as the groupWeight percentage when weightedGroups is true but groupWeight is 0', function () {
  const props = defaultProps({ assignmentGroup: { groupWeight: 0 } });
  const wrapper = mount(<AssignmentGroupColumnHeader {...props} />);
  const groupWeight = wrapper.find('.Gradebook__ColumnHeaderDetail').childAt(1);
  equal(groupWeight.text().trim(), '0% of grade');
});

test('does not render the groupWeight percentage when weightedGroups is false', function () {
  const props = defaultProps({ props: { weightedGroups: false } });
  const wrapper = mount(<AssignmentGroupColumnHeader {...props} />);
  const headerDetails = wrapper.find('.Gradebook__ColumnHeaderDetail');
  equal(headerDetails.text().trim(), 'Assignment Group 1');
});

QUnit.module('AssignmentGroupColumnHeader - Sort by Settings', {
  setup () {
    this.mountAndOpenOptions = mountAndOpenOptions;
  },
  teardown () {
    this.wrapper.unmount();
  }
});

test('includes the "Sort by" group', function () {
  const sortByFlyout = findFlyout.call(this, defaultProps(), 'Sort by');
  strictEqual(sortByFlyout.prop('label'), 'Sort by');
});

test('includes "Grade - Low to High" sort setting', function () {
  const sortByGradeAscendingMenuItem = findMenuItem.call(this, defaultProps(), 'Sort by', 'Grade - Low to High');
  strictEqual(sortByGradeAscendingMenuItem.length, 1);
});

test('selects "Grade - Low to High" when sorting by grade ascending', function () {
  const sortByGradeAscendingMenuItem = findMenuItem.call(this, defaultProps(), 'Sort by', 'Grade - Low to High');
  strictEqual(sortByGradeAscendingMenuItem.prop('selected'), true);
});

test('does not select "Grade - Low to High" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { isSortColumn: false } });
  const sortByGradeAscendingMenuItem = findMenuItem.call(this, props, 'Sort by', 'Grade - Low to High');
  strictEqual(sortByGradeAscendingMenuItem.prop('selected'), false);
});

test('clicking "Grade - Low to High" calls onSortByGradeAscending', function () {
  const onSortByGradeAscending = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByGradeAscending } });
  findMenuItem.call(this, props, 'Sort by', 'Grade - Low to High').simulate('click');
  strictEqual(onSortByGradeAscending.callCount, 1);
});

test('"Grade - Low to High" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  const onSortByGradeAscendingMenuItem = findMenuItem.call(this, props, 'Sort by', 'Grade - Low to High');
  equal(onSortByGradeAscendingMenuItem.prop('disabled'), true);
});

test('includes "Grade - High to Low" sort setting', function () {
  const sortByGradeDescendingMenuItem = findMenuItem.call(this, defaultProps(), 'Sort by', 'Grade - High to Low');
  strictEqual(sortByGradeDescendingMenuItem.length, 1);
});

test('selects "Grade - High to Low" when sorting by grade descending', function () {
  const props = defaultProps({ sortBySetting: { direction: 'descending' } });
  const sortByGradeDescendingMenuItem = findMenuItem.call(this, props, 'Sort by', 'Grade - High to Low');
  strictEqual(sortByGradeDescendingMenuItem.prop('selected'), true);
});

test('does not select "Grade - High to Low" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { direction: 'descending', isSortColumn: false } });
  const sortByGradeDescendingMenuItem = findMenuItem.call(this, props, 'Sort by', 'Grade - High to Low');
  strictEqual(sortByGradeDescendingMenuItem.prop('selected'), false);
});

test('clicking "Grade - High to Low" calls onSortByGradeDescending', function () {
  const onSortByGradeDescending = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByGradeDescending } });
  findMenuItem.call(this, props, 'Sort by', 'Grade - High to Low').simulate('click');
  strictEqual(onSortByGradeDescending.callCount, 1);
});

test('"Grade - High to Low" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  const onSortByGradeDescendingMenuItem = findMenuItem.call(this, props, 'Sort by', 'Grade - High to Low');
  equal(onSortByGradeDescendingMenuItem.prop('disabled'), true);
});

QUnit.module('AssignmentGroupColumnHeader#handleKeyDown', function (hooks) {
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

QUnit.module('AssignmentGroupColumnHeader: focus', {
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
