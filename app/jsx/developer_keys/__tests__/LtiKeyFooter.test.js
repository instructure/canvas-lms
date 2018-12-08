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
import LtiKeyFooter from '../LtiKeyFooter'

function newProps(customizing = false) {
  return {
    onCancelClick: jest.fn(),
    onSaveClick: jest.fn(),
    onAdvanceToCustomization: jest.fn(),
    customizing,
    dispatch: jest.fn(),
    ltiKeysSetCustomizing: jest.fn()
  }
}

let wrapper = 'empty wrapper'

afterEach(() => {
  wrapper.unmount()
})

it("Calls 'onCancelClick' when the cancel button is clicked", () => {
  const props = newProps()
  wrapper = mount(<LtiKeyFooter {...props} />)
  wrapper
    .find('Button')
    .first()
    .simulate('click')
  expect(props.onCancelClick).toHaveBeenCalled()
})

it("Calls 'onSaveClick' when the save button is clicked", () => {
  const props = newProps(true)
  wrapper = mount(<LtiKeyFooter {...props} />)
  wrapper
    .find('Button')
    .at(1)
    .simulate('click')
  expect(props.onSaveClick).toHaveBeenCalled()
})

it("Renders the 'Next' button if not customizing", () => {
  wrapper = mount(<LtiKeyFooter {...newProps()} />)
  expect(
    wrapper
      .find('Button')
      .at(1)
      .text()
  ).toEqual('Save and Customize')
})

it("Renders the 'Save' button if not customizing", () => {
  wrapper = mount(<LtiKeyFooter {...newProps(true)} />)
  expect(
    wrapper
      .find('Button')
      .at(1)
      .text()
  ).toEqual('Save Customizations')
})

it("Disables the save button if disable is true", () => {
  wrapper = mount(<LtiKeyFooter {...newProps()} disable />)
  expect(
    wrapper
      .find('Button')
      .at(1)
      .props()
      .disabled
  ).toEqual(true)
})
