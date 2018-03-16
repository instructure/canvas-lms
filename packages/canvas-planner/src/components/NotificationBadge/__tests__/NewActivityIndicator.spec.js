/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import { shallow, mount } from 'enzyme';
import { NewActivityIndicator } from '../NewActivityIndicator';

it('passes props to Indicator', () => {
  const wrapper = shallow(<NewActivityIndicator
    title={'some title'}
    itemIds={['1', '2']}
  />);
  expect(wrapper).toMatchSnapshot();
});

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn();
  const fakeDeregister = jest.fn();
  const wrapper = mount(<NewActivityIndicator
    title={'some title'}
    itemIds={['first', 'second']}
    registerAnimatable={fakeRegister}
    deregisterAnimatable={fakeDeregister}
    animatableIndex={42}
  />);
  const instance = wrapper.instance();
  expect(fakeRegister).toHaveBeenCalledWith('new-activity-indicator', instance, 42, ['first', 'second']);

  wrapper.setProps({animatableIndex: 84, itemIds: ['third', 'fourth']});
  expect(fakeDeregister).toHaveBeenCalledWith('new-activity-indicator', instance, ['first', 'second']);
  expect(fakeRegister).toHaveBeenCalledWith('new-activity-indicator', instance, 84, ['third', 'fourth']);

  wrapper.unmount();
  expect(fakeDeregister).toHaveBeenCalledWith('new-activity-indicator', instance, ['third', 'fourth']);
});
