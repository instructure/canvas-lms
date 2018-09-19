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
import {Grouping} from '../index';

const getDefaultProps = () => ({
  items: [{
    id: "5",
    uniqueId: "five",
    title: 'San Juan',
    date: moment.tz('2017-04-25T05:06:07-08:00', "America/Denver"),
    context: {
      url: 'example.com',
      color: "#5678",
      id: 256,
    }
  }, {
    id: "6",
    uniqueId: "six",
    date: moment.tz('2017-04-25T05:06:07-08:00', "America/Denver"),
    title: 'Roll for the Galaxy',
    context: {
      color: "#5678",
      id: 256,
    }
  }],
  timeZone: "America/Denver",
  color: "#5678",
  id: 256,
  url: 'example.com',
  title: 'Board Games',
  updateTodo: () => {},
  animatableIndex: 1,
});

it('renders the base component with required props', () => {
  const wrapper = shallow(
    <Grouping {...getDefaultProps()} />
  );
  expect(wrapper).toMatchSnapshot();
});

it('grouping contains link pointing to course url', () => {
  const props = getDefaultProps();
  const wrapper = shallow(
    <Grouping {...props} />
  );

  expect(wrapper).toMatchSnapshot();
});

it('renders to do items correctly', () => {
  const props = {
    items: [{
      id: "700",
      uniqueId: "seven hundred",
      title: 'To Do 700',
      date: moment.tz('2017-06-16T05:06:07-06:00', "America/Denver"),
      context: null,
    }],
    timeZone: "America/Denver",
    color: null,
    id: null,
    url: null,
    title: null,
    updateTodo: () => {},
    animatableIndex: 1,
  };
  const wrapper = shallow(
    <Grouping {...props} />
  );
  expect(wrapper).toMatchSnapshot();
});

it('does not render completed items by default', () => {
  const props = getDefaultProps();
  props.items[0].completed = true;
  const wrapper = mount(
    <Grouping {...props} />
  );

  expect(wrapper.find('Animatable(ResponsivePlannerItem)')).toHaveLength(1);
});

it('renders a CompletedItemsFacade when completed items are present by default', () => {
  const props = getDefaultProps();
  props.items[0].completed = true;

  const wrapper = shallow(
    <Grouping {...props} />
  );

  expect(wrapper).toMatchSnapshot();
});

it('renders completed items when the facade is clicked', () => {
  const props = getDefaultProps();
  props.items[0].completed = true;

  const wrapper = mount(
    <Grouping {...props} />
  );

  wrapper.find('ToggleDetails button').simulate('click')
  expect(wrapper.find('Animatable(ResponsivePlannerItem)')).toHaveLength(2);
});

it('renders completed items when they have the show property', () => {
  const props = getDefaultProps();
  props.items[0].show = true;
  props.items[0].completed = true;

  const wrapper = shallow(
    <Grouping {...props} />
  );

  expect(wrapper.find('Animatable(ResponsivePlannerItem)')).toHaveLength(2);
});

it('does not render a CompletedItemsFacade when showCompletedItems state is true', () => {
  const props = getDefaultProps();
  props.items[0].completed = true;

  const wrapper = shallow(
    <Grouping {...props} />
  );

  wrapper.setState({ showCompletedItems: true });
  expect(wrapper.find('CompletedItemsFacade')).toHaveLength(0);
});

it('renders an activity notification when there is new activity', () => {
  const props = getDefaultProps();
  props.items[1].newActivity = true;
  const wrapper = shallow(
    <Grouping {...props} />
  );
  const nai = wrapper.find('Animatable(NewActivityIndicator)');
  expect(nai).toHaveLength(1);
  expect(nai.prop('title')).toBe(props.title);
});

it('does not render an activity notification when layout is not large', () => {
  const props = getDefaultProps();
  props.items[1].newActivity = true;
  props.responsiveSize = 'medium';
  const wrapper = shallow(
    <Grouping {...props} />
  );
  const nai = wrapper.find('Animatable(NewActivityIndicator)');
  expect(nai).toHaveLength(0);
});

