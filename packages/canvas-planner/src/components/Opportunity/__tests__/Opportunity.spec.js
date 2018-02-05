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
import { Opportunity } from '../index';
import Pill from '@instructure/ui-core/lib/components/Pill';

function defaultProps (options) {
  return {
    id: "1",
    dueAt: "2017-03-09T20:40:35Z",
    courseName: "course about stuff",
    opportunityTitle: "this is a description about the opportunity",
    points: 20,
    showPill: true,
    url: "http://www.non_default_url.com",
    timeZone: 'America/Denver',
    dismiss: () => {},
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
    animatableIndex: 1,
  };
}

it('renders the base component correctly', () => {
  const wrapper = shallow(
    <Opportunity {...defaultProps()} />
  );
  expect(wrapper).toMatchSnapshot();
});

it('calls the onClick prop when dismissed is clicked', () => {
  let tempProps = defaultProps();
  tempProps.dismiss = jest.fn();
  const wrapper = shallow(
    <Opportunity {...tempProps}/>
  );
  wrapper.find('Button').simulate('click');
  expect(tempProps.dismiss).toHaveBeenCalled();
});

it('renders the base component correctly without points', () => {
  let tempProps = defaultProps();
  tempProps.points = null;
  const wrapper = shallow(
    <Opportunity {...tempProps} />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders a Pill if passed showPill: true', () => {
  const props = defaultProps();
  const wrapper = shallow(<Opportunity {...props} />);
  expect(wrapper.find(Pill).length).toEqual(1);
});

it('does not render a Pill if passed showPill: false', () => {
  const props = defaultProps();
  props.showPill = false;
  const wrapper = shallow(<Opportunity {...props} />);
  expect(wrapper.find(Pill).length).toEqual(0);
});

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn();
  const fakeDeregister = jest.fn();
  const wrapper = mount(
    <Opportunity
      {...defaultProps()}
      id='1'
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      animatableIndex={42}
    />
  );
  const instance = wrapper.instance();
  expect(fakeRegister).toHaveBeenCalledWith('opportunity', instance, 42, ['1']);

  wrapper.setProps({id: '2', animatableIndex: 43});
  expect(fakeDeregister).toHaveBeenCalledWith('opportunity', instance, ['1']);
  expect(fakeRegister).toHaveBeenCalledWith('opportunity', instance, 43, ['2']);

  wrapper.unmount();
  expect(fakeDeregister).toHaveBeenCalledWith('opportunity', instance, ['2']);
});
