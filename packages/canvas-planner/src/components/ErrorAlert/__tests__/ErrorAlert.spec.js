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
import ErrorAlert from '../index';
import {shallow} from 'enzyme';

it('renders', () => {
  const wrapper = shallow(<ErrorAlert>uh oh</ErrorAlert>);
  expect(wrapper).toMatchSnapshot();
});

it('renders with string details', () => {
  const wrapper = shallow(<ErrorAlert error='whoops'>uh oh</ErrorAlert>);
  expect(wrapper).toMatchSnapshot();
});

it('renders with Error details', () => {
  const wrapper = shallow(<ErrorAlert error={new Error('whoops')}>uh oh</ErrorAlert>);
  expect(wrapper).toMatchSnapshot();
});
