import React from 'react'
import { mount, ReactWrapper } from 'enzyme'
import ViewOptionsMenu from 'jsx/gradezilla/default_gradebook/components/ViewOptionsMenu'

function mountAndOpenOptions (props) {
  const wrapper = mount(<ViewOptionsMenu {...props} />);
  wrapper.find('button').simulate('click');
  return wrapper;
}

QUnit.module('ViewOptionsMenu', {
  setup () {
    this.props = {
      teacherNotes: {
        disabled: false,
        onSelect: () => {},
        selected: true
      }
    };
  },

  getMenuItemGroup () {
    return new ReactWrapper(
      [this.wrapper.node.optionsMenuContent],
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
  equal(notesMenuItem.prop('disabled'), false)
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
