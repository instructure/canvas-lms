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
import { mount } from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme';
import TotalGradeColumnHeader from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/TotalGradeColumnHeader'
import {findFlyout, findMenuItem} from './columnHeaderHelpers'

function mountComponent (props, mountOptions = {}) {
  return mount(<TotalGradeColumnHeader {...props} />, mountOptions);
}

function mountAndOpenOptions (props) {
  const wrapper = mount(<TotalGradeColumnHeader {...props} />);
  wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');
  return wrapper;
}

function defaultProps ({ props, sortBySetting, gradeDisplay, position } = {}) {
  return {
    sortBySetting: {
      direction: 'ascending',
      disabled: false,
      isSortColumn: true,
      onSortByGradeAscending () {},
      onSortByGradeDescending () {},
      settingKey: 'grade',
      ...sortBySetting
    },
    gradeDisplay: {
      currentDisplay: 'points',
      onSelect () {},
      disabled: false,
      hidden: false,
      ...gradeDisplay
    },
    position: {
      isInFront: false,
      isInBack: false,
      onMoveToFront () {},
      onMoveToBack () {},
      ...position
    },
    addGradebookElement () {},
    removeGradebookElement () {},
    onMenuDismiss () {},
    ...props
  };
}

QUnit.module('TotalGradeColumnHeader - base behavior', {
  setup () {
    this.props = defaultProps({
      props: {
        addGradebookElement: sinon.stub(),
        removeGradebookElement: sinon.stub(),
        onMenuDismiss: sinon.stub()
      }
    });
    this.wrapper = mount(<TotalGradeColumnHeader {...this.props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders the label Total', function () {
  const label = this.wrapper.find('.Gradebook__ColumnHeaderDetail');

  equal(label.text().trim(), 'Total');
});

test('renders a Menu', function () {
  const optionsMenu = this.wrapper.find('Menu');

  equal(optionsMenu.length, 1);
});

test('renders a Menu with a trigger', function () {
  const optionsMenuTrigger = this.wrapper.find('Menu button');

  equal(optionsMenuTrigger.length, 1);
});

test('adds a class to the action container when the Menu is opened', function () {
  const actionContainer = this.wrapper.find('.Gradebook__ColumnHeaderAction');
  actionContainer.find('button').simulate('click');
  ok(actionContainer.hasClass('menuShown'));
});

test('renders a title that says "Total Options"', function () {
  const optionsMenuTrigger = this.wrapper.find('Button ScreenReaderContent');
  equal(optionsMenuTrigger.text(), 'Total Options');
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

QUnit.module('TotalGradeColumnHeader - Sort by Settings', {
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
  const menuItem = findMenuItem.call(this, defaultProps(), 'Sort by', 'Grade - Low to High');
  strictEqual(menuItem.text().trim(), 'Grade - Low to High');
});

test('selects "Grade - Low to High" when sorting by grade ascending', function () {
  const menuItem = findMenuItem.call(this, defaultProps(), 'Sort by', 'Grade - Low to High');
  strictEqual(menuItem.prop('selected'), true);
});

test('does not select "Grade - Low to High" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { isSortColumn: false } });
  const menuItem = findMenuItem.call(this, props, 'Sort by', 'Grade - Low to High');
  strictEqual(menuItem.prop('selected'), false);
});

test('clicking "Grade - Low to High" calls onSortByGradeAscending', function () {
  const onSortByGradeAscending = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByGradeAscending } });
  findMenuItem.call(this, props, 'Sort by', 'Grade - Low to High').simulate('click');
  strictEqual(onSortByGradeAscending.callCount, 1);
});

test('"Grade - Low to High" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  const menuItem = findMenuItem.call(this, props, 'Sort by', 'Grade - Low to High');
  strictEqual(menuItem.prop('disabled'), true);
});

test('includes "Grade - High to Low" sort setting', function () {
  const menuItem = findMenuItem.call(this, defaultProps(), 'Sort by', 'Grade - High to Low');
  strictEqual(menuItem.text().trim(), 'Grade - High to Low');
});

test('selects "Grade - High to Low" when sorting by grade descending', function () {
  const props = defaultProps({ sortBySetting: { direction: 'descending' } });
  const menuItem = findMenuItem.call(this, props, 'Sort by', 'Grade - High to Low');
  strictEqual(menuItem.prop('selected'), true);
});

test('does not select "Grade - High to Low" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { direction: 'descending', isSortColumn: false } });
  const menuItem = findMenuItem.call(this, props, 'Sort by', 'Grade - High to Low');
  strictEqual(menuItem.prop('selected'), false);
});

test('clicking "Grade - High to Low" calls onSortByGradeDescending', function () {
  const onSortByGradeDescending = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByGradeDescending } });
  findMenuItem.call(this, props, 'Sort by', 'Grade - High to Low').simulate('click');
  strictEqual(onSortByGradeDescending.callCount, 1);
});

test('"Grade - High to Low" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  const menuItem = findMenuItem.call(this, props, 'Sort by', 'Grade - High to Low');
  strictEqual(menuItem.prop('disabled'), true);
});

