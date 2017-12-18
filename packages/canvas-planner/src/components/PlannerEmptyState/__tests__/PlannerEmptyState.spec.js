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
import PlannerEmptyState from '../index';

it('renders empty page', () => {
  const wrapper = shallow(<PlannerEmptyState changeToDashboardCardView={() => {}} />, );
  expect(wrapper).toMatchSnapshot();
});

it('does not changeToDashboardCardView on mount', () => {
  const mockDispatch = jest.fn();

  const changeToDashboardCardView = mockDispatch;

  mount(<PlannerEmptyState changeToDashboardCardView={changeToDashboardCardView} />, );
  expect(changeToDashboardCardView).not.toHaveBeenCalled();
});

it('calls changeToDashboardCardView on link click', () => {
  const mockDispatch = jest.fn();

  const changeToDashboardCardView = mockDispatch;

  const wrapper = mount(<PlannerEmptyState changeToDashboardCardView={changeToDashboardCardView} />, );
  const button = wrapper.find('Link').find('button');

  button.simulate('click');
  expect(changeToDashboardCardView).toHaveBeenCalled();
});

it('does not call changeToDashboardCardView on false prop', () => {
  const wrapper = mount(<PlannerEmptyState/>, );
  const button = wrapper.find('Link').find('button');

  button.simulate('click');
  expect(() => {
    button.simulate('click');
  }).not.toThrow();
});
