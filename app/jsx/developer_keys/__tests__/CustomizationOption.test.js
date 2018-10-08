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
import {mount} from 'enzyme'
import CustomizationOption from '../CustomizationOption'

function newProps(checked = false) {
  return {
    label: 'Manage Line Items',
    name: 'manage_line_items',
    type: 'scope',
    onChange: jest.fn(),
    checked,
    toggleStyle: {width: '25%'}
  }
}

let wrapper = 'empty wrapper'

afterEach(() => {
  wrapper.unmount()
})

it("uses the 'name' prop for the checkbox", () => {
  wrapper = mount(<CustomizationOption {...newProps()} />)
  expect(wrapper.find('Checkbox').instance().props.name).toEqual('manage_line_items')
})

it("checks the checkbox when 'checked' is true", () => {
  wrapper = mount(<CustomizationOption {...newProps(true)} />)
  expect(wrapper.find('Checkbox').instance().props.checked).toBeTruthy()
})

it("uses the 'toogleStyle' prop", () => {
  wrapper = mount(<CustomizationOption {...newProps()} />)
  expect(
    wrapper
      .find('td')
      .at(1)
      .instance().style._values
  ).toEqual({width: '25%'})
})

it("calls 'onChange' when changed", () => {
  const props = newProps()
  wrapper = mount(<CustomizationOption {...props} />)
  wrapper
    .find('Checkbox')
    .instance()
    .handleChange()
  expect(props.onChange).toHaveBeenCalled()
})
