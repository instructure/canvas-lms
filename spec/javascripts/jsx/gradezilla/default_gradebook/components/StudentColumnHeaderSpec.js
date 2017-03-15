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
import { mount } from 'enzyme'
import StudentRowHeaderConstants from 'jsx/gradezilla/default_gradebook/constants/StudentRowHeaderConstants'
import StudentColumnHeader from 'jsx/gradezilla/default_gradebook/components/StudentColumnHeader'

QUnit.module('StudentColumnHeader - base behavior', {
  setup () {
    const props = {
      selectedSecondaryInfo: StudentRowHeaderConstants.defaultSecondaryInfo,
      sectionsEnabled: true,
      onSelectSecondaryInfo: this.stub(),
      selectedPrimaryInfo: StudentRowHeaderConstants.defaultPrimaryInfo,
      onSelectPrimaryInfo: this.stub()
    };

    this.renderOutput = mount(<StudentColumnHeader {...props} />);
  },

  teardown () {
    this.renderOutput.unmount();
  }
});

test('renders a title for .Gradebook__ColumnHeaderDetail', function () {
  const selectedElements = this.renderOutput.find('.Gradebook__ColumnHeaderDetail');

  ok(selectedElements.text().includes('Student Name'));
});

test('renders a PopoverMenu', function () {
  const selectedElements = this.renderOutput.find('PopoverMenu');

  equal(selectedElements.length, 1);
});

test('renders an IconMoreSolid inside the PopoverMenu', function () {
  const selectedElements = this.renderOutput.find('PopoverMenu IconMoreSolid');

  equal(selectedElements.length, 1)
});

test('renders a title for the More icon', function () {
  const selectedElements = this.renderOutput.find('PopoverMenu IconMoreSolid');

  equal(selectedElements.props().title, 'Student Name Options');
});

QUnit.module('StudentColumnHeader - secondaryInfoMenuGroup', {
  setup () {
    this.props = {
      sectionsEnabled: true,
      selectedSecondaryInfo: StudentRowHeaderConstants.defaultSecondaryInfo,
      onSelectSecondaryInfo: this.stub(),
      selectedPrimaryInfo: StudentRowHeaderConstants.defaultPrimaryInfo,
      onSelectPrimaryInfo: this.stub()
    };
  },

  teardown () {
    this.renderOutput.unmount();
  }
});

test('renders a MenuItemGroup for secondary info options', function () {
  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);
  this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

  const menuItemGroup = document.querySelector('[data-menu-item-group-id="secondary-info"]');

  ok(menuItemGroup);
});

test('renders a MenuItem for each secondary info option', function () {
  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);
  this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

  StudentRowHeaderConstants.secondaryInfoKeys.forEach((key) => {
    const menuItem = document.querySelector(`[data-menu-item-id="${key}"]`);
    ok(menuItem);
  });
});

test('invokes prop onSelectSecondaryInfo when MenuItem is clicked', function () {
  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);

  StudentRowHeaderConstants.secondaryInfoKeys.forEach((key) => {
    this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');
    const menuItem = document.querySelector(`[data-menu-item-id="${key}"]`);

    menuItem.click();

    equal(this.props.onSelectSecondaryInfo.lastCall.args[0], key);
  });
});

test('omits section when sectionsEnabled prop is false', function () {
  this.props.sectionsEnabled = false;

  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);
  this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

  const menuItem = document.querySelector('[data-menu-item-id="section"]');

  notOk(menuItem);
});

QUnit.module('StudentColumnHeader - primaryInfoMenuGroup', {
  setup () {
    this.props = {
      sectionsEnabled: true,
      selectedSecondaryInfo: StudentRowHeaderConstants.defaultSecondaryInfo,
      onSelectSecondaryInfo: this.stub(),
      selectedPrimaryInfo: StudentRowHeaderConstants.defaultPrimaryInfo,
      onSelectPrimaryInfo: this.stub()
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

test('invokes prop onSelectSecondaryInfo when MenuItem is clicked', function () {
  this.renderOutput = mount(<StudentColumnHeader {...this.props} />);

  StudentRowHeaderConstants.primaryInfoKeys.forEach((key) => {
    this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');
    const menuItem = document.querySelector(`[data-menu-item-id="${key}"]`);

    menuItem.click();

    equal(this.props.onSelectPrimaryInfo.lastCall.args[0], key);
  });
});
