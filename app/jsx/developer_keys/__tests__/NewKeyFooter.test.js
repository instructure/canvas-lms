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
import NewKeyFooter from '../NewKeyFooter'

function newProps() {
  return {
    onCancelClick: jest.fn(),
    onSaveClick: jest.fn()
  }
}

let wrapper = 'empty wrapper'

afterEach(() => {
  wrapper.unmount()
})

it("Calls 'onCancelClick' when the cancel button is clicked", () => {
  const props = newProps()
  wrapper = mount(<NewKeyFooter {...props} />)
  wrapper
    .find('Button')
    .first()
    .simulate('click')
  expect(props.onCancelClick).toHaveBeenCalled()
})

it("Calls 'onSaveClick' when the save button is clicked", () => {
  const props = newProps()
  wrapper = mount(<NewKeyFooter {...props} />)
  wrapper
    .find('Button')
    .at(1)
    .simulate('click')
  expect(props.onSaveClick).toHaveBeenCalled()
})
