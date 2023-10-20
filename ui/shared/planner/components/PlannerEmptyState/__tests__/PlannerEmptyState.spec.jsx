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
import React from 'react'
import {shallow, mount} from 'enzyme'
import PlannerEmptyState from '../index'

function defaultProps(opts = {}) {
  return {
    changeDashboardView: () => {},
    onAddToDo: () => {},
    isCompletelyEmpty: true,
    isWeekly: false,
    ...opts,
  }
}

it('renders desert when completely empty', () => {
  const wrapper = shallow(<PlannerEmptyState {...defaultProps()} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders balloons when not completely empty', () => {
  const wrapper = shallow(<PlannerEmptyState {...defaultProps({isCompletelyEmpty: false})} />)
  expect(wrapper.find('.balloons').length).toEqual(1)
  expect(wrapper.find('.desert').length).toEqual(0)
  expect(wrapper.contains('Nothing More To Do')).toBeTruthy()
  expect(wrapper.contains('Add To-Do')).toBeTruthy()
})

it('renders balloons and different text when weekly', () => {
  const wrapper = shallow(
    <PlannerEmptyState {...defaultProps({isCompletelyEmpty: false, isWeekly: true})} />
  )
  expect(wrapper.find('.balloons').length).toEqual(1)
  expect(wrapper.find('.desert').length).toEqual(0)
  expect(wrapper.contains('Nothing Due This Week')).toBeTruthy()
  expect(wrapper.contains('Add To-Do')).toBeFalsy()
})

it('does not changeDashboardView on mount', () => {
  const mockDispatch = jest.fn()
  const changeDashboardView = mockDispatch
  mount(<PlannerEmptyState {...defaultProps({changeDashboardView})} />)
  expect(changeDashboardView).not.toHaveBeenCalled()
})

it('calls changeDashboardView on link click', () => {
  const mockDispatch = jest.fn()
  const changeDashboardView = mockDispatch
  const wrapper = mount(
    <PlannerEmptyState {...defaultProps({changeDashboardView, isCompletelyEmpty: true})} />
  )
  const button = wrapper.find('button#PlannerEmptyState_CardView')
  button.simulate('click')
  expect(changeDashboardView).toHaveBeenCalledWith('cards')
})

it('does not call changeDashboardView on false prop', () => {
  const wrapper = mount(<PlannerEmptyState {...defaultProps({isCompletelyEmpty: true})} />)
  const button = wrapper.find('button#PlannerEmptyState_CardView')
  button.simulate('click')
  expect(() => {
    button.simulate('click')
  }).not.toThrow()
})
