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

import { ToDoSidebar } from '../index';
import { shallow, mount } from 'enzyme';
import React from 'react';
import moment from 'moment-timezone';

const defaultProps = {
  sidebarLoadInitialItems: () => {},
  sidebarCompleteItem: () => {},
  loaded: true,
  items: [],
  courses: [],
  changeDashboardView: () => {},
};

it('displays a spinner when the loaded prop is false', () => {
  const wrapper = shallow(<ToDoSidebar {...defaultProps} loaded={false} />);
  expect(wrapper.find('Spinner').exists()).toBe(true);
});

it('calls loadItems prop on mount', () => {
  const fakeLoadItems = jest.fn();
  mount(<ToDoSidebar {...defaultProps} sidebarLoadInitialItems={fakeLoadItems} />);
  expect(fakeLoadItems).toHaveBeenCalled();
});

it('renders out ToDoItems for each item', () => {
  const items = [{
    uniqueId: '1',
    type: 'Assignment',
    date: moment('2017-07-15T20:00:00Z'),
    title: 'Glory to Rome',
  }, {
    uniqueId: '2',
    type: 'Quiz',
    date: moment('2017-07-15T20:00:00Z'),
    title: 'Glory to Rome',
  }];
  const wrapper = shallow(
    <ToDoSidebar
      {...defaultProps}
      items={items}
    />
  );
  expect(wrapper.find('ToDoItem')).toHaveLength(2);
});

it('initially renders out 5 ToDoItems', () => {
  const items = [{
    uniqueId: '1',
    type: 'Assignment',
    date: moment('2017-07-15T20:00:00Z'),
    title: 'Glory to Rome',
  }, {
    uniqueId: '2',
    type: 'Quiz',
    date: moment('2017-07-15T20:00:00Z'),
    title: 'Glory to Orange County',
  }, {
    uniqueId: '3',
    type: 'Assignment',
    date: moment('2017-07-15T20:00:00Z'),
    title: 'Glory to China',
  }, {
    uniqueId: '4',
    type: 'Quiz',
    date: moment('2017-07-15T20:00:00Z'),
    title: 'Glory to Egypt',
  }, {
    uniqueId: '5',
    type: 'Assignment',
    date: moment('2017-07-15T20:00:00Z'),
    title: 'Glory to Sacramento',
  }, {
    uniqueId: '6',
    type: 'Quiz',
    date: moment('2017-07-15T20:00:00Z'),
    title: 'Glory to Atlantis',
  }, {
    uniqueId: '7',
    type: 'Quiz',
    date: moment('2017-07-15T20:00:00Z'),
    title: 'Glory to Hoboville',
  }];

  const wrapper = shallow(
    <ToDoSidebar
      {...defaultProps}
      items={items}
    />
  );
  expect(wrapper.find('ToDoItem')).toHaveLength(5);
});

it('invokes change dashboard view when link is clicked', () => {
  const changeDashboardView = jest.fn();
  const wrapper = shallow(
    <ToDoSidebar {...defaultProps} changeDashboardView={changeDashboardView} />
  );
  wrapper.find('Button').simulate('click');
  expect(changeDashboardView).toHaveBeenCalledWith('planner');
});

it('does not render out items that are completed', () => {
  const items = [{
    uniqueId: '1',
    plannable_type: 'assignment',
    date: moment('2017-07-15T20:00:00Z'),
    completed: true,
    title: 'Glory to Rome',
  }, {
    uniqueId: '2',
    plannable_type: 'quiz',
    date: moment('2017-07-15T20:00:00Z'),
    completed: true,
    title: 'Glory to Rome',
  }];
  const wrapper = shallow(
    <ToDoSidebar
      {...defaultProps}
      items={items}
    />
  );
  expect(wrapper.find('ToDoItem')).toHaveLength(0);
});