QUnit.module('TotalGradeColumnHeader - Display as Points', {
  mountAndGetMenuItem () {
    this.wrapper = mountAndOpenOptions(this.props);
    this.menuItem = document.querySelector('[data-menu-item-id="grade-display-switcher"]');
  },

  setup () {
    this.props = defaultProps();
    this.props.gradeDisplay.currentDisplay = 'percentage';
    this.props.gradeDisplay.onSelect = sinon.stub();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('the grade display switcher option does not show when hidden is true', function () {
  this.props.gradeDisplay.hidden = true;
  this.mountAndGetMenuItem();

  notOk(this.menuItem);
});

test('the grade display switcher option is disabled when disabled is true', function () {
  this.props.gradeDisplay.disabled = true;
  this.mountAndGetMenuItem();
  this.menuItem.click();

  equal(this.props.gradeDisplay.onSelect.callCount, 0);
});

test('the grade display switcher option reads "Display as Points"', function () {
  this.mountAndGetMenuItem();

  equal(this.menuItem.textContent, 'Display as Points');
});

test('clicking the "Display as Points" option calls the gradeDisplay onSelect callback', function () {
  this.mountAndGetMenuItem();
  this.menuItem.click();

  equal(this.props.gradeDisplay.onSelect.callCount, 1);
});

QUnit.module('TotalGradeColumnHeader - Display as Percentage', {
  mountAndGetMenuItem () {
    this.wrapper = mountAndOpenOptions(this.props);
    this.menuItem = document.querySelector('[data-menu-item-id="grade-display-switcher"]');
  },

  setup () {
    this.props = defaultProps();
    this.props.gradeDisplay.currentDisplay = 'points';
    this.props.gradeDisplay.onSelect = sinon.stub();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('the grade display switcher option does not show when hidden is true', function () {
  this.props.gradeDisplay.hidden = true;
  this.mountAndGetMenuItem();

  notOk(this.menuItem);
});

test('the grade display switcher option is disabled when disabled is true', function () {
  this.props.gradeDisplay.disabled = true;
  this.mountAndGetMenuItem();
  this.menuItem.click();

  equal(this.props.gradeDisplay.onSelect.callCount, 0);
});

test('the grade display switcher option reads "Display as Percentage"', function () {
  this.mountAndGetMenuItem();

  equal(this.menuItem.textContent, 'Display as Percentage');
});

test('clicking the "Display as Percentage" option calls the gradeDisplay onSelect callback', function () {
  this.mountAndGetMenuItem();
  this.menuItem.click();

  equal(this.props.gradeDisplay.onSelect.callCount, 1);
});

QUnit.module('TotalGradeColumnHeader - Move to Front', {
  setup () {
    this.props = defaultProps();
    this.props.position.isInFront = false;
    this.props.position.onMoveToFront = sinon.stub();
  },

  getMenuItem () {
    return document.querySelector('[data-menu-item-id="total-grade-move-to-front"]');
  }
});

test('the "Move to Front" option does not appear when isInFront is true', function () {
  this.props.position.isInFront = true;
  const wrapper = mountAndOpenOptions(this.props);

  notOk(this.getMenuItem());

  wrapper.unmount();
});

test('the "Move to Front" option shows up when ths isInFront property is false', function () {
  const wrapper = mountAndOpenOptions(this.props);

  ok(this.getMenuItem());

  wrapper.unmount();
});

test('the "Move to Front" option reads "Move to Front"', function () {
  const wrapper = mountAndOpenOptions(this.props);

  strictEqual(this.getMenuItem().textContent, 'Move to Front');

  wrapper.unmount();
});

test('clicking the "Move to Front" option calls the onMoveToFront callback', function () {
  const wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem().click();

  strictEqual(this.props.position.onMoveToFront.callCount, 1);

  wrapper.unmount();
});

QUnit.module('TotalGradeColumnHeader - Move to Back', {
  setup () {
    this.props = defaultProps();
    this.props.position.isInBack = false;
    this.props.position.onMoveToBack = sinon.stub();
  },

  getMenuItem () {
    return document.querySelector('[data-menu-item-id="total-grade-move-to-back"]');
  }
});

test('the "Move to Back" option does not appear when isInBack is true', function () {
  this.props.position.isInBack = true;
  const wrapper = mountAndOpenOptions(this.props);

  notOk(this.getMenuItem());

  wrapper.unmount();
});

test('the "Move to Back" option shows up when ths isInBack property is false', function () {
  const wrapper = mountAndOpenOptions(this.props);

  ok(this.getMenuItem());

  wrapper.unmount();
});

test('the "Move to Back" option reads "Move to End"', function () {
  const wrapper = mountAndOpenOptions(this.props);

  strictEqual(this.getMenuItem().textContent, 'Move to End');

  wrapper.unmount();
});

test('clicking the "Move to Back" option calls the onMoveToBack callback', function () {
  const wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem().click();

  strictEqual(this.props.position.onMoveToBack.callCount, 1);

  wrapper.unmount();
});

QUnit.module('TotalGradeColumnHeader#handleKeyDown', function (hooks) {
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

QUnit.module('TotalGradeColumnHeader: focus', {
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
