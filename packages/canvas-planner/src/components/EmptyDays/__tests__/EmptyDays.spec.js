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
import { shallow } from 'enzyme';
import MockDate from 'mockdate';
import { EmptyDays } from '../index';

const TZ = 'Asia/Tokyo';

const getDefaultProps = (overrides = {}) => {
  return Object.assign({
    day: '2017-04-23',
    endday: '2017-04-26',
    animatableIndex: 0,
    timeZone: TZ,
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
  }, overrides);
};

beforeAll (() => {
  MockDate.set('2017-04-22', TZ);
});

afterAll (() => {
  MockDate.reset();
});

it('renders the component', () => {
  const wrapper = shallow(
    <EmptyDays {...getDefaultProps()} />
  );
  expect(wrapper).toMatchSnapshot();
});

it('renders the today className when surrounds Today', () => {
  const wrapper = shallow(
    <EmptyDays {...getDefaultProps({day: '2017-04-22'})} />
  );
  expect(wrapper).toMatchSnapshot();
});
