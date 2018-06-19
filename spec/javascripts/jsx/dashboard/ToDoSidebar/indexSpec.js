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

import { ToDoSidebar } from 'jsx/dashboard/ToDoSidebar';
import { shallow, mount } from 'enzyme';
import React from 'react';

import ButtonLink from '@instructure/ui-core/lib/components/Link';

QUnit.module('ToDoSidebar Index');

const defaultProps = {
  loadInitialItems: () => {},
  completeItem: () => {},
  items: [],
  courses: []
};

test('displays a spinner when the loading prop is true', () => {
  const wrapper = shallow(<ToDoSidebar {...defaultProps} loading />);
  ok(wrapper.find('Spinner').exists());
});

test('calls loadItems prop on mount', () => {
  const fakeLoadItems = sinon.spy();
  mount(<ToDoSidebar {...defaultProps} loadInitialItems={fakeLoadItems} />);
  ok(fakeLoadItems.called);
});

test('renders out ToDoItems for each item', () => {
  const items = [{
    plannable_id: '1',
    plannable_type: 'assignment',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Rome'
    }
  }, {
    plannable_id: '2',
    plannable_type: 'quiz',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Rome'
    }
  }];
  const wrapper = shallow(
    <ToDoSidebar
      {...defaultProps}
      items={items}
    />
  );
  equal(wrapper.find('ToDoItem').length, 2);
});

test('initially renders out 5 ToDoItems', () => {
  const items = [{
    plannable_id: '1',
    plannable_type: 'assignment',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Rome'
    }
  }, {
    plannable_id: '2',
    plannable_type: 'quiz',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Orange County'
    }
  }, {
    plannable_id: '3',
    plannable_type: 'assignment',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to China'
    }
  }, {
    plannable_id: '4',
    plannable_type: 'quiz',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Egypt'
    }
  }, {
    plannable_id: '5',
    plannable_type: 'assignment',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Sacramento'
    }
  }, {
    plannable_id: '6',
    plannable_type: 'quiz',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Atlantis'
    }
  }, {
    plannable_id: '7',
    plannable_type: 'quiz',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Hoboville'
    }
  }];

  const wrapper = shallow(
    <ToDoSidebar
      {...defaultProps}
      items={items}
    />
  );
  equal(wrapper.find('ToDoItem').length, 5);
});

test('initially renders out all ToDoItems when link is clicked', () => {
  const items = [{
    plannable_id: '1',
    plannable_type: 'assignment',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Rome'
    }
  }, {
    plannable_id: '2',
    plannable_type: 'quiz',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Orange County'
    }
  }, {
    plannable_id: '3',
    plannable_type: 'assignment',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to China'
    }
  }, {
    plannable_id: '4',
    plannable_type: 'quiz',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Egypt'
    }
  }, {
    plannable_id: '5',
    plannable_type: 'assignment',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Sacramento'
    }
  }, {
    plannable_id: '6',
    plannable_type: 'quiz',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Atlantis'
    }
  }, {
    plannable_id: '7',
    plannable_type: 'quiz',
    plannable_date: '2017-07-15T20:00:00Z',
    plannable: {
      name: 'Glory to Hoboville'
    }
  }];

  const wrapper = shallow(
    <ToDoSidebar
      {...defaultProps}
      items={items}
    />
  );
  wrapper.find(ButtonLink).simulate('click');
  equal(wrapper.find('ToDoItem').length, 7);
});

test('does not render out items that are completed', () => {
  const items = [{
    plannable_id: '1',
    plannable_type: 'assignment',
    plannable_date: '2017-07-15T20:00:00Z',
    planner_override: {
      marked_complete: true
    },
    plannable: {
      name: 'Glory to Rome'
    }
  }, {
    plannable_id: '2',
    plannable_type: 'quiz',
    plannable_date: '2017-07-15T20:00:00Z',
    planner_override: {
      marked_complete: true
    },
    plannable: {
      name: 'Glory to Rome'
    }
  }];
  const wrapper = shallow(
    <ToDoSidebar
      {...defaultProps}
      items={items}
    />
  );
  equal(wrapper.find('ToDoItem').length, 0);
});
