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
import {PlannerItem} from '../index';
import moment from 'moment-timezone';

const DEFAULT_DATE = moment.tz('2011-12-17T03:30:00', "America/Los_Angeles");

function defaultProps (option = {}) {
  return {
      color: '#d71f85',
      id: "1",
      uniqueId: "one",
      associated_item: option.associated_item || "Assignment",
      date: option.date,
      courseName: 'A Course about being Diffrient',
      completed: !!option.completed,
      title: option.title || "This Assignment is about awesome stuff",
      points: option.points,
      html_url: option.html_url,
      toggleCompletion: () => {},
      updateTodo: () => {},
      currentUser: {id: '1', displayName: 'Jane', avatarUrl: '/picture/is/here'},
  };
}

function noteProps (option) {
  return {
      id: "22",
      uniqueId: "twenty-two",
      associated_item: null,
      date: option.date,
      courseName: option.courseName,
      completed: !!option.completed,
      title: option.title || "A note about note taking",
      toggleCompletion: () => {},
      updateTodo: () => {},
      currentUser: {id: '1', displayName: 'Jane', avatarUrl: '/picture/is/here'},
  };
}

function groupProps (option) {
  return {
    "color": "#F06291",
    "completed": false,
    "id": "25",
    "uniqueId": "wiki_page-25",
    "courseName": "Account-level group 1",
    "context": {
      "type": "Group",
      "id": "9",
      "title": "Account-level group 1",
      "inform_students_of_overdue_submissions": false,
      "color": "#F06291",
      "url": "/groups/9"
    },
    "date": DEFAULT_DATE,
    "associated_item": "Page",
    "title": "this is an account-level group page",
    "html_url": "/groups/9/pages/this-is-an-account-level-group-page",
    "badges": [],
    toggleCompletion: () => {},
    updateTodo: () => {},
    currentUser: {id: '1', displayName: 'Jane', avatarUrl: '/picture/is/here'},
  };
}

it('renders correctly', () => {
  const wrapper = shallow(
    <PlannerItem {...defaultProps({points: 35, date: DEFAULT_DATE})} />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Quiz correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Quiz',
          completed: true,
          title: "I am a Quiz",
          points: 4,
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Quiz correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Quiz',
          completed: false,
          title: "I am a Quiz",
          points: 2,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Quiz correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Quiz',
          completed: false,
          title: "I am a Quiz",
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Quiz correctly with just date', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Quiz',
          completed: false,
          title: "I am a Quiz",
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Assignment correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Assignment',
          completed: true,
          title: "I am a Assignment",
          points: 4,
          html_url: "http://www.non_default_url.com",
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Assignment correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Assignment',
          completed: false,
          title: "I am a Assignment",
          points: 2,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Assignment correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Assignment',
          completed: false,
          title: "I am a Assignment",
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Assignment correctly with just date', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Assignment',
          completed: false,
          title: "I am a Assignment",
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Discussion correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Discussion',
          completed: true,
          title: "I am a Discussion",
          points: 4,
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Discussion correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Discussion',
          completed: false,
          title: "I am a Discussion",
          points: 2,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Discussion correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Discussion',
          completed: false,
          title: "I am a Discussion",
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Discussion correctly with just date', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Discussion',
          completed: false,
          title: "I am a Discussion",
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Announcement correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Announcement',
          completed: true,
          title: "I am a Announcement",
          points: 4,
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Announcement correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Announcement',
          completed: false,
          title: "I am a Announcement",
          points: 2,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Announcement correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Announcement',
          completed: false,
          title: "I am a Announcement",
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Announcement correctly with just date', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Announcement',
          completed: false,
          title: "I am a Announcement",
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Calendar Event correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Calendar Event',
          completed: true,
          title: "I am a Calendar Event",
          points: 4,
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Calendar Event correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Calendar Event',
          completed: false,
          title: "I am a Calendar Event",
          points: 2,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Calendar Event correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Calendar Event',
          completed: false,
          title: "I am a Calendar Event",
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Calendar Event correctly with just date', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Calendar Event',
          completed: false,
          title: "I am a Calendar Event",
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Page correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Page',
          completed: true,
          title: "I am a Page",
          points: 4,
          date: DEFAULT_DATE,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Page correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Page',
          completed: false,
          title: "I am a Page",
          points: 2,
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Page correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...defaultProps(
        {
          associated_item: 'Page',
          completed: false,
          title: "I am a Page",
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Page correctly with just date', () => {
  let props = defaultProps(
    {
      associated_item: 'Page',
      completed: false,
      title: "I am a Page",
      date: DEFAULT_DATE,
    }
  );
  props.courseName = null;
  const wrapper = shallow(
    <PlannerItem {
      ...props
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Note correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...noteProps(
        {
          completed: true,
          title: "I am a Note",
          date: DEFAULT_DATE,
          courseName: 'Math 101'
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Note correctly without Course', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...noteProps(
        {
          associated_item: 'Note',
          completed: false,
          title: "I am a Note",
        })
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders Note correctly with Group', () => {
  const wrapper = shallow(
    <PlannerItem {
      ...groupProps()
    } />
  );
  expect(wrapper).toMatchSnapshot();
});

it('displays Pills when given them', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({points: 35, date: DEFAULT_DATE})}
      onClick={() => {}}
      itemCount={3}
      badges={[{id: 'new_grades', text: 'Graded' }]}
    />
  );

  expect(wrapper.find('Pill')).toHaveLength(1);
});

it('calls toggleCompletion when the checkbox is clicked', () => {
  const mock = jest.fn();
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({points: 35, date: DEFAULT_DATE})}
      toggleCompletion={mock}
    />
  );
  wrapper.find('Checkbox').simulate('change');
  expect(mock).toBeCalled();
});

it('disables the checkbox when toggleAPIPending is true', () => {
  const mock = jest.fn();
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({points: 35, date: DEFAULT_DATE})}
      toggleAPIPending={true}
      toggleCompletion={mock}
    />
  );
  wrapper.find('Checkbox').simulate('change');
  expect(wrapper.find('Checkbox').node.props.disabled).toBe(true);
});

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn();
  const fakeDeregister = jest.fn();
  const wrapper = mount(
    <PlannerItem
      {...defaultProps()}
      id="1"
      uniqueId="first"
      animatableIndex={42}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
    />
  );
  const instance = wrapper.instance();
  expect(fakeRegister).toHaveBeenCalledWith('item', instance, 42, ['first']);

  wrapper.setProps({uniqueId: 'second'});
  expect(fakeDeregister).toHaveBeenCalledWith('item', instance, ['first']);
  expect(fakeRegister).toHaveBeenCalledWith('item', instance, 42, ['second']);

  wrapper.unmount();
  expect(fakeDeregister).toHaveBeenCalledWith('item', instance, ['second']);
});