it('renders a danger activity notification when there is a missing item', () => {
  const props = getDefaultProps();
  props.items[1].status = {missing: true};
  const wrapper = shallow(
    <Grouping {...props} />
  );
  expect(wrapper.find('MissingIndicator')).toHaveLength(1);
});

it(`does not render a danger activity notification when there is a missing item
  but the course is not configured to inform students of overdue submissions`, () => {
  const props = getDefaultProps();
  const item = props.items[1];
  item.status = { missing: true };
  const wrapper = shallow(<Grouping {...props} />);
  expect(wrapper.find('Badge')).toHaveLength(0);
  expect(wrapper.find('ScreenReaderContent')).toHaveLength(0);
});

it(`does not render a danger activity notification when there is a missing item
  but the course is not present`, () => {
  const props = getDefaultProps();
  const item = props.items[1];
  item.status = { missing: true };
  delete item.context;
  const wrapper = shallow(<Grouping {...props} />);
  expect(wrapper.find('Badge')).toHaveLength(0);
  expect(wrapper.find('ScreenReaderContent')).toHaveLength(0);
});

it('renders the to do title when there is no course', () => {
  let props = getDefaultProps();
  props.title = null;
  props.items[1].newActivity = true;
  const wrapper = shallow(
    <Grouping {...props} />
  );
  expect(wrapper.find('Animatable(NewActivityIndicator)').prop('title')).toBe('To Do');
});

it('does not render an activity badge when things have no new activity', () => {
  const props = getDefaultProps();
  const wrapper = shallow(
    <Grouping {...props} />
  );
  expect(wrapper.find('Badge')).toHaveLength(0);
});

describe('handleFacadeClick', () => {
  it('sets focus to the groupingLink when called', () => {
    const wrapper = mount(
      <Grouping {...getDefaultProps()} />
    );
    wrapper.instance().handleFacadeClick();
    expect(document.activeElement).toBe(wrapper.instance().groupingLink);
  });

  it('calls preventDefault on an event if given one', () => {
    const wrapper = mount(
      <Grouping {...getDefaultProps()} />
    );
    const fakeEvent = {
      preventDefault: jest.fn()
    };
    wrapper.instance().handleFacadeClick(fakeEvent);
    expect(fakeEvent.preventDefault).toHaveBeenCalled();
  });
});

describe('toggleCompletion', () => {
  it('binds the toggleCompletion method to item', () => {
    const mock = jest.fn();
    const props = getDefaultProps();
    const wrapper = mount(
      <Grouping
        {...props}
        toggleCompletion={mock}
      />
    );
    wrapper.find('input').first().simulate('change');
    expect(mock).toHaveBeenCalledWith(props.items[0]);
  });
});

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn();
  const fakeDeregister = jest.fn();
  const firstItems = [{title: 'asdf', context: {id: 128}, id: '1', uniqueId: 'first'}, {title: 'jkl', context: {id: 256}, id: '2', uniqueId: 'second'}];
  const secondItems = [{title: 'qwer', context: {id: 128}, id: '3', uniqueId: 'third'}, {title: 'uiop', context: {id: 256}, id: '4', uniqueId: 'fourth'}];
  const wrapper = mount(
    <Grouping
      {...getDefaultProps()}
      items={firstItems}
      animatableIndex={42}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
    />
  );
  const instance = wrapper.instance();
  expect(fakeRegister).toHaveBeenCalledWith('group', instance, 42, ['first', 'second']);

  wrapper.setProps({items: secondItems});
  expect(fakeDeregister).toHaveBeenCalledWith('group', instance, ['first', 'second']);
  expect(fakeRegister).toHaveBeenCalledWith('group', instance, 42, ['third', 'fourth']);

  wrapper.unmount();
  expect(fakeDeregister).toHaveBeenCalledWith('group', instance, ['third', 'fourth']);
});
