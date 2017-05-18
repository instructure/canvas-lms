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
    },
    gradeDisplay: {
      currentDisplay: 'points',
      onSelect () {},
      disabled: false,
      hidden: false
    },
    position: {
      isInFront: false,
      isInBack: false,
      onMoveToFront () {},
      onMoveToBack () {}
    }
  };
}

function mountAndOpenOptions (props) {
  const wrapper = mount(<TotalGradeColumnHeader {...props} />);
  wrapper.find('.Gradebook__ColumnHeaderAction').simulate('click');

  return wrapper;
}

QUnit.module('TotalGradeColumnHeader - base behavior', {
  setup () {
    this.props = createExampleProps();
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

test('renders a PopoverMenu', function () {
  const optionsMenu = this.wrapper.find('PopoverMenu');

  equal(optionsMenu.length, 1);
});

test('renders an IconMoreSolid inside the PopoverMenu', function () {
  const optionsMenuTrigger = this.wrapper.find('PopoverMenu IconMoreSolid');

  equal(optionsMenuTrigger.length, 1);
});

test('renders a title for the More icon based on the assignment name', function () {
  const optionsMenuTrigger = this.wrapper.find('PopoverMenu IconMoreSolid');

  equal(optionsMenuTrigger.props().title, 'Total Options');
});

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
  equal(menuItem.text().trim(), 'Grade - Low to High');
});

test('selects "Grade - Low to High" when sorting by grade ascending', function () {
  this.props.sortBySetting.settingKey = 'grade';
  this.props.sortBySetting.direction = 'ascending';
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');
  equal(menuItem.text().trim(), 'Grade - Low to High', '"Grade - Low to High" is selected');
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

  equal(menuItem.text().trim(), 'Grade - High to Low');
});

test('selects "Grade - High to Low" when sorting by grade descending', function () {
  this.props.sortBySetting.settingKey = 'grade';
  this.props.sortBySetting.direction = 'descending';
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');

  equal(menuItem.text().trim(), 'Grade - High to Low', '"Grade - High to Low" is selected');
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

QUnit.module('TotalGradeColumnHeader - Display as Points', {
  mountAndGetMenuItem () {
    this.wrapper = mountAndOpenOptions(this.props);
    this.menuItem = document.querySelector('[data-menu-item-id="grade-display-switcher"]');
  },

  setup () {
    this.props = createExampleProps();
    this.props.gradeDisplay.currentDisplay = 'percentage';
    this.props.gradeDisplay.onSelect = this.stub();
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
    this.props = createExampleProps();
    this.props.gradeDisplay.currentDisplay = 'points';
    this.props.gradeDisplay.onSelect = this.stub();
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
    this.props = createExampleProps();
    this.props.position.isInFront = false;
    this.props.position.onMoveToFront = this.stub();
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
    this.props = createExampleProps();
    this.props.position.isInBack = false;
    this.props.position.onMoveToBack = this.stub();
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
