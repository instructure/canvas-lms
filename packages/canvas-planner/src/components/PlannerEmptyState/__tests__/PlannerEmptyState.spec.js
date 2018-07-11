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

function defaultProps(opts={}) {
  return {
    changeToDashboardCardView: ()=>{},
    onAddToDo: ()=>{},
    isCompletelyEmpty: true,
    ...opts
  };
}

it('renders desert when completely empty', () => {
  const wrapper = shallow(<PlannerEmptyState {...defaultProps()} />);
  expect(wrapper).toMatchSnapshot();
});

it('renders balloons when not completely empty', () => {
  const wrapper = shallow(<PlannerEmptyState {...defaultProps({isCompletelyEmpty: false})} /> );
  expect(wrapper.find('.balloons').length).toEqual(1);
  expect(wrapper.find('.desert').length).toEqual(0);
});

it('does not changeToDashboardCardView on mount', () => {
  const mockDispatch = jest.fn();

  const changeToDashboardCardView = mockDispatch;

  mount(<PlannerEmptyState {...defaultProps({changeToDashboardCardView})} /> );
  expect(changeToDashboardCardView).not.toHaveBeenCalled();
});

it('calls changeToDashboardCardView on link click', () => {
  const mockDispatch = jest.fn();

  const changeToDashboardCardView = mockDispatch;

  const wrapper = mount(<PlannerEmptyState {...defaultProps({changeToDashboardCardView, isCompletelyEmpty:true})} /> );
  const button = wrapper.find('#PlannerEmptyState_CardView');

  button.simulate('click');
  expect(changeToDashboardCardView).toHaveBeenCalled();
});

it('does not call changeToDashboardCardView on false prop', () => {
  const wrapper = mount(<PlannerEmptyState {...defaultProps({isCompletelyEmpty:true})} /> );
  const button = wrapper.find('#PlannerEmptyState_CardView');

  button.simulate('click');
  expect(() => {
    button.simulate('click');
  }).not.toThrow();
});