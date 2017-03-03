import React from 'react'
import TestUtils from 'react-addons-test-utils'
import { mount } from 'enzyme'
import StudentRowHeaderConstants from 'jsx/gradezilla/default_gradebook/constants/StudentRowHeaderConstants'
import StudentColumnHeader from 'jsx/gradezilla/default_gradebook/components/StudentColumnHeader'

QUnit.module('StudentColumnHeader - base behavior', {
  setup () {
    const props = {
      selectedSecondaryInfo: StudentRowHeaderConstants.defaultSecondaryInfo,
      sectionsEnabled: true,
      onSelectSecondaryInfo: this.stub()
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
      onSelectSecondaryInfo: this.stub()
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
