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
