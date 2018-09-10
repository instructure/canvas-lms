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

import ToDoItem from '../ToDoItem';
import React from 'react';
import { shallow, mount } from 'enzyme';
import moment from 'moment-timezone';

const getDefaultProps = overrides => ({
  handleDismissClick () {},
  item: {
    type: 'Assignment',
    title: 'Introduction to Board Games',
    course_id: null,
    date: moment('2017-07-15T20:00:00-0600'),
    ...overrides
  },
  courses: [{
    id: '1',
    shortName: 'BGG 101'
  }, {
    id: '2',
    shortName: 'BGG 201'
  }],
});

it('renders assignment icon for assignments', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ type: 'Assignment' })} />
  );
  expect(wrapper.find('IconAssignment').exists()).toBe(true);
});

it('renders quiz icon for quizzes', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ type: 'Quiz' })} />
  );
  expect(wrapper.find('IconQuiz').exists()).toBe(true);
});

it('renders discussion icon for discussions', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ type: 'Discussion' })} />
  );
  expect(wrapper.find('IconDiscussion').exists()).toBe(true);
});

it('renders announcement icon for announcements', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ type: 'Announcement' })} />
  );
  expect(wrapper.find('IconAnnouncement').exists()).toBe(true);
});

it('renders calendar icon for calendar events', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ type: 'Calendar Event' })} />
  );
  expect(wrapper.find('IconCalendarMonth').exists()).toBe(true);
});

it('renders page icon for pages', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ type: 'Page' })} />
  );
  expect(wrapper.find('IconMsWord').exists()).toBe(true);
});

it('renders peer review icon for peer reviews', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ type: 'Peer Review' })} />
  );
  expect(wrapper.find('IconPeerReview').exists()).toBe(true);
});

it('renders note icon for planner_notes', () => {
  const wrapper = shallow(
    <ToDoItem {...getDefaultProps({ type: '' })} />
  );
  expect(wrapper.find('IconNote').exists()).toBe(true);
});

it('renders the courses short name when the item has an associated course', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps({ course_id: '1' })} />
  );
  const info = wrapper.find('.ToDoSidebarItem__Info');
  expect(info.text()).toMatch(/BGG 101/);
});

it('renders out points if the item has points', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps({ course_id: '1', points: 50 })} />
  );
  const info = wrapper.find('.ToDoSidebarItem__Info');
  expect(info.text()).toMatch(/50 points/);
});

// TODO: need to unskip this test when we figure out how to use canvas's locale formats
xit('renders out the due date in the proper format', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps()} />
  );
  const info = wrapper.find('.ToDoSidebarItem__Info');
  // The due date in was '2017-07-15T20:00:00-0600'
  // since this test is not running in canvas,
  // the user's profile TZ will default to UTC
  // and the output will be 6 hours later
  expect(info.text()).toMatch('Jul 16 at  2:00am');
});

it('renders the title as a Link when given an href prop', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps({ html_url: '/some_example_url' })} />
  );
  const link = wrapper.find('.ToDoSidebarItem__Title').find('Link');
  expect(link.exists()).toBe(true);
  expect(link.text()).toBe('Introduction to Board Games');
});

it('renders out the title as a Text when not given an href prop', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps()} />
  );
  const title = wrapper.find('.ToDoSidebarItem__Title').find('Text').first();
  expect(title.exists()).toBe(true);
  expect(title.text()).toBe('Introduction to Board Games');
});

it('renders unique text for dismiss button', () => {
  const wrapper = mount(
    <ToDoItem {...getDefaultProps()} />
  );
  const dismissButton = wrapper.find('.ToDoSidebarItem__Close').find('Button');
  expect(dismissButton.text()).toBe('Dismiss Introduction to Board Games');
});

it('calls the handleDismissClick prop when the dismiss X is clicked', () => {
  const handleDismissClick = jest.fn();
  const wrapper = mount(
    <ToDoItem
      {...getDefaultProps()}
      handleDismissClick={handleDismissClick}
    />
  );
  const btn = wrapper.find('Button');
  btn.simulate('click');
  expect(handleDismissClick).toHaveBeenCalledWith(expect.objectContaining({
    type: 'Assignment',
    title: 'Introduction to Board Games',
  }));
});
