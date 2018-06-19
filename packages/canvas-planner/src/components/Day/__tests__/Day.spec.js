/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React from 'react';
import { shallow, mount } from 'enzyme';
import moment from 'moment-timezone';
import {Day} from '../index';

it('renders the base component with required props', () => {
  const wrapper = shallow(
    <Day timeZone="America/Denver" day="2017-04-25" />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders the friendly name in large text when it is today', () => {
  const today = moment();

  const wrapper = shallow(
    <Day timeZone="America/Denver" day={today.format('YYYY-MM-DD')} />
  );
  expect(wrapper.find('Text').first().props().size).toEqual('large');
});

it('renders the friendlyName in medium text when it is not today', () => {
  const yesterday = moment().add(1, 'days');
  const wrapper = shallow(
    <Day timeZone="America/Denver" day={yesterday.format('YYYY-MM-DD')} />
  );
  expect(wrapper.find('Text').first().props().size).toEqual('medium');
});

it('groups itemsForDay based on context type + context id', () => {
  const items = [{
    title: 'Black Friday',
    context: {
      type: 'Course',
      id: 128,
      inform_students_of_overdue_submissions: true
    }
  }, {
    title: 'San Juan',
    context: {
      type: 'Course',
      id: 256,
      inform_students_of_overdue_submissions: true
    }
  }, {
    title: 'Roll for the Galaxy',
    context: {
      type: 'Course',
      id: 256,
      inform_students_of_overdue_submissions: true
    }
  }, {
      title: 'Same id, different type',
      context: {
        type: 'Group',
        id: 256,
        inform_students_of_overdue_submissions: false
      }
  }];

  const wrapper = shallow(
    <Day timeZone="America/Denver" day="2017-04-25" itemsForDay={items} />
  );
  const groupedItems = wrapper.state('groupedItems');
  expect(groupedItems['Course128'].length).toEqual(1);
  expect(groupedItems['Course256'].length).toEqual(2);
  expect(groupedItems['Group256'].length).toEqual(1);
});

it('renders grouping correctly when having itemsForDay', () => {
  const items = [{
    title: 'Black Friday',
    context: {
      type: 'Course',
      id: 128,
      url:"http://www.non_default_url.com",
      inform_students_of_overdue_submissions: true
    }
  }, {
    title: 'San Juan',
    context: {
      type: 'Course',
      id: 256,
      url:"http://www.non_default_url.com",
      inform_students_of_overdue_submissions: true
    }
  }, {
    title: 'Roll for the Galaxy',
    context: {
      type: 'Course',
      id: 256,
      url:"http://www.non_default_url.com",
      inform_students_of_overdue_submissions: true
    }
  }, {
      title: 'Same id, different type',
      context: {
        type: 'Group',
        id: 256,
        inform_students_of_overdue_submissions: false
      }
  }];

  const wrapper = shallow(
    <Day timeZone="America/Denver" day="2017-04-25" itemsForDay={items} />
  );
  expect(wrapper).toMatchSnapshot();
});
it('groups itemsForDay that have no context into the "Notes" category', () => {
  const items = [{
    title: 'Black Friday',
    context: {
      type: 'Course',
      id: 128,
      inform_students_of_overdue_submissions: true
    }
  }, {
    title: 'San Juan',
    context: {
      type: 'Course',
      id: 256,
      inform_students_of_overdue_submissions: true
    }
  }, {
    title: 'Roll for the Galaxy',
    context: {
      type: 'Course',
      id: 256,
      inform_students_of_overdue_submissions: true
    }
  }, {
    title: 'Get work done!'
  }];

  const wrapper = shallow(
    <Day timeZone="America/Denver" day="2017-04-25" itemsForDay={items} />
  );
  const groupedItems = wrapper.state('groupedItems');
  expect(groupedItems.Notes.length).toEqual(1);
});

it('groups itemsForDay that come in on prop changes', () => {
  const items = [{
    title: 'Black Friday',
    context: {
      type: 'Course',
      id: 128,
      inform_students_of_overdue_submissions: true
    }
  }, {
    title: 'San Juan',
    context: {
      type: 'Course',
      id: 256,
      inform_students_of_overdue_submissions: true
    }
  }];

  const wrapper = shallow(
    <Day timeZone="America/Denver" day="2017-04-25" itemsForDay={items} registerAnimatable={() => {}} deregisterAnimatable={() => {}} />
  );
  let groupedItems = wrapper.state('groupedItems');
  expect(Object.keys(groupedItems).length).toEqual(2);

  const newItemsForDay = items.concat([{
    title: 'Roll for the Galaxy',
    context: {
      type: 'Course',
      id: 256,
      inform_students_of_overdue_submissions: true
    }
  }, {
    title: 'Get work done!'
  }]);

  wrapper.setProps({ itemsForDay: newItemsForDay });
  groupedItems = wrapper.state('groupedItems');
  expect(Object.keys(groupedItems).length).toEqual(3);
});


it('renders even when there are no items', () => {
  const date = moment.tz("Asia/Tokyo").add(13, 'days');
  const wrapper = shallow(
    <Day timeZone="Asia/Tokyo" day={date.format('YYYY-MM-DD')} itemsForDay={[]} />
  );
  expect(wrapper.type).not.toBeNull();
});

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn();
  const fakeDeregister = jest.fn();
  const firstItems = [{title: 'asdf', context: {id: 128, inform_students_of_overdue_submissions: true}, id: '1', uniqueId: 'first'}, {title: 'jkl', context: {id: 256, inform_students_of_overdue_submissions: true}, id: '2', uniqueId: 'second'}];
  const secondItems = [{title: 'qwer', context: {id: 128, inform_students_of_overdue_submissions: true}, id: '3', uniqueId: 'third'}, {title: 'uiop', context: {id: 256, inform_students_of_overdue_submissions: true}, id: '4', uniqueId: 'fourth'}];
  const wrapper = mount(
    <Day
      day={'2017-08-11'}
      timeZone="Asia/Tokyo"
      animatableIndex={42}
      itemsForDay={firstItems}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      updateTodo={() => {}}
    />
  );
  const instance = wrapper.instance();
  expect(fakeRegister).toHaveBeenCalledWith('day', instance, 42, ['first', 'second']);

  wrapper.setProps({itemsForDay: secondItems});
  expect(fakeDeregister).toHaveBeenCalledWith('day', instance, ['first', 'second']);
  expect(fakeRegister).toHaveBeenCalledWith('day', instance, 42, ['third', 'fourth']);

  wrapper.unmount();
  expect(fakeDeregister).toHaveBeenCalledWith('day', instance, ['third', 'fourth']);
});
