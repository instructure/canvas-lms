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
import React from 'react'
import {shallow, mount} from 'enzyme'
import ShowOnFocusButton from '../index'

it('renders a ScreenReaderContent by default', () => {
  const wrapper = shallow(<ShowOnFocusButton>Button</ShowOnFocusButton>)

  expect(wrapper).toMatchSnapshot()
})

it('renders a Button when it has focus', () => {
  const wrapper = mount(<ShowOnFocusButton>Button</ShowOnFocusButton>)

  wrapper.find('Button').simulate('focus')
  expect(wrapper.find('ScreenReaderContent').exists()).toBe(false)
})

it('renders ScreeenReaderContent after blur', () => {
  const wrapper = mount(<ShowOnFocusButton>Button</ShowOnFocusButton>)

  wrapper.find('Button').simulate('focus')
  expect(wrapper.find('ScreenReaderContent').exists()).toBe(false)

  wrapper.find('Button').simulate('blur')
  expect(wrapper.find('ScreenReaderContent').exists()).toBe(true)
})
