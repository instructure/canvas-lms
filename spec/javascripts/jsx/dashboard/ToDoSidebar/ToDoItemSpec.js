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

import ToDoItem from 'jsx/dashboard/ToDoSidebar/ToDoItem';
import React from 'react';
import { shallow, mount } from 'enzyme';

QUnit.module('ToDoItem');

const getDefaultProps = overrides => ({
  handleDismissClick () {},
  itemId: '123',
  itemType: '',
  title: 'Introduction to Board Games',
  courseId: null,
  dueAt: '2017-07-15T20:00:00-0600',
  courses: [{
    id: '1',
    shortName: 'BGG 101'
  }, {
    id: '2',
    shortName: 'BGG 201'
  }],
  ...overrides
});

test('renders assignment icon for assignments', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ itemType: 'assignment' })} />
  );
  ok(wrapper.find('IconAssignmentLine').exists());
});

test('renders quiz icon for quizzes', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ itemType: 'quiz' })} />
  );
  ok(wrapper.find('IconQuizLine').exists());
});

test('renders discussion icon for discussions', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ itemType: 'discussion_topic' })} />
  );
  ok(wrapper.find('IconDiscussionLine').exists());
});

test('renders announcement icon for announcements', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ itemType: 'announcement' })} />
  );
  ok(wrapper.find('IconAnnouncementLine').exists());
});

test('renders calendar icon for calendar events', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ itemType: 'calendar' })} />
  );
  ok(wrapper.find('IconCalendarMonthLine').exists());
});

test('renders page icon for pages', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ itemType: 'page' })} />
  );
  ok(wrapper.find('IconMsWordLine').exists());
});

test('renders note icon for planner_notes', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ itemType: 'planner_note' })} />
  );
  ok(wrapper.find('IconNoteLightLine').exists());
});

test('renders the courses short name when the item has an associated course', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps({ courseId: '1' })} />
  );
  const info = wrapper.find('.ToDoSidebarItem__Info');
  ok(info.text().match(/BGG 101/));
});

test('renders out points if the item has points', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps({ courseId: '1', points: 50 })} />
  );
  const info = wrapper.find('.ToDoSidebarItem__Info');
  ok(info.text().match(/50 points/));
});

test('renders out the due date in the proper format', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps()} />
  );
  const info = wrapper.find('.ToDoSidebarItem__Info');
  // The due date in was '2017-07-15T20:00:00-0600'
  // since this test is not running in canvas,
  // the user's profile TZ will default to UTC
  // and the output will be 6 hours later
  ok(info.text().indexOf('Jul 16 at  2:00am') > 0);
});

test('renders the title as a Link when given an href prop', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps({ href: '/some_example_url' })} />
  );
  const link = wrapper.find('.ToDoSidebarItem__Title').find('Link');
  ok(link.exists());
  equal(link.text(), 'Introduction to Board Games');
});

test('renders out the title as a Text when not given an href prop', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps()} />
  );
  const title = wrapper.find('.ToDoSidebarItem__Title').find('Text').first();
  ok(title.exists());
  equal(title.text(), 'Introduction to Board Games');
});

test('renders unique aria string for dismiss button', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps()} />
  );
  const dismissButton = wrapper.find('.ToDoSidebarItem__Close').find('Button');
  equal(dismissButton.props()['aria-label'], 'Dismiss Introduction to Board Games');
});

test('calls the handleDismissClick prop when the dismiss X is clicked', () => {
  const handleDismissClick = sinon.spy();
  const wrapper = mount(
    <ToDoItem
      {...getDefaultProps({
        itemType: 'planner_note',
        itemId: '1',
        handleDismissClick
      })}
    />
  );
  const btn = wrapper.find('Button');
  btn.simulate('click');
  ok(handleDismissClick.calledWith('planner_note', '1'));
});
