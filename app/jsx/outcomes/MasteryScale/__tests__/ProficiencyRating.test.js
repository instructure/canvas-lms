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

import React from 'react'
import {mount, shallow} from 'enzyme'
import ProficiencyRating from '../ProficiencyRating'

const defaultProps = (props = {}) => ({
  color: '00ff00',
  description: 'Stellar',
  disableDelete: false,
  mastery: false,
  onColorChange: () => {},
  onDelete: () => {},
  onDescriptionChange: () => {},
  onMasteryChange: () => {},
  onPointsChange: () => {},
  points: '10.0',
  position: 1,
  ...props
})

it('renders the ProficiencyRating component', () => {
  const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
  expect(wrapper).toMatchSnapshot()
})

it('mastery checkbox is checked if mastery', () => {
  const wrapper = shallow(
    <ProficiencyRating
      {...defaultProps({
        mastery: true
      })}
    />
  )
  const radio = wrapper.find('RadioInput')
  expect(radio.props().checked).toBe(true)
})

it('mastery checkbox receives focus', () => {
  const wrapper = mount(
    <div>
      <ProficiencyRating {...defaultProps({focusField: 'mastery'})} />
    </div>
  )
  expect(
    wrapper
      .find('RadioInput')
      .find('input')
      .instance()
  ).toBe(document.activeElement)
})

it('clicking mastery checkbox triggers change', () => {
  const onMasteryChange = jest.fn()
  const wrapper = mount(<ProficiencyRating {...defaultProps({onMasteryChange})} />)
  wrapper
    .find('RadioInput')
    .find('input')
    .simulate('change')
  expect(onMasteryChange).toHaveBeenCalledTimes(1)
})

it('includes the rating description', () => {
  const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
  const input = wrapper.find('TextInput').at(0)
  expect(input.prop('defaultValue')).toBe('Stellar')
})

it('changing description triggers change', () => {
  const onDescriptionChange = jest.fn()
  const wrapper = mount(<ProficiencyRating {...defaultProps({onDescriptionChange})} />)
  wrapper
    .find('TextInput')
    .at(0)
    .find('input')
    .simulate('change')
  expect(onDescriptionChange).toHaveBeenCalledTimes(1)
})

it('includes the points', () => {
  const wrapper = shallow(<ProficiencyRating {...defaultProps()} />)
  const input = wrapper.find('TextInput').at(1)
  expect(input.prop('defaultValue')).toBe('10')
})

it('changing points triggers change', () => {
  const onPointsChange = jest.fn()
  const wrapper = mount(<ProficiencyRating {...defaultProps({onPointsChange})} />)
  wrapper
    .find('TextInput')
    .at(1)
    .find('input')
    .simulate('change')
  expect(onPointsChange).toHaveBeenCalledTimes(1)
})

it('clicking delete button triggers delete', () => {
  const onDelete = jest.fn()
  const wrapper = mount(<ProficiencyRating {...defaultProps({onDelete})} />)
  wrapper
    .find('IconButton')
    .at(0)
    .simulate('click')
  expect(onDelete).toHaveBeenCalledTimes(1)
})

it('clicking disabled delete button does not triggers delete', () => {
  const onDelete = jest.fn()
  const wrapper = mount(
    <ProficiencyRating
      {...defaultProps({
        onDelete,
        disableDelete: true
      })}
    />
  )
  wrapper
    .find('IconButton')
    .at(0)
    .simulate('click')
  expect(onDelete).toHaveBeenCalledTimes(0)
})
